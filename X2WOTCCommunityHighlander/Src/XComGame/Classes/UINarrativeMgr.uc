//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UINarrativeMgr.uc
//  AUTHOR:  Brit Steiner -10/11/11
//  PURPOSE: This file corresponds to the narrative popup window with portrait in flash. 
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UINarrativeMgr extends TickableStateObject
	native(UI)
	dependson(XGNarrative, XGTacticalScreenMgr);

//----------------------------------------------------------------------------
// MEMBERS

enum EPreloadStatus
{
	ePendingPreload,
	ePreloaded,
	eNoPreloadRequested
};

struct native TConversation
{
	var name                                                CueName;                                               
	var SoundCue                                            ResolvedCue;
	var XComConversationNode                                ConversationNode;
	var AudioComponent                                      AudioComponent;
	var bool                                                bPendingAudioLoad;       // Pending Audio load
	var bool                                                bPendingMapLoad;    // Pending a streamed map load
	var delegate<OnNarrativeCompleteCallback>               m_NarrativeCompleteCallback;
	var delegate<PreRemoteEventCallback>                    m_PreRemoteEventCallback; // Called before the remote event is triggered
	var XComNarrativeMoment                                 NarrativeMoment;
	var bool                                                bFirstLineStarted;  // Has the first line of dialogue started (Used for kismet triggered moments)
	var bool                                                bMuffled;
	var Actor                                               ActorToLookAt;
	var bool                                                bFadedToBlack;
	var bool                                                bNoAudio;       // There was no audio requested for this conversation
	var EPreloadStatus                                      PreloadStatus;
	var bool                                                bUISound;
	var Vector                                              Location;
};

struct native TPreloadedConversation
{
	var name                                                CueName;
	var SoundCue                                            ResolvedCue;
	var XComNarrativeMoment                                 NarrativeMoment;
	var bool                                                bWasPreloadingWhenAddedToMgr;  // Its already a pending conversation because we were preloading when AddConversation was called
};

struct native TCurrentOutput
{
	var string strTitle;
	var string strImage;
	var string strText;

	var float  fTimeStarted;
	var float  fDuration;
};



var transient array<TPreloadedConversation> PendingPreloadConversations;  // Conversations that are actively being preloaded
var transient array<TPreloadedConversation> PreloadedConversations;   // Conversations that are finished preloading

var transient array<TConversation> PendingConversations;  // Conversations that are being loaded/pending load
var array<TConversation>        m_arrConversations;       // Conversations actively playing or queued to play, but already loaded (not preloaded)  

var array<TConversation> m_arrVOOnlyConversations; // These can play simultaneously as other conversations

var bool m_bIsModal; 
var UIScreen m_kTargetScreen; 

var localized string m_stNarrativeOk; 

var TCurrentOutput CurrentOutput;

var bool bActivelyPlayingConversation;

var bool bPaused;
var bool bWasPausedWhenStartFadeToBlack;

var transient SkeletalMeshActor CurrentFaceFxTargetActor;
var transient XComUnitPawn CurrentFaceFxTargetPawn;
var transient bool bPodRevealHappend;

var Vector m_vCurrentLookAt; 

var SeqEvent_HQUnits    kHQUnits;
var bool                m_bTentpoleStarted;

var float LastVOTime;

// While true, don't attempt to start the next conversation
var bool				DelayedStart;
var float				DelayedFadeDuration;

var float FailedAudioDuration; //A default duration to use if the audio cue fails ( due to the wise event not existing )

var delegate<OnNarrativeCompleteCallback> m_ActiveNarrativeCompleteCallback;
var delegate<PreRemoteEventCallback>      m_ActivePreRemoteEventCallback;

delegate OnNarrativeCompleteCallback();
delegate PreRemoteEventCallback();

simulated function Shutdown()
{
	local int i;

	for ( i = 0; i < m_arrConversations.Length; i++ )
	{
		m_arrConversations[i].AudioComponent.Stop();
	}

	m_arrConversations.Remove(0, m_arrConversations.Length);
}

simulated function SetPaused(bool bPause)
{
	if (bPaused == bPause)
		return;

	bPaused = bPause;

	if (!bPaused)
	{
		// Unpausing, check to see if there is something to play
		CheckConversationFullyLoaded();
		CheckForNextConversation();
		ShowComm();

	}
	else
	{
		HideComm();
	}
}


function float GetLastVOTime()
{
	return LastVOTime;
}

function bool AnyActiveConversations()
{
	return m_arrConversations.Length > 0 || PendingConversations.Length > 0 || bActivelyPlayingConversation;
}

simulated function StopNarrative(XComNarrativeMoment narrative)
{
	local int i;
	local delegate<OnNarrativeCompleteCallback> NarrativeCompleteCallback;

	if (narrative.IsVoiceOnly())
	{
		for (i = 0; i < m_arrVOOnlyConversations.Length; ++i)
		{
			if (m_arrVOOnlyConversations[i].NarrativeMoment == narrative)
			{
				NarrativeCompleteCallback = m_arrVOOnlyConversations[i].m_NarrativeCompleteCallback;
				if (NarrativeCompleteCallback != none)
					NarrativeCompleteCallback();

				// This also removes the conversation from the m_arrVOOnlyConversations array
				m_arrVOOnlyConversations[i].AudioComponent.Stop();

				break;
			}
		}
	}
	else
	{
		for (i = 0; i < m_arrConversations.Length; ++i)
		{
			if (m_arrConversations[i].NarrativeMoment == narrative)
			{
				NarrativeCompleteCallback = m_arrConversations[i].m_NarrativeCompleteCallback;
				if (NarrativeCompleteCallback != none)
					NarrativeCompleteCallback();

				// This also removes the conversation from the m_arrVOOnlyConversations array
				m_arrConversations[i].AudioComponent.Stop();

				break;
			}
		}
	}
}

simulated function StopConversations()
{
	local int i;
	local XComPresentationLayerBase pres;

	if (m_arrConversations.Length <= 0)
	{
		`log("UINarrativeMgr::StopConversations, but no active conversations!");
		return;
	}

	if( m_kTargetScreen != none )
	{
		m_kTargetScreen = none; 
	}

	pres = XComPresentationLayerBase(Outer); 
	if( m_bIsModal )
	{
		if(pres.GetStateName() != 'State_UINarrative')
			`warn("STATE STACK BUG: Narrative is not the top level of the expected state stack, and trying to pop out to clear self. Popping state: " $pres.GetStateName());
		pres.PopState(); 
	}

	// Clear out any timer, if necessary.
	XComPresentationLayerBase(Outer).ClearTimer( 'FinishConversation0', self );

	m_ActiveNarrativeCompleteCallback = m_arrConversations[0].m_NarrativeCompleteCallback;

	if (m_ActiveNarrativeCompleteCallback != none)
		m_ActiveNarrativeCompleteCallback();

	m_ActiveNarrativeCompleteCallback = none;

	bActivelyPlayingConversation = false;

	CurrentOutput.strTitle = "";
	CurrentOutput.strText = "";

	for ( i = 0; i < m_arrConversations.Length; i++ )
	{
		m_arrConversations[i].AudioComponent.Stop();
	}

	m_arrConversations.Remove(0, m_arrConversations.Length);
}

//==============================================================================
// 		UNIQUE FUNCTIONS:
//==============================================================================

function XComConversationNode GetConversationNode(SoundCue SndCue, optional SoundNode SndNode)
{
	local int i;
	local XComConversationNode retNode;

	if (SndCue != none)
	{
		SndNode = SndCue.FirstNode;
	}
	
	if (SndNode != none)
	{
		if (SndNode.IsA('XComConversationNode'))
		{
			return XComConversationNode(SndNode);
		}
		else
		{
			for ( i = 0; i < SndNode.ChildNodes.Length; i++ )
			{
				retNode = GetConversationNode(none, SndNode.ChildNodes[i]);
				
				if (retNode != none)
					return retNode;
			}
		}
	}

	return none;
}

