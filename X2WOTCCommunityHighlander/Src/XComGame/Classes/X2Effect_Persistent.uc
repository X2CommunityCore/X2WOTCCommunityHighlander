//---------------------------------------------------------------------------------------
//  FILE:    X2Effect_Persistent.uc
//  AUTHOR:  Joshua Bouscher
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2Effect_Persistent extends X2Effect
	native(Core);

enum EGameplayBlocking
{
	eGameplayBlocking_DoesNotModify,
	eGameplayBlocking_DoesNotBlock,
	eGameplayBlocking_Blocks,
};

var array<X2EffectTrigger> TickTriggers;

var int     iNumTurns;
var int     iInitialShedChance;
var int     iPerTurnShedChance;
var bool    bInfiniteDuration;
var bool    bTickWhenApplied;
var bool    bCanTickEveryAction;               // If true and the character templates supports it, this effect will tick after every target action
var bool    bConvertTurnsToActions;            // If ticking per-action instead of per-turn, iNumTurns will be multiplied by the number of actions per turn
var bool    bRemoveWhenSourceDies;
var bool    bRemoveWhenTargetDies;
var bool	bRemoveWhenSourceDamaged;
var bool    bRemoveWhenTargetConcealmentBroken;
var bool	bPersistThroughTacticalGameEnd;		// if true, this effect will remain on the unit even after it has been removed from play (until tactical game end)
var bool    bIgnorePlayerCheckOnTick;
var bool    bUniqueTarget;                     // for a given source, this effect may only apply to one target. any pre-existing effect on another target is removed in HandleApplyEffect
var bool    bStackOnRefresh;                   // increment the stack counter on the effect state when this effect is refreshed
var bool    bDupeForSameSourceOnly;            // when adding the effect to a target, any similar effects coming from a different source are ignored when checking for a pre-existing effect
var bool	bEffectForcesBleedout;
var EDuplicateEffect DuplicateResponse;
var array<X2Effect> ApplyOnTick;               // These non-persistent effects are applied with the same target parameters every tick
var GameRuleStateChange WatchRule;			   // the rule determining when this effect needs to tick
var name	CustomIdleOverrideAnim;			   // tells the Idle state machine that a persistent effect is taking over animation
var int     EffectRank;                        // This rank currently is used by auras. The value of the rank to allow different unit templates
											   // apply effects with the same aura type.
var name    EffectName;                        // Used to identify the effect for purposes of stacking with other effects.
var EPerkBuffCategory BuffCategory;
var Name AbilitySourceName;              // Used to color passive buffs in the HUD
var bool    bDisplayInUI;                      // Effect will only appear in German mode if this is true
var bool	bDisplayInSpecialDamageMessageUI;  // If true, this effect FriendlyName will be displayed in the damage feedback ui as a special damage source
var string  FriendlyName;                      // Used in German mode UI
var string  FriendlyDescription;               // Used in German mode UI
var string  IconImage;
//  UI display info for effect SOURCE - usually only applicable for certain abilities, such as Mind Control, where you need to distinguish the source and the target
var EPerkBuffCategory SourceBuffCategory;
var bool    bSourceDisplayInUI;
var string  SourceFriendlyName;
var string  SourceFriendlyDescription;
var string  SourceIconLabel;
var string  StatusIcon;
var int     EffectHierarchyValue;               // This is used to signify which effects have precedence over other effects. This controls which effect might control the animation
												// if multiple persistent effects are present. A value of -1 is default and means it is not in the hierarchy. Blocks of 100 to allow
												// for changes.
var name EffectAppliedEventName;				// When this effect is applied, trigger an event with this ID
var name ChanceEventTriggerName;                // Event to trigger if we pass the trigger shed chance percent check

var string VFXTemplateName;						// Name of a particle system to play on the unit while this persistent effect is active
var name VFXSocket;								// The name of a socket to which the particle system component should be attached. (optional)
var name VFXSocketsArrayName;                   // Name associated with an array of sockets the particle system will attach to. (optional)
var string PersistentPerkName;					// Name of the perk that should be played on the unit while this persistent effect is active

var float VisionArcDegreesOverride;				// This will limit the sight arc of the character.  If 2 effects have this it chooses the smaller arc.

var class<XComGameState_Effect> GameStateEffectClass;   //  The class to use when instantiating a state object

var delegate<AddEffectVisualization> VisualizationFn;
var delegate<AddEffectVisualization> CleansedVisualizationFn;
var delegate<AddEffectVisualization> EffectTickedVisualizationFn;
var delegate<AddEffectVisualization> EffectSyncVisualizationFn;
var delegate<AddEffectVisualization> EffectRemovedVisualizationFn;
var delegate<AddEffectVisualization> EffectRemovedSourceVisualizationFn;
var delegate<AddEffectVisualization_Death> DeathVisualizationFn;
var delegate<AddEffectVisualization> ModifyTracksFn;
var delegate<EffectRemoved> EffectRemovedFn;
var delegate<EffectAdded> EffectAddedFn;
var delegate<EffectTicked> EffectTickedFn;
var delegate<GetModifyChosenActivationIncreasePerUse> GetModifyChosenActivationIncreasePerUseFn;	// This method gets any bonus ChosenActivationIncreasePerUse points based on the AbilityState
var delegate<UnitBreaksConcealmentIgnoringDistance> UnitBreaksConcealmentIgnoringDistanceFn;	// When this unit sees another unit and it can break concealment, return if the distance between the units matters

