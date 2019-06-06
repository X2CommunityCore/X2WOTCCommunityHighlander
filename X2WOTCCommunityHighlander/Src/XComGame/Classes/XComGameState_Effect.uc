//---------------------------------------------------------------------------------------
//  FILE:    XComGameState_Effect.uc
//  AUTHOR:  Dan Kaplan
//	DATE:	 5/22/2014
//           
//  Game state information for any active X2Effects currently present in the tactical game.
//
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComGameState_Effect extends XComGameState_BaseObject 
	native(Core) 
	dependson(X2Effect);

var() private{private} X2EffectTemplateRef EffectTemplateRef; // Contains template data relating to this effect
var() EffectAppliedData ApplyEffectParameters;      // Instance data required to apply the effects of this ability

var() int iTurnsRemaining;                          // Number of turns remaining on this effect. Unless the template specifies an infinite duration 
													// this effect will be removed when this value hits 0.
var() int iShedChance;                              // If this number is > 0, each tick has this % chance to remove the effect.
var() int iStacks;                                  // Number of times this effect has been refreshed, if it is allowed to stack.
var() int AttacksReceived;							// The number of attacks received by the unit this effect is applied to (since it was applied)

var StateObjectReference CreatedObjectReference;    // Used by various effect classes that need to track what they created.

var private float DamageTakenThisFullTurn;
var private int GrantsThisTurn;                     // Used sort of how you want. Resets automatically when the effect is ticked (assuming it is).
var int FullTurnsTicked;

var array<StatChange> StatChanges;                  //  Persistent stat changes are tracked here, as they may be dynamic

var array<TTile> AffectedTiles;						// List of tiles affected by this effect

cpptext
{
	const FStatChange& GetStatChangeForType( ECharStatType StatType ) const;
}

native function bool Validate(XComGameState HistoryGameState, INT GameStateIndex) const;

function X2Effect_Persistent GetX2Effect()
{
	return X2Effect_Persistent(class'X2Effect'.static.GetX2Effect(EffectTemplateRef));
}

function EventListenerReturn OnPlayerTurnTicked(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	// only applicable at the end of the instigating player's turn, unless bIgnorePlayerCheckOnTick is true
	if( GetX2Effect().FullTurnComplete(self, XComGameState_Player(EventData)) )
	{			
		InternalTickEffect(GameState, XComGameState_Player(EventData));
	}

	return ELR_NoInterrupt;
}

function EventListenerReturn OnGroupTurnTicked(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameState_Player ActivePlayer;

	ActivePlayer = XComGameState_Player(`XCOMHISTORY.GetGameStateForObjectID(`TACTICALRULES.GetCachedUnitActionPlayerRef().ObjectID));

	// only applicable at the end of the instigating player's turn, unless bIgnorePlayerCheckOnTick is true
	if( GetX2Effect().FullTurnComplete(self, ActivePlayer) )
	{			
		InternalTickEffect(GameState, ActivePlayer);
	}

	return ELR_NoInterrupt;
}

function EventListenerReturn OnAbilityActivated(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameStateHistory History;
	local XComGameStateContext_TickEffect TickContext;
	local XComGameState_Ability AbilityState;
	local XComGameState_Effect OriginalEffectState;
	local int ChainStartIndex;
	local XComGameState_Player ActivePlayer;

	// only tick after the rest of the ability has resolved
	if(GameState.GetContext().InterruptionStatus == eInterruptionStatus_Interrupt) 
	{
		return ELR_NoInterrupt;
	}

	// only tick if the activated ability should tick per action effects
	AbilityState = XComGameState_Ability(EventData);
	if(AbilityState == none || !AbilityState.GetMyTemplate().bTickPerActionEffects)
	{
		return ELR_NoInterrupt;
	}
	
	History = `XCOMHISTORY;
	ChainStartIndex = History.GetEventChainStartIndex();

	// not if it was just applied in this chain
	OriginalEffectState = XComGameState_Effect(History.GetOriginalGameStateRevision(ObjectID));
	if(OriginalEffectState != none && OriginalEffectState.GetParentGameState().GetContext().EventChainStartIndex == ChainStartIndex)
	{
		return ELR_NoInterrupt;
	}

	// make sure we only tick the effect once per chain
	foreach History.IterateContextsByClassType(class'XComGameStateContext_TickEffect', TickContext,, true)
	{
		if(TickContext.EventChainStartIndex < ChainStartIndex)
		{
			// we've iterated past the start of this chain, so we can stop looking.
			// we haven't ticked yet in this chain
			break;
		}

		if(TickContext.TickedEffect.ObjectID == self.ObjectID)
		{
			// this effect has already ticked once in this chain, don't do it again
			return ELR_NoInterrupt;
		}
	}

	ActivePlayer = XComGameState_Player(`XCOMHISTORY.GetGameStateForObjectID(`TACTICALRULES.GetCachedUnitActionPlayerRef().ObjectID));

	InternalTickEffect(GameState, ActivePlayer);
	return ELR_NoInterrupt;
}

// helper to prevent duplicated code between the on turn and on action tick callbacks
// builds a new tick context and submits the results to the rules engine
protected function InternalTickEffect(XComGameState CallbackGameState, XComGameState_Player Player)
{
	local XComGameStateContext_TickEffect TickContext;
	local XComGameState NewGameState;
	local X2TacticalGameRuleset TacticalRules;

	TacticalRules = `TACTICALRULES;

	// only act if this Effect is not already removed, and if 
	// the tactical game has not ended (so poison/etc can't kill units after game end).
	if( !bRemoved && !TacticalRules.HasTacticalGameEnded() )
	{
		TickContext = class'XComGameStateContext_TickEffect'.static.CreateTickContext(self);
		TickContext.SetVisualizationFence(true);
		NewGameState = `XCOMHISTORY.CreateNewGameState(true, TickContext);
		if( !TickEffect(NewGameState, false, Player) )
		{
			RemoveEffect(NewGameState, CallbackGameState);
		}

		if( NewGameState.GetNumGameStateObjects() > 0 )
		{
			TacticalRules.SubmitGameState(NewGameState);
		}
		else
		{
			`XCOMHISTORY.CleanupPendingGameState(NewGameState);
		}
	}
}