simulated function EndCurrentConversation(optional bool bDontStartNextConversation=false)
{
	local XComPresentationLayerBase pres;
	local AudioComponent AudioComponent;

	if (m_arrConversations.Length <= 0)
	{
		if (PendingConversations.Length > 0)
		{
			`log("UINarrativeMgr::EndCurrentConversation, no active conversations, but we have PendingConversations",, 'XComNarrative');
			`log("UINarrativeMgr::EndCurrentConversation, Ending PendingConversation:"@PendingConversations[0].NarrativeMoment,, 'XComNarrative');
			PendingConversations.Remove(0,1);
		}
		else
		{
			`log("UINarrativeMgr::EndCurrentConversation, but no active conversations!",, 'XComNarrative');
		}
		return;
	}

	//ScriptTrace();
	`log("UINarrativeMgr::EndCurrentConversation:"@m_arrConversations[0].CueName,, 'XComNarrative');
	if (m_arrConversations[0].AudioComponent != none)
	{
		`log("UINarrativeMgr::EndCurrentConversation:"@m_arrConversations[0].AudioComponent.bFinished@m_arrConversations[0].AudioComponent.PlaybackTime@m_arrConversations[0].AudioComponent,,'XComNarrative');
	}
	
	pres = XComPresentationLayerBase(Outer);
	if( m_arrConversations[0].NarrativeMoment.eType == eNarrMoment_UIOnly )
	{
		//The screen may have already closed itself, which triggers this narrative to end, 
		//so then the screen in this case wouldn't exist in the stack anymore. 
		if (pres.ScreenStack.Screens.Find(m_kTargetScreen) != INDEX_NONE)
			pres.ScreenStack.Pop(m_kTargetScreen, false);
	}

	if( m_kTargetScreen != none )
	{
		// Commlink UI will still be around here
		if (!m_kTargetScreen.bIsRemoved)
		{
			HideComm();
		}
		m_kTargetScreen = none;
	}

	if( m_bIsModal )
	{
		if( pres.GetStateName() == 'State_UINarrative' )
			`warn("STATE STACK BUG: Narrative is not the top level of the expected state stack, and trying to pop out to clear self. Popping state: " $pres.GetStateName());
		pres.PopState(); 
	}

	m_ActiveNarrativeCompleteCallback = m_arrConversations[0].m_NarrativeCompleteCallback;

	if (m_ActiveNarrativeCompleteCallback != none)
		m_ActiveNarrativeCompleteCallback();

	m_ActiveNarrativeCompleteCallback = none;

	AudioComponent = m_arrConversations[0].AudioComponent;
	
	if (m_arrConversations[0].NarrativeMoment.bUseCinematicSoundClass)
	{
		StopCinematicSound();
	}

	m_arrConversations.Remove(0,1);

	if (AudioComponent != none)
	{
		AudioComponent.bAllowCleanup = true;
		AudioComponent.Stop();
	}

	bActivelyPlayingConversation = false;

	CurrentOutput.strTitle = "";
	CurrentOutput.strText = "";

	XComPresentationLayerBase(Outer).ClearTimer('HideComm', self);
	XComPresentationLayerBase(Outer).ClearTimer('NextDialogueLine', self);
	XComPresentationLayerBase(Outer).ClearTimer('FinishConversation0', self);
	ClearTimer('EndCurrentConversation');

	if (!bDontStartNextConversation)
	{
		CheckConversationFullyLoaded();
		CheckForNextConversation();
	}
}

simulated function NextDialogueLine(optional Actor FaceFxTargetActor)
{ 
	local XGUnit Unit;
	local float fTimeDifference;
	local ENarrativeMomentType NarrativeType;

	if( m_arrConversations.length <= 0)
		return;

	if (m_arrConversations[0].AudioComponent != none)
		`log("NextDialogLine::Top"@m_arrConversations[0].AudioComponent.PlaybackTime@m_arrConversations[0].AudioComponent@m_arrConversations[0].AudioComponent.SoundCue.Name@m_arrConversations[0].AudioComponent.bFinished,,'XComNarrative');

	if (CurrentFaceFxTargetPawn != none)
	{
		if (CurrentFaceFxTargetPawn.m_kHeadMeshComponent != none)
		{
			CurrentFaceFxTargetPawn.m_kHeadMeshComponent.CachedFaceFXAudioComp = none;
		}
	}

	CurrentFaceFxTargetPawn = none;

	CurrentFaceFxTargetActor = SkeletalMeshActor(FaceFxTargetActor);
	if (CurrentFaceFxTargetActor == none)
	{
		CurrentFaceFxTargetPawn = XComUnitPawn(FaceFxTargetActor);
		if (CurrentFaceFxTargetPawn == none)
		{
			Unit = XGUnit(FaceFxTargetActor);
			if (Unit != none)
			{
				CurrentFaceFxTargetPawn = Unit.GetPawn();
				if (CurrentFaceFxTargetPawn != none)
				{
					if (CurrentFaceFxTargetPawn.m_kHeadMeshComponent != none)
					{
						CurrentFaceFxTargetPawn.m_kHeadMeshComponent.CachedFaceFXAudioComp = m_arrConversations[0].AudioComponent;
					}
				}
			}
		}
	}

	if (m_arrConversations[0].AudioComponent != none && !m_arrConversations[0].AudioComponent.bFinished)
	{
		`log("NextDialogLine: AudioComponentPlaybackTime:"@m_arrConversations[0].AudioComponent.PlaybackTime@m_arrConversations[0].AudioComponent,,'XComNarrative');
		`log("NextDialogLine: CurrentOutputDuration:"@CurrentOutput.fDuration,,'XComNarrative');
	
		if (!m_bIsModal)
		{
			fTimeDifference = CurrentOutput.fDuration - m_arrConversations[0].AudioComponent.PlaybackTime; 

			if (fTimeDifference > 0)
			{
				XComPresentationLayerBase(Outer).SetTimer(fTimeDifference, false, 'NextDialogueLine', self);
				return;
			}
			else if (m_arrConversations[0].ConversationNode != none && !m_arrConversations[0].ConversationNode.bDialogLineFinished)
			{
				`log("NextDialogLine: Durations say we're finshed but ConversationNode not finished, adding more time",,'XComNarrative');
				XComPresentationLayerBase(Outer).SetTimer(0.1f, false, 'NextDialogueLine', self);
				return;
			}
		}
	}

	XComPresentationLayerBase(Outer).ClearTimer('HideComm', self);

	//`log("***NextDialogueLine");
	NarrativeType = m_arrConversations[0].NarrativeMoment.eType;
	if (m_arrConversations[0].AudioComponent != none)
	{
		if (!m_arrConversations[0].AudioComponent.IsPlaying() && !m_arrConversations[0].bFirstLineStarted)
		{

			LastVOTime = class'WorldInfo'.static.GetWorldInfo().TimeSeconds;

			m_arrConversations[0].AudioComponent.Play();
			m_arrConversations[0].bFirstLineStarted=true;
			//`log("***NextDialogueLine: PLAY");
		}
		else if (m_arrConversations[0].ConversationNode != none)
		{
			//`log("***NextDialogueLine: NEXT");
			m_arrConversations[0].ConversationNode.SkipToNextDialogueLine(m_arrConversations[0].AudioComponent);
			if (m_arrConversations.Length > 0)
			{
				m_arrConversations[0].AudioComponent.bDontStartNewWave = false;
			}
		}

		//SkipToNextDialogueLine above can remove conversations, so check for this
		if (m_arrConversations.Length > 0)
		{
			m_arrConversations[0].AudioComponent.PlaybackTime = 0.0f; // Starting a new line, so reset the playback time, required for FaceFx to work right.
		}
	}
	else
	{
		if (m_arrConversations[0].ConversationNode != none)
			m_arrConversations[0].ConversationNode.bFinished = true;
	}

	// Do we have more messages to run? 
	if (m_arrConversations.Length > 0 && 
		(m_arrConversations[0].ConversationNode == none || !m_arrConversations[0].ConversationNode.bFinished))
	{
		UpdateConversationDialogueBox();
	}
	else //Finished with the messages 
	{
		// Tentpoles ended by Kismet SeqAct_EndDialogue.  All other types end when last dialogline played.
		if (NarrativeType != eNarrMoment_Tentpole)
		{
			if (`XENGINE.bSubtitlesEnabled)
			{
				// Build in a little delay so the subtitles hang around a bit longer
				SetTimer(m_arrConversations.Length > 1 ? 0.75 : 1.5, false, 'EndCurrentConversation');
			}
			else
			{
				EndCurrentConversation();
			}
		}
	}
}

simulated function HideComm()
{
	if (m_kTargetScreen != none)
	{
		m_kTargetScreen.Hide();
	}
}

simulated function ShowComm()
{
	if (m_kTargetScreen != none)
	{
		m_kTargetScreen.Show();
	}
}

function OnNarrativeUICompleted(Name eAction, out DynamicPropertySet AlertData, optional bool bInstant = false)
{
	local XComPresentationLayerBase PresentationLayer;
	local XComGameState NewGameState;

	if( eAction == 'eUIAction_Accept' || eAction == 'eUIAction_Cancel' )
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Narrative UI Closed");
		PresentationLayer = XComPresentationLayerBase(Outer);
		if( PresentationLayer.m_kNarrative.NarrativeScreensUniqueVO.Find(m_arrConversations[0].NarrativeMoment.Name) != INDEX_NONE )
		{
			// Trigger unique NM dialogue instead of Central's usual new objective remarks
			`XEVENTMGR.TriggerEvent('UniqueNarrativeUICompleted', , , NewGameState);
		}
		else
		{
			`XEVENTMGR.TriggerEvent('NarrativeUICompleted', , , NewGameState);
		}


		`GAMERULES.SubmitGameState(NewGameState);

		//`assert(m_kTargetScreen == Control);
		//m_kTargetScreen.ClearOnRemovedDelegate(OnNarrativeUICompleted);
		EndCurrentConversation();
	}
}

simulated function CheckForNextConversation()
{
	local XComPresentationLayerBase PresentationLayer;
	local bool bUIOnly;

	// Don't check for conversations while we're paused, need to make sure bActivelyPlayingConversation doesnt get set
	if (bPaused || DelayedStart)
		return;

	if(m_arrConversations.Length > 0 && bActivelyPlayingConversation == false)
	{
		PresentationLayer = XComPresentationLayerBase(Outer);
		bUIOnly = false;

		bActivelyPlayingConversation = true;

		m_bIsModal = m_arrConversations[0].NarrativeMoment.IsModal();

		// Tentpoles are Modal, but we want to use the non-modal UI to basically only do subtitles.
		if(m_arrConversations[0].NarrativeMoment.eType == eNarrMoment_Tentpole) 
		{
			m_kTargetScreen = PresentationLayer.GetUIComm();
			//m_kTargetScreen.SetInputState(eInputState_Consume); 
			PresentationLayer.PushState('TentPoleScreenState');
		}
		else if( m_arrConversations[0].NarrativeMoment.eType == eNarrMoment_UIOnly )
		{
			X2NarrativeMoment(m_arrConversations[0].NarrativeMoment).PopulateUIData(OnNarrativeUICompleted);
			//m_kTargetScreen = PresentationLayer.Spawn(X2NarrativeMoment(m_arrConversations[0].NarrativeMoment).UIScreenClass, PresentationLayer);
			//X2NarrativeMoment(m_arrConversations[0].NarrativeMoment).PopulateUIData(m_kTargetScreen);
			//m_kTargetScreen.AddOnRemovedDelegate(OnNarrativeUICompleted);
			//PresentationLayer.ScreenStack.Push(m_kTargetScreen);
			bUIOnly = true;
		}
		else if( m_arrConversations[0].NarrativeMoment.eType == eNarrMoment_Bink )
		{
			// Nutting
		}
		else if( m_bIsModal )
		{
			//`log("CheckForNextConversation::Pushing State: State_UINarrative");
			//ScriptTrace();
			PresentationLayer.PushState('State_UINarrative');
			m_kTargetScreen = PresentationLayer.m_kNarrativePopup;
		}
		else
		{
			m_kTargetScreen = PresentationLayer.GetUIComm();
			//m_kTargetScreen.SetInputState(eInputState_None); 			
		}

		//if( m_kTargetScreen == none  )
		//	`log("NarrativeMgr trying to use an invalid screen, m_bIsModal = .",,'uixcom'); 

		BeginConversation(!bUIOnly);
	}
	else if (!bActivelyPlayingConversation)
	{
		UnMuffleVOOnly();
	}
}

// Checks the first pending conversation to see if its been loaded
simulated function CheckConversationFullyLoaded(optional bool bForceStart=false)
{
	local TConversation Conversation;
	if (PendingConversations.Length <= 0)
		return;
	
	if ((IsInState('DelayingFadeToBlack') || IsInState('FadingToBlack')) && !bForceStart )
		return;

    if (!PendingConversations[0].bPendingAudioLoad && !PendingConversations[0].bPendingMapLoad || PendingConversations[0].NarrativeMoment.eType == eNarrMoment_Bink)
	{
		//`assert(Conversation.CueName == PendingConversations[0].CueName);

		// Conversation is no longer pending, remove it from the queue
		Conversation = PendingConversations[0];
		PendingConversations.Remove(0,1);

		// If we faded to black, fade FROM black
		if (Conversation.NarrativeMoment.UseFadeToBlack() && Conversation.bFadedToBlack)
		{
			StartFadeFromBlack();
		}

		// first run narrative moments do not get played if a pod reveal has
		if (!Conversation.NarrativeMoment.bFirstRunOnly || !bPodRevealHappend)
		{
			// Start the conversation
			m_arrConversations.AddItem(Conversation);
		}
		
		CheckForNextConversation();
	}
}

simulated event OnConversationPreLoaded(SoundCue LoadedSoundCue)
{
	local int iIndex;
	local TPreloadedConversation PreloadedConv;

	`assert(PendingPreloadConversations.Length > 0);

	`log("UINarrativeMgr: Conversation sound cue PREloaded:"@LoadedSoundCue,,'XComNarrative');

	for (iIndex=0; iIndex < PendingPreloadConversations.Length; iIndex++)
	{
		if (PendingPreloadConversations[iIndex].ResolvedCue == none && LoadedSoundCue != none && PendingPreloadConversations[iIndex].CueName == name(PathName(LoadedSoundCue)))
		{
			// Move the Pending preload to the preloaded array
			PreloadedConv = PendingPreloadConversations[iIndex];
			PreloadedConv.ResolvedCue = LoadedSoundCue;

			PendingPreloadConversations.Remove(iIndex, 1);

			if (PreloadedConv.bWasPreloadingWhenAddedToMgr)
			{
				`log("OnConversationPreLoaded - bWasPreloadingWhenAddedToMgr:"@LoadedSoundCue ,,'XComNarrative');
				OnConversationLoaded(PreloadedConv.ResolvedCue);
			}
			else
			{
				`log("OnConversationPreLoaded:"@LoadedSoundCue ,,'XComNarrative');
				PreloadedConversations.AddItem(PreloadedConv);
			}

			return;
		}
	}
}

simulated event OnConversationLoaded(SoundCue LoadedSoundCue)
{
	local int iIndex;

	// This condition is now valid because we may have removed conversations in order to play a tentpole/bink immediately and the converstaions would
	// still be loaded.. just throw these out now.
	//`assert(PendingConversations.Length > 0);
	if (PendingConversations.Length <= 0)
		return;
	

	`log("UINarrativeMgr: Conversation sound cue loaded:"@LoadedSoundCue,,'XComNarrative');

	for (iIndex=0; iIndex < PendingConversations.Length; iIndex++)
	{
		// Crazy long logic, sorry
		// If we are not a preloading sound, and don't have a resolved cue already, OR we are fully preloaded, and the resolved Cue is the same as the one passed in
		if (PendingConversations[iIndex].ResolvedCue == none && LoadedSoundCue != none && PendingConversations[iIndex].PreloadStatus != ePendingPreload &&
			PendingConversations[iIndex].CueName == name(PathName(LoadedSoundCue)) ||
			(PendingConversations[iIndex].ResolvedCue == LoadedSoundCue && PendingConversations[iIndex].PreloadStatus == ePreLoaded))
		{
			PendingConversations[iIndex].ResolvedCue = LoadedSoundCue;
			PendingConversations[iIndex].ConversationNode = GetConversationNode(PendingConversations[iIndex].ResolvedCue);
			PendingConversations[iIndex].bPendingAudioLoad = false;

			// VOOnly conversations should just begin immediately
			if (PendingConversations[iIndex].NarrativeMoment.IsVoiceOnly())
			{
				if (PendingConversations[iIndex].NarrativeMoment.eType == eNarrMoment_VoiceOnlyMissionStream)
				{
					FadeoutAllVOOnlyOfType(eNarrMoment_VoiceOnlyMissionStream);
				}

				m_arrVOOnlyConversations.AddItem(PendingConversations[iIndex]);
				BeginVOOnlyConversation(m_arrVOOnlyConversations.Length-1);
				PendingConversations.Remove(iIndex, 1);
			}
			
			break;
		}
		else if (PendingConversations[iIndex].ResolvedCue == none && LoadedSoundCue == none && PendingConversations[iIndex].bPendingAudioLoad && PendingConversations[iIndex].bNoAudio)
		{
			// This narrative moment didn't have audio (matinee only)
			PendingConversations[iIndex].bPendingAudioLoad = false;
			break;
		}
	}

	// It may not be > 0 because we could have just loaded a VOOnly conversation, which just gets played immediately
	if (PendingConversations.Length > 0)
		CheckConversationFullyLoaded();
}

simulated function OnStreamedLevelLoaded(name LevelName, optional LevelStreaming LevelStreamedIn = new class'LevelStreaming')
{
	local int iIndex;

	if (PendingConversations.Length <= 0)
	{
		`log("UINarrativeMgr::OnStreamedLevelLoaded - PendingCOnversations.Length <= 0");
	}
	//`assert(PendingConversations.Length > 0);

	`log("UINarrativeMgr: Conversation streaming map loaded:"@LevelName,,'XComNarrative');

	for (iIndex=0; iIndex < PendingConversations.Length; iIndex++)
	{
		if (PendingConversations[iIndex].NarrativeMoment.strMapToStream == string(LevelName))
		{
			PendingConversations[iIndex].bPendingMapLoad = false;
		}
	}

	CheckConversationFullyLoaded();
}

simulated function StartFadeToBlack(optional float speed=0.5)
{
	`HQPRES.StartFadeToBlack(speed, self); // Adds fading to black to queue, which eventually calls DoStartFadeToBlack.
}