delegate AddEffectVisualization(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult);
delegate EffectRemoved(X2Effect_Persistent PersistentEffect, const out EffectAppliedData ApplyEffectParameters, XComGameState NewGameState, bool bCleansed);
delegate EffectAdded(X2Effect_Persistent PersistentEffect, const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState);
delegate bool EffectTicked(X2Effect_Persistent PersistentEffect, const out EffectAppliedData ApplyEffectParameters, XComGameState_Effect kNewEffectState, XComGameState NewGameState, bool FirstApplication);
delegate X2Action AddEffectVisualization_Death(out  VisualizationActionMetadata ActionMetadata, XComGameStateContext Context);
delegate bool GetModifyChosenActivationIncreasePerUse(XComGameState_Ability AbilityState, out ModifyChosenActivationIncreasePerUse ModifyChosenActivationPoints);
delegate bool UnitBreaksConcealmentIgnoringDistance();

simulated function BuildPersistentEffect(int _iNumTurns, optional bool _bInfiniteDuration=false, optional bool _bRemoveWhenSourceDies=true, optional bool _bIgnorePlayerCheckOnTick=false, optional GameRuleStateChange _WatchRule=eGameRule_TacticalGameStart )
{
	iNumTurns = _iNumTurns;
	bInfiniteDuration = _bInfiniteDuration;
	if (bInfiniteDuration)
		iNumTurns = 1;
	bRemoveWhenSourceDies = _bRemoveWhenSourceDies;
	bIgnorePlayerCheckOnTick = _bIgnorePlayerCheckOnTick;	
	WatchRule = _WatchRule;
}

simulated function SetDisplayInfo(EPerkBuffCategory BuffCat, string strName, string strDesc, string strIconLabel, optional bool DisplayInUI=true, optional string strStatusIcon = "", optional Name opAbilitySource = 'eAbilitySource_Standard')
{
	BuffCategory = BuffCat;
	FriendlyName = strName;
	FriendlyDescription = strDesc;
	IconImage = strIconLabel;
	bDisplayInUI = DisplayInUI;
	StatusIcon = strStatusIcon;
	AbilitySourceName = opAbilitySource;
}

simulated function SetSourceDisplayInfo(EPerkBuffCategory BuffCat, string strName, string strDesc, string strIconLabel, optional bool DisplayInUI=true, optional Name opAbilitySource = 'eAbilitySource_Standard')
{
	SourceBuffCategory = BuffCat;
	SourceFriendlyName = strName;
	SourceFriendlyDescription = strDesc;
	SourceIconLabel = strIconLabel;
	bSourceDisplayInUI = DisplayInUI;
	AbilitySourceName = opAbilitySource;
}

simulated function bool FullTurnComplete(XComGameState_Effect kEffect, XComGameState_Player TurnPlayer)
{
	local XComGameState_Player PlayerState;
	local XGPlayer CurrentPlayer;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;

	if( bIgnorePlayerCheckOnTick || TurnPlayer.ObjectID == kEffect.ApplyEffectParameters.PlayerStateObjectRef.ObjectID )
	{
		// Either ignoring the Player or the current player is equal tothe effect's source player
		return true;
	}
	else
	{
		// A full turn still may happen for civilians
		PlayerState = XComGameState_Player(History.GetGameStateForObjectID(kEffect.ApplyEffectParameters.PlayerStateObjectRef.ObjectID));

		if( PlayerState.GetTeam() == eTeam_Neutral )
		{
			CurrentPlayer = XGPlayer(History.GetVisualizer(TurnPlayer.ObjectID));

			return (CurrentPlayer.m_eTeam == eTeam_Alien);
		}

		return false;
	}
}

event X2Effect_Persistent GetPersistantTemplate( );

