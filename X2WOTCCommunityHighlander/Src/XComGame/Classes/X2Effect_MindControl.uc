class X2Effect_MindControl extends X2Effect_Persistent
	native(Core);           //  This is only native to expose it for IsMindControlled on the unit state

var int iNumTurnsForAI;

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameState_Unit ControllerState;
	local XComGameState_Unit UnitState;
	local Object EffectObj;
	local int i;

	super.OnEffectAdded(ApplyEffectParameters, kNewTargetState, NewGameState, NewEffectState);

	ControllerState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ApplyEffectParameters.SourceStateObjectRef.ObjectID));
	UnitState = XComGameState_Unit(kNewTargetState);
	UnitState.SetControllingPlayer(ControllerState.ControllingPlayer);

	if(UnitState.IsTurret()) // Turret hacked ability.
	{
		// Give the turret immediate action points for the current turn when hacked.
		UnitState.ActionPoints.Length = 0;
		for( i = 0; i < class'X2CharacterTemplateManager'.default.StandardActionsPerTurn; ++i )
		{
			UnitState.ActionPoints.AddItem(class'X2CharacterTemplateManager'.default.StandardActionPoint);
		}

		// Also remove any residual 'stunned' action points if this unit was just activated and is in its 'AI warm-up' time.
		UnitState.StunnedActionPoints = 0;
		UnitState.UpdateTurretState(false);
	}
	// issue #188 - make sure this only fires in singleplayer games
	if(`XENGINE.IsSinglePlayerGame()){
		UpdateAIData(NewGameState, UnitState, true);
	}
	EffectObj = NewEffectState;

	`XEVENTMGR.TriggerEvent('MindControlled', UnitState, UnitState, NewGameState);

	//Typically, mind-control should get removed when the source is impaired, like a sustained effect.
	//Because mind-control impairs a unit momentarily when being added or removed,
	//this means we don't have to propagate team changes if we have a mind-control train.
	//(For extra fun, consider an acyclic graph of Sectoids mind-controlling each other and raising Psi Zombies.)
	//-btopp 2015-10-16
	if (!bInfiniteDuration)
		`XEVENTMGR.RegisterForEvent(EffectObj, 'ImpairingEffect', NewEffectState.OnSourceBecameImpaired, ELD_OnStateSubmitted, , ControllerState);
}

simulated function UpdateAIData(XComGameState NewGameState, XComGameState_Unit MindControlledUnit, bool MindControlAdded)
{
	local XComGameState_Unit InstigatorState;
	local XComGameStateContext_Ability AbilityContext;
	local XComGameState_AIPlayerData kAIData;
	local int iAIDataID;
	local ETeam InstigatorTeam;

	AbilityContext = XComGameStateContext_Ability(NewGameState.GetContext());
	if (AbilityContext != None)
	{
		InstigatorState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(AbilityContext.InputContext.SourceObject.ObjectID));
	}
	else
	{
		InstigatorState = MindControlledUnit;
	}

	if( InstigatorState != None )
	{
		InstigatorTeam = InstigatorState.GetTeam();

		//issue #188 - changing if statement to exclude eTeam_Neutral
		//if( InstigatorTeam == eTeam_Alien || InstigatorTeam == eTeam_XCom || InstigatorTeam == eTeam_TheLost || InstigatorTeam == eTeam_Resistance )
		if(InstigatorTeam != eTeam_Neutral)
		{
			// Issue #226 -- make it grab the right data
			iAIDataID = InstigatorState.GetAIPlayerDataID(true);
			kAIData = XComGameState_AIPlayerData(NewGameState.ModifyStateObject(class'XComGameState_AIPlayerData', iAIDataID));

			if (MindControlAdded)
				kAIData.UpdateForMindControlledUnit(NewGameState, MindControlledUnit, InstigatorState.GetReference());
			else
				kAIData.UpdateForMindControlRemoval(NewGameState, MindControlledUnit);
		}
	}
}

simulated function OnEffectRemoved(const out EffectAppliedData ApplyEffectParameters, XComGameState NewGameState, bool bCleansed, XComGameState_Effect RemovedEffectState)
{
	local XComGameStateHistory History;
	local XComGameState_Effect OriginalEffectState;
	local XComGameState_Unit UnitState;
	local StateObjectReference OriginalControllingPlayer;
	local int i;

	super.OnEffectRemoved(ApplyEffectParameters, NewGameState, bCleansed, RemovedEffectState);

	History = `XCOMHISTORY;

	// find which team the unit was on just before we mind controlled them
	OriginalEffectState = XComGameState_Effect(History.GetOriginalGameStateRevision(RemovedEffectState.ObjectID));
	UnitState = XComGameState_Unit(History.GetGameStateForObjectID(ApplyEffectParameters.TargetStateObjectRef.ObjectID,, OriginalEffectState.GetParentGameState().HistoryIndex - 1));
	OriginalControllingPlayer = UnitState.ControllingPlayer;

	// now put them back on that team
	UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', ApplyEffectParameters.TargetStateObjectRef.ObjectID));
	UnitState.SetControllingPlayer(OriginalControllingPlayer);
	
	// and update other stuff that needs to be reset when they stop being mind controlled
	UnitState.ActionPoints.Length = 0;
	if(UnitState.IsTurret()) // Turret hacked ability.
	{
		// Disable for a turn as part of the mind control reversal process.
		UnitState.ReserveActionPoints.Length = 0;
		UnitState.UpdateTurretState(false);
	}

	// if they were sustaining an effect for the mind-controlling team, stop it
	// (A unit is momentarily impaired when leaving mind-control)
	`XEVENTMGR.TriggerEvent('ImpairingEffect', UnitState, UnitState);

	if (`TACTICALRULES.GetCachedUnitActionPlayerRef().ObjectID == UnitState.ControllingPlayer.ObjectID)
	{
		for (i = 0; i < class'X2CharacterTemplateManager'.default.StandardActionsPerTurn; ++i)
		{
			UnitState.ActionPoints.AddItem(class'X2CharacterTemplateManager'.default.StandardActionPoint);
		}
	}
	UpdateAIData(NewGameState, UnitState, false);

	// Start Issue #643
	`XEVENTMGR.TriggerEvent('MindControlLost', UnitState, UnitState, NewGameState);
	// End Issue #643
}

simulated function AddX2ActionsForVisualization(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, name EffectApplyResult)
{
	local XComGameState_Unit UnitState;
	local X2Action_CameraLookAt LookAtAction;

	super.AddX2ActionsForVisualization(VisualizeGameState, ActionMetadata, EffectApplyResult);
	UnitState = XComGameState_Unit(ActionMetadata.StateObject_NewState);
	if(UnitState != None && EffectApplyResult == 'AA_Success')
	{
		LookAtAction = X2Action_CameraLookAt(class'X2Action_CameraLookAt'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded));
		LookAtAction.UseTether = false;
		LookAtAction.LookAtObject = UnitState;
		LookAtAction.BlockUntilActorOnScreen = true;

		class'X2Action_SwapTeams'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded);
		if(UnitState.IsTurret())
		{
			class'X2Action_UpdateTurretAnim'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded);
		}
	}
}
simulated function AddX2ActionsForVisualization_Removed(XComGameState VisualizeGameState, out VisualizationActionMetadata ActionMetadata, const name EffectApplyResult, XComGameState_Effect RemovedEffect)
{
	local XComGameState_Unit UnitState;
	local X2Action_CameraLookAt LookAtAction;

	super.AddX2ActionsForVisualization_Removed(VisualizeGameState, ActionMetadata, EffectApplyResult, RemovedEffect);
	UnitState = XComGameState_Unit(ActionMetadata.StateObject_NewState);
	if(UnitState != None)
	{
		LookAtAction = X2Action_CameraLookAt(class'X2Action_CameraLookAt'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded));
		LookAtAction.UseTether = false;
		LookAtAction.LookAtObject = UnitState;
		LookAtAction.BlockUntilActorOnScreen = true;

		class'X2Action_SwapTeams'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded);
		if(UnitState.IsTurret())
		{
			class'X2Action_UpdateTurretAnim'.static.AddToVisualizationTree(ActionMetadata, VisualizeGameState.GetContext(), false, ActionMetadata.LastActionAdded);
		}

		if( !UnitState.GetMyTemplate().bIsCosmetic )
		{
			`PRES.ResetUnitFlag(UnitState.GetReference());
		}
	}
}