// Gets called by `HQPRES, as fading to black has to wait for the current camera swoop to finish.
simulated function DoStartFadeToBlack(optional float speed=0.5)
{
	local PlayerController Controller;

	Controller = XComPresentationLayerBase(Outer).GetALocalPlayerController();

	Controller.ClientSetCameraFade(true, MakeColor(0,0,0),vect2d(0,1), speed, ,true);

	//`log(self $ "::" $ GetFuncName() @ "BEFORE");
	
	if (!bPaused)
	{
		//`log("StartFadeToBlack::Pushing State: State_UINarrative");
		//ScriptTrace();
		XComPresentationLayerBase(Outer).PushState('State_UINarrative');
		XComPresentationLayerBase(Outer).HideUIForCinematics();     //  ShowUI should be called by the end of the narrative moment... if not, stuff will be hosed
		XComPresentationLayerBase(Outer).UILoadAnimation(true);     //  Load animation is hidden when fade completes (in the tick)
	}
	else
	{
		bWasPausedWhenStartFadeToBlack = true;
	}

	PushState('FadingToBlack');
	//`log(self $ "::" $ GetFuncName() @ "AFTER");

	
}

simulated function StartFadeFromBlack()
{
	local PlayerController Controller;

	Controller = XComPresentationLayerBase(Outer).GetALocalPlayerController();

	Controller.ClientSetCameraFade(true, MakeColor(0,0,0),vect2d(1,0), 0.5);

	//`log("StartFadeFromBlack:: Pop Pres: "@XComPresentationLayerBase(Outer).GetStateName());
	XComPresentationLayerBase(Outer).PopState();
	XComPresentationLayerBase(Outer).ShowUIForCinematics();
}

