//---------------------------------------------------------------------------------------
//  FILE:    X2ReactionFireSequencer.uc
//  AUTHOR:  Ryan McFall --  07/08/2015
//  PURPOSE: Pulls together logic that formerly lived in X2Actions related to firing with
//			 the goal of compartmentalizing the specialized logic needed to control the 
//			 camera and slo mo rates of actors participating in a reaction fire sequence.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2ReactionFireSequencer extends X2ReactionFireSequencerNative implements(X2VisualizationMgrObserverInterface);

/// <summary>
/// Returns true if the ability used in the passed in context is considered reaction fire
/// </summary>
function bool IsReactionFire(XComGameStateContext_Ability FiringAbilityContext)
{
	local X2AbilityTemplate AbilityTemplate;
	local X2AbilityToHitCalc_StandardAim ToHitCalc;	
	local XComGameState_Unit Shooter;
	local bool bIsReactionFire;	

	//This wasn't a firing ability context... or we were interrupted and didn't resume ( died or otherwise failed to use the ability )
	if (FiringAbilityContext == none || 
		(FiringAbilityContext.InterruptionStatus == eInterruptionStatus_Interrupt && FiringAbilityContext.ResumeHistoryIndex == -1) )
	{
		return false;
	}	

	AbilityTemplate = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate(FiringAbilityContext.InputContext.AbilityTemplateName);
	if(AbilityTemplate != none)
	{
		ToHitCalc = X2AbilityToHitCalc_StandardAim(AbilityTemplate.AbilityToHitCalc);
		if(ToHitCalc != none && ToHitCalc.bReactionFire)
		{			
			bIsReactionFire = true;			
		}

		History = `XCOMHISTORY;
		Shooter = XComGameState_Unit(History.GetGameStateForObjectID(FiringAbilityContext.InputContext.SourceObject.ObjectID));		

		//Disallow melee, chosen shots to count as reaction fire, per request from Jake & Garth. There is melee handling in this class in case we want to bring it back.
		bIsReactionFire = bIsReactionFire && !AbilityTemplate.IsMelee() && !Shooter.IsChosen();
	}

	return bIsReactionFire;
}

/// <summary>
/// Returns the target of this reaction fire sequence
/// </summary>
function Actor GetTargetVisualizer()
{
	return TargetVisualizer;
}

function bool InReactionFireSequence()
{
	return ReactionFireCount > 0;
}

function bool FiringAtMovingTarget()
{
	return bFancyOverwatchActivated;
}

private function StartReactionFireSequence(XComGameStateContext_Ability FiringAbilityContext)
{
	local float NumReactions;
	local float WorldSloMoRate;
	local int NumTilesVisibleToShooters;
	local XComGameStateVisualizationMgr VisualizationMgr;

	History = `XCOMHISTORY;
	VisualizationMgr = `XCOMVISUALIZATIONMGR;

	TargetVisualizer = History.GetVisualizer(FiringAbilityContext.InputContext.PrimaryTarget.ObjectID);
	TargetVisualizerInterface = X2VisualizerInterface(TargetVisualizer);

	//Force the slomo rate to be a reasonable value
	WorldSloMoRate = FMax(FMin(ReactionFireWorldSloMoRate, 1.0f), 0.33f);

	//See how many reaction fires there will be
	NumReactions = FMax(float(GetNumRemainingReactionFires(FiringAbilityContext, , NumTilesVisibleToShooters)), 1.0f);

	//Decide between a standard overwatch sequence and a more dynamic one. For the more dynamic one we let the character run faster while the
	//shooter tracks and shoots at them. This has several requirements relating to how many shooters and the number of tiles left in the path
	//that are visible. If the unit was killed or didn't resume from the shot NumTilesVisibleToShooters will be 0
	if(NumReactions == 1.0f && NumTilesVisibleToShooters > 6)
	{		
		WorldInfo.Game.SetGameSpeed(WorldSloMoRate);				
		VisualizationMgr.SetInterruptionSloMoFactor(TargetVisualizer, ReactionFireTargetSloMoRate*2.0f);
		bFancyOverwatchActivated = true;
	}
	else
	{
		WorldInfo.Game.SetGameSpeed(WorldSloMoRate);				
		VisualizationMgr.SetInterruptionSloMoFactor(TargetVisualizer, ReactionFireTargetSloMoRate);
	}
	
	PlayAkEvent(SlomoStartSound);
}

function EndReactionFireSequence(XComGameStateContext_Ability FiringAbilityContext)
{
	local int Index;
	local XComGameStateVisualizationMgr VisualizationMgr;
	
	//Failsafe handling to make sure that no reaction fire cameras get stuck on the camera stack
	for(Index = 0; Index < AddedCameras.Length; ++Index)
	{
		`CAMERASTACK.RemoveCamera(AddedCameras[Index]);
	}

	//The reaction fire sequences is allowed to operate outside the bounds of the visualization mgr's interruption stack. So check to see
	//whether we are the only one controlling the target's slo mo rate. Put it back if so.
	VisualizationMgr = `XCOMVISUALIZATIONMGR;
	if (VisualizationMgr.InterruptionStack.Length == 0)
	{
		VisualizationMgr.SetInterruptionSloMoFactor(TargetVisualizer, 1.0f);		
	}
	
	WorldInfo.Game.SetGameSpeed(1.0f);
	PlayAkEvent(SlomoStopSound);
	bFancyOverwatchActivated = false;
}

function PushReactionFire(X2Action_ExitCover ExitCoverAction)
{
	local XComGameStateContext_Ability FiringAbilityContext;
	local ReactionFireInstance NewReactionFire;
	local XComGameState_Unit ShooterState;
	local XComGameState_Unit TargetState;
	local X2Camera_OTSReactionFireShooter ShooterCam;
	local X2Camera_Midpoint MeleeCam;
	local X2AbilityTemplate FiringAbilityTemplate;

	++ReactionFireCount;

	if(History == none)
	{
		History = `XCOMHISTORY;
	}
	
	FiringAbilityContext = ExitCoverAction.AbilityContext;

	NewReactionFire.ShooterObjectID = FiringAbilityContext.InputContext.SourceObject.ObjectID;
	NewReactionFire.TargetObjectID = FiringAbilityContext.InputContext.PrimaryTarget.ObjectID;	
	NewReactionFire.ExitCoverAction = ExitCoverAction;
	ShooterState = XComGameState_Unit(History.GetGameStateForObjectID(NewReactionFire.ShooterObjectID, eReturnType_Reference, FiringAbilityContext.AssociatedState.HistoryIndex));

	FiringAbilityTemplate = class'XComGameState_Ability'.static.GetMyTemplateManager().FindAbilityTemplate(FiringAbilityContext.InputContext.AbilityTemplateName);
	if (FiringAbilityTemplate.IsMelee())
	{
		//Don't use an over-the-shoulder camera for melee reactions
		MeleeCam = new class'X2Camera_Midpoint';
		MeleeCam.AddFocusActor(ShooterState.GetVisualizer());
		MeleeCam.AddFocusActor(History.GetVisualizer(NewReactionFire.TargetObjectID));

		NewReactionFire.ShooterCam = MeleeCam;
	}
	else
	{
		ShooterCam = new class'X2Camera_OTSReactionFireShooter';
		ShooterCam.FiringUnit = XGUnit(ShooterState.GetVisualizer());
		ShooterCam.CandidateMatineeCommentPrefix = ShooterState.GetMyTemplate().strTargetingMatineePrefix;
		ShooterCam.ShouldBlend = true;
		ShooterCam.ShouldHideUI = true;
		ShooterCam.SetTarget(XGUnit(History.GetVisualizer(NewReactionFire.TargetObjectID)));

		NewReactionFire.ShooterCam = ShooterCam;
	}

	NewReactionFire.ShotDir = Normal(FiringAbilityContext.InputContext.ProjectileTouchEnd - FiringAbilityContext.InputContext.ProjectileTouchStart);
	InsertReactionFireInstance(NewReactionFire);

	if(ReactionFireCount == 1)
	{		
		TargetState = XComGameState_Unit(History.GetGameStateForObjectID(NewReactionFire.TargetObjectID));

		TargetCam = new class'X2Camera_OTSReactionFireTarget';
		TargetCam.FiringUnit = XGUnit(History.GetVisualizer(NewReactionFire.TargetObjectID));
		TargetCam.CandidateMatineeCommentPrefix = TargetState.GetMyTemplate().strTargetingMatineePrefix;
		TargetCam.ShouldBlend = true;
		TargetCam.ShouldHideUI = true;
		TargetCam.SetTarget(XGUnit(ShooterState.GetVisualizer()));

		StartReactionFireSequence(FiringAbilityContext);
		ShowReactionFireInstance(FiringAbilityContext); //If this is the first instance, kick it off right away
	}
}