function EventListenerReturn OnUnitDiedOrBleedingOut(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
	local XComGameStateContext_EffectRemoved EffectRemovedState;
	local XComGameState NewGameState;
	local XComGameState_Unit UnitState;
	local X2TacticalGameRuleset TacticalRules;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;

	UnitState = XComGameState_Unit(EventData);

	//If this effect is to be removed on both source death and target death, the event manager can't filter events by objectID for us.
	//We might, then, get events for irrelevant units dying. (See comment in OnCreation.) -btopp 2015-08-26
	if (UnitState.ObjectID != ApplyEffectParameters.SourceStateObjectRef.ObjectID && UnitState.ObjectID != ApplyEffectParameters.TargetStateObjectRef.ObjectID)
		return ELR_NoInterrupt;

	if(UnitState != none && (UnitState.IsDead() || UnitState.IsBleedingOut()) && !bRemoved)
	{
		if (EventID == 'UnitBleedingOut' && (UnitState.IsBleedingOut() && UnitState.GetBleedingOutTurnsRemaining() > 0) &&
			GetX2Effect().EffectName == class'X2StatusEffects'.default.BleedingOutName)
		{
			return ELR_NoInterrupt;
		}

		EffectRemovedState = class'XComGameStateContext_EffectRemoved'.static.CreateEffectRemovedContext(self);
		NewGameState = History.CreateNewGameState(true, EffectRemovedState);
		RemoveEffect(NewGameState, GameState);

		if( NewGameState.GetNumGameStateObjects() > 0 )
		{
			TacticalRules = `TACTICALRULES;
			TacticalRules.SubmitGameState(NewGameState);

			//  effects may have changed action availability - if a unit died, took damage, etc.
		}
		else
		{
			History.CleanupPendingGameState(NewGameState);
		}
	}

	return ELR_NoInterrupt;
}

function EventListenerReturn OnUnitRemovedFromPlay(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameState_Unit UnitState;
	local XComGameStateContext_EffectRemoved EffectRemovedState;
	local XComGameState NewGameState;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;

	UnitState = XComGameState_Unit(EventData);
	if (UnitState == None || (!UnitState.bRemovedFromPlay) || bRemoved)
		return ELR_NoInterrupt;

	//See comment in OnUnitDiedOrBleedingOut.
	if (UnitState.ObjectID != ApplyEffectParameters.SourceStateObjectRef.ObjectID && UnitState.ObjectID != ApplyEffectParameters.TargetStateObjectRef.ObjectID)
		return ELR_NoInterrupt;

	EffectRemovedState = class'XComGameStateContext_EffectRemoved'.static.CreateEffectRemovedContext(self);
	NewGameState = History.CreateNewGameState(true, EffectRemovedState);
	RemoveEffect(NewGameState, GameState, true); //Cleansed, so we don't end up killing bleeding-out units, for example

	if (NewGameState.GetNumGameStateObjects() > 0)
	{
		`TACTICALRULES.SubmitGameState(NewGameState);
	}
	else
	{
		History.CleanupPendingGameState(NewGameState);
	}

	return ELR_NoInterrupt;
}

function PostCreateInit(EffectAppliedData InApplyEffectParameters, GameRuleStateChange WatchRule, XComGameState NewGameState)
{
	local XComGameState_Effect ThisEffect;
	local Object ThisObj;
	local XComGameState_Player PlayerState;
	local XComGameState_Unit SourceUnitState;
	local XComGameState_Unit TargetUnitState;
	local X2Effect_Persistent EffectTemplate;
	local XComGameStateHistory History;
	local X2EventManager EventMgr;
	local XComGameStateContext_Ability AbilityContext;
	local X2AbilityTemplate AbilityTemplate;
	local X2AbilityMultiTarget_BurstFire BurstFire;
	local XComGameState_AIGroup GroupState;

	History = `XCOMHISTORY;
	EventMgr = `XEVENTMGR;
	EffectTemplateRef = InApplyEffectParameters.EffectRef;

	EffectTemplate = GetX2Effect();

	ThisObj = self;

	ApplyEffectParameters = InApplyEffectParameters;
	iTurnsRemaining = EffectTemplate.GetStartingNumTurns(ApplyEffectParameters);

	iShedChance = EffectTemplate.iInitialShedChance;

	if (EffectTemplate.bStackOnRefresh)
	{
		iStacks = 1;
		AbilityContext = XComGameStateContext_Ability(NewGameState.GetContext());
		if (AbilityContext != none && AbilityContext.InputContext.PrimaryTarget.ObjectID == ApplyEffectParameters.TargetStateObjectRef.ObjectID)
		{
			AbilityTemplate = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate(AbilityContext.InputContext.AbilityTemplateName);
			if (AbilityTemplate != none)
			{
				BurstFire = X2AbilityMultiTarget_BurstFire(AbilityTemplate.AbilityMultiTargetStyle);
				if (BurstFire != none)
				{
					iStacks += BurstFire.NumExtraShots;
				}
			}
		}
	}

	PlayerState = XComGameState_Player(History.GetGameStateForObjectID(ApplyEffectParameters.PlayerStateObjectRef.ObjectID));
	if (PlayerState.GetTeam() == eTeam_Neutral )
	{
		// Neutral is civilian, so change this to tick on the alien turn
		foreach History.IterateByClassType(class'XComGameState_Player', PlayerState)
		{
			if( PlayerState.GetTeam() == eTeam_Alien )
			{
				break;
			}
		}
	}


	// register for the appropriate tick events
	TargetUnitState = XComGameState_Unit(History.GetGameStateForObjectID(ApplyEffectParameters.TargetStateObjectRef.ObjectID));

	if (TargetUnitState != none)
	{
		GroupState = TargetUnitState.GetGroupMembership( );
	}

	if(TargetUnitState != none && EffectTemplate.IsTickEveryAction(TargetUnitState))
	{
		EventMgr.RegisterForEvent( ThisObj, 'AbilityActivated', OnAbilityActivated, ELD_OnStateSubmitted, 0, TargetUnitState );
	}
	else
	{
		if( WatchRule == eGameRule_PlayerTurnBegin )
		{
			EventMgr.RegisterForEvent( ThisObj, 'PlayerTurnBegun', OnPlayerTurnTicked, ELD_OnStateSubmitted,, EffectTemplate.bIgnorePlayerCheckOnTick ? none : PlayerState );
		}
		else if( WatchRule == eGameRule_PlayerTurnEnd )
		{
			EventMgr.RegisterForEvent( ThisObj, 'PlayerTurnEnded', OnPlayerTurnTicked, ELD_OnStateSubmitted,, EffectTemplate.bIgnorePlayerCheckOnTick ? none : PlayerState );
		}
		else if ( WatchRule == eGameRule_UnitGroupTurnBegin )
		{
			EventMgr.RegisterForEvent( ThisObj, 'UnitGroupTurnBegun', OnGroupTurnTicked, ELD_OnStateSubmitted,, GroupState );
		}
		else if ( WatchRule == eGameRule_UnitGroupTurnEnd )
		{
			EventMgr.RegisterForEvent( ThisObj, 'UnitGroupTurnEnded', OnGroupTurnTicked, ELD_OnStateSubmitted,, GroupState );
		}
	}

	//The event manager can't handle having us registered for the same event with two different object filters.
	//Unfortunately, that's just what we need to do if we want to watch for source and target death.
	//Checking the unit's objectID will have to happen in OnUnitDiedOrBleedingOut instead. -btopp 2015-08-26
	if (EffectTemplate.bRemoveWhenSourceDies && EffectTemplate.bRemoveWhenTargetDies)
	{
		EventMgr.RegisterForEvent(ThisObj, 'UnitDied', OnUnitDiedOrBleedingOut, ELD_OnStateSubmitted, , );
		EventMgr.RegisterForEvent(ThisObj, 'UnitBleedingOut', OnUnitDiedOrBleedingOut, ELD_OnStateSubmitted, , ); //For x2effect purposes, bleeding out should be handled the same as death
	}
	else if (EffectTemplate.bRemoveWhenSourceDies)
	{
		SourceUnitState = XComGameState_Unit(History.GetGameStateForObjectID(ApplyEffectParameters.SourceStateObjectRef.ObjectID));
		EventMgr.RegisterForEvent(ThisObj, 'UnitDied', OnUnitDiedOrBleedingOut, ELD_OnStateSubmitted, , SourceUnitState);
		EventMgr.RegisterForEvent(ThisObj, 'UnitBleedingOut', OnUnitDiedOrBleedingOut, ELD_OnStateSubmitted, , SourceUnitState); //For x2effect purposes, bleeding out should be handled the same as death
	}
	else if (EffectTemplate.bRemoveWhenTargetDies)
	{
		SourceUnitState = XComGameState_Unit(History.GetGameStateForObjectID(ApplyEffectParameters.TargetStateObjectRef.ObjectID));
		EventMgr.RegisterForEvent(ThisObj, 'UnitDied', OnUnitDiedOrBleedingOut, ELD_OnStateSubmitted, , SourceUnitState);
		EventMgr.RegisterForEvent(ThisObj, 'UnitBleedingOut', OnUnitDiedOrBleedingOut, ELD_OnStateSubmitted, , SourceUnitState); //For x2effect purposes, bleeding out should be handled the same as death
	}

	if (EffectTemplate.bRemoveWhenSourceDamaged)
	{
		SourceUnitState = XComGameState_Unit(History.GetGameStateForObjectID(ApplyEffectParameters.SourceStateObjectRef.ObjectID));
		EventMgr.RegisterForEvent(ThisObj, 'UnitTakeEffectDamage', OnSourceUnitTookEffectDamage, ELD_OnStateSubmitted, , SourceUnitState);
	}
	if (EffectTemplate.bRemoveWhenTargetConcealmentBroken)
	{
		SourceUnitState = XComGameState_Unit(History.GetGameStateForObjectID(ApplyEffectParameters.TargetStateObjectRef.ObjectID));
		EventMgr.RegisterForEvent(ThisObj, 'UnitConcealmentBroken', OnTargetConcealmentBroken, ELD_OnStateSubmitted, , SourceUnitState);
	}

	//Handle units being removed from play
	if (EffectTemplate.bRemoveWhenSourceDies)
	{
		//If the effect is to be removed when the source dies, then either the source's or target's removal should get rid of it.
		EventMgr.RegisterForEvent(ThisObj, 'UnitRemovedFromPlay', OnUnitRemovedFromPlay, ELD_OnStateSubmitted, , );
	}
	else if( !EffectTemplate.bPersistThroughTacticalGameEnd )
	{
		//If the effect ignores the death of its source, it should also ignore the removal of its source.
		//Every effect should be removed when its target is removed, however.
		SourceUnitState = XComGameState_Unit(History.GetGameStateForObjectID(ApplyEffectParameters.TargetStateObjectRef.ObjectID));
		EventMgr.RegisterForEvent(ThisObj, 'UnitRemovedFromPlay', OnUnitRemovedFromPlay, ELD_OnStateSubmitted, , SourceUnitState);
	}

	ThisEffect = self;
	EffectTemplate.RegisterForEvents(ThisEffect);
}

function OnRefresh(EffectAppliedData NewApplyEffectParameters, XComGameState NewGameState)
{
	local X2Effect_Persistent EffectTemplate;
	local XComGameStateContext_Ability AbilityContext;
	local X2AbilityTemplate AbilityTemplate;
	local X2AbilityMultiTarget_BurstFire BurstFire;

	EffectTemplate = GetX2Effect();

	iTurnsRemaining = EffectTemplate.GetStartingNumTurns(NewApplyEffectParameters);
	iShedChance = EffectTemplate.iInitialShedChance;

	if (EffectTemplate.bStackOnRefresh)
	{
		iStacks++;
		AbilityContext = XComGameStateContext_Ability(NewGameState.GetContext());
		if (AbilityContext != none && AbilityContext.InputContext.PrimaryTarget.ObjectID == ApplyEffectParameters.TargetStateObjectRef.ObjectID)
		{
			AbilityTemplate = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate(AbilityContext.InputContext.AbilityTemplateName);
			if (AbilityTemplate != none)
			{
				BurstFire = X2AbilityMultiTarget_BurstFire(AbilityTemplate.AbilityMultiTargetStyle);
				if (BurstFire != none)
				{
					iStacks += BurstFire.NumExtraShots;
				}
			}
		}
	}
}

// NewGameState is the game state this remove effect is happening in
// VisualizeWithGameState is the history index the remove effect should be visualized at, this could be the same as the NewGameState.
// If this is not the same, then it will be moved to VisualizeWithGameState's visualization history index. For example,
// if the viper is binding a unit and is killed, the bound unit should unbind at the same time as the Viper is dying.
function RemoveEffect(XComGameState NewGameState, XComGameState VisualizeWithGameState, optional bool bCleansed=false, optional bool bPurge=false)
{	
	local X2EventManager EventManager;
	local Object ThisObj;
	local XComGameState_Unit OldTargetState, NewTargetState, OldSourceState, NewSourceState;
	local X2Effect_Persistent EffectTemplate;
	local XComGameStateContext_EffectRemoved EffectRemovedContext;

	if (bRemoved)
	{
		`RedScreen("RemoveEffect called on an effect state that is already marked bRemoved." @ ToString() @ "\n" @ GetScriptTrace());
		return;
	}

	OldTargetState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ApplyEffectParameters.TargetStateObjectRef.ObjectID));
	if (OldTargetState != none)
	{
		NewTargetState = XComGameState_Unit(NewGameState.ModifyStateObject(OldTargetState.Class, OldTargetState.ObjectID));
		`assert(NewTargetState != none);
	}
	OldSourceState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ApplyEffectParameters.SourceStateObjectRef.ObjectID));
	if (OldSourceState != none)
	{
		NewSourceState = XComGameState_Unit(NewGameState.ModifyStateObject(OldSourceState.Class, OldSourceState.ObjectID));
		`assert(NewSourceState != none);
	}
	
	EffectTemplate = GetX2Effect();	
	EventManager = `XEVENTMGR;
	ThisObj = self;
	EventManager.UnRegisterFromAllEvents(ThisObj);

	if( EffectTemplate.bBringRemoveVisualizationForward && (VisualizeWithGameState != none) && (VisualizeWithGameState.HistoryIndex > -1))
	{
		NewGameState.GetContext().SetDesiredVisualizationBlockIndex(VisualizeWithGameState.HistoryIndex);
	}

	EffectTemplate.OnEffectRemoved( ApplyEffectParameters, NewGameState, bCleansed, self );

	if (NewTargetState != none)
	{
		NewTargetState.RemoveAffectingEffect(self);
	}
	if (NewSourceState != none)
	{
		NewSourceState.RemoveAppliedEffect(self);
	}

	`assert(!bRemoved);
	if (bPurge)
	{
		NewGameState.PurgeGameStateForObjectID(ObjectID);
	}
	else
	{
		NewGameState.RemoveStateObject(ObjectID);
	}

	EffectRemovedContext = XComGameStateContext_EffectRemoved(NewGameState.GetContext());
	if ((EffectRemovedContext != none) && (EffectRemovedContext.RemovedEffects.Find('ObjectID', self.ObjectID) == INDEX_NONE))
	{
		// The NewGameState's Context is for EffectRemoved 
		// and this effect is not yet in the context's list of removed effects
		EffectRemovedContext.AddEffectRemoved(self);
	}
}

/// <summary>
/// Returns a boolean indicating whether this effect should be removed or not
/// </summary>
function bool TickEffect(XComGameState NewGameState, bool FirstApplication, XComGameState_Player Player)
{
	local XComGameState_Effect NewEffectState;
	local X2Effect_Persistent EffectTemplate;
	local bool bContinueTicking;

	EffectTemplate = GetX2Effect();

	NewEffectState = XComGameState_Effect(NewGameState.ModifyStateObject(Class, ObjectID));
	NewEffectState.DamageTakenThisFullTurn = 0;
	NewEffectState.GrantsThisTurn = 0;

	//Apply the tick effect to our target / source	
	bContinueTicking = EffectTemplate.OnEffectTicked(  ApplyEffectParameters,
															 NewEffectState,
															 NewGameState,
															 FirstApplication,
															 Player );

	// If the effect removes itself return false, stop the ticking of the effect
	// If the effect does not return iteslf, then the effect will be ticked again if it is infinite or there is time remaining
	return bContinueTicking;
}

// Sustained Ability: This is called when the effect is ticked and an associated ability 
// should fire.
function EventListenerReturn OnFireSustainedAbility(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameState_Unit SustainedEffectSourceUnit, SustainedEffectTargetUnit;
	local X2Effect_Sustained SustainedEffectTemplate;
	local StateObjectReference SustainedAbilityRef;
	local XComGameState_Ability SustainedAbility;
	local XComGameStateContext SustainedAbilityContext;
	local X2TacticalGameRuleset Ruleset;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;
	Ruleset = X2TacticalGameRuleset(`XCOMGAME.GameRuleset);
	
	SustainedEffectSourceUnit = XComGameState_Unit(History.GetGameStateForObjectID(ApplyEffectParameters.SourceStateObjectRef.ObjectID));
	`assert(SustainedEffectSourceUnit != none);
	SustainedEffectTargetUnit = XComGameState_Unit(History.GetGameStateForObjectID(ApplyEffectParameters.TargetStateObjectRef.ObjectID));
	`assert(SustainedEffectTargetUnit != none);

	SustainedEffectTemplate = X2Effect_Sustained(GetX2Effect());
	`assert(SustainedEffectTemplate != none);

	// Get the associated sustain ability and attempt to build a context for it
	//SustainedAbility = XComGameState_Ability(History.GetGameStateForObjectID(m_SustainedAbilityReference.ObjectID));
	SustainedAbilityRef = SustainedEffectSourceUnit.FindAbility(SustainedEffectTemplate.SustainedAbilityName);
	`assert(SustainedAbilityRef.ObjectID != 0);

	SustainedAbility = XComGameState_Ability(History.GetGameStateForObjectID(SustainedAbilityRef.ObjectID));
	SustainedAbilityContext = class'XComGameStateContext_Ability'.static.BuildContextFromAbility(SustainedAbility, SustainedEffectTargetUnit.ObjectID);

	// If the sustained ability context was sucessfully created, fire the sustained ability.
	// Otherwise remove this sustained effect because it has been broken
	if (SustainedAbilityContext.Validate())
	{
 		Ruleset.SubmitGameStateContext(SustainedAbilityContext);
	}

	return ELR_NoInterrupt;
}