//Occurs once per turn during the Unit Effects phase
// Returns true if the associated XComGameSate_Effect should NOT be removed
simulated function bool OnEffectTicked(const out EffectAppliedData ApplyEffectParameters, XComGameState_Effect kNewEffectState, XComGameState NewGameState, bool FirstApplication, XComGameState_Player Player)
{
	local X2Effect TickEffect;
	local XComGameState_BaseObject OldTargetState, NewTargetState;
	local XComGameStateContext_TickEffect TickContext;
	local EffectAppliedData TickData;
	local bool TickCompletesEffect;
	local XComGameState_Unit EffectTargetUnit;
	local X2EventManager EventManager;
	local XComGameStateHistory History;
	local bool bIsFullTurnComplete;

	bIsFullTurnComplete = FullTurnComplete(kNewEffectState, Player);
	OldTargetState = `XCOMHISTORY.GetGameStateForObjectID(ApplyEffectParameters.TargetStateObjectRef.ObjectID);

	if(bIsFullTurnComplete 
		|| (FirstApplication && bTickWhenApplied) 
		|| (IsTickEveryAction(OldTargetState)))
	{
		TickContext = XComGameStateContext_TickEffect(NewGameState.GetContext());
		if (ApplyOnTick.Length > 0)
		{
			NewTargetState = NewGameState.ModifyStateObject(OldTargetState.Class, OldTargetState.ObjectID);
			
			TickContext.arrTickSuccess.Length = 0;
			TickData = ApplyEffectParameters;
			TickData.EffectRef.ApplyOnTickIndex = 0;
			foreach ApplyOnTick(TickEffect)
			{
				TickContext.arrTickSuccess.AddItem( TickEffect.ApplyEffect(TickData, NewTargetState, NewGameState) );
				TickData.EffectRef.ApplyOnTickIndex++;
			}
		}

		if (!bInfiniteDuration)
		{
			kNewEffectState.iTurnsRemaining -= 1;
			`assert(kNewEffectState.iTurnsRemaining > -1); //If this goes negative, something has gone wrong with the handling
		}

		kNewEffectState.iShedChance += iPerTurnShedChance;
		if (kNewEffectState.iShedChance > 0)
		{
			if (`SYNC_RAND(100) <= kNewEffectState.iShedChance)
			{
				kNewEffectState.iTurnsRemaining = 0;

				// If there is an event that should be triggered due to this chance, fire it
				if( ChanceEventTriggerName != '' )
				{
					History = `XCOMHISTORY;
					EventManager = `XEVENTMGR;

					EffectTargetUnit = XComGameState_Unit(History.GetGameStateForObjectID(ApplyEffectParameters.TargetStateObjectRef.ObjectID));
					EventManager.TriggerEvent(ChanceEventTriggerName, EffectTargetUnit, EffectTargetUnit);
				}
			}
		}
		if (EffectTickedFn != none)
		{
			TickCompletesEffect = EffectTickedFn(self, ApplyEffectParameters, kNewEffectState, NewGameState, FirstApplication);
		}

		if( bIsFullTurnComplete )
		{
			++kNewEffectState.FullTurnsTicked;
		}
	}

	return (bInfiniteDuration || kNewEffectState.iTurnsRemaining > 0) && !TickCompletesEffect;
}

simulated function OnEffectRemoved(const out EffectAppliedData ApplyEffectParameters, XComGameState NewGameState, bool bCleansed, XComGameState_Effect RemovedEffectState)
{
	if (EffectRemovedFn != none)
		EffectRemovedFn(self, ApplyEffectParameters, NewGameState, bCleansed);
}

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameState_Player ActivePlayer;
	local X2EventManager EventMan;
	local XComGameState_Unit UnitState;

	if( EffectAppliedEventName != '' )
	{
		EventMan = `XEVENTMGR;
		UnitState = XComGameState_Unit(kNewTargetState);
		if( UnitState != none )
		{
			EventMan.TriggerEvent(EffectAppliedEventName, kNewTargetState, kNewTargetState, NewGameState);
		}
	}

	ActivePlayer = XComGameState_Player(`XCOMHISTORY.GetGameStateForObjectID(`TACTICALRULES.GetCachedUnitActionPlayerRef().ObjectID));

	if (EffectAddedFn != none)
		EffectAddedFn(self, ApplyEffectParameters, kNewTargetState, NewGameState);

	if (bTickWhenApplied)
	{
		if (NewEffectState != none)
		{
			if (!NewEffectState.TickEffect(NewGameState, true, ActivePlayer))
				NewEffectState.RemoveEffect(NewGameState, NewGameState, false, true);
		}
	}
}