function PopReactionFire(XComGameStateContext_Ability FiringAbilityContext)
{
	local int Index;	

	if( ReactionFireCount > 0 )
	{
		--ReactionFireCount;

		for( Index = 0; Index < ReactionFireInstances.Length; ++Index )
		{
			if (ReactionFireInstances[Index].bComplete)
				continue;

			if( ReactionFireInstances[Index].ShooterObjectID == FiringAbilityContext.InputContext.SourceObject.ObjectID &&
			   ReactionFireInstances[Index].TargetObjectID == FiringAbilityContext.InputContext.PrimaryTarget.ObjectID )
			{
				ReactionFireInstances[Index].bStarted = true; //Mark as shown even though we were skipped. Maybe warn on this?
				ReactionFireInstances[Index].bReadyForNext = true; //Mark as shown even though we were skipped. Maybe warn on this?
				ReactionFireInstances[Index].bComplete = true;

				//If we're the last reaction fire, then we can pop the camera. Otherwise wait for the next push
				if( Index == (ReactionFireInstances.Length - 1) )
				{
					`CAMERASTACK.RemoveCamera(ReactionFireInstances[Index].ShooterCam);
				}

				break; // only pop
			}
		}

		if( ReactionFireCount <= 0 )
		{
			ReactionFireInstances.Length = 0;
			EndReactionFireSequence(FiringAbilityContext);
		}
	}
}

private function ShowReactionFireInstance(XComGameStateContext_Ability FiringAbilityContext)
{
	//local X2Camera_OTSReactionFireShooter ShooterCam;
	local int Index;

	for(Index = 0; Index < ReactionFireInstances.Length; ++Index)
	{
		if(ReactionFireInstances[Index].ShooterObjectID == FiringAbilityContext.InputContext.SourceObject.ObjectID &&
		   ReactionFireInstances[Index].TargetObjectID == FiringAbilityContext.InputContext.PrimaryTarget.ObjectID &&
		   !ReactionFireInstances[Index].bReadyForNext ) //Don't admit shooters that have already gone ( some abilities let a shooter take multiple shots ).
		{	
			ReactionFireInstances[Index].bStarted = true;
			
			AddedCameras.AddItem(ReactionFireInstances[Index].ShooterCam);
			`CAMERASTACK.AddCamera(ReactionFireInstances[Index].ShooterCam);			

			if(Index > 0)
			{
				`CAMERASTACK.RemoveCamera(ReactionFireInstances[Index - 1].ShooterCam);
			}
		}
	}
}

function MarkReactionFireInstanceDone(XComGameStateContext_Ability FiringAbilityContext)
{
	local int Index;
	local XComGameStateVisualizationMgr VisualizationMgr;
	local XComGameStateContext_Ability OutNextReactionFire;
	local int NextReactionFireRunIndex;

	VisualizationMgr = `XCOMVISUALIZATIONMGR;

	for(Index = 0; Index < ReactionFireInstances.Length; ++Index)
	{
		if(ReactionFireInstances[Index].ShooterObjectID == FiringAbilityContext.InputContext.SourceObject.ObjectID &&
		   ReactionFireInstances[Index].TargetObjectID == FiringAbilityContext.InputContext.PrimaryTarget.ObjectID)
		{
			// if the next shooter is the same as the current shooter (specialist ability guardian)
			// ignore the completion and wait for the pop to occur on fire action completion.
			if (Index + 1 < ReactionFireInstances.Length &&
				ReactionFireInstances[Index + 1].ShooterObjectID == ReactionFireInstances[Index].ShooterObjectID)
			{
				return;
			}

			ReactionFireInstances[Index].bReadyForNext = true;

			//Only do this if there is more reaction fire waiting
			if(GetNumRemainingReactionFires(FiringAbilityContext, OutNextReactionFire) > 0)
			{
				NextReactionFireRunIndex = OutNextReactionFire.VisualizationStartIndex == -1 ? (OutNextReactionFire.AssociatedState.HistoryIndex - 1) : OutNextReactionFire.VisualizationStartIndex;
				VisualizationMgr.ManualPermitNextVisualizationBlockToRun(NextReactionFireRunIndex);
			}
		}
	}
}

function bool AttemptStartReactionFire(X2Action_ExitCover ExitCoverAction)
{
	local int Index;

	if(ReactionFireInstances.Length == 0)
	{
		return true; //Something has gone wrong, abort
	}

	if(ReactionFireInstances[0].ExitCoverAction == ExitCoverAction &&
	   ReactionFireInstances[0].bStarted)
	{
		return true; //The party has already begun
	}

	for(Index = 1; Index < ReactionFireInstances.Length; ++Index)
	{
		if(Index > 0 && !ReactionFireInstances[Index - 1].bReadyForNext)
		{
			break;
		}		

		if(ReactionFireInstances[Index].ExitCoverAction == ExitCoverAction &&
		  !ReactionFireInstances[Index].bStarted)
		{
			ShowReactionFireInstance(ExitCoverAction.AbilityContext);
			return true;
		}
	}

	return false;
}

/// <summary>
/// Called when an active visualization block is marked complete 
/// </summary>
event OnVisualizationBlockComplete(XComGameState AssociatedGameState)
{

}

/// <summary>
/// Called when the visualizer runs out of active and pending blocks, and becomes idle
/// </summary>
event OnVisualizationIdle()
{
	//Failsafe check. If ReactionFireCount is non-zero here, it means that something weird happened - and as a result 
	//the reaction fire sequencer got stuck on. This should have been caught by IsReactionFire, but this failsafe will handled it either way.
	if (ReactionFireCount > 0)
	{	
		EndReactionFireSequence(none);
		ReactionFireCount = 0;
		ReactionFireInstances.Length = 0;
	}
}

/// <summary>
/// Called when the active unit selection changes
/// </summary>
event OnActiveUnitChanged(XComGameState_Unit NewActiveUnit)
{

}

simulated event Tick(float DT)
{
	UpdateTimeDilation();
}