// This is called when the a X2Effect_ImmediateAbilityActivation is added to a unit
function EventListenerReturn OnFireImmediateAbility(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameState_Unit EffectSourceUnit;
	local XComGameState_Unit EffectTargetUnit;
	local XComGameState_Unit FireAbilityUnit;
	local X2Effect_ImmediateAbilityActivation EffectTemplate;
	local StateObjectReference AbilityRef;
	local XComGameStateHistory History;
	local X2TacticalGameRuleset TacticalRules;
	local GameRulesCache_Unit UnitCache;
	local int i, j;
	local XComGameStateContext_EffectRemoved EffectRemovedState;
	local XComGameState NewGameState;

	History = `XCOMHISTORY;
	
	EffectSourceUnit = XComGameState_Unit(History.GetGameStateForObjectID(ApplyEffectParameters.SourceStateObjectRef.ObjectID));
	`assert(EffectSourceUnit != none);
	EffectTargetUnit = XComGameState_Unit(History.GetGameStateForObjectID(ApplyEffectParameters.TargetStateObjectRef.ObjectID));
	if( EffectTargetUnit == None )
	{
		// Target can be an interactive object, in which case, we don't want to apply any effects.
		return ELR_NoInterrupt;
	}

	EffectTemplate = X2Effect_ImmediateAbilityActivation(GetX2Effect());
	`assert(EffectTemplate != none);

	// determine which unit should activate the ability
	FireAbilityUnit = EffectTemplate.ActivateAbilityOnTarget ? EffectTargetUnit : EffectSourceUnit;

	// Get the associated sustain ability and attempt to build a context for it
	AbilityRef = FireAbilityUnit.FindAbility(EffectTemplate.AbilityName);
	`assert(AbilityRef.ObjectID != 0);

	TacticalRules = `TACTICALRULES;

	if (TacticalRules.GetGameRulesCache_Unit(FireAbilityUnit.GetReference(), UnitCache))
	{
		for (i = 0; i < UnitCache.AvailableActions.Length; ++i)
		{
			if (UnitCache.AvailableActions[i].AbilityObjectRef.ObjectID == AbilityRef.ObjectID)
			{
				if (UnitCache.AvailableActions[i].AvailableCode == 'AA_Success')
				{
					for (j = 0; j < UnitCache.AvailableActions[i].AvailableTargets.Length; ++j)
					{	
						if(!EffectTemplate.EffectTargetOnly || (UnitCache.AvailableActions[i].AvailableTargets[j].PrimaryTarget.ObjectID == EffectTargetUnit.ObjectID))
						{
							if( !bRemoved )
							{
								EffectRemovedState = class'XComGameStateContext_EffectRemoved'.static.CreateEffectRemovedContext(self);
								NewGameState = History.CreateNewGameState(true, EffectRemovedState);
								RemoveEffect(NewGameState, GameState);
								SubmitNewGameState(NewGameState);
							}

							class'XComGameStateContext_Ability'.static.ActivateAbility(UnitCache.AvailableActions[i], j);
						}
					}
				}
				break;
			}
		}
	}

	return ELR_NoInterrupt;
}

// Sustained Ability: This is called when the source unit of this effect is damaged. If
// too much damage is taken in a full turn, then the effect is removed.
// This is also now called on Suppression, which is not a sustained ability
function EventListenerReturn OnSourceUnitTookEffectDamage(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local X2Effect_Sustained SustainedEffectTemplate;
	local UnitValue LastEffectDamage;
	local XComGameState_Unit SustainedEffectSourceUnit;
	local XComGameState NewGameState;
	local XComGameStateHistory History;
	local XComGameStateContext_EffectRemoved EffectRemovedState;
	local X2TacticalGameRuleset TacticalRules;

	// If this effect is already removed, don't do it again
	if( !bRemoved )
	{
		History = `XCOMHISTORY;

		SustainedEffectTemplate = X2Effect_Sustained(GetX2Effect());
		//removed assert, this function is now used also for other effects other than sustained effects.
		//`assert(SustainedEffectTemplate != none);
		if(SustainedEffectTemplate != none)
		{
			SustainedEffectSourceUnit = XComGameState_Unit(History.GetGameStateForObjectID(ApplyEffectParameters.SourceStateObjectRef.ObjectID));
			SustainedEffectSourceUnit.GetUnitValue('LastEffectDamage', LastEffectDamage);

			DamageTakenThisFullTurn += LastEffectDamage.fValue;
			if (!(SustainedEffectTemplate.FragileAmount > 0 && (DamageTakenThisFullTurn >= SustainedEffectTemplate.FragileAmount)))
			{
				// The sustained effect's source unit has not taken enough damge, the sustain is kept, we just break out
				return ELR_NoInterrupt;
			}
		}

		EffectRemovedState = class'XComGameStateContext_EffectRemoved'.static.CreateEffectRemovedContext(self);
		NewGameState = History.CreateNewGameState(true, EffectRemovedState);
		RemoveEffect(NewGameState, GameState);

		if( NewGameState.GetNumGameStateObjects() > 0 )
		{
			TacticalRules = `TACTICALRULES;
			TacticalRules.SubmitGameState(NewGameState);
			//  effects may have changed action availability - if a unit died, took damage, etc.
		}
		else
		{
			History.CleanupPendingGameState(NewGameState);
		}
	}

	return ELR_NoInterrupt;
}

function EventListenerReturn OnTargetConcealmentBroken(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameStateContext_EffectRemoved EffectRemovedState;
	local XComGameState NewGameState;
	local XComGameState_Unit TargetUnitState;
	local X2TacticalGameRuleset TacticalRules;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;

	TargetUnitState = XComGameState_Unit(History.GetGameStateForObjectID(ApplyEffectParameters.TargetStateObjectRef.ObjectID));
	if (TargetUnitState != none && !TargetUnitState.IsConcealed() && !bRemoved)
	{
		EffectRemovedState = class'XComGameStateContext_EffectRemoved'.static.CreateEffectRemovedContext(self);
		NewGameState = History.CreateNewGameState(true, EffectRemovedState);
		RemoveEffect(NewGameState, GameState);

		TacticalRules = `TACTICALRULES;
		TacticalRules.SubmitGameState(NewGameState);
	}

	return ELR_NoInterrupt;
}

// Sustained Ability: This is called when the source unit of this effect is impaired.
// This causes the effect to be removed.
function EventListenerReturn OnSourceBecameImpaired(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameState NewGameState;
	local XComGameStateHistory History;
	local XComGameStateContext_EffectRemoved EffectRemovedState;
	local X2TacticalGameRuleset TacticalRules;

	History = `XCOMHISTORY;

	EffectRemovedState = class'XComGameStateContext_EffectRemoved'.static.CreateEffectRemovedContext(self);
	NewGameState = History.CreateNewGameState(true, EffectRemovedState);
	EffectRemovedState.SetAssociatedPlayTiming(SPT_AfterSequential);
	RemoveEffect(NewGameState, GameState);

	if( NewGameState.GetNumGameStateObjects() > 0 )
	{
		TacticalRules = `TACTICALRULES;
		TacticalRules.SubmitGameState(NewGameState);

		//  effects may have changed action availability - if a unit died, took damage, etc.
	}
	else
	{
		History.CleanupPendingGameState(NewGameState);
	}

	return ELR_NoInterrupt;
}

// This is called when the source unit of this effect is confused.
function EventListenerReturn OnConfusedMovement(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameState_Unit TargetUnitState;
	local XGUnit UnitVisualizer;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;

	TargetUnitState = XComGameState_Unit(History.GetGameStateForObjectID(ApplyEffectParameters.TargetStateObjectRef.ObjectID));
	`assert(TargetUnitState != none);

	if (TargetUnitState != none)
	{
		//  @TODO gameplay - the function on XGUnit needs to move to the state system
		UnitVisualizer = XGUnit(TargetUnitState.GetVisualizer());
		if (UnitVisualizer != none)
		{
			UnitVisualizer.RunForCover(`XWORLD.GetPositionFromTileCoordinates(TargetUnitState.TileLocation));
			TargetUnitState.ActionPoints.Length = 0;
		}
	}

	return ELR_NoInterrupt;
}

function EventListenerReturn CoveringFireCheck(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameState_Unit AttackingUnit, CoveringUnit;
	local XComGameStateHistory History;
	local X2Effect_CoveringFire CoveringFireEffect;
	local StateObjectReference AbilityRef;
	local XComGameState_Ability AbilityState;
	local XComGameStateContext_Ability AbilityContext;
	local XComGameState NewGameState;
	local XComGameState_Effect NewEffectState;
	local int RandRoll;

	AbilityContext = XComGameStateContext_Ability(GameState.GetContext());
	if (AbilityContext != none)
	{
		History = `XCOMHISTORY;
		CoveringUnit = XComGameState_Unit(History.GetGameStateForObjectID(ApplyEffectParameters.TargetStateObjectRef.ObjectID));
		AttackingUnit = class'X2TacticalGameRulesetDataStructures'.static.GetAttackingUnitState(GameState);
		if (AttackingUnit != none && AttackingUnit.IsEnemyUnit(CoveringUnit))
		{
			CoveringFireEffect = X2Effect_CoveringFire(GetX2Effect());
			`assert(CoveringFireEffect != none);

			if (CoveringFireEffect.bOnlyDuringEnemyTurn)
			{
				//  make sure it's the enemy turn if required
				if (`TACTICALRULES.GetCachedUnitActionPlayerRef().ObjectID != AttackingUnit.ControllingPlayer.ObjectID)
					return ELR_NoInterrupt;
			}

			if (CoveringFireEffect.bPreEmptiveFire)
			{
				//  for pre emptive fire, only process during the interrupt step
				if (AbilityContext.InterruptionStatus != eInterruptionStatus_Interrupt)
					return ELR_NoInterrupt;
			}
			else
			{
				//  for non-pre emptive fire, don't process during the interrupt step
				if (AbilityContext.InterruptionStatus == eInterruptionStatus_Interrupt)
					return ELR_NoInterrupt;
			}

			if (CoveringFireEffect.bDirectAttackOnly)
			{
				//  do nothing if the covering unit was not fired upon directly
				if (AbilityContext.InputContext.PrimaryTarget.ObjectID != CoveringUnit.ObjectID)
					return ELR_NoInterrupt;
			}

			if (CoveringFireEffect.ActivationPercentChance > 0)
			{
				RandRoll = `SYNC_RAND(100);
				if (RandRoll >= CoveringFireEffect.ActivationPercentChance)
				{
					return ELR_NoInterrupt;
				}
			}

			if (CoveringFireEffect.bOnlyWhenAttackMisses)
			{
				//  do nothing if the covering unit was not hit in the attack
				if (class'XComGameStateContext_Ability'.static.IsHitResultHit(AbilityContext.ResultContext.HitResult))
					return ELR_NoInterrupt;
			}

			AbilityRef = CoveringUnit.FindAbility(CoveringFireEffect.AbilityToActivate);
			AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(AbilityRef.ObjectID));
			if (AbilityState != none)
			{
				if (CoveringFireEffect.GrantActionPoint != '' && (CoveringFireEffect.MaxPointsPerTurn > GrantsThisTurn || CoveringFireEffect.MaxPointsPerTurn <= 0))
				{
					NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState(string(GetFuncName()));
					NewEffectState = XComGameState_Effect(NewGameState.ModifyStateObject(Class, ObjectID));
					NewEffectState.GrantsThisTurn++;

					CoveringUnit = XComGameState_Unit(NewGameState.ModifyStateObject(CoveringUnit.Class, CoveringUnit.ObjectID));
					CoveringUnit.ReserveActionPoints.AddItem(CoveringFireEffect.GrantActionPoint);

					if (AbilityState.CanActivateAbilityForObserverEvent(AttackingUnit, CoveringUnit) != 'AA_Success')
					{
						History.CleanupPendingGameState(NewGameState);
					}
					else
					{
						`TACTICALRULES.SubmitGameState(NewGameState);

						if (CoveringFireEffect.bUseMultiTargets)
						{
							AbilityState.AbilityTriggerAgainstSingleTarget(CoveringUnit.GetReference(), true);
						}
						else
						{
							AbilityContext = class'XComGameStateContext_Ability'.static.BuildContextFromAbility(AbilityState, AttackingUnit.ObjectID);
							if( AbilityContext.Validate() )
							{
								`TACTICALRULES.SubmitGameStateContext(AbilityContext);
							}
						}
					}
				}
				else if (CoveringFireEffect.bSelfTargeting && AbilityState.CanActivateAbilityForObserverEvent(CoveringUnit) == 'AA_Success')
				{
					AbilityState.AbilityTriggerAgainstSingleTarget(CoveringUnit.GetReference(), CoveringFireEffect.bUseMultiTargets);
				}
				else if (AbilityState.CanActivateAbilityForObserverEvent(AttackingUnit) == 'AA_Success')
				{
					if (CoveringFireEffect.bUseMultiTargets)
					{
						AbilityState.AbilityTriggerAgainstSingleTarget(CoveringUnit.GetReference(), true);
					}
					else
					{
						AbilityContext = class'XComGameStateContext_Ability'.static.BuildContextFromAbility(AbilityState, AttackingUnit.ObjectID);
						if( AbilityContext.Validate() )
						{
							`TACTICALRULES.SubmitGameStateContext(AbilityContext);
						}
					}
				}
			}
		}
	}
	return ELR_NoInterrupt;
}

function EventListenerReturn ReaperKillCheck(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameStateContext_Ability AbilityContext;
	local XComGameState_Unit UnitState;
	local X2AbilityTemplate AbilityTemplate;
	local XComGameState NewGameState;
	local UnitValue ReaperKillCount;

	AbilityContext = XComGameStateContext_Ability(GameState.GetContext());

	//  was this a melee kill made by the reaper unit? if so, grant an action point
	if (AbilityContext != None && ApplyEffectParameters.SourceStateObjectRef == AbilityContext.InputContext.SourceObject)
	{
		AbilityTemplate = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate(AbilityContext.InputContext.AbilityTemplateName);
		if (AbilityTemplate != none && AbilityTemplate.IsMelee())
		{
			UnitState = XComGameState_Unit(GameState.GetGameStateForObjectID(ApplyEffectParameters.SourceStateObjectRef.ObjectID));
			if (UnitState == None)
				UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ApplyEffectParameters.SourceStateObjectRef.ObjectID));
			`assert(UnitState != None);
			UnitState.GetUnitValue(class'X2Effect_Reaper'.default.ReaperKillName, ReaperKillCount);
			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState(string(GetFuncName()));
			XComGameStateContext_ChangeContainer(NewGameState.GetContext()).BuildVisualizationFn = ReaperKillVisualizationFn;
			UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(UnitState.Class, UnitState.ObjectID));
			UnitState.SetUnitFloatValue(class'X2Effect_Reaper'.default.ReaperKillName, ReaperKillCount.fValue + 1, eCleanup_BeginTurn);
			UnitState.ActionPoints.AddItem(class'X2CharacterTemplateManager'.default.StandardActionPoint);
			`TACTICALRULES.SubmitGameState(NewGameState);
		}
	}

	return ELR_NoInterrupt;
}

function ReaperKillVisualizationFn(XComGameState VisualizeGameState)
{
	local XComGameState_Unit UnitState;
	local X2Action_PlaySoundAndFlyOver SoundAndFlyOver;
	local VisualizationActionMetadata ActionMetadata;
	local XComGameStateHistory History;
	local X2AbilityTemplate AbilityTemplate;

	History = `XCOMHISTORY;
	foreach VisualizeGameState.IterateByClassType(class'XComGameState_Unit', UnitState)
	{
		History.GetCurrentAndPreviousGameStatesForObjectID(UnitState.ObjectID, ActionMetadata.StateObject_OldState, ActionMetadata.StateObject_NewState, , VisualizeGameState.HistoryIndex);
		ActionMetadata.StateObject_NewState = UnitState;
		ActionMetadata.VisualizeActor = UnitState.GetVisualizer();

		AbilityTemplate = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate('Reaper');

		SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded));
		SoundAndFlyOver.SetSoundAndFlyOverParameters(None, AbilityTemplate.LocFlyOverText, '', eColor_Good, AbilityTemplate.IconImage);

		
		break;
	}
}