simulated function AddX2ActionsForVisualization(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, name EffectApplyResult)
{
	local XComGameStateVisualizationMgr VisMgr;
	local XComGameStateHistory History;
	local XComGameStateContext_Ability AbilityContext;
	local XComGameState_Unit SourceState;
	local Actor SourceVisualizer;
	local X2Action_Fire FireAction;
	local XComGameState_Effect EffectState, TickedEffectState;
	local X2Action_PersistentEffect PersistentEffectAction;
	local X2Action_PlayEffect PlayEffectAction;
	local X2Action_AbilityPerkStart PerkStartAction;
	local X2Action_AbilityPerkEnd PerkEndAction;
	local int i;

	VisMgr = `XCOMVISUALIZATIONMGR;
	History = `XCOMHISTORY;

	if( (EffectApplyResult == 'AA_Success') && (XComGameState_Unit(ActionMetadata.StateObject_NewState) != none) )
	{
		AbilityContext = XComGameStateContext_Ability(VisualizeGameState.GetContext());
		if( AbilityContext != None )
		{
			SourceState = XComGameState_Unit(History.GetGameStateForObjectID(AbilityContext.InputContext.SourceObject.ObjectID, eReturnType_Reference, VisualizeGameState.HistoryIndex));
			if( SourceState != None )
			{
				SourceVisualizer = History.GetVisualizer(SourceState.ObjectID);
				if( SourceVisualizer != None )
				{
					FireAction = X2Action_Fire(VisMgr.GetNodeOfType(VisMgr.BuildVisTree, class'X2Action_Fire', SourceVisualizer));
					if( FireAction != None )
					{
						class'X2Action_WaitForAbilityEffect'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, FireAction);
					}
				}
			}
		}

		if (CustomIdleOverrideAnim != '')
		{
			// We started an idle override so this will clear it
			PersistentEffectAction = X2Action_PersistentEffect(class'X2Action_PersistentEffect'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded));
			PersistentEffectAction.IdleAnimName = CustomIdleOverrideAnim;
		}

		if (VFXTemplateName != "")
		{
			PlayEffectAction = X2Action_PlayEffect( class'X2Action_PlayEffect'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded));

			PlayEffectAction.AttachToUnit = true;
			PlayEffectAction.EffectName = VFXTemplateName;
			PlayEffectAction.AttachToSocketName = VFXSocket;
			PlayEffectAction.AttachToSocketsArrayName = VFXSocketsArrayName;
		}

		if (PersistentPerkName != "")
		{
			PerkStartAction = X2Action_AbilityPerkStart( class'X2Action_AbilityPerkStart'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded));
			PerkEndAction = X2Action_AbilityPerkEnd( class'X2Action_AbilityPerkEnd'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded));

			PerkStartAction.PersistentPerkEffect = self;
			PerkEndAction.PersistentPerkEffect = self;
		}

		//  anything inside of ApplyOnTick needs handling here because when bTickWhenApplied is true, there is no separate context (which normally handles the visualization)
		if (bTickWhenApplied)
		{
			foreach VisualizeGameState.IterateByClassType(class'XComGameState_Effect', EffectState)
			{
				if (EffectState.GetX2Effect() == self)
				{
					TickedEffectState = EffectState;
					break;
				}
			}
			if (TickedEffectState != none)
			{
				for (i = 0; i < ApplyOnTick.Length; ++i)
				{
					ApplyOnTick[i].AddX2ActionsForVisualization_Tick(VisualizeGameState, ActionMetadata, i, TickedEffectState); 
				}
			}
		}
	}
	super.AddX2ActionsForVisualization(VisualizeGameState, ActionMetadata, EffectApplyResult);

	if (VisualizationFn != none)
		VisualizationFn(VisualizeGameState, ActionMetadata, EffectApplyResult);		
}

simulated function AddX2ActionsForVisualization_Sync( XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata )
{
	local X2Action_PlayEffect PlayEffectAction;

	if (VFXTemplateName != "")
	{
		PlayEffectAction = X2Action_PlayEffect( class'X2Action_PlayEffect'.static.AddToVisualizationTree( ActionMetadata, VisualizeGameState.GetContext( ) ) );

		PlayEffectAction.AttachToUnit = true;
		PlayEffectAction.EffectName = VFXTemplateName;
		PlayEffectAction.AttachToSocketName = VFXSocket;
		PlayEffectAction.AttachToSocketsArrayName = VFXSocketsArrayName;
	}

	if( EffectSyncVisualizationFn != None )
	{
		EffectSyncVisualizationFn(VisualizeGameState, ActionMetadata, 'AA_Success');
	}
}

simulated function AddX2ActionsForVisualization_Tick(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const int TickIndex, XComGameState_Effect EffectState)
{
	if( EffectTickedVisualizationFn != none && 
	    EffectState != None && 
	    !EffectState.bRemoved )
	{
		EffectTickedVisualizationFn(VisualizeGameState, ActionMetadata, 'AA_Success');
	}
}


simulated function AddX2ActionsForVisualization_Removed(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult, XComGameState_Effect RemovedEffect)
{
	local X2Action_PersistentEffect PersistentEffectAction;
	local X2Action_AbilityPerkDurationEnd PerkEnded;
	local X2Action_PlayEffect PlayEffectAction;

	if (CustomIdleOverrideAnim != '')
	{
		// We started an idle override so this will clear it
		PersistentEffectAction = X2Action_PersistentEffect(class'X2Action_PersistentEffect'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded));
		PersistentEffectAction.IdleAnimName = '';
	}

	if (VFXTemplateName != "")
	{
		PlayEffectAction = X2Action_PlayEffect( class'X2Action_PlayEffect'.static.AddToVisualizationTree( ActionMetadata, VisualizeGameState.GetContext() ) );

		PlayEffectAction.AttachToUnit = true;
		PlayEffectAction.EffectName = VFXTemplateName;
		PlayEffectAction.AttachToSocketName = VFXSocket;
		PlayEffectAction.AttachToSocketsArrayName = VFXSocketsArrayName;
		PlayEffectAction.bStopEffect = true;
	}

	if( EffectRemovedVisualizationFn != none &&
	    RemovedEffect != None &&
	    RemovedEffect.bRemoved )
	{
		EffectRemovedVisualizationFn(VisualizeGameState, ActionMetadata, EffectApplyResult);
	}

	PerkEnded = X2Action_AbilityPerkDurationEnd( class'X2Action_AbilityPerkDurationEnd'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded));
	PerkEnded.EndingEffectState = RemovedEffect;
}

simulated function AddX2ActionsForVisualization_RemovedSource(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult, XComGameState_Effect RemovedEffect)
{
	if (EffectRemovedSourceVisualizationFn != none)
		EffectRemovedSourceVisualizationFn(VisualizeGameState, ActionMetadata, EffectApplyResult);
}

