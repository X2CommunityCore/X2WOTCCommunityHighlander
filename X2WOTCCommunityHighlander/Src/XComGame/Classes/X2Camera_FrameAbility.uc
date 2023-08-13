//---------------------------------------------------------------------------------------
//  FILE:    X2Camera_Midpoint.uc
//  AUTHOR:  David Burchanowski  --  2/10/2014
//  PURPOSE: Camera that keeps all points of interest within the safe zone.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2Camera_FrameAbility extends X2Camera
	implements(X2VisualizationMgrObserverInterface);

// ability that this camera should be framing
var array<XComGameStateContext_Ability> AbilitiesToFrame;

// child cameras we will push to do the actual framing
var X2Camera_MidpointTimed MidpointCamera;
var X2Camera_LookAtActor LookAtCamera;

// because we can visualize blocks out of order, we need to make sure we see all the blocks. So count the number we expect in this chain,
// and when you see one, decrement
var private int RemainingBlocksToComplete;

// if true, the camera will follow the units' movement
var bool bFollowMovingActors;

function Added()
{
	super.Added();

	`XCOMVISUALIZATIONMGR.RegisterObserver(self);

	CreateFramingCamera();
}

function Removed()
{
	super.Removed();

	`XCOMVISUALIZATIONMGR.RemoveObserver(self);
}

