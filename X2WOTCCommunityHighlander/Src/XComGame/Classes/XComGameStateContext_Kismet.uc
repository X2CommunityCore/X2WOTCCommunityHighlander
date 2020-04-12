//---------------------------------------------------------------------------------------
//  FILE:    XComGameStateContext_Kismet.uc
//  AUTHOR:  David Burchanowski  --  1/15/2014
//  PURPOSE: XComGameStateContexts for kismet events
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComGameStateContext_Kismet extends XComGameStateContext
	native(Core);

var private name SeqOpMap;		// the kismet map this seqop resides in
var private name SeqOpName;		// the name of this specific seqop
var private name SeqOpClassName;// the class name of this sequenceOp
var private array<int> ActivatedInputs; // the inputs that were active when this op fired
var private int ActivatedOutput; // the output that was activated when this op fired

cpptext
{
	// saves all variables in the list to the specified game state
	static void SaveKismetVars(TArray<USequenceVariable*>& KismetVariables, UXComGameState* NewGameState); 
}

native function SetSequenceOp(SequenceOp SeqOp);
native private function SequenceOp FindSequenceOp();
native private function ExecuteSequenceOp(SequenceOp SeqOp);
native private function RestoreActivatedInputs(SequenceOp SeqOp);

native function SaveAttachedKismetVars(SequenceOp SeqOp, XComGameState NewGameState);
native function RestoreAttachedKismetVars(SequenceOp SeqOp);

function XComGameState ContextBuildGameState()
{
	local XComGameStateHistory History;
	local XComGameState GameState;
	local SequenceOp SeqOp;
	local X2KismetSeqOpVisualizer SeqOpVisualizer;

	History = `XComHistory;

	SeqOp = FindSequenceOp();
	if(SeqOp != none)
	{
		if(SequenceEvent(SeqOp) == none)
		{
			// make sure that any seq vars attached to this op are set to the correct values before processing the node.
			// we need to skip this for events, though, as their values are set externally in code and we will just overwrite them
			RestoreAttachedKismetVars(SeqOp);
		}

		// activate and process the sequence node
		ExecuteSequenceOp(SeqOp);

		// save the resulting kismet state to the history
		GameState = History.CreateNewGameState(true, self);

		SaveAttachedKismetVars(SeqOp, GameState);

		// give the op the chance to modify the gamestate if it needs to
		SeqOpVisualizer = X2KismetSeqOpVisualizer(SeqOp);
		if(SeqOpVisualizer != none)
		{
			SeqOpVisualizer.ModifyKismetGameState(GameState);
		}

		GameState.GetContext().SetAssociatedPlayTiming(SPT_AfterSequential);
	}

	return GameState;
}

protected function ContextBuildVisualization()
{
	local SequenceOp SeqOp;
	local X2KismetSeqOpVisualizer VisInterface; 
	local XComGameState_TimerData Timer;

	//If we are watching a replay, and this replay is of a challenge mode run, skip kismet driven visualization (ie. narratives)
	if (`REPLAY.bInReplay && !`REPLAY.bInTutorial)
	{
		Timer = XComGameState_TimerData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_TimerData', true));
		if ((Timer != none) && Timer.bIsChallengeModeTimer)
		{
			return;
		}
	}

	SeqOp = FindSequenceOp();
	if(SeqOp != none)
	{
		VisInterface = X2KismetSeqOpVisualizer(SeqOp);
		if(VisInterface != none)
		{
			// restore any attached vars to the values they contained when this op
			// was originally activated. This allows us to mask the fact that visualization and activation
			// happen at different times from the seqop developers
			RestoreAttachedKismetVars(SeqOp);
			
			SeqOp.PublishLinkedVariableValues();

			RestoreActivatedInputs(SeqOp);

			VisInterface.BuildVisualization(AssociatedState);
		}
	}
}

function string SummaryString()
{
	local SequenceOp SeqOp;

	SeqOp = FindSequenceOp();
	return "Kismet: " $ ((SeqOp != none) ? string(SeqOp.Name) : ("SeqOp not found: '" $ string(SeqOpMap) $ "." $ string(SeqOpName) $ "'"));
}

function string ToString()
{
	return "Kismet Context";
}

function string VerboseDebugString()
{
	local XComGameStateHistory History;
	local XComGameState_KismetVariable KismetObject;
	local SequenceOp SeqOp;
	local string Result;
	local int LinkIndex;
	local int VariableIndex;

	SeqOp = FindSequenceOp();
	if(SeqOp == none) return "";

	History = `XCOMHISTORY;

	// dump the var name and comment
	Result = SeqOp.Name $ "\n\"" $ SeqOp.ObjComment $ "\"\n\n";
	
	// dump input links
	Result $= "Input Links (-> indicates activated link):\n";
	for(LinkIndex = 0; LinkIndex < SeqOp.InputLinks.Length; LinkIndex++)
	{
		if(ActivatedInputs.Find(LinkIndex) != INDEX_NONE)
		{
			Result $= "-> ";
		}

		Result $= SeqOp.InputLinks[LinkIndex].LinkDesc $ "\n";
	}

	// dump output links
	Result $= "\nOutput Links (-> indicates activated link):\n";
	for(LinkIndex = 0; LinkIndex < SeqOp.OutputLinks.Length; LinkIndex++)
	{
		if(LinkIndex == ActivatedOutput)
		{
			Result $= "-> ";
		}
		
		Result $= SeqOp.OutputLinks[LinkIndex].LinkDesc $ "\n";
	}

	// dump linked variables
	Result $= "\nLinked Variables:\n";

	for(LinkIndex = 0; LinkIndex < SeqOp.VariableLinks.Length; LinkIndex++)
	{
		Result $= SeqOp.VariableLinks[LinkIndex].LinkDesc $ ":\n";

		for(VariableIndex = 0; VariableIndex < SeqOp.VariableLinks[LinkIndex].LinkedVariables.Length; VariableIndex++)
		{
			Result $= "  "; // indent to make things readable

			// find the linked variable in the history
			foreach History.IterateByClassType(class'XComGameState_KismetVariable', KismetObject)
			{	
				if(KismetObject.VarName == string(SeqOp.VariableLinks[LinkIndex].LinkedVariables[VariableIndex].VarName))
				{
					// get the correct version of this object for the associated state
					KismetObject = XComGameState_KismetVariable(History.GetGameStateForObjectID(KismetObject.ObjectID,, AssociatedState.HistoryIndex));
					
					// append to the result
					Result $= KismetObject.ToString();
					break;
				}
			}

			Result $= "\n";
		}
	}

	return Result;
}
