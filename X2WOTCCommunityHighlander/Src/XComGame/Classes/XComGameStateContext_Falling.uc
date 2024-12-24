//---------------------------------------------------------------------------------------
//  FILE:    XComGameStateContext_Falling.uc
//  AUTHOR:  Russell Aasland  --  8/8/2014
//  PURPOSE: This context is used with falling events that require their own game state
//           object.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class XComGameStateContext_Falling extends XComGameStateContext
	native(Core)
	config(GameCore);

var() StateObjectReference FallingUnit;
var() TTile StartLocation;

var() array<TTile> LandingLocations;
var() array<TTile> EndingLocations;

var() array<StateObjectReference> LandedUnits;

var const config int MinimumFallingDamage;

function bool Validate(optional EInterruptionStatus InInterruptionStatus)
{
	return true;
}

function XComGameState ContextBuildGameState()
{
	local XComGameState NewGameState;
	local XComGameState_Unit FallingUnitState, LandedUnitState;
	local X2CharacterTemplate CharacterTemplate;
	local XComGameState_EnvironmentDamage WorldDamage;
	local XGUnit Unit;
	local float FallingDamage;
	local TTile Tile;
	local TTile LastEndLocation;
	local StateObjectReference LandedUnit;
	local int x;
	local int iStoryHeightInTiles;
	local int iNumStoriesFallen;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;
	
	FallingUnitState = XComGameState_Unit(History.GetGameStateForObjectID(FallingUnit.ObjectID));
	CharacterTemplate = FallingUnitState.GetMyTemplate();

	if(CharacterTemplate.bImmueToFalling) //Flying units are immune to falling
	{
		return none;
	}

	SetDesiredVisualizationBlockIndex( History.GetEventChainStartIndex( ) );
	NewGameState = History.CreateNewGameState( true, self );

	FallingUnitState = XComGameState_Unit( NewGameState.ModifyStateObject( class'XComGameState_Unit', FallingUnit.ObjectID ) );

	if (CharacterTemplate.bIsTurret) // turrets don't fall
	{
		FallingDamage = FallingUnitState.GetCurrentStat( eStat_HP );
		FallingUnitState.TakeDamage( NewGameState, FallingDamage, 0, 0, , , , , , , , true );
		FallingUnitState.bFallingApplied = true;
		FallingUnitState.RemoveStateFromPlay( );
	}
	else
	{
		LastEndLocation = EndingLocations[EndingLocations.Length - 1];

		FallingUnitState.SetVisibilityLocation(LastEndLocation);


		// Damage calculation for falling, per designer instructions via Hansoft,
		//     "Falling DMG should be flat for XCOM: Should be 2 damage per floor."
		// Note: Griffin says this rule should apply to all units, not just "for XCOM".
		// mdomowicz 2015_08_06
		iStoryHeightInTiles = 4;
		iNumStoriesFallen = (StartLocation.Z - LastEndLocation.Z) / iStoryHeightInTiles;
		FallingDamage = 2 * iNumStoriesFallen;


		if(FallingDamage < MinimumFallingDamage)
		{
			FallingDamage = MinimumFallingDamage;
		}

		if(!FallingUnitState.IsImmuneToDamage('Falling') && ((StartLocation.Z - LastEndLocation.Z >= iStoryHeightInTiles) || (LandedUnits.Length > 0)))
		{
			FallingUnitState.TakeDamage(NewGameState, FallingDamage, 0, 0, , , , , , , , true);
		}

		foreach LandedUnits(LandedUnit)
		{
			Unit = XGUnit(`XCOMHISTORY.GetVisualizer(LandedUnit.ObjectID));
			if(Unit != none)
			{
				LandedUnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', LandedUnit.ObjectID));

				if (LandedUnitState.IsImmuneToDamage( 'Falling' ))
					continue;

				LandedUnitState.TakeDamage(NewGameState, FallingDamage, 0, 0, , , , , , , , true);
			}
		}

		Tile = StartLocation;
		for(x = 0; x < LandingLocations.Length; ++x)
		{
			while(Tile != LandingLocations[x])
			{
				--Tile.Z;

				WorldDamage = XComGameState_EnvironmentDamage(NewGameState.CreateNewStateObject(class'XComGameState_EnvironmentDamage'));

				WorldDamage.DamageTypeTemplateName = 'Falling';
				WorldDamage.DamageCause = FallingUnitState.GetReference();
				WorldDamage.DamageSource = WorldDamage.DamageCause;
				WorldDamage.bRadialDamage = false;
				WorldDamage.HitLocationTile = Tile;
				WorldDamage.DamageTiles.AddItem(WorldDamage.HitLocationTile);
				WorldDamage.bAllowDestructionOfDamageCauseCover = true;

				WorldDamage.DamageDirection.X = 0.0f;
				WorldDamage.DamageDirection.Y = 0.0f;
				WorldDamage.DamageDirection.Z = (Tile.Z == LandingLocations[x].Z) ? 1.0f : -1.0f; // change direction of landing tile so as to not destroy the floor they should be landing on

				WorldDamage.DamageAmount = (FallingUnitState.UnitSize == 1) ? 10 : 100; // Large Units smash through more things
				WorldDamage.bAffectFragileOnly = false;
			}

			Tile = EndingLocations[x];
		}

		`XEVENTMGR.TriggerEvent('UnitMoveFinished', FallingUnitState, FallingUnitState, NewGameState);
	}

	return NewGameState;
}

protected function ContextBuildVisualization()
{
	local VisualizationActionMetadata ActionMetadata;	
	local VisualizationActionMetadata EmptyTrack;
	local XComGameState_EnvironmentDamage DamageEventStateObject;
	local XGUnit Unit;
	local TTile LastEndLocation;
	local StateObjectReference LandedUnit;
	local X2VisualizerInterface TargetVisualizerInterface;
	local XComGameState_Unit FallingUnitState;
	local XComGameState_Effect TestEffect;
	local bool PartOfCarry;
	local X2Action_MoveTeleport MoveTeleport;
	local vector PathEndPos;
	local PathingInputData PathingData;
	local PathingResultData ResultData;
	local X2Action_UpdateFOW FOWUpdate;
	local X2Action FallingAction;

	ActionMetadata = EmptyTrack;
	ActionMetadata.VisualizeActor = `XCOMHISTORY.GetVisualizer(FallingUnit.ObjectID);
	`XCOMHISTORY.GetCurrentAndPreviousGameStatesForObjectID(FallingUnit.ObjectID, ActionMetadata.StateObject_OldState, ActionMetadata.StateObject_NewState, eReturnType_Reference, AssociatedState.HistoryIndex);

	class'X2Action_WaitForWorldDamage'.static.AddToVisualizationTree( ActionMetadata, self );
	
	if (XComGameState_Unit(ActionMetadata.StateObject_OldState).GetMyTemplate().bIsTurret)
	{
		class'X2Action_RemoveUnit'.static.AddToVisualizationTree( ActionMetadata, self );

		class'X2Action_ApplyWeaponDamageToUnit'.static.AddToVisualizationTree( ActionMetadata, self );

		return;
	}

	PartOfCarry = false;
	FallingUnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(FallingUnit.ObjectID));
	if( FallingUnitState != None )
	{
		TestEffect = FallingUnitState.GetUnitAffectedByEffectState(class'X2AbilityTemplateManager'.default.BeingCarriedEffectName);
		if( TestEffect != None )
		{
			PartOfCarry = true;
		}

		TestEffect = FallingUnitState.GetUnitAffectedByEffectState(class'X2Ability_CarryUnit'.default.CarryUnitEffectName);
		if( TestEffect != None )
		{
			PartOfCarry = true;
		}
	}

	FOWUpdate = X2Action_UpdateFOW( class'X2Action_UpdateFOW'.static.AddToVisualizationTree(ActionMetadata, self, false, ActionMetadata.LastActionAdded ) );
	FOWUpdate.BeginUpdate = true;

	if (XGUnit(ActionMetadata.VisualizeActor).GetPawn().RagdollFlag == ERagdoll_Never)
	{
		PathEndPos = `XWORLD.GetPositionFromTileCoordinates( XComGameState_Unit(ActionMetadata.StateObject_NewState).TileLocation );
		MoveTeleport = X2Action_MoveTeleport( class'X2Action_MoveTeleport'.static.AddToVisualizationTree( ActionMetadata, self ) );
		MoveTeleport.ParsePathSetParameters( 0, PathEndPos, 0, PathingData, ResultData );
		MoveTeleport.SnapToGround = true;
		FallingAction = MoveTeleport;
	}
	else if( PartOfCarry )
	{
		FallingAction = class'X2Action_UnitFallingNoRagdoll'.static.AddToVisualizationTree(ActionMetadata, self);
	}
	else
	{
		FallingAction = class'X2Action_UnitFalling'.static.AddToVisualizationTree(ActionMetadata, self);
	}

	FOWUpdate = X2Action_UpdateFOW( class'X2Action_UpdateFOW'.static.AddToVisualizationTree(ActionMetadata, self, false, ActionMetadata.LastActionAdded) );
	FOWUpdate.EndUpdate = true;	

	LastEndLocation = EndingLocations[ EndingLocations.Length - 1 ];
	if (StartLocation.Z - LastEndLocation.Z >= 4)
	{
		class'X2Action_ApplyWeaponDamageToUnit'.static.AddToVisualizationTree(ActionMetadata, self);
	}

	//Allow the visualizer to do any custom processing based on the new game state. For example, units will create a death action when they reach 0 HP.
	TargetVisualizerInterface = X2VisualizerInterface(ActionMetadata.VisualizeActor);
	if (TargetVisualizerInterface != none)
		TargetVisualizerInterface.BuildAbilityEffectsVisualization(AssociatedState, ActionMetadata);

	foreach LandedUnits( LandedUnit )
	{
		Unit = XGUnit(`XCOMHISTORY.GetVisualizer(LandedUnit.ObjectID));
		if (Unit != none)
		{
			ActionMetadata = EmptyTrack;
			ActionMetadata.VisualizeActor = `XCOMHISTORY.GetVisualizer( LandedUnit.ObjectID );
			`XCOMHISTORY.GetCurrentAndPreviousGameStatesForObjectID(LandedUnit.ObjectID, ActionMetadata.StateObject_OldState, ActionMetadata.StateObject_NewState, eReturnType_Reference, AssociatedState.HistoryIndex);

			class'X2Action_ApplyWeaponDamageToUnit'.static.AddToVisualizationTree(ActionMetadata, self);

			TargetVisualizerInterface = X2VisualizerInterface(ActionMetadata.VisualizeActor);
			if (TargetVisualizerInterface != none)
				TargetVisualizerInterface.BuildAbilityEffectsVisualization(AssociatedState, ActionMetadata);

			
		}
	}

	// add visualization of environment damage, should be triggered by the fall
	foreach AssociatedState.IterateByClassType( class'XComGameState_EnvironmentDamage', DamageEventStateObject )
	{
		ActionMetadata = EmptyTrack;
		ActionMetadata.StateObject_OldState = DamageEventStateObject;
		ActionMetadata.StateObject_NewState = DamageEventStateObject;
		ActionMetadata.VisualizeActor = `XCOMHISTORY.GetVisualizer(DamageEventStateObject.ObjectID);
		class'X2Action_WaitForAbilityEffect'.static.AddToVisualizationTree(ActionMetadata, self, false, FallingAction);
		class'X2Action_ApplyWeaponDamageToTerrain'.static.AddToVisualizationTree( ActionMetadata, self, false, FallingAction);
	}
}

/// <summary>
/// Falling contexts are the result of the falling game mechanic which is trigged by the destruction of a floor beneath a unit. As a result we perform custom 
/// merge logic that will take the falling visualization and attach it to the action where the floor was destroyed
/// </summary>
function MergeIntoVisualizationTree(X2Action BuildTree, out X2Action VisualizationTree)
{	
	local XComGameStateHistory History;
	local XComGameStateVisualizationMgr VisualizationMgr;	
	local XComGameStateContext Context;
	local array<X2Action> EnvironmentalDestructionActions;
	local array<X2Action> UnitDeathActions;
	local X2Action_ApplyWeaponDamageToTerrain EvaluateAction;
	local X2Action_Death EvaluateActionDeath;
	local X2Action AttachToAction;
	local XComGameState_EnvironmentDamage DamageStateObject;
	local X2Action DamageCauseAction;
	local array<X2Action> TreeEndNodes;
	local array<X2Action> Nodes;
	local int Index;
	local int TileIndex;
	local int FoundIndex;	
	local bool bFirstFallInChain;	
	local TTile BelowStartLocation;

	History = `XCOMHISTORY;
	VisualizationMgr = `XCOMVISUALIZATIONMGR;
	VisualizationMgr.GetNodesOfType(VisualizationTree, class'X2Action_ApplyWeaponDamageToTerrain', EnvironmentalDestructionActions);	

	BelowStartLocation = StartLocation;
	BelowStartLocation.Z = BelowStartLocation.Z - 1;

	//Locate the environmental destruction action that corresponds to the fall
	FoundIndex = -1;	
	for (Index = 0; Index < EnvironmentalDestructionActions.Length; ++Index)
	{
		EvaluateAction = X2Action_ApplyWeaponDamageToTerrain(EnvironmentalDestructionActions[Index]);

		//If we have not found a suitable match by tile, fall back to a match using the parent game state information
		if ((EvaluateAction.StateChangeContext.AssociatedState.ParentGameState == AssociatedState.ParentGameState ||
			 EvaluateAction.StateChangeContext.AssociatedState == AssociatedState.ParentGameState) && FoundIndex < 0 )
		{
			//Default to attaching to the first action. For additional actions, see if they are a better match
			AttachToAction = EvaluateAction;
			FoundIndex = Index;
		}
		else
		{
			//Look for a perfect match
			DamageStateObject = XComGameState_EnvironmentDamage(EvaluateAction.Metadata.StateObject_NewState);
			for (TileIndex = 0; TileIndex < DamageStateObject.DamageTiles.Length; ++TileIndex)
			{
				if (DamageStateObject.DamageTiles[TileIndex] == StartLocation ||
					DamageStateObject.DamageTiles[TileIndex] == BelowStartLocation)
				{
					AttachToAction = EvaluateAction;
					FoundIndex = Index;
					break;
				}
			}
		}
	}

	//Look for area damage visualization, which requires that we search for any death actions that will be run by the falling unit.
	if (VisualizationTree.HasChildOfType(class'X2Action_WaitForDestructibleActorActionTrigger') ||
		VisualizationTree.HasChildOfType(class'X2Action_WaitForWorldDamage'))
	{
		//Also look for death actions. If we find one, then using it is prioritized over area damage
		VisualizationMgr.GetNodesOfType(VisualizationTree, class'X2Action_Death', UnitDeathActions);
		for (Index = 0; Index < UnitDeathActions.Length; ++Index)
		{
			EvaluateActionDeath = X2Action_Death(UnitDeathActions[Index]);
			if (EvaluateActionDeath.Metadata.StateObject_NewState.ObjectID == FallingUnit.ObjectID)
			{
				AttachToAction = EvaluateActionDeath.ParentActions[0]; //Attach to one of the parents of the death action
				break;
			}
		}
	}

	if (FoundIndex > -1)
	{
		//Ascertain whether we are the first fall in a chain of falls or not. The first in the chain will be inserted, the rest will be attached as leaf sub trees that visualize
		//simultaneously with the first fall		
		for (Index = EventChainStartIndex; Context == none || !Context.bLastEventInChain; ++Index)
		{
			Context = History.GetGameStateFromHistory(Index).GetContext();
			if (XComGameStateContext_Falling(Context) != none)
			{
				bFirstFallInChain = Context == self;
				break;
			}
		}

		//Find the X2Action_MarkerTreeInsertEnd within the BuildTree we are trying to merge
		VisualizationMgr.GetNodesOfType(BuildTree, class'X2Action_MarkerTreeInsertEnd', TreeEndNodes);
				
		if (bFirstFallInChain && TreeEndNodes.Length == 1)
		{	
			//Insert the sub tree for falling, forces it into the critical path of actions
			VisualizationMgr.InsertSubtree(BuildTree, TreeEndNodes[0], AttachToAction);
		}
		else
		{
			// Attach the fall sub tree as a leaf tree
			VisualizationMgr.ConnectAction(BuildTree, VisualizationTree, false, AttachToAction);
		}

		//Get the action that is leading to the apply weapon damage to terrain. See if the unit falling here also caused the damage leading to the fall.
		DamageCauseAction = EvaluateAction.ParentActions[0];
		if (DamageCauseAction.Metadata.StateObject_NewState.ObjectID == FallingUnit.ObjectID)
		{
			//Since they caused the damage, see if they have an enter cover action that we need to cancel
			VisualizationMgr.GetNodesOfType(VisualizationTree, class'X2Action_EnterCover', Nodes);
			for (Index = 0; Index < Nodes.Length; ++Index)
			{
				//Only cancel their exit cover actions that occurred during or after the damage
				if (Nodes[Index].StateChangeContext.AssociatedState.HistoryIndex >= DamageCauseAction.StateChangeContext.AssociatedState.HistoryIndex)
				{					
					VisualizationMgr.DestroyAction(Nodes[Index]);
				}
			}
		}
	}
}

function string SummaryString()
{
	return "XComGameStateContext_Falling";
}