native function LoadConversationAsync(const out name SoundCueName, bool bPreloading);

// will send telemetry event
native function NotifyConversationStarted(XComNarrativeMoment narrativeMoment);

// TODO:  Add support for streaming maps, right now only supporting preloading audio
simulated function bool PreloadConversation(name nmConversation, XComNarrativeMoment NarrativeMoment)
{
	local TPreloadedConversation PreloadConversation;
	PreloadConversation.CueName = nmConversation;
	PreloadConversation.NarrativeMoment = NarrativeMoment;

	PendingPreloadConversations.AddItem(PreloadConversation);

	// Kick off load
	`log("UINarrativeMgr: requesting preload for" @ nmConversation @ "for" @ NarrativeMoment,,'XComNarrative');
	LoadConversationAsync(nmConversation, true);

	return true;
}

simulated function CheckAndHandlePreloadedConversations(out TConversation PendingConversation)
{
	local int iIndex;

	for (iIndex = 0; iIndex < PreloadedConversations.Length; iIndex++)
	{
		if (PreloadedConversations[iIndex].CueName == PendingConversation.CueName)
		{
			PendingConversation.ResolvedCue = PreloadedConversations[iIndex].ResolvedCue;
			PendingConversation.PreloadStatus = ePreloaded;
			PreloadedConversations.Remove(iIndex,1);
			return;
		}
	}

	for (iIndex = 0; iIndex < PendingPreloadConversations.Length; iIndex++)
	{
		if (PendingPreloadConversations[iIndex].CueName == PendingConversation.CueName)
		{
			PendingConversation.PreloadStatus = ePendingPreload;
			PendingPreloadConversations[iIndex].bWasPreloadingWhenAddedToMgr = true;  // Tell the preloading conversation we've already been added
			return;
		}
	}

	// PendingConversation was not preloaded, and is not pending preload
	PendingConversation.PreloadStatus = eNoPreloadRequested;
}

simulated function ClearConversationQueueOfNonTentpoles()
{
	local int i;

	// clear out all pending and current conversations, except for the one currently playing.
	// when we stop the currently playing narrative, it will automatically start the next one in line
	// if there is one, and we don't want that
	for (i=0; i < PendingConversations.Length; i++)
	{
		if (PendingConversations[i].NarrativeMoment.CanBeCanceled())
		{
			PendingConversations.Remove(i,1);
			i--;
		}
	}

	// start from index 1, index 0 is the currently playing narrative
	for (i=1; i < m_arrConversations.Length; i++)
	{
		if (m_arrConversations[i].NarrativeMoment.CanBeCanceled())
		{
			// None of these should be playing, but they could still be loading
			
			// TODO - Remove async loads
			m_arrConversations.Remove(i, 1);
			i--;

		}
	}

	// cancel the currently playing narrative
	if (m_arrConversations.Length > 0 && m_arrConversations[0].NarrativeMoment.CanBeCanceled())
	{
		if (bActivelyPlayingConversation) 
			EndCurrentConversation(true);
		else
			m_arrConversations.Remove(0, 1);
	}
}

simulated function bool AddConversation(name nmConversation, delegate<OnNarrativeCompleteCallback> InNarrativeCompleteCallback, delegate<PreRemoteEventCallback> InPreRemoteEventCallback, XComNarrativeMoment NarrativeMoment, Actor FocusActor, vector vOffset, bool bUISound, float FadeSpeed)
{
	local LevelStreaming StreamedLevel;
	local TConversation PendingConversation;
	local XComCheatManager CheatManager;
	local XComLWTuple Tuple;						// issue #204

	`log("AddConversation:"@nmConversation@":"@NarrativeMoment@GetScriptTrace(), , 'XComNarrative');

	CheatManager = XComCheatManager(`XCOMGRI.GetALocalPlayerController().CheatManager);
	if( CheatManager != none && CheatManager.bNarrativeDisabled )
	{
		if( InNarrativeCompleteCallback != none )
		{
			InNarrativeCompleteCallback();
		}

		return true;
	}

	// jboswell: Detect scary cases and bitch/bail
	// If this happens, more than likely someone needs to go in and re-associate the conversations with
	// the narrative moment. Seems to happen when conversation sound cues get moved around.
	// This can also happen when the NM is in a package that someone forgot to add to the cooking list/startup
	if( NarrativeMoment == none || (nmConversation == 'None' && NarrativeMoment.arrConversations.Length > 0) )
	{
		`log("UINarrativeMgr: WARNING: No conversation found to load, but NarrativeMoment thinks it should have conversations:" @ NarrativeMoment @ "BAILING OUT!");
		if( InNarrativeCompleteCallback != none )
		{
			InNarrativeCompleteCallback();
		}

		return true;
	}

	// If there is a conversation already being spoken,...
	if( m_arrConversations.Length != 0 )
	{
		// check to see if the conversation to add is the same as currently spoken...
		if( m_arrConversations[0].NarrativeMoment == NarrativeMoment )
		{
			// and if so, don't add it.

			// but still call the on-complete, or we might block gameplay
			if(InNarrativeCompleteCallback != none)
			{
				InNarrativeCompleteCallback();
			}

			return true;
		}
	}
	
	// start issue #204

	Tuple = new class'XComLWTuple';
	Tuple.Id = 'AddConversationOverride';
	Tuple.Data.Add(6);
	
	// Bool that determines whether this conversation should be played
	Tuple.Data[0].kind = XComLWTVBool;
	Tuple.Data[0].b = true;

	// NarrativeMoment
	Tuple.Data[1].kind = XComLWTVObject;
	Tuple.Data[1].o = NarrativeMoment;
	
	// CueName
	Tuple.Data[2].kind = XComLWTVName;
	Tuple.Data[2].n = nmConversation;
	
	// Actor
	Tuple.Data[3].kind = XComLWTVObject;
	Tuple.Data[3].o = FocusActor;
	
	// bUISound
	Tuple.Data[4].kind = XComLWTVBool;
	Tuple.Data[4].b = bUISound;
	
	// Fade speed (used for StartFadeToBlack() function)
	Tuple.Data[5].kind = XComLWTVFloat;
	Tuple.Data[5].f = FadeSpeed;
	
	`XEVENTMGR.TriggerEvent('AddConversation', Tuple);

	// if event listener returns the Tuple and the first boolean is false, do not play conversation
	if (!Tuple.Data[0].b)
	{
		if( InNarrativeCompleteCallback != none )
		{
			InNarrativeCompleteCallback();
		}
		
		return true;
	}

	// end issue #204

	if( NarrativeMoment.bDontPlayIfNarrativePlaying && (m_arrConversations.Length > 0 || PendingConversations.Length > 0) )
	{
		`log("Not adding because of bDontPlayIfNarrativePlaying:"@NarrativeMoment@m_arrConversations.Length@PendingConversations.Length, , 'XComNarrative');
		return true;
	}

	if( NarrativeMoment.ShouldClearQueueOfNonTentpoles() )
	{
		ClearConversationQueueOfNonTentpoles();
	}

	PendingConversation.bNoAudio = (nmConversation == 'None');
	PendingConversation.bPendingAudioLoad = true; // We still set this to true even if bNoAudio is true so things can go through the same code path
	PendingConversation.CueName = nmConversation;
	PendingConversation.m_NarrativeCompleteCallback = InNarrativeCompleteCallback;
	PendingConversation.m_PreRemoteEventCallback = InPreRemoteEventCallback;
	PendingConversation.NarrativeMoment = NarrativeMoment;
	PendingConversation.ActorToLookAt = FocusActor;
	PendingConversation.bUISound = bUISound;
	PendingConversation.Location = vOffset;

	CheckAndHandlePreloadedConversations(PendingConversation);

	// Only fade to black now if there are no other pending conversations before this one, and we're not actively playing a conversation
	if( PendingConversations.Length == 0 && PendingConversation.NarrativeMoment.UseFadeToBlack()
		&& m_arrConversations.Length == 0 && PendingConversation.PreloadStatus != ePreloaded )
	{
		PendingConversation.bFadedToBlack = true;

		if (PendingConversation.NarrativeMoment.PreFadeDelayDuration <= 0)
		{
			StartFadeToBlack(NarrativeMoment.FadeDuration > 0 ? NarrativeMoment.FadeDuration : FadeSpeed);
		}
		else
		{
			DelayedFadeDuration = NarrativeMoment.FadeDuration > 0 ? NarrativeMoment.FadeDuration : FadeSpeed;
			SetTimer(NarrativeMoment.PreFadeDelayDuration, false, 'DelayedStartFadeToBlack', self);
			PushState('DelayingFadeToBlack');
		}
	}
	else
	{
		// This is an Invalid Narrative moment if it has no conversations, and never fires off a remote event
		if( NarrativeMoment.eType != eNarrMoment_Bink && NarrativeMoment.eType != eNarrMoment_UIOnly && (nmConversation == 'None' || NarrativeMoment.arrConversations.Length == 0) && NarrativeMoment.nmRemoteEvent == 'None' )
		{
			`log("UINarrativeMgr: adding invalid narrativemoment: "@NarrativeMoment.Name, , 'XCom_Content');
			return false;
		}

		// We did not fade to black
		PendingConversation.bFadedToBlack = false;
	}

	// Check to see if we need to stream a map in. If so, kick off the streamer
	if( Len(PendingConversation.NarrativeMoment.strMapToStream) > 0 )
	{
		if( `MAPS.IsLevelLoaded(name(PendingConversation.NarrativeMoment.strMapToStream)) == false )
		{
			PendingConversation.bPendingMapLoad = true;

			StreamedLevel = `MAPS.AddStreamingMap(PendingConversation.NarrativeMoment.strMapToStream, vOffset, , false);
			if( StreamedLevel != none )
			{
				StreamedLevel.LevelVisibleDelegate = OnStreamedLevelLoaded;
			}
			else
			{
				PendingConversation.bPendingMapLoad = false; // failed to find map, screw it -- jboswell
			}
		}
		else
		{
			PendingConversation.bPendingMapLoad = false; // Map is already loaded
		}
	}
	else
	{
		PendingConversation.bPendingMapLoad = false;
	}

	PendingConversations.AddItem(PendingConversation);

	DelayedStart = true;

	if( PendingConversation.NarrativeMoment.eType == eNarrMoment_Bink )
	{
		DelayedStart = false; //No delay starts for binks. This has strange side effects ( black screens ) when playing during tactical.
		CheckConversationFullyLoaded();
	}
	else if( PendingConversation.PreloadStatus == eNoPreloadRequested )
	{
		// Kick off load
		`log("UINarrativeMgr: requesting load for" @ nmConversation @ "for" @ NarrativeMoment, , 'XCom_Content');
		LoadConversationAsync(nmConversation, false);
	}
	else if( PendingConversation.PreloadStatus == ePreloaded )
	{
		OnConversationLoaded(PendingConversation.ResolvedCue);
	}

	if(DelayedStart)
	{
		SetTimer(0.01, false, 'ClearDelayedStart', self);
	}

	return true;
}