function EventListenerReturn ReaperActivatedCheck(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameStateContext_Ability AbilityContext;
	local XComGameState_Unit UnitState;
	local X2AbilityTemplate AbilityTemplate;
	local XComGameState NewGameState;
	local UnitValue UnitVal;

	AbilityContext = XComGameStateContext_Ability(GameState.GetContext());

	//	was this a successful melee attack made by the reaper unit? if so, mark reaper as activated for the guaranteed hit this turn
	if (AbilityContext != none && AbilityContext.IsResultContextHit() && ApplyEffectParameters.SourceStateObjectRef == AbilityContext.InputContext.SourceObject)
	{
		AbilityTemplate = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate(AbilityContext.InputContext.AbilityTemplateName);
		if (AbilityTemplate != none && AbilityTemplate.IsMelee())
		{
			UnitState = XComGameState_Unit(GameState.GetGameStateForObjectID(AbilityContext.InputContext.SourceObject.ObjectID));
			if (UnitState == none)
				UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(AbilityContext.InputContext.SourceObject.ObjectID));
			if (UnitState != none)
			{
				UnitState.GetUnitValue(class'X2Effect_Reaper'.default.ReaperActivatedName, UnitVal);
				if (UnitVal.fValue == 0)
				{
					NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState(string(GetFuncName()));
					UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(UnitState.Class, UnitState.ObjectID));
					UnitState.SetUnitFloatValue(class'X2Effect_Reaper'.default.ReaperActivatedName, 1, eCleanup_BeginTurn);
					`TACTICALRULES.SubmitGameState(NewGameState);
				}
			}
		}
	}
	return ELR_NoInterrupt;
}

function EventListenerReturn ImplacableCheck(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameStateContext_Ability AbilityContext;
	local XComGameState NewGameState;
	local XComGameState_Unit SourceUnit, DeadUnit;
	local XComGameStateHistory History;
	local UnitValue ImplacableValue;

	if (!bRemoved)
	{
		AbilityContext = XComGameStateContext_Ability(GameState.GetContext());
		if (AbilityContext != none)
		{
			if (AbilityContext.InputContext.SourceObject.ObjectID == ApplyEffectParameters.SourceStateObjectRef.ObjectID)
			{
				History = `XCOMHISTORY;
				SourceUnit = XComGameState_Unit(History.GetGameStateForObjectID(ApplyEffectParameters.SourceStateObjectRef.ObjectID));
				DeadUnit = XComGameState_Unit(EventData);

				if (`TACTICALRULES.GetCachedUnitActionPlayerRef().ObjectID == SourceUnit.ControllingPlayer.ObjectID)
				{
					if (SourceUnit.IsEnemyUnit(DeadUnit))
					{
						SourceUnit.GetUnitValue(class'X2Effect_Implacable'.default.ImplacableThisTurnValue, ImplacableValue);
						if (ImplacableValue.fValue == 0)
						{
							NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState(string(GetFuncName()));
							XComGameStateContext_ChangeContainer(NewGameState.GetContext()).BuildVisualizationFn = ImplacableVisualizationFn;
							SourceUnit = XComGameState_Unit(NewGameState.ModifyStateObject(SourceUnit.Class, SourceUnit.ObjectID));
							SourceUnit.SetUnitFloatValue(class'X2Effect_Implacable'.default.ImplacableThisTurnValue, 1, eCleanup_BeginTurn);
							SourceUnit.ActionPoints.AddItem(class'X2CharacterTemplateManager'.default.MoveActionPoint);
							SubmitNewGameState(NewGameState);
						}
					}
				}
			}
		}
	}

	return ELR_NoInterrupt;
}

function ImplacableVisualizationFn(XComGameState VisualizeGameState)
{
	local XComGameState_Unit UnitState;
	local X2Action_PlaySoundAndFlyOver SoundAndFlyOver;
	local VisualizationActionMetadata ActionMetadata;
	local XComGameStateHistory History;
	local X2AbilityTemplate AbilityTemplate;

	History = `XCOMHISTORY;
	foreach VisualizeGameState.IterateByClassType(class'XComGameState_Unit', UnitState)
	{
		History.GetCurrentAndPreviousGameStatesForObjectID(UnitState.ObjectID, ActionMetadata.StateObject_OldState, ActionMetadata.StateObject_NewState, , VisualizeGameState.HistoryIndex);
		ActionMetadata.StateObject_NewState = UnitState;
		ActionMetadata.VisualizeActor = UnitState.GetVisualizer();

		AbilityTemplate = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate('Implacable');
		if (AbilityTemplate != none)
		{
			SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded));
			SoundAndFlyOver.SetSoundAndFlyOverParameters(None, AbilityTemplate.LocFlyOverText, '', eColor_Good, AbilityTemplate.IconImage);

		}
		break;
	}
}

function EventListenerReturn UntouchableCheck(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameStateContext_Ability AbilityContext;
	local XComGameState NewGameState;
	local XComGameState_Unit SourceUnit, DeadUnit;
	local XComGameStateHistory History;

	if (!bRemoved)
	{
		AbilityContext = XComGameStateContext_Ability(GameState.GetContext());
		if (AbilityContext != none)
		{
			if (AbilityContext.InputContext.SourceObject.ObjectID == ApplyEffectParameters.SourceStateObjectRef.ObjectID)
			{
				History = `XCOMHISTORY;
				SourceUnit = XComGameState_Unit(History.GetGameStateForObjectID(ApplyEffectParameters.SourceStateObjectRef.ObjectID));
				DeadUnit = XComGameState_Unit(EventData);

				if (SourceUnit.IsEnemyUnit(DeadUnit) && (SourceUnit.Untouchable < class'X2Ability_RangerAbilitySet'.default.MAX_UNTOUCHABLE || class'X2Ability_RangerAbilitySet'.default.MAX_UNTOUCHABLE < 1))
				{
					NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState(string(GetFuncName()));
					SourceUnit = XComGameState_Unit(NewGameState.ModifyStateObject(SourceUnit.Class, SourceUnit.ObjectID));
					SourceUnit.Untouchable++;
					SubmitNewGameState(NewGameState);
				}
			}
		}
	}

	return ELR_NoInterrupt;
}

//Returns the state of the source of this effect, at the time the effect was applied.
//Used for deciding what is an "enemy" of a proximity mine.
function XComGameState_Unit GetSourceUnitAtTimeOfApplication()
{
	local XComGameState_Effect FirstEffectState;
	local int                  FirstHistoryIndex;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;

	//Follow the chain back.
	FirstEffectState = self;
	while (FirstEffectState != None)
	{
		FirstHistoryIndex = FirstEffectState.GetParentGameState().HistoryIndex;
		FirstEffectState = XComGameState_Effect(History.GetPreviousGameStateForObject(FirstEffectState));
	}

	return XComGameState_Unit(History.GetGameStateForObjectID(ApplyEffectParameters.SourceStateObjectRef.ObjectID, , FirstHistoryIndex));
}

function EventListenerReturn ProximityMine_AbilityActivated(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameState_Ability			AbilityState;
	local XComGameState_Unit			AbilityUnit, SourceUnit, SourceUnitAtTimeOfLaunch;
	local XComGameStateHistory			History;
	local XComGameStateContext_Ability  AbilityContext;
	local TTile                         CheckTile, AffectedTile;
	local bool                          bLocationMatch;
	local int                           LocationIdx;
	local vector                        TargetLoc;
	local bool							bAbilityUnitCaughtInDetonation;
	
	if (bRemoved)
		return ELR_NoInterrupt;

	AbilityContext = XComGameStateContext_Ability(GameState.GetContext());
	//  Proximity mine should not blow up as a pre-emptive strike; only blow up after the ability has successfully executed
	if (AbilityContext.InterruptionStatus == eInterruptionStatus_Interrupt)
		return ELR_NoInterrupt;

	History = `XCOMHISTORY;
	SourceUnit = XComGameState_Unit(History.GetGameStateForObjectID(ApplyEffectParameters.SourceStateObjectRef.ObjectID));
	AbilityUnit = XComGameState_Unit(EventSource);
	AbilityState = XComGameState_Ability(EventData);

	if (SourceUnit != none && AbilityUnit != none && AbilityState != none && AbilityContext != none)
	{
		SourceUnitAtTimeOfLaunch = GetSourceUnitAtTimeOfApplication();

		if (SourceUnitAtTimeOfLaunch.IsEnemyUnit(AbilityUnit) && AbilityState.IsAbilityInputTriggered() && AbilityState.GetMyTemplate().Hostility == eHostility_Offensive)
		{
			foreach ApplyEffectParameters.AbilityResultContext.RelevantEffectTiles(CheckTile)
			{
				if (CheckTile == AbilityUnit.TileLocation)
				{
					bLocationMatch = true;
					bAbilityUnitCaughtInDetonation = true; //The unit itself tripped the mine; it must be caught in the explosion
					break;
				}
			}
			if (!bLocationMatch)
			{
				for (LocationIdx = 0; LocationIdx < AbilityContext.InputContext.TargetLocations.Length; ++LocationIdx)
				{
					TargetLoc = AbilityContext.InputContext.TargetLocations[LocationIdx];
					AffectedTile = `XWORLD.GetTileCoordinatesFromPosition(TargetLoc);
					foreach ApplyEffectParameters.AbilityResultContext.RelevantEffectTiles(CheckTile)
					{
						if (CheckTile == AffectedTile)
						{
							bLocationMatch = true;
							bAbilityUnitCaughtInDetonation = false;
							break;
						}
					}
				}
			}
			if (bLocationMatch)
			{
				DetonateProximityMine(SourceUnit, bAbilityUnitCaughtInDetonation?AbilityUnit:None, GameState);
			}
		}
	}

	return ELR_NoInterrupt;
}

function EventListenerReturn ProximityMine_ObjectMoved(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameStateHistory  History;
	local XComGameState_Unit    MovedUnit, SourceUnit, SourceUnitAtTimeOfLaunch;	
	local TTile                 AffectedTile;
	local bool                  bTileMatches;

	if (bRemoved)
		return ELR_NoInterrupt;

	History = `XCOMHISTORY;
	SourceUnit = XComGameState_Unit(History.GetGameStateForObjectID(ApplyEffectParameters.SourceStateObjectRef.ObjectID));
	MovedUnit = XComGameState_Unit(EventData);
	if (MovedUnit != none && SourceUnit != none)
	{
		foreach ApplyEffectParameters.AbilityResultContext.RelevantEffectTiles(AffectedTile)
		{
			if (AffectedTile == MovedUnit.TileLocation)
			{
				bTileMatches = true;
				break;
			}
		}
		if (bTileMatches)
		{
			SourceUnitAtTimeOfLaunch = GetSourceUnitAtTimeOfApplication();

			if (MovedUnit.IsEnemyUnit(SourceUnitAtTimeOfLaunch) && MovedUnit.IsAlive())          //  friendlies will not trigger the proximity mine
			{
				DetonateProximityMine(SourceUnit, MovedUnit, GameState);
			}
		}
	}

	return ELR_NoInterrupt;
}

private function DetonateProximityMine(XComGameState_Unit SourceUnit, XComGameState_Unit TriggeringUnit, XComGameState RespondingToGameState)
{
	local XComGameState_Ability AbilityState;
	local AvailableAction Action;
	local AvailableTarget Target;
	local XComGameStateContext_EffectRemoved EffectRemovedState;
	local XComGameState NewGameState;
	local XComGameStateHistory History;
	local TTile                 AffectedTile;
	local XComGameState_Unit    UnitState;

	History = `XCOMHISTORY;
	Action.AbilityObjectRef = SourceUnit.FindAbility(class'X2Ability_Grenades'.default.ProximityMineDetonationAbilityName);
	if (Action.AbilityObjectRef.ObjectID != 0)
	{
		AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(Action.AbilityObjectRef.ObjectID));
		if (AbilityState != none)
		{
			//  manually check the unit states being modified by the event as they may not be properly updated in the world data until the event is complete
			foreach RespondingToGameState.IterateByClassType(class'XComGameState_Unit', UnitState)
			{
				foreach ApplyEffectParameters.AbilityResultContext.RelevantEffectTiles(AffectedTile)
				{
					if (UnitState.TileLocation == AffectedTile)
					{
						if (Target.AdditionalTargets.Find('ObjectID', UnitState.ObjectID) == INDEX_NONE)
							Target.AdditionalTargets.AddItem(UnitState.GetReference());

						break;      //  no need to keep checking tiles for this unit
					}
				}
			}

			Action.AvailableCode = 'AA_Success';
			AbilityState.GatherAdditionalAbilityTargetsForLocation(ApplyEffectParameters.AbilityInputContext.TargetLocations[0], Target);

			//Ensure that the triggering unit is caught in the blast.
			if (TriggeringUnit != None && Target.AdditionalTargets.Find('ObjectID', TriggeringUnit.ObjectID) == INDEX_NONE)
				Target.AdditionalTargets.AddItem(TriggeringUnit.GetReference());

			Action.AvailableTargets.AddItem(Target);

			if (class'XComGameStateContext_Ability'.static.ActivateAbility(Action, 0, ApplyEffectParameters.AbilityInputContext.TargetLocations))
			{
				EffectRemovedState = class'XComGameStateContext_EffectRemoved'.static.CreateEffectRemovedContext(self);
				NewGameState = History.CreateNewGameState(true, EffectRemovedState);
				RemoveEffect(NewGameState, RespondingToGameState);
				SubmitNewGameState(NewGameState);
			}
		}
	}
}

function EventListenerReturn TriggerAbilityFlyover(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameState NewGameState;
	local XComGameState_Unit UnitState;
	local XComGameState_Ability AbilityState;

	UnitState = XComGameState_Unit(EventSource);
	AbilityState = XComGameState_Ability(EventData);
	if (UnitState != none && AbilityState != none)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState(string(GetFuncName()));
		UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(UnitState.Class, UnitState.ObjectID));
		AbilityState = XComGameState_Ability(NewGameState.ModifyStateObject(AbilityState.Class, AbilityState.ObjectID));
		XComGameStateContext_ChangeContainer(NewGameState.GetContext()).BuildVisualizationFn = TriggerAbilityFlyoverVisualizationFn;
		`TACTICALRULES.SubmitGameState(NewGameState);
	}
	return ELR_NoInterrupt;
}

function EventListenerReturn AuraUpdateSingleTarget(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
	local XComGameStateHistory History;
	local XComGameState_Unit TargetUnit;
	local XComGameState_Unit AbilitySourceUnit;
	local X2Effect_Aura AuraEffect;
	local XComGameState NewGameState;

	History = `XCOMHISTORY;

	TargetUnit = XComGameState_Unit(EventData);
	AbilitySourceUnit = XComGameState_Unit(History.GetGameStateForObjectID(ApplyEffectParameters.AbilityInputContext.SourceObject.ObjectID));
	if( TargetUnit != None && AbilitySourceUnit != None )
	{
		if( TargetUnit.ObjectID == AbilitySourceUnit.ObjectID )
		{
			AuraUpdateTargets(EventData, EventSource, GameState, EventID, CallbackData);
		}
		else
		{
			NewGameState = History.CreateNewGameState(true, new class'XComGameStateContext_AuraUpdate');
			AuraEffect = X2Effect_Aura(GetX2Effect());
			AuraEffect.UpdateSingleTarget(ApplyEffectParameters, TargetUnit, NewGameState);

			SubmitNewGameState(NewGameState);
		}
	}

	return ELR_NoInterrupt;
}

function EventListenerReturn AuraUpdateTargets(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameStateContext_Ability AbilityContext;
	local X2Effect_Aura AuraEffect;
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_Unit TargetUnit;

	History = `XCOMHISTORY;

	AbilityContext = XComGameStateContext_Ability(GameState.GetContext());
	if( AbilityContext != None && AbilityContext.InterruptionStatus != eInterruptionStatus_Interrupt )
	{	
		AuraEffect = X2Effect_Aura(GetX2Effect());
		NewGameState = History.CreateNewGameState(true, new class'XComGameStateContext_AuraUpdate');
		foreach History.IterateByClassType(class'XComGameState_Unit', TargetUnit)
		{
			// Add/remove multi target effect
			AuraEffect.UpdateSingleTarget(ApplyEffectParameters, TargetUnit, NewGameState);
		}
		SubmitNewGameState(NewGameState);
	}

	return ELR_NoInterrupt;
}

function TriggerAbilityFlyoverVisualizationFn(XComGameState VisualizeGameState)
{
	local XComGameState_Unit UnitState;
	local X2Action_PlaySoundAndFlyOver SoundAndFlyOver;
	local VisualizationActionMetadata ActionMetadata;
	local XComGameStateHistory History;
	local X2AbilityTemplate AbilityTemplate;
	local XComGameState_Ability AbilityState;

	History = `XCOMHISTORY;
	foreach VisualizeGameState.IterateByClassType(class'XComGameState_Unit', UnitState)
	{
		foreach VisualizeGameState.IterateByClassType(class'XComGameState_Ability', AbilityState)
		{
			break;
		}
		if (AbilityState == none)
		{
			`RedScreenOnce("Ability state missing from" @ GetFuncName() @ "-jbouscher @gameplay");
			return;
		}

		History.GetCurrentAndPreviousGameStatesForObjectID(UnitState.ObjectID, ActionMetadata.StateObject_OldState, ActionMetadata.StateObject_NewState, , VisualizeGameState.HistoryIndex);
		ActionMetadata.StateObject_NewState = UnitState;
		ActionMetadata.VisualizeActor = UnitState.GetVisualizer();

		AbilityTemplate = AbilityState.GetMyTemplate();
		if (AbilityTemplate != none)
		{
			SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded));
			SoundAndFlyOver.SetSoundAndFlyOverParameters(None, AbilityTemplate.LocFlyOverText, '', eColor_Good, AbilityTemplate.IconImage, `DEFAULTFLYOVERLOOKATTIME, true);
		}
		break;
	}
}

function EventListenerReturn OnUnitAttacked(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local X2Effect_DamageImmunity EffectTemplate;
	local XComGameState NewGameState;
	local XComGameState_Effect EffectState;
	local XComGameStateContext_EffectRemoved RemoveContext;

	EffectTemplate = X2Effect_DamageImmunity(GetX2Effect());
	`assert(EffectTemplate != none);
	`assert(EffectTemplate.RemoveAfterAttackCount > 0);

	if( AttacksReceived + 1 >= EffectTemplate.RemoveAfterAttackCount )
	{
		RemoveContext = class'XComGameStateContext_EffectRemoved'.static.CreateEffectRemovedContext(self);
		NewGameState = `XCOMHISTORY.CreateNewGameState(true, RemoveContext);
		RemoveEffect(NewGameState, GameState);
	}
	else
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("OnUnitDiedWithParthenogenicPoison");
		EffectState = XComGameState_Effect(NewGameState.ModifyStateObject(Class, ObjectID));
		++EffectState.AttacksReceived;
	}

	SubmitNewGameState(NewGameState);

	return ELR_NoInterrupt;
}

// This is called when a unit dies and it has X2Effect_ParthenogenicPoison on it
function EventListenerReturn OnUnitDiedWithParthenogenicPoison(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local X2Effect_ParthenogenicPoison EffectTemplate;
	local XComGameState_Unit TargetUnitState;
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	
	History = `XCOMHISTORY;

	TargetUnitState = XComGameState_Unit(History.GetGameStateForObjectID(ApplyEffectParameters.TargetStateObjectRef.ObjectID));
	EffectTemplate = X2Effect_ParthenogenicPoison(GetX2Effect());

	if( TargetUnitState == none )
	{
		`RedScreen("TargetUnitState in OnUnitDiedWithParthenogenicPoison does not exist. @dslonneger");
	}	
	else if( EffectTemplate == none )
	{
		`RedScreen("EffectTemplate in OnUnitDiedWithParthenogenicPoison does not exist. @dslonneger");
	}
	else
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("OnUnitDiedWithParthenogenicPoison");
		EffectTemplate.TriggerSpawnEvent(ApplyEffectParameters, TargetUnitState, NewGameState, self);
		SubmitNewGameState(NewGameState);
	}

	return ELR_NoInterrupt;
}

function EventListenerReturn SharpshooterAimListener(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameState_Ability AbilityState;
	local XComGameStateContext_EffectRemoved RemoveContext;
	local XComGameState NewGameState;

	AbilityState = XComGameState_Ability(EventData);
	if (AbilityState != none && AbilityState.IsAbilityInputTriggered() && AbilityState.GetMyTemplate().Hostility == eHostility_Offensive)
	{
		RemoveContext = class'XComGameStateContext_EffectRemoved'.static.CreateEffectRemovedContext(self);
		NewGameState = `XCOMHISTORY.CreateNewGameState(true, RemoveContext);
		RemoveEffect(NewGameState, GameState);
		SubmitNewGameState(NewGameState);
	}

	return ELR_NoInterrupt;
}

function EventListenerReturn GenerateCover_ObjectMoved(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameStateContext_EffectRemoved RemoveContext;
	local XComGameState NewGameState;
	
	RemoveContext = class'XComGameStateContext_EffectRemoved'.static.CreateEffectRemovedContext(self);
	NewGameState = `XCOMHISTORY.CreateNewGameState(true, RemoveContext);
	RemoveEffect(NewGameState, GameState);
	SubmitNewGameState(NewGameState);

	return ELR_NoInterrupt;
}

function EventListenerReturn GenerateCover_ObjectMoved_Update(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameState NewGameState;
	local XComGameState_Unit UnitState;

	UnitState = XComGameState_Unit(EventSource);
	if (UnitState != none && GameState.GetContext().InterruptionStatus != eInterruptionStatus_Interrupt) // only update on the last movement tile
	{
		// build a new game state to update visibility and the world data

		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("GenerateCover_ObjectMoved_Update()");
		X2Effect_GenerateCover(GetX2Effect()).UpdateWorldCoverData(UnitState, NewGameState);

		`TACTICALRULES.SubmitGameState(NewGameState);
	}
	return ELR_NoInterrupt;
}

function EventListenerReturn GenerateCover_AbilityActivated(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
	local XComGameStateContext_Ability AbilityContext;
	local X2AbilityTemplate AbilityTemplate;
	local XComGameState_Ability AbilityState;

	AbilityContext = XComGameStateContext_Ability(GameState.GetContext());
	if (AbilityContext != None)
	{
		AbilityTemplate = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate(AbilityContext.InputContext.AbilityTemplateName);
		if (AbilityTemplate != None)
		{
			if (AbilityTemplate.Hostility == eHostility_Offensive)
			{
				AbilityState = XComGameState_Ability(GameState.GetGameStateForObjectID(AbilityContext.InputContext.AbilityRef.ObjectID));
				if (AbilityState == None)
					AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(AbilityContext.InputContext.AbilityRef.ObjectID));

				if (AbilityState != None)
				{
					if (AbilityState.IsAbilityInputTriggered())
					{
						GenerateCover_ObjectMoved(EventData, EventSource, GameState, EventID, CallbackData);
					}
				}
			}
		}
	}
	return ELR_NoInterrupt;
}

function EventListenerReturn SustainActivated(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameState_Unit UnitState;
	local XComGameState NewGameState;

	UnitState = XComGameState_Unit(EventSource);
	if (UnitState != none)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState(string(GetFuncName()));
		XComGameStateContext_ChangeContainer(NewGameState.GetContext()).BuildVisualizationFn = SustainActivationVisualizationFn;
		UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(UnitState.Class, UnitState.ObjectID));
		`TACTICALRULES.SubmitGameState(NewGameState);
	}

	return ELR_NoInterrupt;
}

function EventListenerReturn AffectedByStasis_Listener(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameState_Unit UnitState;
	local XComGameState NewGameState;
	local XComGameStateContext_EffectRemoved EffectRemovedContext;
	local XComGameState_Effect EffectState;
	local XComGameStateHistory History;
	local X2Effect_Persistent PersistentEffect;
	local bool bRemove, bAtLeastOneRemoved;

	UnitState = XComGameState_Unit(EventSource);
	if (UnitState != none)
	{
		// Check to see if the target is an Advent Priest, if so remove Holy Warrior or Mind Control that is is the source of
		History = `XCOMHISTORY;

		bAtLeastOneRemoved = false;
		foreach History.IterateByClassType(class'XComGameState_Effect', EffectState)
		{
			PersistentEffect = EffectState.GetX2Effect();
			bRemove = false;

			if( (EffectState.ApplyEffectParameters.SourceStateObjectRef.ObjectID == UnitState.ObjectID) &&
				(class'X2Effect_Stasis'.default.STASIS_REMOVE_EFFECTS_SOURCE.Find(PersistentEffect.EffectName) != INDEX_NONE) )
			{
				// The Unit under stasis is the source of this existing effect
				bRemove = true;
			}

			if( !bRemove &&
				(EffectState.ApplyEffectParameters.TargetStateObjectRef.ObjectID == UnitState.ObjectID) &&
				(class'X2Effect_Stasis'.default.STASIS_REMOVE_EFFECTS_TARGET.Find(PersistentEffect.EffectName) != INDEX_NONE) )
			{
				// The Unit under stasis is the target of this existing effect
				bRemove = true;
			}

			if( bRemove )
			{
				// Stasis removes the existing effect
				if( !bAtLeastOneRemoved )
				{
					EffectRemovedContext = class'XComGameStateContext_EffectRemoved'.static.CreateEffectRemovedContext(EffectState);
					NewGameState = History.CreateNewGameState(true, EffectRemovedContext);
					EffectRemovedContext.RemovedEffects.Length = 0;

					bAtLeastOneRemoved = true;
				}

				EffectState.RemoveEffect(NewGameState, NewGameState, false);

				EffectRemovedContext.RemovedEffects.AddItem(EffectState.GetReference());
			}
		}

		if( bAtLeastOneRemoved )
		{
			`TACTICALRULES.SubmitGameState(NewGameState);
		}
	}

	return ELR_NoInterrupt;
}

function SustainActivationVisualizationFn(XComGameState VisualizeGameState)
{
	local XComGameState_Unit UnitState;
	local X2Action_PlaySoundAndFlyOver SoundAndFlyOver;
	local VisualizationActionMetadata ActionMetadata;
	local XComGameStateHistory History;
	local X2AbilityTemplate AbilityTemplate;

	History = `XCOMHISTORY;
	foreach VisualizeGameState.IterateByClassType(class'XComGameState_Unit', UnitState)
	{
		History.GetCurrentAndPreviousGameStatesForObjectID(UnitState.ObjectID, ActionMetadata.StateObject_OldState, ActionMetadata.StateObject_NewState, , VisualizeGameState.HistoryIndex);
		ActionMetadata.StateObject_NewState = UnitState;
		ActionMetadata.VisualizeActor = UnitState.GetVisualizer();

		AbilityTemplate = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate('SustainTriggered');

		SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded));
		SoundAndFlyOver.SetSoundAndFlyOverParameters(None, AbilityTemplate.LocFlyOverText, '', eColor_Good, AbilityTemplate.IconImage);

		
		break;
	}
}