simulated function X2Action AddX2ActionsForVisualization_Death(out VisualizationActionMetadata ActionMetadata, XComGameStateContext Context)
{
	if( DeathVisualizationFn != none )
	{
		return DeathVisualizationFn(ActionMetadata, Context);
	}

	return none;
}

simulated final function name HandleApplyEffect(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, out XComGameState_Effect NewEffectState)
{
	local XComGameState_Effect PersistentEffectStateObject, ExistingEffect;
	local bool bFoundRefreshEffect, bShouldCreateNewEffect;
	local XComGameState_Unit TargetUnitState, SourceUnitState;
	local StateObjectReference EffectRef;
	local XComGameStateHistory History;
	local int i;

	History = `XCOMHISTORY;
	bShouldCreateNewEffect = true;

	TargetUnitState = XComGameState_Unit(kNewTargetState);

	if( (DuplicateResponse != eDupe_Allow) && (TargetUnitState != none))
	{
		// Check if an effect of this type is already affecting the target
		for (i = 0; i < TargetUnitState.AffectedByEffectNames.length; i++)
		{
			if (TargetUnitState.AffectedByEffectNames[i] == EffectName)
			{
				ExistingEffect = XComGameState_Effect(History.GetGameStateForObjectID(TargetUnitState.AffectedByEffects[i].ObjectID));
				if (ExistingEffect == none)
					continue;
				
				if (bDupeForSameSourceOnly)
				{
					if (ExistingEffect.ApplyEffectParameters.SourceStateObjectRef.ObjectID != ApplyEffectParameters.SourceStateObjectRef.ObjectID)
						continue;
				}
				

				NewEffectState = ExistingEffect;
				bFoundRefreshEffect = true;
				break;
			}
		}

		if( bFoundRefreshEffect )
		{
			if( DuplicateResponse == eDupe_Ignore )
			{
				// there exists an effect of this type and this effect is explicitly supposed to not be applied as a result
				return 'AA_DuplicateEffectIgnored';
			}
			else
			{
				// there exists an effect of this type; determine which effect (the new one vs. the existing one) is the more potent
				`assert( DuplicateResponse == eDupe_Refresh );

				if ( IsThisEffectBetterThanExistingEffect(ExistingEffect) )
				{
					// the new effect is better, so remove the existing effect
					ExistingEffect.RemoveEffect(NewGameState, NewGameState);
				}
				else
				{
					// the existing effect is better (or they have equivalent potency), so refresh the existing effect and do not add the new effect
					PersistentEffectStateObject = XComGameState_Effect(NewGameState.ModifyStateObject(ExistingEffect.Class, ExistingEffect.ObjectID));
					PersistentEffectStateObject.OnRefresh(ApplyEffectParameters, NewGameState);

					return 'AA_EffectRefreshed';
				}
			}
		}
	}

	if( bShouldCreateNewEffect )
	{
		SourceUnitState = XComGameState_Unit(History.GetGameStateForObjectID(ApplyEffectParameters.SourceStateObjectRef.ObjectID));
		if (SourceUnitState != none)
		{
			SourceUnitState = XComGameState_Unit(NewGameState.ModifyStateObject(SourceUnitState.Class, SourceUnitState.ObjectID));
		}

		if (bUniqueTarget)          //  Remove previous effect from a different target.
		{
			foreach SourceUnitState.AppliedEffects(EffectRef)
			{
				ExistingEffect = XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID));
				if (ExistingEffect == none)
					continue;
				if (ExistingEffect.bRemoved)
					continue;
				if (ExistingEffect.GetX2Effect().EffectName != EffectName)
					continue;
				if (ExistingEffect.ApplyEffectParameters.TargetStateObjectRef.ObjectID != ApplyEffectParameters.TargetStateObjectRef.ObjectID)
				{
					ExistingEffect.RemoveEffect(NewGameState, NewGameState);
					break;
				}
			}
		}

		PersistentEffectStateObject = XComGameState_Effect(NewGameState.CreateNewStateObject(GameStateEffectClass != none ? GameStateEffectClass : class'XComGameState_Effect'));
		PersistentEffectStateObject.PostCreateInit( ApplyEffectParameters, WatchRule, NewGameState );
		NewEffectState = PersistentEffectStateObject;

		if( TargetUnitState != None )
		{
			TargetUnitState.AddAffectingEffect(PersistentEffectStateObject);
		}
		if (SourceUnitState != none)
		{
			SourceUnitState.AddAppliedEffect(PersistentEffectStateObject);
		}
	}

	return 'AA_Success';
}