function DelayedStartFadeToBlack()
{
	if (!IsInState('DelayingFadeToBlack'))
		return;

	PopState();

	StartFadeToBlack(DelayedFadeDuration);
	DelayedFadeDuration = 0;
}

function ClearDelayedStart()
{
	DelayedStart = false;
	CheckForNextConversation();
}

simulated function BeginVOOnlyConversation(int iIndex)
{
	// If we're being triggered but we'e empty, ignore it. 
	if( m_arrVOOnlyConversations.length <= iIndex)
	{
		`assert(m_arrVOOnlyConversations.length > iIndex);
		return; 
	}

	//`log("VOOnly::BeginningConversation-"@m_arrVOOnlyConversations[iIndex].NarrativeMoment.eMoment);

	m_arrVOOnlyConversations[iIndex].AudioComponent = XComPresentationLayerBase(Outer).CreateAudioComponent(m_arrVOOnlyConversations[iIndex].ResolvedCue, true, true);
	m_arrVOOnlyConversations[iIndex].AudioComponent.bToggleDontStartNewWaveAfterStart = false;
	m_ActiveNarrativeCompleteCallback = m_arrVOOnlyConversations[0].m_NarrativeCompleteCallback;
	m_arrVOOnlyConversations[iIndex].bFirstLineStarted=true;
	m_arrVOOnlyConversations[iIndex].AudioComponent.OnAudioFinished = OnVOOnlyConversationFinished;
	m_arrVOOnlyConversations[iIndex].AudioComponent.bIsUISound = m_arrVOOnlyConversations[iIndex].bUISound;

	// Muffle the VO if we have a "real" conversation going on (VOOnly considered less important)
	if(m_arrConversations.Length > 0)
	{
		if(m_arrConversations.Length != 1 || m_arrConversations[0].NarrativeMoment.eType != eNarrMoment_UIOnly)
		{
			MuffleVOOnly();
		}
	}
}

simulated function OnVOOnlyConversationFinished(AudioComponent AC)
{
	local int i;
	local delegate<OnNarrativeCompleteCallback> NarrativeCompleteCallback;

	for (i = 0; i < m_arrVOOnlyConversations.Length; i++)
	{
		if (m_arrVOOnlyConversations[i].AudioComponent == AC)
		{
			// This is for the XCOM Database so that the paused game can call the narrative complete callback. - Ryan Baker
			if (m_arrVOOnlyConversations[i].bUISound && XComPresentationLayerBase(Outer).GetALocalPlayerController().IsPaused())
			{
				NarrativeCompleteCallback = m_arrVOOnlyConversations[i].m_NarrativeCompleteCallback;
				if (NarrativeCompleteCallback != none)
					NarrativeCompleteCallback();
			}
			`log("OnVOOnlyConversationFinished:"@m_arrVOOnlyConversations[i].CueName,,'XComNarrative');
			m_arrVOOnlyConversations.Remove(i,1);
		}
	}	
}

simulated function OnAudioComponentFinished(AudioComponent AC)
{
	if ((m_arrConversations.Length > 0) && (m_arrConversations[0].AudioComponent == AC))
	{
		EndCurrentConversation();
	}
}

simulated function BeginConversation(optional bool bMuffleVOOnly = true)
{
	local float fTimerDuration;
	local int SoundID;	

	// skip while ladder vo is still playing
	if (`XENGINE.IsLoadingAudioPlaying())
	{
		SetTimer(0.01, false, 'BeginConversation', self);
		return;
	}


	if (m_arrConversations[0].NarrativeMoment.bUseCinematicSoundClass)
	{
		StartCinematicSound();
	}

	if (m_arrConversations[0].NarrativeMoment.eType != eNarrMoment_Bink)
	{
		if( m_kTargetScreen == none)
			return; // Wait until Flash has been initialized.

		if( !m_kTargetScreen.bIsInited )
			return; // Wait until Flash has been initialized
	}
	
	// If we're being triggered but we'e empty, ignore it. 
	if( m_arrConversations.length == 0)
		return; 


	// Don't begin conversations while we're paused
	if (bPaused)
		return;

	NotifyConversationStarted(m_arrConversations[0].NarrativeMoment);

	if (m_arrConversations[0].ConversationNode != None)
	{
		m_arrConversations[0].ConversationNode.Reset(m_arrConversations[0].ConversationNode.bModal);
	}

	if(bMuffleVOOnly)
	{
		MuffleVOOnly();
	}

	if (m_arrConversations[0].NarrativeMoment.eType == eNarrMoment_Bink)
	{
		if (m_arrConversations[0].NarrativeMoment.arrConversations.Length > 0) //Method for mods to play custom audio for binks
		{
			class'WorldInfo'.static.GetWorldInfo().PlaySound(SoundCue(DynamicLoadObject(string(m_arrConversations[0].NarrativeMoment.arrConversations[0]), class'SoundCue')), true);
		}

		SoundID = XComPresentationLayerBase(Outer).UIPlayMovie(m_arrConversations[0].NarrativeMoment.strBink, !m_arrConversations[0].NarrativeMoment.PlayBinkOverGameplay, false,
															   m_arrConversations[0].NarrativeMoment.BinkAudioEvent == none ? "" : string(m_arrConversations[0].NarrativeMoment.BinkAudioEvent.Name));
		
		//Only stop the movie sound if the bink was blocking
		if (!m_arrConversations[0].NarrativeMoment.PlayBinkOverGameplay && !m_arrConversations[0].NarrativeMoment.DontStopAudioEventOnCompletion)
		{
			class'WorldInfo'.static.GetWorldInfo().StopAkSound(SoundID);
		}
		
		EndCurrentConversation();
	}
	else if (m_arrConversations[0].NarrativeMoment.eType == eNarrMoment_Tentpole)
	{
		// If there is a streamed in map, override texture streaming to the location for 5s, after that the map is on its own -- jboswell
		if (!IsZero(m_arrConversations[0].Location))
			`XENGINE.AddStreamingTextureSlaveLocation(m_arrConversations[0].Location, rot(0,0,0), 5.0f, false);

		if (m_arrConversations[0].m_PreRemoteEventCallback != none)
		{
			m_ActivePreRemoteEventCallback = m_arrConversations[0].m_PreRemoteEventCallback;
			m_ActivePreRemoteEventCallback();
		}

		StartTentpoleRemoteEvent();
	}
	else
	{
		// start audio if there is not associated dialog anim. Otherwise let the anim cue the audio ( also passes through DialogTriggerAudio
		if (!m_arrConversations[0].bNoAudio/*  && name(m_arrConversations[0].ResolvedCue.AkEventOverride.AnimName) == ''*/)
		{
			DialogTriggerAudio();
		}

		m_ActiveNarrativeCompleteCallback = m_arrConversations[0].m_NarrativeCompleteCallback;
		m_arrConversations[0].bFirstLineStarted = true;

		if (m_arrConversations[0].ActorToLookAt != none)
		{
			if (!IsInState('LookAtCursorCameraTransition'))
				PushState('LookAtCursorCameraTransition');
			else
				`log("UINarrativeMgr has colliding look ats!");
		}

		// If NOT using Wwise, then update the conversation box immediately. But if we ARE using Wwise, 
		// this update is made later, via callback, once the audio duration is known.  mdomowicz 2015_11_12
		if (m_arrConversations[0].ResolvedCue.AkEventOverride == none)
		{
			UpdateConversationDialogueBox();
		}

		//PlayAnimForConversation();

		// If there are no audio devices,the audio component will never "finish".
		// Because of that, we need to set a timer that goes off a little before the length of the audio
		// and set all the appropriate flags as though it had played. -dwuenschell
		if(class'Engine'.Static.GetAudioDevice() == none)
		{
			fTimerDuration = 0.5f;
			fTimerDuration = FMax( fTimerDuration - 0.25, 0.5 );
			XComPresentationLayerBase(Outer).SetTimer( fTimerDuration, false, 'FinishConversation0', self);
		}
	}
}

function DialogTriggerAudio()
{
	m_arrConversations[0].AudioComponent = XComPresentationLayerBase(Outer).CreateAudioComponent(m_arrConversations[0].ResolvedCue, true, true);
	m_arrConversations[0].AudioComponent.bToggleDontStartNewWaveAfterStart = true;
	m_arrConversations[0].AudioComponent.OnAudioFinished = OnAudioComponentFinished;
	m_arrConversations[0].AudioComponent.bIsUISound = m_arrConversations[0].bUISound;
	m_arrConversations[0].AudioComponent.OnAudioDurationSet = OnAudioDurationSet;
	m_arrConversations[0].AudioComponent.OnAudioFailedToPlay = OnAudioFailedToPlay;

	`log("UINarrativeMgr::BeginConversation:"@m_arrConversations[0].CueName@m_arrConversations[0].AudioComponent, , 'XComNarrative');
}

function OnAudioDurationSet(AudioComponent AC, float fSeconds)
{
	UpdateConversationDialogueBox();
}

function OnAudioFailedToPlay(AudioComponent AC)
{
	UpdateConversationDialogueBox();

	SetTimer(FailedAudioDuration, false, nameof(EndCurrentConversation));
}

simulated state TentpoleRemoteEvent
{
	event Tick(float DeltaTime)
	{
		super.Tick(DeltaTime);

		if (!m_bTentpoleStarted)
		{
			if (kHQUnits == none || kHQUnits.AreHQUnitsReady())
			{
				StartTentpoleRemoteEvent();
			}
		}
	}

Begin:
	m_bTentpoleStarted = false;
	kHQUnits = class'SeqEvent_HQUnits'.static.FindHQUnitsInLevel(m_arrConversations[0].NarrativeMoment.strMapToStream);
	if (kHQUnits == none || kHQUnits.AreHQUnitsReady())
	{
		StartTentpoleRemoteEvent();
		GotoState('');
	}
	else
	{
		XComPresentationLayerBase(Outer).UILoadAnimation(true);
	}
}

simulated function StartTentpoleRemoteEvent()
{
	XComPresentationLayerBase(Outer).UILoadAnimation(false);
	m_bTentpoleStarted = true;
	`XCOMGRI.DoRemoteEvent(m_arrConversations[0].NarrativeMoment.nmRemoteEvent);

	// Start audio
	if (!m_arrConversations[0].bNoAudio)
	{
		m_arrConversations[0].AudioComponent = XComPresentationLayerBase(Outer).CreateAudioComponent(m_arrConversations[0].ResolvedCue, false, true);
		m_arrConversations[0].AudioComponent.bToggleDontStartNewWaveAfterStart = true;
		m_arrConversations[0].AudioComponent.OnAudioFinished = OnAudioComponentFinished;
		m_arrConversations[0].AudioComponent.bAllowCleanup = false;
		m_arrConversations[0].AudioComponent.bIsUISound = m_arrConversations[0].bUISound;
	}

	m_ActiveNarrativeCompleteCallback = m_arrConversations[0].m_NarrativeCompleteCallback;
	m_arrConversations[0].bFirstLineStarted=false;		
}

// Only to be called from the timer set in BeginConversation().  -dwuenschell
simulated function FinishConversation0()
{
	XComPresentationLayerBase(Outer).ClearTimer( 'FinishConversation0', self );
	m_arrConversations[0].AudioComponent.bFinished = true;
	m_arrConversations[0].AudioComponent.OnAudioFinished( m_arrConversations[0].AudioComponent );
}


simulated state LookAtCursorCameraTransition 
{
	event Tick(float fDeltaTime)
	{
		//Stay  in this state while the camera catches up, then remove this transition state. 
		//if( `CAMERAMGR.WaitForCamera() )
			RemoveLookAt();
	}

	simulated function RemoveLookAt()
	{
		//`CAMERAMGR.RemoveLookAt(m_vCurrentLookAt, false);
		PopState();
	}

Begin:
	m_vCurrentLookAt = m_arrConversations[0].ActorToLookAt.Location;
	//`CAMERAMGR.AddLookAt( m_vCurrentLookAt );	
}


simulated function UpdateConversationDialogueBox() //RAM - no conversation nodes
{	
	local name Speaker;
	local SoundCue UsingSoundCue;
	local EGender SpeakerGender;
	local XComEngine kEngine;
	local array<string> Words;
	local bool bDisplayCommLink;

	if (m_arrConversations[0].AudioComponent != none)
	{
		UsingSoundCue = m_arrConversations[0].ResolvedCue;

		if (UsingSoundCue.AkEventOverride == none)
		{
			Speaker = m_arrConversations[0].ConversationNode.GetCurrentSpeaker(m_arrConversations[0].AudioComponent);
			CurrentOutput.strTitle = TemplateToTitle(Speaker);
			CurrentOutput.strImage = TemplateToPortrait(Speaker);			
			CurrentOutput.strText = m_arrConversations[0].ConversationNode.GetCurrentDialogue(m_arrConversations[0].AudioComponent);
			CurrentOutput.fDuration = m_arrConversations[0].ConversationNode.GetCurrentDialogueDuration(m_arrConversations[0].AudioComponent);
			CurrentOutput.fTimeStarted = class'WorldInfo'.static.GetWorldInfo().TimeSeconds;
		}
		else
		{
			CurrentOutput.strTitle = TemplateToTitle(UsingSoundCue.AkEventOverride.SpeakerTemplate);
			CurrentOutput.strImage = TemplateToPortrait(UsingSoundCue.AkEventOverride.SpeakerTemplate, SpeakerGender);
			CurrentOutput.strText = UsingSoundCue.AkEventOverride.SpokenText;

			if (m_arrConversations[0].AudioComponent.fDuration <= 0.0f)
			{
				Words = SplitString(UsingSoundCue.AkEventOverride.SpokenText, " ");
				FailedAudioDuration = float(Words.Length) * 0.33f;
				XComPresentationLayerBase(Outer).Speak(CurrentOutput.strText, SpeakerGender == eGender_Male);
			}

			CurrentOutput.fDuration = m_arrConversations[0].AudioComponent.fDuration <= 0.0f ? FailedAudioDuration : m_arrConversations[0].AudioComponent.fDuration; //Fixed duration if we are doing text to speech
			CurrentOutput.fTimeStarted = class'WorldInfo'.static.GetWorldInfo().TimeSeconds;
		}

		/*
		if (CurrentFaceFxTargetActor != none && FaceFXAnimSetRef != none)
		{
			CurrentFaceFxTargetActor.FacialAudioComp = m_arrConversations[0].AudioComponent;
			CurrentFaceFxTargetActor.PlayActorFaceFXAnim(FaceFXAnimSetRef,FaceFXGroupName,FaceFXAnimName, none, none);
		}
		else if (CurrentFaceFxTargetPawn != none && FaceFXAnimSetRef != none)
		{
			CurrentFaceFxTargetPawn.FacialAudioComp = m_arrConversations[0].AudioComponent;
			CurrentFaceFxTargetPawn.PlayActorFaceFXAnim(FaceFXAnimSetRef,FaceFXGroupName,FaceFXAnimName, none, none);
		}
		*/

		if (!m_bIsModal)
		{
			XComPresentationLayerBase(Outer).SetTimer(CurrentOutput.fDuration, false, 'NextDialogueLine', self);
		}
		else if (m_arrConversations[0].NarrativeMoment.eType == eNarrMoment_Tentpole)
		{
			XComPresentationLayerBase(Outer).ClearTimer('HideComm', self);
			XComPresentationLayerBase(Outer).SetTimer(CurrentOutput.fDuration, false, 'HideComm', self);

			// HACKS: Crazy Show/Hide logic to handle showing subtitles when cutscenes are playing.
			if (!XComPresentationLayerBase(Outer).Get2DMovie().bIsVisible)
			{
				// TODO: This needs refactoring.
				XComPresentationLayerBase(Outer).Get2DMovie().Show(); // Show every screen
				XComPresentationLayerBase(Outer).ScreenStack.HideUIForCinematics(); // Hide every screen except 'UINarrativeCommLink' and 'UIStrategyTutorialBox'
				XComPresentationLayer(Outer).m_kUnitFlagManager.Hide(); // Hide unit flags
			}
		}

		bDisplayCommLink = true;
		if (UsingSoundCue.AkEventOverride != none)
		{
			kEngine = XComEngine(class'GameEngine'.static.GetEngine());
			if (UsingSoundCue.AkEventOverride.HideSpeaker && (kEngine != none && !kEngine.bSubtitlesEnabled))
			{
				// If the speaker is marked as hidden and subtitles are not enabled, do not show the comm link
				bDisplayCommLink = false;
			}
		}
		
		if (bDisplayCommLink)
		{
			m_kTargetScreen.Show();
		}
	}
}

simulated function PlayAnimForConversation()
{
	local SoundCue UsingSoundCue;
	local name CharTemplateName;
	local name AnimToPlayName;
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState;
	local XComUnitPawn UnitPawn;
		
	UsingSoundCue = m_arrConversations[0].ResolvedCue;
	CharTemplateName = UsingSoundCue.AkEventOverride.SpeakerTemplate;
	AnimToPlayName = name(UsingSoundCue.AkEventOverride.AnimName);

	if(AnimToPlayName != '')
	{
		History = `XCOMHISTORY;
		foreach History.IterateByClassType(class'XComGameState_Unit', UnitState)
		{
			if(UnitState.GetMyTemplateName() == CharTemplateName)
			{
				UnitPawn = XComUnitPawn(UnitState.GetVisualizer());
				if(UnitPawn != none)
				{
					UnitPawn.QueueDialog(AnimToPlayName);
				}
			}
		}
	}	
}

simulated function BeginNarrative()
{
	if (m_arrConversations.Length != 0)
	{
		BeginConversation();
		return;
	}
}

simulated function SkeletalMeshActor SpeakerToActor(EXComSpeakerType eSpeaker)
{
	local SkeletalMeshActor retValue;

	//Deprecated
	retValue = none;
	return retValue;
}

simulated function string TemplateToTitle(name CharTemplateName)
{
	local X2CharacterTemplateManager CharMgr;
	local X2CharacterTemplate CharTemplate;

	CharMgr = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager();
	CharTemplate = CharMgr.FindCharacterTemplate(CharTemplateName);

	if( CharTemplate != none && CharTemplate.SpeakerPortrait != "" )
	{
		return CharTemplate.strCharacterName;
	}
}

simulated function string TemplateToPortrait(name CharTemplateName, optional out EGender OutSpeakerGender)
{
	local X2CharacterTemplateManager CharMgr;
	local X2CharacterTemplate CharTemplate;

	CharMgr = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager();
	CharTemplate = CharMgr.FindCharacterTemplate(CharTemplateName);

	if( CharTemplate != none && CharTemplate.SpeakerPortrait != "" )
	{
		OutSpeakerGender = EGender(CharTemplate.DefaultAppearance.iGender);
		return CharTemplate.SpeakerPortrait;
	}
}

simulated function string SpeakerToTitle(EXComSpeakerType eSpeaker)
{
	local X2CharacterTemplateManager CharMgr;
	local X2CharacterTemplate CharTemplate;
	local array<name> TemplateNames;
	local name CharTemplateName;

	CharMgr = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager();
	CharMgr.GetTemplateNames(TemplateNames);

	CharTemplateName = TemplateNames[int(eSpeaker)];
	CharTemplate = CharMgr.FindCharacterTemplate(CharTemplateName);
	if(CharTemplate != none)
	{
		return CharTemplate.strCharacterName;
	}

	return "";
}


simulated function string SpeakerToPortait(EXComSpeakerType eSpeaker)
{
	local X2CharacterTemplateManager CharMgr;
	local X2CharacterTemplate CharTemplate;
	local array<name> TemplateNames;
	local name CharTemplateName;

	CharMgr = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager();
	CharMgr.GetTemplateNames(TemplateNames);

	CharTemplateName = TemplateNames[int(eSpeaker)];
	CharTemplate = CharMgr.FindCharacterTemplate(CharTemplateName);
	if(CharTemplate != none && CharTemplate.SpeakerPortrait != "")
	{
		return CharTemplate.SpeakerPortrait;
	}

	return "";
}

event Tick(float fDeltaTime)
{
}

simulated state DelayingFadeToBlack
{
}

// jboswell: the only conversation we could be waiting on during this is PendingConversations[0]. all code
// below assumes this. If we ever do re-ordering, we'll need to re-work this whole thing
simulated state FadingToBlack
{
	event Tick(float fDeltaTime)
	{
		local PlayerController Controller;
		
		if (!bPaused && bWasPausedWhenStartFadeToBlack)
		{
			//`log("FadingToBlack::Pushing State: State_UINarrative");
			//ScriptTrace();
			XComPresentationLayerBase(Outer).PushState('State_UINarrative');
			XComPresentationLayerBase(Outer).HideUIForCinematics();     //  ShowUI should be called by the end of the narrative moment... if not, stuff will be hosed
			XComPresentationLayerBase(Outer).UILoadAnimation(true);     //  Load animation is hidden when fade completes (in the tick)
			bWasPausedWhenStartFadeToBlack = false;
		}

		if (PendingConversations.Length > 0 && PendingConversations[0].bPendingMapLoad == false && PendingConversations[0].bFadedToBlack &&
			(PendingConversations[0].NarrativeMoment.eType == eNarrMoment_Bink || PendingConversations[0].bPendingAudioLoad == false))
		{
			Controller = XComPresentationLayerBase(Outer).GetALocalPlayerController();
			
			// When the fade completes, let the conversation finally kick itself off
			if (Controller.PlayerCamera.FadeTimeRemaining <= 0.0f && !bPaused)
			{
				CheckConversationFullyLoaded(true);
				XComPresentationLayerBase(Outer).UILoadAnimation(false);

				PopState();
			}
		}
	}
};