function EventListenerReturn OnShieldsExpended(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameStateContext_EffectRemoved RemoveContext;
	local XComGameState NewGameState;
	
	if (!bRemoved)
	{
		RemoveContext = class'XComGameStateContext_EffectRemoved'.static.CreateEffectRemovedContext(self);
		NewGameState = `XCOMHISTORY.CreateNewGameState(true, RemoveContext);
		RemoveEffect(NewGameState, GameState);
		SubmitNewGameState(NewGameState);
	}

	return ELR_NoInterrupt;
}

function EventListenerReturn ShadowRisingUnitDied(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameState_Unit KilledUnit, SourceUnit;
	local XComGameStateContext_Ability AbilityContext;
	local XComGameState_Ability AbilityState;
	local XComGameStateHistory History;
	local StateObjectReference AbilityRef;
	local XComGameState NewGameState;

	KilledUnit = XComGameState_Unit(EventData);
	AbilityContext = XComGameStateContext_Ability(GameState.GetContext());

	if (KilledUnit != none && AbilityContext != none)
	{
		if (AbilityContext.InputContext.SourceObject.ObjectID == ApplyEffectParameters.SourceStateObjectRef.ObjectID)
		{
			History = `XCOMHISTORY;
			AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(AbilityContext.InputContext.AbilityRef.ObjectID));
			if (AbilityState != none && AbilityState.SourceWeapon.ObjectID == ApplyEffectParameters.ItemStateObjectRef.ObjectID)
			{
				//  ok to reduce cooldown on Shadow, if it is cooling down
				SourceUnit = XComGameState_Unit(History.GetGameStateForObjectID(ApplyEffectParameters.SourceStateObjectRef.ObjectID));
				if (SourceUnit != none)
				{
					AbilityRef = SourceUnit.FindAbility('Shadow');
					if (AbilityRef.ObjectID > 0)
					{
						AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(AbilityRef.ObjectID));
						if (AbilityState.iCooldown > 0)
						{
							NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Shadow Rising Cooldown Reduction");
							AbilityState = XComGameState_Ability(NewGameState.ModifyStateObject(AbilityState.Class, AbilityState.ObjectID));
							AbilityState.iCooldown--;
							SourceUnit = XComGameState_Unit(NewGameState.ModifyStateObject(SourceUnit.Class, SourceUnit.ObjectID));
							XComGameStateContext_ChangeContainer(NewGameState.GetContext()).BuildVisualizationFn = ShadowRisingVisualizationFn;
							SubmitNewGameState(NewGameState);
						}
					}
				}
			}
		}
	}
	return ELR_NoInterrupt;
}