function int GetStartingNumTurns(const out EffectAppliedData ApplyEffectParameters)
{
	local XComGameState_Unit TargetUnit, MindControllingUnit;
	local int NumTurns;
	local XComGameState_Player PlayerState;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;

	MindControllingUnit = XComGameState_Unit(History.GetGameStateForObjectID(ApplyEffectParameters.SourceStateObjectRef.ObjectID));
	PlayerState = XComGameState_Player(History.GetGameStateForObjectID(MindControllingUnit.ControllingPlayer.ObjectID));

	NumTurns = super.GetStartingNumTurns(ApplyEffectParameters);

	if( PlayerState.IsAIPlayer() && (iNumTurnsForAI > 0) )
	{
		// If the player state is AI (alien or civilian) and has a valid number of turns
		// then use the iNumTurnsForAI value
		NumTurns = iNumTurnsForAI;
	}	

	//  Always increase duration by one turn if the target is panicked or confused
	TargetUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ApplyEffectParameters.TargetStateObjectRef.ObjectID));
	if (TargetUnit != none)
	{
		if (TargetUnit.IsPanicked() || TargetUnit.IsConfused())
		{
			NumTurns++;
		}
	}

	//Mind-controlled units will spend one turn with no action points (the turn in which they get mind-controlled)
	return NumTurns + 1;
}

DefaultProperties
{
	bRemoveWhenSourceDies=true
	bRemoveWhenTargetDies=true
	DuplicateResponse=eDupe_Ignore
	EffectName="MindControl"
	WatchRule=eGameRule_PlayerTurnBegin //This applies to the _old_ team of the mind-controlled unit!
	bIsImpairingMomentarily=true //Standard mechanism to send an impairing event when added. (Code above also impairs momentarily when mind-control is removed.)
	DamageTypes.Add("Mental");
	iNumTurnsForAI=0
}