function bool IsThisEffectBetterThanExistingEffect(const out XComGameState_Effect ExistingEffect)
{
	local X2Effect_Persistent PersistentEffectTemplate;

	PersistentEffectTemplate = ExistingEffect.GetX2Effect();
	`assert(PersistentEffectTemplate != none);
	
	if( (EffectRank > PersistentEffectTemplate.EffectRank) )
	{
		return true;
	}

	return false;
}

// Returns true if this function will tick after abilities marked as effected ticking are activated
function bool IsTickEveryAction(XComGameState_BaseObject TargetObject)
{
	local XComGameState_Unit TargetUnitState;

	TargetUnitState = XComGameState_Unit(TargetObject);
	if(TargetUnitState != none)
	{
		return bCanTickEveryAction && TargetUnitState.GetMyTemplate().bCanTickEffectsEveryAction;
	}
	else
	{
		return false; // non-units do not take actions, and therefore cannot tick per action
	}
}

function int GetStartingNumTurns(const out EffectAppliedData ApplyEffectParameters)
{
	local XComGameState_Ability AbilityState;
	local XComGameState_BaseObject TargetState;
	local XComGameState_Unit TargetUnit;
	local StateObjectReference EffectRef;
	local XComGameState_Effect EffectState;
	local XComGameStateHistory History;
	local int StartingNumTurns;
	local XComGameState_BattleData BattleDataState;
	local X2SitRepEffect_ModifyEffectDuration SitRepEffect;

	// if the Ability that spawned this effect has a limited duration, we want to use that duration
	History = `XCOMHISTORY;
	AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(ApplyEffectParameters.AbilityStateObjectRef.ObjectID));
	if (AbilityState != none && AbilityState.TurnsUntilAbilityExpires > 0)
	{
		bInfiniteDuration = false;
		return AbilityState.TurnsUntilAbilityExpires;
	}

	// if this effect is specified for an infinite duration, return 1
	if( bInfiniteDuration )
	{
		return 1;
	}

	StartingNumTurns = iNumTurns;
	TargetState = History.GetGameStateForObjectID(ApplyEffectParameters.TargetStateObjectRef.ObjectID);

	// Check if any other effects on the source or target unit want to change the duration of this effect
	TargetUnit = XComGameState_Unit(TargetState);
	if(TargetUnit != none)
	{
		foreach TargetUnit.AffectedByEffects(EffectRef)
		{
			EffectState = XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID));
			EffectState.GetX2Effect().AdjustEffectDuration(ApplyEffectParameters, StartingNumTurns);
		}
	}

	// find any sitreps that can modify effect durations and apply those limits
	BattleDataState = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
	if (BattleDataState != none)
	{
		foreach class'X2SitreptemplateManager'.static.IterateEffects(class'X2SitRepEffect_ModifyEffectDuration', SitRepEffect, BattleDataState.ActiveSitReps)
		{
			StartingNumTurns = SitRepEffect.MaybeModifyDuration( self, TargetUnit, StartingNumTurns );
		}
	}

	// if the effect will tick per action instead of per turn, then modify the turns remaining counter
	// to reflect that.
	if(bConvertTurnsToActions && IsTickEveryAction(TargetState))
	{
		StartingNumTurns *= class'X2CharacterTemplateManager'.default.StandardActionsPerTurn;
	}

	// return the configured duration for this effect
	return StartingNumTurns;
}