function ShadowRisingVisualizationFn(XComGameState VisualizeGameState)
{
	local XComGameState_Unit UnitState;
	local X2Action_PlaySoundAndFlyOver SoundAndFlyOver;
	local VisualizationActionMetadata ActionMetadata;
	local XComGameStateHistory History;
	local X2AbilityTemplate AbilityTemplate;

	History = `XCOMHISTORY;
	foreach VisualizeGameState.IterateByClassType(class'XComGameState_Unit', UnitState)
	{
		History.GetCurrentAndPreviousGameStatesForObjectID(UnitState.ObjectID, ActionMetadata.StateObject_OldState, ActionMetadata.StateObject_NewState, , VisualizeGameState.HistoryIndex);
		ActionMetadata.StateObject_NewState = UnitState;
		ActionMetadata.VisualizeActor = UnitState.GetVisualizer();
		AbilityTemplate = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate('ShadowRising');
		
		if (AbilityTemplate != none)
		{
			SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded));
			SoundAndFlyOver.SetSoundAndFlyOverParameters(None, AbilityTemplate.LocFlyOverText, '', eColor_Good, AbilityTemplate.IconImage);
		}
		break;
	}
}

function EventListenerReturn WindAbilityActivated(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameStateContext_Ability AbilityContext;
	local XComGameState_Ability AbilityState;
	local XComGameState_Unit UnitState;
	local XComGameStateHistory History;
	local XComGameState NewGameState;

	AbilityContext = XComGameStateContext_Ability(GameState.GetContext());
	if (AbilityContext != none && AbilityContext.InterruptionStatus != eInterruptionStatus_Interrupt)
	{
		if (AbilityContext.InputContext.ItemObject == ApplyEffectParameters.ItemStateObjectRef)
		{
			History = `XCOMHISTORY;
			UnitState = XComGameState_Unit(GameState.GetGameStateForObjectID(ApplyEffectParameters.SourceStateObjectRef.ObjectID));
			if (UnitState == none)
				UnitState = XComGameState_Unit(History.GetGameStateForObjectID(ApplyEffectParameters.SourceStateObjectRef.ObjectID));

			AbilityState = XComGameState_Ability(GameState.GetGameStateForObjectID(AbilityContext.InputContext.AbilityRef.ObjectID));
			if (AbilityState == none)
				AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(AbilityContext.InputContext.AbilityRef.ObjectID));

			if (AbilityState.IsAbilityInputTriggered() && UnitState.IsSuperConcealed())
			{
				AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(UnitState.FindAbility('Wind').ObjectID));
				if (AbilityState != none)
				{
					NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Wind - Move Action Point Added");
					UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(UnitState.Class, UnitState.ObjectID));
					UnitState.ActionPoints.AddItem(class'X2CharacterTemplateManager'.default.MoveActionPoint);
					AbilityState = XComGameState_Ability(NewGameState.ModifyStateObject(AbilityState.Class, AbilityState.ObjectID));
					XComGameStateContext_ChangeContainer(NewGameState.GetContext()).BuildVisualizationFn = TriggerAbilityFlyoverVisualizationFn;
					`TACTICALRULES.SubmitGameState(NewGameState);
				}
			}
		}
	}
	return ELR_NoInterrupt;
}

function EventListenerReturn DistractionListener(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
	local XComGameState_Destructible DestructibleState;
	local XComGameState_Unit OwnerUnit, TargetUnit;
	local XComGameState_Ability ShadowAbility;
	local StateObjectReference ShadowRef, EffectIter;
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_Effect CheckEffect;
	local XComGameStateContext_Ability AbilityContext;
	local bool bUpdateConcealment;

	History = `XCOMHISTORY;
	OwnerUnit = XComGameState_Unit(GameState.GetGameStateForObjectID(ApplyEffectParameters.SourceStateObjectRef.ObjectID));
	if (OwnerUnit == none)
	{
		OwnerUnit = XComGameState_Unit(History.GetGameStateForObjectID(ApplyEffectParameters.SourceStateObjectRef.ObjectID));
	}

	if (OwnerUnit != none && OwnerUnit.IsAlive())
	{
		if (EventID == 'KilledByDestructible')
		{
			DestructibleState = XComGameState_Destructible(EventSource);
			if (DestructibleState != None)
			{
				//  look for the matching Claymore effect
				foreach OwnerUnit.AppliedEffects(EffectIter)
				{
					CheckEffect = XComGameState_Effect(History.GetGameStateForObjectID(EffectIter.ObjectID));
					if (CheckEffect != none && CheckEffect.ApplyEffectParameters.ItemStateObjectRef.ObjectID == DestructibleState.ObjectID)
					{
						bUpdateConcealment = true;
						break;
					}
				}
			}
		}
		else if (EventID == 'HomingMineDetonated')
		{
			//	make sure the homing mine that blew up was ours
			AbilityContext = XComGameStateContext_Ability(GameState.GetContext());
			foreach OwnerUnit.AppliedEffects(EffectIter)
			{
				CheckEffect = XComGameState_Effect(History.GetGameStateForObjectID(EffectIter.ObjectID));
				if (CheckEffect != none && X2Effect_HomingMine(CheckEffect.GetX2Effect()) != none &&
					CheckEffect.ApplyEffectParameters.TargetStateObjectRef == AbilityContext.InputContext.PrimaryTarget)
				{
					TargetUnit = XComGameState_Unit(GameState.GetGameStateForObjectID(AbilityContext.InputContext.PrimaryTarget.ObjectID));
					if (TargetUnit.IsDead())
					{
						bUpdateConcealment = true;
					}
					break;
				}
			}
		}

		if (bUpdateConcealment)
		{
			if (OwnerUnit.IsSuperConcealed())
			{
				//  if already concealed, reset concealment loss chance to 0
				if (OwnerUnit.SuperConcealmentLoss > 0)
				{
					NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Distraction Reset Super Concealment Loss");
					OwnerUnit = XComGameState_Unit(NewGameState.ModifyStateObject(OwnerUnit.Class, OwnerUnit.ObjectID));
					OwnerUnit.SuperConcealmentLoss = 0;
					`TACTICALRULES.SubmitGameState(NewGameState);
				}
			}
			else
			{
				//  if not concealed, get concealed if possible
				ShadowRef = OwnerUnit.FindAbility('DistractionShadow');
				if (ShadowRef.ObjectID > 0)
				{
					ShadowAbility = XComGameState_Ability(History.GetGameStateForObjectID(ShadowRef.ObjectID));
					return ShadowAbility.AbilityTriggerEventListener_Self(EventData, EventSource, GameState, EventID, CallbackData);
				}
			}
		}
	}
	return ELR_NoInterrupt;
}

function EventListenerReturn HomingMineListener(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameState_Ability AbilityState;
	local AvailableAction Action;
	local AvailableTarget Target;
	local XComGameStateContext_EffectRemoved EffectRemovedState;
	local XComGameState NewGameState;
	local XComGameStateHistory History;
	local XComGameState_Unit    UnitState, SourceUnit;
	local vector				TargetLoc;
	local array<vector>			TargetLocs;
	local XComGameStateContext_Ability AbilityContext;
	local name AbilityToTrigger;

	if (bRemoved || GameState.GetContext().InterruptionStatus == eInterruptionStatus_Interrupt)
		return ELR_NoInterrupt;

	AbilityToTrigger = X2Effect_HomingMine(GetX2Effect()).AbilityToTrigger;
	AbilityContext = XComGameStateContext_Ability(GameState.GetContext());
	if (AbilityContext != none && AbilityContext.InputContext.AbilityTemplateName == AbilityToTrigger)
	{
		//	don't respond to this same event if we were already the target
		if (AbilityContext.InputContext.PrimaryTarget == ApplyEffectParameters.TargetStateObjectRef)
			return ELR_NoInterrupt;
	}

	//	if not taking damage from an ability, ignore it (e.g. damage over time effects)
	if (AbilityContext == none && Event == 'UnitTakeEffectDamage')
	{
		return ELR_NoInterrupt;
	}

	History = `XCOMHISTORY;
	SourceUnit = XComGameState_Unit(History.GetGameStateForObjectID(ApplyEffectParameters.SourceStateObjectRef.ObjectID));
	Action.AbilityObjectRef = SourceUnit.FindAbility(AbilityToTrigger);
	if (Action.AbilityObjectRef.ObjectID != 0)
	{
		AbilityState = XComGameState_Ability(History.GetGameStateForObjectID(Action.AbilityObjectRef.ObjectID));
		if (AbilityState != none)
		{
			Action.AvailableCode = 'AA_Success';
			UnitState = XComGameState_Unit(EventSource);
			TargetLoc = `XWORLD.GetPositionFromTileCoordinates(UnitState.TileLocation);
			AbilityState.GatherAdditionalAbilityTargetsForLocation(TargetLoc, Target);

			//	primary target will not be hit with effects (due to ability setup) but we need to know to prevent double responses to this
			Target.PrimaryTarget = UnitState.GetReference();		
			//	ensure the initial target is in the blast
			if (Target.AdditionalTargets.Find('ObjectID', UnitState.ObjectID) == INDEX_NONE)
				Target.AdditionalTargets.AddItem(UnitState.GetReference());

			Action.AvailableTargets.AddItem(Target);
			TargetLocs.AddItem(TargetLoc);
			if (class'XComGameStateContext_Ability'.static.ActivateAbility(Action, 0, TargetLocs, ,,,GameState.HistoryIndex))
			{
				EffectRemovedState = class'XComGameStateContext_EffectRemoved'.static.CreateEffectRemovedContext(self);
				NewGameState = History.CreateNewGameState(true, EffectRemovedState);
				RemoveEffect(NewGameState, GameState);
				SubmitNewGameState(NewGameState);
			}
		}
	}
	return ELR_NoInterrupt;
}

function EventListenerReturn SkirmisherReflexListener(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameStateContext_Ability AbilityContext;
	local XComGameState NewGameState;
	local UnitValue ReflexValue, TotalValue;
	local XComGameState_Unit TargetUnit, SourceUnit;
	local XComGameState_Ability AbilityState;

	AbilityState = XComGameState_Ability(EventData);
	// Set to only Offensive abilities to prevent Reflex from being kicked off on Chosen Tracking Shot Marker.
	if (AbilityState.IsAbilityInputTriggered() && AbilityState.GetMyTemplate().Hostility == eHostility_Offensive)
	{
		AbilityContext = XComGameStateContext_Ability(GameState.GetContext());
		if (AbilityContext != none && AbilityContext.InterruptionStatus != eInterruptionStatus_Interrupt)
		{
			if (AbilityContext.InputContext.PrimaryTarget.ObjectID == ApplyEffectParameters.TargetStateObjectRef.ObjectID)
			{
				SourceUnit = XComGameState_Unit(GameState.GetGameStateForObjectID(AbilityContext.InputContext.SourceObject.ObjectID));
				if (SourceUnit == none)
					return ELR_NoInterrupt;

				TargetUnit = XComGameState_Unit(GameState.GetGameStateForObjectID(ApplyEffectParameters.TargetStateObjectRef.ObjectID));
				if (TargetUnit == none)
					TargetUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ApplyEffectParameters.TargetStateObjectRef.ObjectID));
				`assert(TargetUnit != none);

				if (TargetUnit.IsFriendlyUnit(SourceUnit))
					return ELR_NoInterrupt;

				TargetUnit.GetUnitValue(class'X2Effect_SkirmisherReflex'.default.TotalEarnedValue, TotalValue);
				if (TotalValue.fValue >= 1)
					return ELR_NoInterrupt;

				//	if it's the target unit's current turn, give them an action immediately
				if (`TACTICALRULES.GetCachedUnitActionPlayerRef().ObjectID == TargetUnit.ControllingPlayer.ObjectID)
				{
					if (TargetUnit.IsAbleToAct())
					{
						NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Skirmisher Reflex Immediate Action");
						TargetUnit = XComGameState_Unit(NewGameState.ModifyStateObject(TargetUnit.Class, TargetUnit.ObjectID));
						TargetUnit.SetUnitFloatValue(class'X2Effect_SkirmisherReflex'.default.TotalEarnedValue, TotalValue.fValue + 1, eCleanup_BeginTactical);
						TargetUnit.ActionPoints.AddItem(class'X2CharacterTemplateManager'.default.StandardActionPoint);
					}
				}
				//	if it's not their turn, increment the counter for next turn
				else if (`TACTICALRULES.GetCachedUnitActionPlayerRef().ObjectID != TargetUnit.ControllingPlayer.ObjectID)
				{
					TargetUnit.GetUnitValue(class'X2Effect_SkirmisherReflex'.default.ReflexUnitValue, ReflexValue);
					if (ReflexValue.fValue == 0)
					{
						NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Skirmisher Reflex For Next Turn Increment");
						TargetUnit = XComGameState_Unit(NewGameState.ModifyStateObject(TargetUnit.Class, TargetUnit.ObjectID));
						TargetUnit.SetUnitFloatValue(class'X2Effect_SkirmisherReflex'.default.ReflexUnitValue, 1, eCleanup_BeginTactical);
						TargetUnit.SetUnitFloatValue(class'X2Effect_SkirmisherReflex'.default.TotalEarnedValue, TotalValue.fValue + 1, eCleanup_BeginTactical);
					}
				}

				if (NewGameState != none)
				{
					NewGameState.ModifyStateObject(class'XComGameState_Ability', ApplyEffectParameters.AbilityStateObjectRef.ObjectID);
					XComGameStateContext_ChangeContainer(NewGameState.GetContext()).BuildVisualizationFn = TriggerAbilityFlyoverVisualizationFn;
					`TACTICALRULES.SubmitGameState(NewGameState);
				}
			}
		}
	}
	
	return ELR_NoInterrupt;
}

function EventListenerReturn RemoveSuperConcealModifierListener(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameStateContext_Ability AbilityContext;
	local XComGameState NewGameState;
	local X2Effect_SuperConcealModifier Modifier;

	if (bRemoved) // In case the bRemoveWhenTargetConcealmentBroken already removed us when the ability activated
		return ELR_NoInterrupt;

	AbilityContext = XComGameStateContext_Ability(GameState.GetContext());
	if ((AbilityContext != none) && (AbilityContext.InterruptionStatus != eInterruptionStatus_Interrupt))
	{
		Modifier = X2Effect_SuperConcealModifier( GetX2Effect( ) );

		if ((Modifier != none) && (Modifier.RemoveOnAbilityActivation.Find( AbilityContext.InputContext.AbilityTemplateName ) != INDEX_NONE))
		{
			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Remove SuperConcealment Modifier Effect");

			RemoveEffect( NewGameState, NewGameState );

			`TACTICALRULES.SubmitGameState(NewGameState);
		}
	}

	return ELR_NoInterrupt;
}

function EventListenerReturn ZeroInListener(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameStateContext_Ability AbilityContext;
	local XComGameState_Ability AbilityState;
	local XComGameState NewGameState;
	local XComGameState_Unit UnitState;
	local XComGameState_Item SourceWeapon;
	local UnitValue UValue;

	AbilityContext = XComGameStateContext_Ability(GameState.GetContext());
	`assert(AbilityContext != none);
	if (AbilityContext.InterruptionStatus == eInterruptionStatus_Interrupt)
		return ELR_NoInterrupt;

	AbilityState = XComGameState_Ability(EventData);
	`assert(AbilityState != none);
	UnitState = XComGameState_Unit(EventSource);
	`assert(UnitState != none);
	
	if (AbilityState.IsAbilityInputTriggered())
	{
		SourceWeapon = AbilityState.GetSourceWeapon();
		if (AbilityState.GetMyTemplate().Hostility == eHostility_Offensive && SourceWeapon != none && SourceWeapon.InventorySlot == eInvSlot_PrimaryWeapon)
		{
			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("ZeroIn Increment");
			UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(UnitState.Class, UnitState.ObjectID));
			UnitState.GetUnitValue('ZeroInShots', UValue);
			UnitState.SetUnitFloatValue('ZeroInShots', UValue.fValue + 1);
			UnitState.SetUnitFloatValue('ZeroInTarget', AbilityContext.InputContext.PrimaryTarget.ObjectID);

			if (UnitState.ActionPoints.Length > 0)
			{
				//	show flyover for boost, but only if they have actions left to potentially use them
				NewGameState.ModifyStateObject(class'XComGameState_Ability', ApplyEffectParameters.AbilityStateObjectRef.ObjectID);		//	create this for the vis function
				XComGameStateContext_ChangeContainer(NewGameState.GetContext()).BuildVisualizationFn = TriggerAbilityFlyoverVisualizationFn;
			}
		}
		else
		{
			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("ZeroIn Reset");
			UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(UnitState.Class, UnitState.ObjectID));
			UnitState.ClearUnitValue('ZeroInShots');
			UnitState.ClearUnitValue('ZeroInTarget');
		}
		SubmitNewGameState(NewGameState);
	}
	return ELR_NoInterrupt;
}

function EventListenerReturn ForwardOperatorListener(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameState_Unit UnitState;
	local XComGameState NewGameState;
	local UnitValue PendingPointsValue;

	UnitState = XComGameState_Unit(GameState.GetGameStateForObjectID(ApplyEffectParameters.TargetStateObjectRef.ObjectID));
	if (UnitState == none)
		UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ApplyEffectParameters.TargetStateObjectRef.ObjectID));

	if (UnitState.IsAbleToAct())
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Forward Operator");
		UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', ApplyEffectParameters.TargetStateObjectRef.ObjectID));
		
		//	if it is the unit's current turn, add an action point immediately
		if (UnitState.ControllingPlayer == `TACTICALRULES.GetCachedUnitActionPlayerRef())
		{
			UnitState.ActionPoints.AddItem(class'X2CharacterTemplateManager'.default.StandardActionPoint);
		}
		//	otherwise, mark the point to be awarded next turn
		else
		{
			UnitState.GetUnitValue('ForwardOperatorPending', PendingPointsValue);
			UnitState.SetUnitFloatValue('ForwardOperatorPending', PendingPointsValue.fValue + 1, eCleanup_BeginTactical);
		}
		NewGameState.ModifyStateObject(class'XComGameState_Ability', ApplyEffectParameters.AbilityStateObjectRef.ObjectID);
		XComGameStateContext_ChangeContainer(NewGameState.GetContext()).BuildVisualizationFn = ForwardOperatorVisualizationFn;

		SubmitNewGameState(NewGameState);
	}
	
	return ELR_NoInterrupt;
}

function ForwardOperatorVisualizationFn(XComGameState VisualizeGameState)
{
	local XComGameState_Unit UnitState;
	local X2Action_PlaySoundAndFlyOver SoundAndFlyOver;
	local VisualizationActionMetadata ActionMetadata;
	local XComGameStateHistory History;
	local X2AbilityTemplate AbilityTemplate;
	local XComGameState_Ability AbilityState;

	History = `XCOMHISTORY;
	foreach VisualizeGameState.IterateByClassType(class'XComGameState_Unit', UnitState)
	{
		foreach VisualizeGameState.IterateByClassType(class'XComGameState_Ability', AbilityState)
		{
			break;
		}
		if (AbilityState == none)
		{
			`RedScreenOnce("Ability state missing from" @ GetFuncName() @ "-jbouscher @gameplay");
			return;
		}

		History.GetCurrentAndPreviousGameStatesForObjectID(UnitState.ObjectID, ActionMetadata.StateObject_OldState, ActionMetadata.StateObject_NewState, , VisualizeGameState.HistoryIndex);
		ActionMetadata.StateObject_NewState = UnitState;
		ActionMetadata.VisualizeActor = UnitState.GetVisualizer();

		AbilityTemplate = AbilityState.GetMyTemplate();
		if (AbilityTemplate != none)
		{
			SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded));
			SoundAndFlyOver.SetSoundAndFlyOverParameters(SoundCue(`CONTENT.RequestGameArchetype("XPACK_SoundCharacterFX.Forward_Operator_Activate_Cue")), AbilityTemplate.LocFlyOverText, '', eColor_Good, AbilityTemplate.IconImage);
		}
		break;
	}
}

function EventListenerReturn BattlelordListener(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
	local XComGameState_Unit TargetUnit, SourceUnit;
	local XComGameStateContext_Ability AbilityContext;
	local XComGameState NewGameState;
	local X2TacticalGameRuleset TacticalRules;
	local GameRulesCache_VisibilityInfo	VisInfo;
	local UnitValue BattlelordInterrupts;

	TargetUnit = XComGameState_Unit(EventData);
	AbilityContext = XComGameStateContext_Ability(GameState.GetContext());
	if (AbilityContext != none && AbilityContext.InterruptionStatus != eInterruptionStatus_Interrupt)
	{
		SourceUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ApplyEffectParameters.TargetStateObjectRef.ObjectID));
		`assert(SourceUnit != none);
		if( !SourceUnit.IsAbleToAct() )
		{
			`redscreen("@dkaplan: Skirmisher Battlelord interruption was prevented due to the Skirmisher being Unable to Act.");
			return ELR_NoInterrupt;
		}
		SourceUnit.GetUnitValue('BattlelordInterrupts', BattlelordInterrupts);
		if (class'X2Ability_SkirmisherAbilitySet'.default.BATTLELORD_ACTIONS < 1 || class'X2Ability_SkirmisherAbilitySet'.default.BATTLELORD_ACTIONS > BattlelordInterrupts.fValue)
		{
			if (SourceUnit.IsEnemyUnit(TargetUnit) && TargetUnit.GetTeam() != eTeam_TheLost)
			{
				TacticalRules = `TACTICALRULES;
				if (TacticalRules.VisibilityMgr.GetVisibilityInfo(SourceUnit.ObjectID, TargetUnit.ObjectID, VisInfo))
				{
					if (VisInfo.bClearLOS)
					{
						NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Battlelord Interrupt Initiative");
						SourceUnit = XComGameState_Unit(NewGameState.ModifyStateObject(SourceUnit.Class, SourceUnit.ObjectID));
						SourceUnit.SetUnitFloatValue('BattlelordInterrupts', BattlelordInterrupts.fValue + 1, eCleanup_BeginTactical);
						TacticalRules.InterruptInitiativeTurn(NewGameState, SourceUnit.GetGroupMembership().GetReference());
						TacticalRules.SubmitGameState(NewGameState);
					}
				}
			}
		}
	}
	return ELR_NoInterrupt;
}