simulated function FadeoutAllVOOnlyOfType(ENarrativeMomentType eType)
{
	local int i;

	for (i = 0; i < m_arrVOOnlyConversations.Length; i++)
	{
		if (m_arrVOOnlyConversations[i].NarrativeMoment.eType == eType)
		{
			m_arrVOOnlyConversations[i].AudioComponent.FadeOut(0.5, 0);
		}
	}
}

simulated function MuffleVOOnly()
{
	local int i;

	for (i = 0; i < m_arrVOOnlyConversations.Length; i++)
	{
		if (!m_arrVOOnlyConversations[i].bMuffled)
		{
			if (m_arrVOOnlyConversations[i].AudioComponent.PlaybackTime < 0.5f)
			{
				m_arrVOOnlyConversations[i].AudioComponent.AdjustVolume(0.0, 0.25f);
			}
			else
			{
				m_arrVOOnlyConversations[i].AudioComponent.AdjustVolume(0.55, 0.25f);
			}
			m_arrVOOnlyConversations[i].bMuffled = true;
		}
	}
}

simulated function UnMuffleVOOnly()
{
	local int i;

	for (i = 0; i < m_arrVOOnlyConversations.Length; i++)
	{
		if (m_arrVOOnlyConversations[i].bMuffled)
		{
			m_arrVOOnlyConversations[i].AudioComponent.AdjustVolume(0.55, 1.0f);
			m_arrVOOnlyConversations[i].bMuffled = false;
		}
	}
}


simulated function StartCinematicSound()
{
	// Turn Off sound and music
	class'Engine'.static.GetCurrentWorldInfo().GetALocalPlayerController().SetAudioGroupVolume('SoundFX', 0.0f);
	class'Engine'.static.GetCurrentWorldInfo().GetALocalPlayerController().SetAudioGroupVolume('Music', 0.0f);

	class'Engine'.static.GetEngine().SetCinematicSoundEnabled(true);
}

simulated function StopCinematicSound()
{
	`XPROFILESETTINGS.ApplyAudioOptions();
	class'Engine'.static.GetEngine().SetCinematicSoundEnabled(false);
}


//==============================================================================

//==============================================================================
//		DEFAULTS:
//==============================================================================

defaultproperties
{
	m_bIsModal = true
	bPodRevealHappend = false
	FailedAudioDuration = 3.0
}