function UnitEndedTacticalPlay(XComGameState_Effect EffectState, XComGameState_Unit UnitState);
function bool IsEffectCurrentlyRelevant(XComGameState_Effect EffectGameState, XComGameState_Unit TargetUnit) { return true; }
function RegisterForEvents(XComGameState_Effect EffectGameState);
function bool AllowCritOverride() { return false; }
function bool ShotsCannotGraze() { return false; }
function bool AllowDodge(XComGameState_Unit Attacker, XComGameState_Ability AbilityState) { return true; }
function bool ChangeHitResultForAttacker(XComGameState_Unit Attacker, XComGameState_Unit TargetUnit, XComGameState_Ability AbilityState, const EAbilityHitResult CurrentResult, out EAbilityHitResult NewHitResult) { return false; }
function bool ChangeHitResultForTarget(XComGameState_Effect EffectState, XComGameState_Unit Attacker, XComGameState_Unit TargetUnit, XComGameState_Ability AbilityState, bool bIsPrimaryTarget, const EAbilityHitResult CurrentResult, out EAbilityHitResult NewHitResult) { return false; }
function GetToHitModifiers(XComGameState_Effect EffectState, XComGameState_Unit Attacker, XComGameState_Unit Target, XComGameState_Ability AbilityState, class<X2AbilityToHitCalc> ToHitType, bool bMelee, bool bFlanking, bool bIndirectFire, out array<ShotModifierInfo> ShotModifiers);
function bool UniqueToHitModifiers() { return false; }
function GetToHitAsTargetModifiers(XComGameState_Effect EffectState, XComGameState_Unit Attacker, XComGameState_Unit Target, XComGameState_Ability AbilityState, class<X2AbilityToHitCalc> ToHitType, bool bMelee, bool bFlanking, bool bIndirectFire, out array<ShotModifierInfo> ShotModifiers);
function bool UniqueToHitAsTargetModifiers() { return false; }
function int GetAttackingDamageModifier(XComGameState_Effect EffectState, XComGameState_Unit Attacker, Damageable TargetDamageable, XComGameState_Ability AbilityState, const out EffectAppliedData AppliedData, const int CurrentDamage, optional XComGameState NewGameState) { return 0; }
function int GetDefendingDamageModifier(XComGameState_Effect EffectState, XComGameState_Unit Attacker, Damageable TargetDamageable, XComGameState_Ability AbilityState, const out EffectAppliedData AppliedData, const int CurrentDamage, X2Effect_ApplyWeaponDamage WeaponDamageEffect, optional XComGameState NewGameState) { return 0; }
function int GetBaseDefendingDamageModifier(XComGameState_Effect EffectState, XComGameState_Unit Attacker, Damageable TargetDamageable, XComGameState_Ability AbilityState, const out EffectAppliedData AppliedData, const int BaseDamage, X2Effect_ApplyWeaponDamage WeaponDamageEffect, optional XComGameState NewGameState) { return 0; }
function int GetExtraArmorPiercing(XComGameState_Effect EffectState, XComGameState_Unit Attacker, Damageable TargetDamageable, XComGameState_Ability AbilityState, const out EffectAppliedData AppliedData) { return 0; }
function int GetExtraShredValue(XComGameState_Effect EffectState, XComGameState_Unit Attacker, Damageable TargetDamageable, XComGameState_Ability AbilityState, const out EffectAppliedData AppliedData) { return 0; }
function int GetConditionalExtraShredValue(int UnconditionalShred, XComGameState_Effect EffectState, XComGameState_Unit Attacker, Damageable TargetDamageable, XComGameState_Ability AbilityState, const out EffectAppliedData AppliedData) { return 0; }
function ModifyTurnStartActionPoints(XComGameState_Unit UnitState, out array<name> ActionPoints, XComGameState_Effect EffectState);
function bool AllowReactionFireCrit(XComGameState_Unit UnitState, XComGameState_Unit TargetState) { return false; }
function ModifyReactionFireSuccess(XComGameState_Unit UnitState, XComGameState_Unit TargetState, out int Modifier);
function bool ProvidesDamageImmunity(XComGameState_Effect EffectState, name DamageType) { return false; }
function ModifyGameplayVisibilityForTarget(out GameRulesCache_VisibilityInfo InOutVisibilityInfo, XComGameState_Unit SourceUnit, XComGameState_Unit TargetUnit);
function bool PostAbilityCostPaid(XComGameState_Effect EffectState, XComGameStateContext_Ability AbilityContext, XComGameState_Ability kAbility, XComGameState_Unit SourceUnit, XComGameState_Item AffectWeapon, XComGameState NewGameState, const array<name> PreCostActionPoints, const array<name> PreCostReservePoints) { return false; }
function GetStatCheckModToSuccessCheck(XComGameState_Effect EffectState, XComGameState_Unit UnitState, XComGameState_Ability AbilityState, out int Successes);
function bool RetainIndividualConcealment(XComGameState_Effect EffectState, XComGameState_Unit UnitState) { return false; }     //  return true to keep individual concealment when squad concealment is broken
function bool DoesEffectAllowUnitToBleedOut(XComGameState_Unit UnitState) { return true; }
function bool DoesEffectAllowUnitToBeLooted(XComGameState NewGameState, XComGameState_Unit UnitState) { return true; }
function bool CanAbilityHitUnit(name AbilityName) { return true; }
function bool PreDeathCheck(XComGameState NewGameState, XComGameState_Unit UnitState, XComGameState_Effect EffectState) { return false; }
function bool PreBleedoutCheck(XComGameState NewGameState, XComGameState_Unit UnitState, XComGameState_Effect EffectState) { return false; }
function bool ForcesBleedout(XComGameState NewGameState, XComGameState_Unit UnitState, XComGameState_Effect EffectState) { return bEffectForcesBleedout; }
function bool ForcesBleedoutWhenDamageSource(XComGameState NewGameState, XComGameState_Unit UnitState, XComGameState_Effect EffectState) { return false; }
function      AdjustEffectDuration(const out EffectAppliedData ApplyEffectParameters, out int Duration);
function Actor GetProjectileVolleyTemplate(XComGameState_Unit UnitState, XComGameState_Effect EffectState, XComGameStateContext_Ability AbilityContext) { return none; }
function bool AdjustSuperConcealModifier(XComGameState_Unit UnitState, XComGameState_Effect EffectState, XComGameState_Ability AbilityState, XComGameState RespondToGameState, const int BaseModifier, out int CurrentModifier) { return false; }
function bool FreeKillOnDamage(XComGameState_Unit Shooter, XComGameState_Unit Target, XComGameState GameState, const int ToKillTarget, const out EffectAppliedData ApplyEffectParameters) { return false; }
function bool GrantsFreeActionPointForApplyCost(XComGameStateContext_Ability AbilityContext, XComGameState_Unit Shooter, XComGameState_Unit Target, XComGameState GameState) { return false; }
function bool GrantsFreeActionPoint_Target(XComGameStateContext_Ability AbilityContext, XComGameState_Unit Shooter, XComGameState_Unit Target, XComGameState GameState) { return false; }
function bool ImmediateSelectNextTarget(XComGameStateContext_Ability AbilityContext, XComGameState_Unit Target) { return false; }
function bool ShouldUseMidpointCameraForTarget(XComGameState_Ability AbilityState, XComGameState_Unit Target) { return false; }
function bool HideUIUnitFlag() { return false; }
function bool AreMovesVisible() { return true; }
function int ModifyDamageFromDestructible(XComGameState_Destructible DestructibleState, int IncomingDamage, XComGameState_Unit TargetUnit, XComGameState_Effect EffectState) { return 0; }
event string GetSpecialDamageMessageName() { return FriendlyName; }