function EventListenerReturn KineticPlatingListener(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
	local XComGameStateContext_Ability AbilityContext;
	local X2AbilityTemplate AbilityTemplate;
	local XComGameState NewGameState;
	local XComGameState_Unit UnitState;
	local X2Effect_KineticPlating PlatingEffect;

	AbilityContext = XComGameStateContext_Ability(GameState.GetContext());
	if (AbilityContext != none && AbilityContext.InterruptionStatus != eInterruptionStatus_Interrupt && AbilityContext.IsResultContextMiss())
	{
		AbilityTemplate = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate(AbilityContext.InputContext.AbilityTemplateName);
		if (AbilityContext.InputContext.PrimaryTarget == ApplyEffectParameters.TargetStateObjectRef && AbilityTemplate.Hostility == eHostility_Offensive)
		{
			PlatingEffect = X2Effect_KineticPlating(GetX2Effect());
			UnitState = XComGameState_Unit(GameState.GetGameStateForObjectID(ApplyEffectParameters.TargetStateObjectRef.ObjectID));
			if (UnitState != none)
			{
				NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Kinetic Plating Shields");
				UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(UnitState.Class, UnitState.ObjectID));
				UnitState.ModifyCurrentStat(eStat_ShieldHP, PlatingEffect.ShieldPerMiss);
				NewGameState.ModifyStateObject(class'XComGameState_Ability', ApplyEffectParameters.AbilityStateObjectRef.ObjectID);
				XComGameStateContext_ChangeContainer(NewGameState.GetContext()).BuildVisualizationFn = TriggerAbilityFlyoverVisualizationFn;
				SubmitNewGameState(NewGameState);
			}
		}
	}

	return ELR_NoInterrupt;
}