private function CreateFramingCamera()
{
	local XComGameStateHistory History;
	local XComWorldData WorldData;
	local StateObjectReference ObjectRef;
	local array<int> ParticipatingObjects; // keep a list of the sources and targets of this ability
	local Vector TargetLocation;
	local Actor SourceVisualizer;
	local PathPoint Point;
	local int Index;

	local XComGameStateContext ChainEndContext;
	local XComGameState ChainEndGameState;
	local XComGameState_BaseObject BaseObject;
	local X2GameRulesetVisibilityInterface VisibilityInterface;
	local TTile Tile;

	local XComGameStateContext_Ability AbilityToFrame;


	History = `XCOMHISTORY;
	WorldData = `XWORLD;

	// destroy any previous framing camera
	MidpointCamera = none;
	LookAtCamera = none;

	if( (AbilitiesToFrame.Length > 1) || 
		( (AbilitiesToFrame[0].InputContext.PrimaryTarget.ObjectID > 0 || AbilitiesToFrame[0].InputContext.TargetLocations.Length > 0)
				&& AbilitiesToFrame[0].InputContext.PrimaryTarget.ObjectID != AbilitiesToFrame[0].InputContext.SourceObject.ObjectID)) // protect against self-targeted ability
	{
		// this ability has targets, frame the whole thing with a midpoint camera
		MidpointCamera = new class'X2Camera_MidpointTimed';

		foreach AbilitiesToFrame(AbilityToFrame)
		{
			// add the shooter
			ObjectRef = AbilityToFrame.InputContext.SourceObject;
			SourceVisualizer = XGUnit(History.GetVisualizer(ObjectRef.ObjectID));
			MidpointCamera.AddFocusActor(SourceVisualizer);
			MidpointCamera.AddFocusPoint(XGUnit(SourceVisualizer).GetLocation()); // add his starting location as a fixed point as well
			ParticipatingObjects.AddItem(ObjectRef.ObjectID);

			// add the primary target
			if( AbilityToFrame.InputContext.PrimaryTarget.ObjectID > 0 )
			{
				ObjectRef = AbilityToFrame.InputContext.PrimaryTarget;
				MidpointCamera.AddFocusActor(History.GetVisualizer(ObjectRef.ObjectID));
				ParticipatingObjects.AddItem(ObjectRef.ObjectID);
			}

			// add the additional targets
			foreach AbilityToFrame.InputContext.MultiTargets(ObjectRef)
			{
				MidpointCamera.AddFocusActor(History.GetVisualizer(ObjectRef.ObjectID));
				ParticipatingObjects.AddItem(ObjectRef.ObjectID);
			}

			// and any target locations
			foreach AbilityToFrame.InputContext.TargetLocations(TargetLocation)
			{
				MidpointCamera.AddFocusPoint(TargetLocation);
			}

			for( Index = 0; Index < AbilityToFrame.InputContext.MovementPaths.Length; ++Index )
			{
				// and the pins (non-straight) parts in any movement path, so that if it's really snaky he doesn't run out of camera view
				foreach AbilityToFrame.InputContext.MovementPaths[Index].MovementData(Point)
				{
					MidpointCamera.AddFocusPoint(Point.Position);
				}
			}

			RemainingBlocksToComplete = 1;
			ChainEndGameState = AbilityToFrame.GetNextStateInEventChain();
			ChainEndContext = ChainEndGameState != none ? ChainEndGameState.GetContext() : none;

			while( ChainEndContext != none )
			{
				//Skip instances where the empty visualization block are already done before this point.
				if( `XCOMVISUALIZATIONMGR.VisualizationBlockExistForHistoryIndex(ChainEndGameState.HistoryIndex) )
				{
					RemainingBlocksToComplete++;
				}

				foreach ChainEndContext.AssociatedState.IterateByClassType(class'XComGameState_BaseObject', BaseObject)
				{
					VisibilityInterface = X2GameRulesetVisibilityInterface(BaseObject);
					if( VisibilityInterface != none && ParticipatingObjects.Find(BaseObject.ObjectID) != INDEX_NONE )
					{
						VisibilityInterface.GetKeystoneVisibilityLocation(Tile);
						MidpointCamera.AddFocusPoint(WorldData.GetPositionFromTileCoordinates(Tile));
					}
				}

				ChainEndGameState = ChainEndContext.GetNextStateInEventChain();
				ChainEndContext = ChainEndGameState != none ? ChainEndGameState.GetContext() : none;
			}
		}


		// if the unit will move, only track him. Otherwise the floor might be cutout from under him
		MidpointCamera.OnlyCutDownForActors = AbilityToFrame.InputContext.MovementPaths.Length > 0;

		MidpointCamera.LookAtDuration = 2000; // we never want this to pop
		MidpointCamera.UpdateWhenInactive = true;
		MidpointCamera.bFollowMovingActors = bFollowMovingActors;
		PushCamera(MidpointCamera);
	}
	else
	{
		RemainingBlocksToComplete = 1;
		ChainEndGameState = AbilitiesToFrame[0].GetNextStateInEventChain();
		ChainEndContext = ChainEndGameState != none ? ChainEndGameState.GetContext() : none;

		while (ChainEndContext != none)
		{
			//Skip instances where the empty visualization block are already done before this point.
			if( `XCOMVISUALIZATIONMGR.VisualizationBlockExistForHistoryIndex(ChainEndGameState.HistoryIndex) )
			{
				RemainingBlocksToComplete++;
			}

			ChainEndGameState = ChainEndContext.GetNextStateInEventChain();
			ChainEndContext = ChainEndGameState != none ? ChainEndGameState.GetContext() : none;
		}

		// this ability has only an activating unit, just move to look at him
		LookAtCamera = new class'X2Camera_LookAtActor';
		LookAtCamera.ActorToFollow = History.GetVisualizer(AbilitiesToFrame[0].InputContext.SourceObject.ObjectID);
		LookAtCamera.UpdateWhenInactive = true;
		PushCamera(LookAtCamera);
	}

	ChildCamera.UpdateWhenInactive = true;
}

public function bool HasArrived()
{
	if(LookAtCamera != none)
	{
		return LookAtCamera.HasArrived;
	}
	else if(MidpointCamera != none)
	{
		// Movement based abilities can begin moving as soon as everything is on screen
		// All other abilities need to wait for the camera to fully arrive or else the
		// accent cams feel really rushed
		if(AbilitiesToFrame[0].InputContext.MovementPaths.Length > 0)
		{
			return MidpointCamera.AreAllFocusPointsInFrustum || MidpointCamera.HasArrived;
		}
		else
		{
			return MidpointCamera.HasArrived;
		}
	}
	else
	{
		return true; // somehow we didn't create a camera
	}
}

event OnActiveUnitChanged(XComGameState_Unit NewActiveUnit)
{
	local XComGameStateContext_Ability AbilityToFrame;
	local bool bNewUnitIsFramed;

	foreach AbilitiesToFrame(AbilityToFrame)
	{
		// if the active unit changes mid-ability, jump to the new active unit
		// so that the player can control it
		if( NewActiveUnit.ObjectID == AbilityToFrame.InputContext.SourceObject.ObjectID )
		{
			bNewUnitIsFramed = true;
		}
	}

	if( !bNewUnitIsFramed )
	{
		RemoveSelfFromCameraStack();
	}
}

event OnVisualizationIdle()
{
	// safety: if visualization goes idle and we're still on the stack, remove ourself from the stack.
	// once idle, the move must be finished

	// VISUALIZATION REWRITE - Restore once the root cause of this has been determined and resolved
	//`Redscreen("Follow moving unit cam had to be removed with OnVisualizationIdle(), something terrible has happened.");

	RemoveSelfFromCameraStack();
}

event OnMarkerEndNodeCompleted(XComGameStateContext_Ability AbilityContext)
{
	local XComGameStateContext FirstContext_A;
	local XComGameStateContext FirstContext_B;

	if( AbilitiesToFrame.Length == 1 )
	{
		FirstContext_A = AbilityContext.GetFirstStateInEventChain().GetContext();
		FirstContext_B = AbilitiesToFrame[0].GetFirstStateInEventChain().GetContext();

		if( FirstContext_A == FirstContext_B )
		{
			RemoveSelfFromCameraStack();
		}
	}
}

event OnVisualizationBlockComplete(XComGameState AssociatedGameState); 

function string GetDebugDescription()
{
	return super.GetDebugDescription() $ " - " $ AbilitiesToFrame[0].InputContext.AbilityTemplateName;
}

defaultproperties
{
	UpdateWhenInactive=true
	Priority=eCameraPriority_CharacterMovementAndFraming
}