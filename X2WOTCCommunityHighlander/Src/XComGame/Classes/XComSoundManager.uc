// XCom Sound manager
// 
// Manages common sound and music related tasks for XCOM

class XComSoundManager extends Actor config(GameData);

struct native AkEventMapping
{
	var string strKey;
	var AkEvent TriggeredEvent;
};

// Start Issue #10
// Equivalent to AkEventMapping but for sound cues.
struct SoundCueMapping
{
    var string strKey;
    var SoundCue Cue;
};

// Alias structure for mapping a standard sound event to an alternative.
struct SoundAlias
{
    var string strKey;
    var string strValue;
};
// End Issue #10

// Sound Mappings
var config array<string> SoundEventPaths;
var config array<AkEventMapping> SoundEvents;

// Start Issue #10
// Add a configurable sound event path mapping allowing mods
// to replace any standard sound path with a custom version.
var config array<SoundAlias> SoundAliases;
// Add sound-cue based sounds
var config array<string> SoundCuePaths;
var config array<SoundCueMapping> SoundCues;
// End Issue #10

struct AmbientChannel
{
	var SoundCue Cue;
	var AudioComponent Component;
	var bool bHasPlayRequestPending;
};

// Map PostProcessEffect name to "on enable" and "on disable" AkEvent paths
struct PPEffectAkEventInfo
{
	var string EffectName;
	var string AkEventOnEnable;
	var string AkEventOnDisable;
	var bool bRetriggerable; // If true, enable event will still play when effect is active
};

var const config array<PPEffectAkEventInfo> PPEffectAkEventPaths;
var array<AkEventMapping> PPEffectSoundEvents; // Separate SoundEvents array for PPEffects because there will be duplicate AkEvent paths for PPEffects
var transient array<string> ActiveEffects; // This is to prevent multiple event triggers

//------------------------------------------------------------------------------
// AmbientChannel Management
//------------------------------------------------------------------------------
protected function SetAmbientCue(out AmbientChannel Ambience, SoundCue NewCue)
{
	if (NewCue != Ambience.Cue)
	{
		if (Ambience.Component != none && Ambience.Component.IsPlaying())
		{
			Ambience.Component.FadeOut(0.5f, 0.0f);
			Ambience.Component = none;
		}

		Ambience.Cue = NewCue;
		Ambience.Component = CreateAudioComponent(NewCue, false, true);

		if (Ambience.bHasPlayRequestPending)
			StartAmbience(Ambience);
	}
}

protected function StartAmbience(out AmbientChannel Ambience, optional float FadeInTime=0.5f)
{
	if (Ambience.Cue == none)
	{
		Ambience.bHasPlayRequestPending = true;
		return;
	}

	if (Ambience.Cue != none && Ambience.Component != none && ( !Ambience.Component.IsPlaying() || Ambience.Component.IsFadingOut() ) )
	{
		Ambience.Component.bIsMusic = (Ambience.Cue.SoundClass == 'Music'); // Make sure the music flag is correct
		Ambience.Component.FadeIn(FadeInTime, 1.0f);
	}
}

protected function StopAmbience(out AmbientChannel Ambience, optional float FadeOutTime=1.0f)
{
	Ambience.bHasPlayRequestPending = false;

	if (Ambience.Component != none && Ambience.Component.IsPlaying())
	{
		Ambience.Component.FadeOut(FadeOutTime, 0.0f);
	}
}

//------------------------------------------------------------------------------
// Music management
//------------------------------------------------------------------------------
function PlayMusic( SoundCue NewMusicCue, optional float FadeInTime=0.0f )
{
	local MusicTrackStruct MusicTrack;

	MusicTrack.TheSoundCue = NewMusicCue;
	MusicTrack.FadeInTime = FadeInTime;
	MusicTrack.FadeOutTime = 1.0f;
	MusicTrack.FadeInVolumeLevel = 1.0f;
	MusicTrack.bAutoPlay = true;

	`log("XComSoundManager.PlayMusic: Starting" @ NewMusicCue,,'DevSound');

	WorldInfo.UpdateMusicTrack(MusicTrack);
}

function StopMusic(optional float FadeOutTime=1.0f)
{
	local MusicTrackStruct MusicTrack;

	`log("XComSoundManager.StopMusic: Stopping" @ WorldInfo.CurrentMusicTrack.TheSoundCue,,'DevSound');

	MusicTrack.TheSoundCue = none;

	WorldInfo.CurrentMusicTrack.FadeOutTime = FadeOutTime;
	WorldInfo.UpdateMusicTrack(MusicTrack);
}

//---------------------------------------------------------------------------------------
function PlaySoundEvent(string strKey)
{
	local int Index;

	// Start Issue #10
	// Look for a sound alias first.
	Index = SoundAliases.Find('strKey', strKey);
	if (Index >= 0)
		strKey = SoundAliases[Index].strValue;
	// End Issue #10

	Index = SoundEvents.Find('strKey', strKey);

	if(Index != INDEX_NONE)
	{
		WorldInfo.PlayAkEvent(SoundEvents[Index].TriggeredEvent);
	}
	// Start Issue #10
	else
	{
		Index = SoundCues.Find('strKey', strKey);
		if (Index != INDEX_NONE)
		{
			PlaySound(SoundCues[Index].Cue);
		}
	}
	// End Issue #10
}