function EventListenerReturn ShadowbindUnitDeathListener(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
	local XComGameState_Unit UnconciousUnitState; // The target of the Shadowbind
	local XComGameStateContext_EffectRemoved EffectRemovedContext;
	local XComGameState NewGameState;
	local XComGameStateHistory History;
	local XComGameState_Effect EffectState;

	History = `XCOMHISTORY;

	UnconciousUnitState = XComGameState_Unit(History.GetGameStateForObjectID(ApplyEffectParameters.TargetStateObjectRef.ObjectID));

	if( UnconciousUnitState != none &&
		UnconciousUnitState.IsUnconscious() )
	{
		if (!UnconciousUnitState.IsBeingCarried())
		{
			EffectState = UnconciousUnitState.GetUnitAffectedByEffectState(class'X2StatusEffects'.default.UnconsciousName);
			EffectRemovedContext = class'XComGameStateContext_EffectRemoved'.static.CreateEffectRemovedContext(EffectState);
			NewGameState = History.CreateNewGameState(true, EffectRemovedContext);
			EffectState.RemoveEffect(NewGameState, NewGameState, true); //Cleansed
			RemoveEffect(NewGameState, NewGameState, true); //Cleansed

			`TACTICALRULES.SubmitGameState(NewGameState);
		}
		else
		{
			// Unconscious units that are being carried should not immediately become conscious
			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState(string(GetFuncName()));
			UnconciousUnitState = XComGameState_Unit(NewGameState.ModifyStateObject(UnconciousUnitState.Class, UnconciousUnitState.ObjectID));
			UnconciousUnitState.SetUnitFloatValue(class'X2Effect_SpawnShadowbindUnit'.default.ShadowbindUnconciousCheckName, 1, eCleanup_BeginTactical);

			`TACTICALRULES.SubmitGameState(NewGameState);
		}
	}

	return ELR_NoInterrupt;
}

function EventListenerReturn AffectedByDaze_Listener(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameState_Unit UnitState;
	local XComGameState NewGameState;
	local XComGameStateContext_EffectRemoved EffectRemovedContext;
	local XComGameState_Effect EffectState;
	local XComGameStateHistory History;
	local X2Effect_Persistent PersistentEffect;
	local bool bRemove, bAtLeastOneRemoved;

	UnitState = XComGameState_Unit(EventSource);
	if( UnitState != none )
	{
		History = `XCOMHISTORY;

		bAtLeastOneRemoved = false;
		foreach History.IterateByClassType(class'XComGameState_Effect', EffectState)
		{
			PersistentEffect = EffectState.GetX2Effect();
			bRemove = false;

			if ( (EffectState.ApplyEffectParameters.TargetStateObjectRef.ObjectID == UnitState.ObjectID) &&
				 (class'X2Effect_Dazed'.default.DAZE_REMOVE_EFFECTS_TARGET.Find(PersistentEffect.EffectName) != INDEX_NONE) )
			{
				// The Unit dazed is the target of this existing effect
				bRemove = true;
			}

			if (bRemove)
			{
				// Dazed removes the existing effect
				if (!bAtLeastOneRemoved)
				{
					EffectRemovedContext = class'XComGameStateContext_EffectRemoved'.static.CreateEffectRemovedContext(EffectState);
					NewGameState = History.CreateNewGameState(true, EffectRemovedContext);
					EffectRemovedContext.RemovedEffects.Length = 0;

					bAtLeastOneRemoved = true;
				}

				EffectState.RemoveEffect(NewGameState, NewGameState, false);

				EffectRemovedContext.RemovedEffects.AddItem(EffectState.GetReference());
			}
		}

		if (bAtLeastOneRemoved)
		{
			`TACTICALRULES.SubmitGameState(NewGameState);
		}
	}

	return ELR_NoInterrupt;
}

function UpdatePerkTarget(bool bAddTarget)
{
	local XComGameStateHistory History;
	local XGUnit SourceUnit, TargetUnit;
	local XComUnitPawnNativeBase SourcePawn;
	local array<XComPerkContentInst> Perks;
	local int i;

	History = `XCOMHISTORY;
	SourceUnit = XGUnit(History.GetVisualizer(ApplyEffectParameters.SourceStateObjectRef.ObjectID));
	TargetUnit = XGUnit(History.GetVisualizer(ApplyEffectParameters.TargetStateObjectRef.ObjectID));
	if (SourceUnit != none && TargetUnit != none)
	{
		SourcePawn = SourceUnit.GetPawn();

		class'XComPerkContent'.static.GetAssociatedPerkInstances( Perks, SourcePawn, ApplyEffectParameters.AbilityInputContext.AbilityTemplateName );

		for (i = 0; i < Perks.Length; ++i)
		{
			if (bAddTarget)
				Perks[ i ].AddPerkTarget( TargetUnit, self );
			else
				Perks[ i ].RemovePerkTarget( TargetUnit );
		}
	}
}

protected function SubmitNewGameState(out XComGameState NewGameState)
{
	local X2TacticalGameRuleset TacticalRules;
	local XComGameStateHistory History;

	if (NewGameState.GetNumGameStateObjects() > 0)
	{
		TacticalRules = `TACTICALRULES;
		TacticalRules.SubmitGameState(NewGameState);
	}
	else
	{
		History = `XCOMHISTORY;
		History.CleanupPendingGameState(NewGameState);
	}
}

defaultproperties
{
	bTacticalTransient=true
}