final event int CallModifyDamageFromDestructible(XComGameState_Destructible DestructibleState, int IncomingDamage, XComGameState_Unit TargetUnit, XComGameState_Effect EffectState)
{
	return ModifyDamageFromDestructible(DestructibleState, IncomingDamage, TargetUnit, EffectState);
}

//  Modify the value that is displayed by XComGameState_Unit:GetUISummary_UnitStats (e.g. tooltip of stats in lower left)
function ModifyUISummaryUnitStats(XComGameState_Effect EffectState, XComGameState_Unit UnitState, const ECharStatType Stat, out int StatValue);

// By default this returns eGameplayBlocking_DoesNotModify because most effects don't change blocking
function EGameplayBlocking ModifyGameplayPathBlockingForTarget(const XComGameState_Unit UnitState, const XComGameState_Unit TargetUnit) { return eGameplayBlocking_DoesNotModify; }

// By default this returns eGameplayBlocking_DoesNotModify because most effects don't change blocking
function EGameplayBlocking ModifyGameplayDestinationBlockingForTarget(const XComGameState_Unit UnitState, const XComGameState_Unit TargetUnit) { return eGameplayBlocking_DoesNotModify; }

//  Register an effect in the config array EffectUpdatesOnMove on AbilityTemplateManager in order to receive these callbacks
function OnUnitChangedTile(const out TTile NewTileLocation, XComGameState_Effect EffectState, XComGameState_Unit TargetUnit);

//  Add the name of the effect to X2AbilityTemplateManager AffectingEffectRedirectors and implement this function to handle potential redirects
function bool EffectShouldRedirect(XComGameStateContext_Ability AbilityContext, XComGameState_Ability SourceAbility, XComGameState_Effect EffectState, const X2Effect PotentialRedirect, XComGameState_Unit SourceUnit, XComGameState_Unit TargetUnit, out StateObjectReference RedirectTarget, out name Reason, out name OverrideEffectResult) { return false; }

function name TargetAdditiveAnimOnApplyWeaponDamage(XComGameStateContext Context, XComGameState_Unit TargetUnit, XComGameState_Effect EffectState) { return ''; }
function name ShooterAdditiveAnimOnFire(XComGameStateContext Context, XComGameState_Unit ShooterUnit, XComGameState_Effect EffectState) { return ''; }

// This is used to test if the effect being visualized is the first
// visualization of that particular effect on a particular unit in the
// current event chain.  This is used to prevent repeated showings of
// effect related flyovers.
function bool IsFirstMatchingEffectInEventChain(XComGameState VisualizeGameState)
{
	local int iStartIndex, i, j;
	local XComGameStateHistory History;
	local XComGameState TestGameState;	
	local XComGameStateContext_ApplyWorldEffects VisualizeContext;
	local XComGameStateContext_ApplyWorldEffects TestContext;
	local X2Effect_Persistent PersistentEffect;

	local bool bEffectNamesMatch;
	local bool bTargetActorsMatch;

	History = `XCOMHISTORY;


	iStartIndex = VisualizeGameState.GetContext().EventChainStartIndex;
	for ( i = iStartIndex; i <= VisualizeGameState.HistoryIndex; ++i )
	{
		TestGameState = History.GetGameStateFromHistory( i );

		TestContext = XComGameStateContext_ApplyWorldEffects(TestGameState.GetContext());
		if ( TestContext != none )
		{
			//-----------------------
			// See if this gamestate applies to the same actor as the given gamestate
			bTargetActorsMatch = false;
			VisualizeContext = XComGameStateContext_ApplyWorldEffects(VisualizeGameState.GetContext());
			if ( VisualizeContext != none )
			{
				bTargetActorsMatch = ( VisualizeContext.ApplyEffectTarget.GetVisualizer() == TestContext.ApplyEffectTarget.GetVisualizer() );
			}


			//-----------------------
			// See if any of the effects in the context are the same type as this effect.
			bEffectNamesMatch = false;
			if ( bTargetActorsMatch )
			{
				for (j = 0; j < TestContext.TargetEffectResults.Effects.length; ++j)
				{
					PersistentEffect = X2Effect_Persistent(TestContext.TargetEffectResults.Effects[j]);

					if ( PersistentEffect != none )
					{
						if ( PersistentEffect.EffectName == self.EffectName )
						{
							bEffectNamesMatch = true;
							break;
						}
					}
				}
			}

			//-----------------------
			// With the very first match we find, return whether or not the contexts are the same.
			if ( bEffectNamesMatch && bTargetActorsMatch )
			{
				return ( TestContext == VisualizeContext );
			}
		}
	}

	return false;
}

function bool HasOverrideDeathAnimOnLoad(out Name DeathAnim)
{
	return false;
}

defaultproperties
{
	DuplicateResponse = eDupe_Allow
	bDisplayInUI = false
	EffectRank = 0
	EffectHierarchyValue = -1
	VisionArcDegreesOverride = 360.0f
	bConvertTurnsToActions = true
	GameStateEffectClass = class'XComGameState_Effect'
	bEffectForcesBleedout = false
}