//---------------------------------------------------------------------------------------
function PlayPersistentSoundEvent(string strKey)
{
	local int Index;

	Index = SoundEvents.Find('strKey', strKey);

	if(Index != INDEX_NONE)
	{
		// Both Tactical and Strategy XCom sound managers have bUsePersistentSoundAkObject set to true,
		// so this will normally play on the Persistent Soundtrack object.
		PlayAkEvent(SoundEvents[Index].TriggeredEvent);
	}
}

//---------------------------------------------------------------------------------------
function Init()
{
	local int idx;
	local XComContentManager ContentMgr;

	ContentMgr = `CONTENT;

	// Load Events
	for( idx = 0; idx < SoundEventPaths.Length; idx++ )
	{
		ContentMgr.RequestObjectAsync(SoundEventPaths[idx], self, OnAkEventMappingLoaded);
	}

	// Load PostProcessEffect Events
	for( idx = 0; idx < PPEffectAkEventPaths.Length; idx++ )
	{
		ContentMgr.RequestObjectAsync(PPEffectAkEventPaths[idx].AkEventOnEnable, self, OnPPEffectAkEventMappingLoaded);
		ContentMgr.RequestObjectAsync(PPEffectAkEventPaths[idx].AkEventOnDisable, self, OnPPEffectAkEventMappingLoaded);
	}

	// Start Issue #10
	// Load sound cues
	for (idx = 0; idx < SoundCuePaths.Length; idx++ )
	{
		ContentMgr.RequestObjectAsync(SoundCuePaths[idx], self, OnSoundCueMappingLoaded);
	}
	// End Issue #10
}

//---------------------------------------------------------------------------------------
function OnAkEventMappingLoaded(object LoadedArchetype)
{
	local AkEvent TempEvent;
	local AkEventMapping EventMapping;

	TempEvent = AkEvent(LoadedArchetype);
	if( TempEvent != none )
	{
		EventMapping.strKey = string(TempEvent.name);
		EventMapping.TriggeredEvent = TempEvent;

		SoundEvents.AddItem(EventMapping);
	}
}

//---------------------------------------------------------------------------------------
function OnPPEffectAkEventMappingLoaded(object LoadedArchetype)
{
	local AkEvent TempEvent;
	local string TempEventPath;
	local AkEventMapping EventMapping;

	TempEvent = AkEvent(LoadedArchetype);
	if( TempEvent != none )
	{
		TempEventPath = PathName(TempEvent);
		if( PPEffectSoundEvents.Find('strKey', TempEventPath) == INDEX_NONE )
		{
			EventMapping.strKey = TempEventPath;
			EventMapping.TriggeredEvent = TempEvent;

			PPEffectSoundEvents.AddItem(EventMapping);
		}
	}
}

//---------------------------------------------------------------------------------------
function PlayPostProcessEffectTransitionAkEvents(name EffectName, bool bEffectEnabled)
{
	local int EffectIndex;
	local PPEffectAkEventInfo EffectEventInfo;
	local int IsActiveIndex;

	EffectIndex = PPEffectAkEventPaths.Find('EffectName', string(EffectName));
	if( EffectIndex != INDEX_NONE )
	{
		EffectEventInfo = PPEffectAkEventPaths[EffectIndex];
		IsActiveIndex = ActiveEffects.Find(EffectEventInfo.EffectName);

		if( bEffectEnabled ) // Enable
		{
			if( IsActiveIndex == INDEX_NONE )
			{
				PlayPPEffectAkEvent(EffectEventInfo.AkEventOnEnable);
				ActiveEffects.AddItem(EffectEventInfo.EffectName);
			}
			else if( EffectEventInfo.bRetriggerable ) // Separate branch for retriggerable sounds so that they don't add to ActiveEffects indefinitely
			{
				PlayPPEffectAkEvent(EffectEventInfo.AkEventOnEnable);
			}
		}
		else if( IsActiveIndex != INDEX_NONE ) // Disable
		{
			PlayPPEffectAkEvent(EffectEventInfo.AkEventOnDisable);
			ActiveEffects.RemoveItem(EffectEventInfo.EffectName);
		}
	}
}

//---------------------------------------------------------------------------------------
function PlayPPEffectAkEvent(string AkEventPath)
{
	local int AkEventIndex;

	AkEventIndex = PPEffectSoundEvents.Find('strKey', AkEventPath);
	if( AkEventIndex != INDEX_NONE )
	{
		PlayAkEvent(PPEffectSoundEvents[AkEventIndex].TriggeredEvent);
	}
}

// Start Issue #10
function OnSoundCueMappingLoaded(object LoadedArchetype)
{
    local SoundCue TempCue;
    local SoundCueMapping CueMapping;

    TempCue = SoundCue(LoadedArchetype);
    if (TempCue != none)
    {
        CueMapping.strKey = string(TempCue.name);
        CueMapping.Cue = TempCue;
        SoundCues.AddItem(CueMapping);
    }
}
// End Issue #10
