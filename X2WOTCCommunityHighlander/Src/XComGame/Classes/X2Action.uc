//---------------------------------------------------------------------------------------
//  FILE:    X2Action.uc
//  AUTHOR:  Ryan McFall  --  11/16/2013
//  PURPOSE: Used by the visualizer system to control a Visualization Actor. This class
//           is the base class from which all other X2Action classes should derive and
//           holds basic information, helper methods, pure virtual methods for message
//           handling, and static methods to help with the creation of new X2Action actors
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2Action extends Actor abstract native(Core) dependson(XComGameStateVisualizationMgr, XComGameStateContext, X2EventManager);

//A wrapper around an event, holding information on whether it was received / sent or not.
struct native EventWrapper
{
	var X2Action Parent;
	var array<name> Events;
};

//The following fields are pieces of information the visualization system will use to locate an appropriate place for this action to go into the visualization tree if a parent or set of
//parents is not specified
var protectedwrite array<name>					OutputEventIDs;		//Defines the unique event IDs ( does not include X2Action_Complete ) that this action can output as part of its operation.
var protectedwrite array<name>					InputEventIDs;		//Defines the unique event IDs ( does not include X2Action_Complete ) that this action can receive as a signal to start
var protectedwrite XComGameStateContext			StateChangeContext; //The state context that this action was created by
var protectedwrite VisualizationActionMetadata	Metadata;			//Container for information such as what state object or visualizer this action represents

//Visualization tree members
var protectedwrite array<EventWrapper>			ReceivedEvents;		//Tracks what events have been received by this action from its parents
var protectedwrite X2Action						TreeRoot;			//Tracks the root of the tree that this node is attached to
var protectedwrite array<X2Action>				ParentActions;		//Actions that we are waiting on for events. Incoming events are filtered by this list.
var protectedwrite array<X2Action>				ChildActions;		//Actions that are waiting for a signal from this action to start

var protectedwrite int							CurrentHistoryIndex;//Cached history index from StateChangeContext. To get the history index of the vis block
																	//this action is part of, it can be found in the VisualizationActionMetadata

//Deprecated
var protected XComGameStateContext_Ability VisualizationBlockContext;  //Points to the context that this action is a part of when Init is called ( ie. when this action starts running ).

//Cached values for when the action is running
var protectedwrite float							StartTime;			//Tracks the wall clock time when this action was started
var protectedwrite float							ExecutingTime;      //Keeps track of the time that this action has been in the 'Executing' state
var protectedwrite float							TimeoutSeconds;     //Expected run-time of the action
var protectedwrite XGUnit							Unit;
var protectedwrite XComUnitPawn						UnitPawn;
var protectedwrite XComGameStateVisualizationMgr	VisualizationMgr;

//Flags
var protectedwrite bool bInterrupted;		//TRUE if this X2Action is currently interrupted
var protectedwrite int InterruptedCount;	//Incremented by BeginInterrupt, decremented by ResumeFromInterrupt
var privatewrite bool bRegisteredForEvents; //TRUE if this action has already registered as a listener for its input events
var privatewrite bool bNoActionCompleteEvent; // Flag to true if the default ActionComplete event should not be fired for this Action
var privatewrite bool bForceImmediateTimeout;
var protectedwrite bool bNewUnitSelected;
var privatewrite bool bCompleted;			//If this flag is set to true, it indicates to the visualizer that the action is done
var privatewrite bool bNotifiedTargets;
var privatewrite bool bNotifiedEnv;
var privatewrite bool bCauseTimeDilationWhenInterrupting;

static function X2Action CreateVisualizationActionClass(class<X2Action> SpawnClass, XComGameStateContext Context, optional actor SpawnOwner )
{
	local X2Action AddAction;

	AddAction = class'WorldInfo'.static.GetWorldInfo( ).Spawn( SpawnClass, SpawnOwner );	
	AddAction.StateChangeContext = Context;
	AddAction.CurrentHistoryIndex = Context.AssociatedState.HistoryIndex;

	return AddAction;
}

static function X2Action CreateVisualizationAction( XComGameStateContext Context, optional actor SpawnOwner )
{
	return CreateVisualizationActionClass( default.Class, Context, SpawnOwner );
}

/// <summary>
/// Static method that should be used to create new X2Action objects and add them to a visualization track
/// </summary>
/// <param name="ActionMetadata">Data to connect the new action to visualizers, state objects</param>
/// <param name="Context">The visualization context that the new X2Action should be added to</param>
/// <param name="ReparentChildren">If this node is added to a node that has children already, this instructs the system to reparent those children to this node</param>
/// <param name="Parent">Parent will be added to the newly created action's parent list</param>
/// <param name="AdditionalParents">A list of additional parents for the new node. Avoids forcing callers to create arrays when calling this method</param>
static function X2Action AddToVisualizationTree(out VisualizationActionMetadata ActionMetadata, XComGameStateContext Context, 
												optional bool ReparentChildren = false,
											    optional X2Action Parent, 
												optional array<X2Action> AdditionalParents)
{
	local X2Action AddAction;	

	AddAction = CreateVisualizationActionClass( default.Class, Context, none );
	AddActionToVisualizationTree(AddAction, ActionMetadata, Context, ReparentChildren, Parent, AdditionalParents);

	return AddAction;
}

/// <summary>
/// Static method used to setup and added an X2Action to the visualization Metadata.
/// </summar>
/// <param name="AddAction">The action that will be added to the track</param>
/// <param name="InTrack">The visualization track that the new X2Action should be added to</param>
/// <param name="Context">The ablity context associated with this action</param>
static function X2Action AddActionToVisualizationTree(X2Action AddAction, out VisualizationActionMetadata ActionMetadata, XComGameStateContext Context, 
													  optional bool ReparentChildren = false,
													  optional X2Action Parent, 
													  optional array<X2Action> AdditionalParents)
{
	local XComGameStateVisualizationMgr LocalVisualizationMgr; //Local because this is a static method

	// Local variable for Issue #295
	local X2VisualizedInterface         VisualizedInterface;

	LocalVisualizationMgr = `XCOMVISUALIZATIONMGR;

	ActionMetadata.LastActionAdded = AddAction;

	AddAction.StateChangeContext = Context;
	AddAction.CurrentHistoryIndex = Context.AssociatedState.HistoryIndex;		
	AddAction.Metadata = ActionMetadata;	

	//Set the visualize actor if it is unset. If it has been set by the calling code, then we go with that
	if (AddAction.Metadata.VisualizeActor == none && ActionMetadata.StateObject_NewState != none)
	{
		//Issue #295 - Store VisualizedInterface in local var and add a 'none' checks before accessing it.
		VisualizedInterface = X2VisualizedInterface(ActionMetadata.StateObject_NewState);
		if (VisualizedInterface != none)
		{
			AddAction.Metadata.VisualizeActor = VisualizedInterface.FindOrCreateVisualizer();
		}
		else
		{
			AddAction.Metadata.VisualizeActor = none;
		}
	}

	ActionMetadata.VisualizeActor = AddAction.Metadata.VisualizeActor;

	if (AddAction.Metadata.StateObject_NewState != none)
	{
		AddAction.Metadata.StateObjectRef = AddAction.Metadata.StateObject_NewState.GetReference();
	}	

	LocalVisualizationMgr.ConnectAction(AddAction, LocalVisualizationMgr.BuildVisTree, ReparentChildren, Parent, AdditionalParents);	

	return AddAction;
}

function SetMetadata(out VisualizationActionMetadata ActionMetadata)
{
	Metadata = ActionMetadata;
}

static function X2Action_MarkerInterruptEnd AddInterruptMarkerPair(out VisualizationActionMetadata ActionMetadata, XComGameStateContext_Ability InterruptContext, X2Action InterruptedAction)
{
	local X2Action_MarkerInterruptBegin Marker;
	local X2Action_MarkerInterruptEnd MarkerEnd;
	local X2Action ParentAction;
	local array<X2Action> AdditionalParents;

	if (ActionMetadata.LastActionAdded.IsA('X2Action_MarkerInterruptEnd'))
	{
		//Make sure the interrupts go in sequence, but they also need to be tied to the lifespan of the action they are interrupting. Currently this only really happens
		//for movement actions
		ParentAction = ActionMetadata.LastActionAdded;
		AdditionalParents.AddItem(InterruptedAction);
	}
	else
	{
		ParentAction = InterruptedAction;
	}

	Marker = X2Action_MarkerInterruptBegin(class'X2Action_MarkerInterruptBegin'.static.AddToVisualizationTree(ActionMetadata, InterruptContext, false, ParentAction, AdditionalParents));
	MarkerEnd = X2Action_MarkerInterruptEnd(class'X2Action_MarkerInterruptEnd'.static.AddToVisualizationTree(ActionMetadata, InterruptContext, false, Marker));

	//Give the markers references to each other for easy tree navigation later
	Marker.EndNode = MarkerEnd;
	MarkerEnd.BeginNode = Marker;


	return MarkerEnd;
}

static function bool AllowOverrideActionDeath(VisualizationActionMetadata ActionMetadata, XComGameStateContext Context)
{
	return false;
}

/// <summary>
/// This event allows actions to insert their own action-specific scoring logic into the process for nodes to be automatically placed into a visualization tree. For example
/// actions like breakable interact actors would boost the score of a move action that passes through their tile.
/// </summar>
/// <param name="PossibleParent">This it the parent node we are evaluating to see if we should be its child</param>
event int ScoreNodeForTreePlacement(X2Action PossibleParent)
{
	return 0;
}

event Destroyed()
{
	super.Destroyed();

	//If this condition is true, it means that the action somehow escaped the proper destruction sequence.
	if (ParentActions.Length > 0)
	{		
		VisualizationMgr.DestroyAction(self, false); //This event is triggered by GWorld->DestroyActor, so don't call it again
	}
}

function AddInputEvent(Name EventID)
{
	local X2EventManager EventManager;
	local Object ThisObj;

	if( EventID != '' && InputEventIDs.Find(EventID) == INDEX_NONE )
	{
		InputEventIDs.AddItem(EventID);

		if( TreeRoot != none )
		{
			EventManager = `XEVENTMGR;
			ThisObj = self;

			// This action is already in a tree, so register for this event
			EventManager.RegisterForEvent(ThisObj, EventID, OnParentEvent);
		}
	}
}

// This function clears all registered events from this Action
function ClearInputEvents()
{
	local Object ThisObj;

	ThisObj = self;
	`XEVENTMGR.UnRegisterFromAllEvents(ThisObj);

	InputEventIDs.Length = 0;
}

//Override in subclasses to provide additional logic on whether an incoming event should be recorded / counted or not
function bool AllowEvent(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
	return InputEventIDs.Find(EventID) != INDEX_NONE;
}

function EventListenerReturn OnParentEvent(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{	
	local int EventWrapperIndex;	
	local EventWrapper NewEventWrapper;
	local X2Action SourceAction;		
	
	SourceAction = X2Action(EventSource);
	//Check whether the source is a parent of this action.
	if (ParentActions.Find(SourceAction) != INDEX_NONE)
	{
		//Only process events we indicated we are waiting for, or the X2Action_Completed event which all actions should respond to
		if (AllowEvent(EventData, EventSource, GameState, EventID, CallbackData) || EventID == 'X2Action_Completed')
		{
			//Record the receipt of this event		
			EventWrapperIndex = ReceivedEvents.Find('Parent', SourceAction);
			if (EventWrapperIndex == INDEX_NONE)
			{
				NewEventWrapper.Parent = SourceAction;
				NewEventWrapper.Events.AddItem(EventID);
				ReceivedEvents.AddItem(NewEventWrapper);
			}
			else
			{
				ReceivedEvents[EventWrapperIndex].Events.AddItem(EventID);
			}

			//Perform custom logic in response to the receipt of the event
			RespondToParentEventReceived(EventData, EventSource, GameState, EventID, CallbackData);
		}
	}

	return ELR_NoInterrupt;
}

/// <summary>
/// Can be extended by child classes to provide custom event driven behaviors.
/// </summary>
function RespondToParentEventReceived(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	//Default behavior: if we have received at least one event of a type we were waiting for from each parent we will start. We are guaranteed to receive the
	//'X2Action_Completed' event from each of our parents.
	if (IsInState('WaitingToStart') && ReceivedEvents.Length == ParentActions.Length)
	{
		Init();
		if (!bCompleted) //Allow for the action to instantly complete without entering the executing state
		{
			GotoState('Executing');
		}
	}
}

function string SummaryString()
{
	return string(Class.Name);
}

/// <summary>
/// This method will mark as completed all previous actions - halting their execution and cleaning them up. Used in situations where a running action may be 
/// interrupting or otherwise affecting previous actions, such as death.
/// </summary>
native function StopAllPreviousRunningActions(Actor Visualizer);

event NativeInit()
{
	Init();
	if (!bCompleted) //Allow for the action to instantly complete without entering the executing state
	{
		GotoState('Executing');
	}
}

/// <summary>
/// Sets basic cache variables that all X2Actions will likely need to use during their operation. Called by the visualization mgr
/// immediately prior to the X2Action entering the 'executing' state
/// </summary>
/// <param name="InAbilityContext">The ablity context associated with this action</param>
/// <param name="InTrack">The visualization track that the new X2Action should be added to</param>
function Init()
{
	local XComGameStateContext Context;
	local XComGameState GameState;
	local XGUnit TempUnit;
	local XComUnitPawn TempPawn;
	local int scan;

	bCompleted = false;	
	VisualizationMgr = `XCOMVISUALIZATIONMGR;

	GameState = `XCOMHISTORY.GetGameStateFromHistory(StateChangeContext.AssociatedState.HistoryIndex);
	if( GameState != None )
	{
		Context = GameState.GetContext();
		if(Context != None && VisualizationBlockContext == none) //VisualizationBlockContext may be non-null if this action has been passed to a resume block already
		{
			VisualizationBlockContext = XComGameStateContext_Ability(Context);
		}
	}

	if( Metadata.VisualizeActor != None )
	{
		Unit = XGUnit(Metadata.VisualizeActor);
		if( Unit != None )
		{
			UpdateLOD_TickRate();
			UnitPawn = Unit.GetPawn();
			if( UnitPawn != None )
			{
				UnitPawn.SetUpdateSkelWhenNotRendered(true);
			}
		}
	}

	for( scan = 0; scan < Metadata.AdditionalVisualizeActors.Length; ++scan )
	{
		TempUnit = XGUnit(Metadata.AdditionalVisualizeActors[scan]);
		if( TempUnit != None )
		{
			TempPawn = TempUnit.GetPawn();
			if( TempPawn != None )
			{
				TempPawn.SetUpdateSkelWhenNotRendered(true);
			}
		}
	}

	VisualizationMgr.OnActionInited(self);

	`assert( StateChangeContext != none );
}

// Jwats: SetVisibleToTeams takes into account the current action. If this is called while this action is running
//			it ensures the visualizeactor ticks.
function UpdateLOD_TickRate()
{
	local XGUnit TempUnit;
	local int scan;

	Unit.SetVisibleToTeams(Unit.m_eTeamVisibilityFlags);

	for( scan = 0; scan < Metadata.AdditionalVisualizeActors.Length; ++scan )
	{
		TempUnit = XGUnit(Metadata.AdditionalVisualizeActors[scan]);
		if( TempUnit != None )
		{
			TempUnit.SetVisibleToTeams(TempUnit.m_eTeamVisibilityFlags);
		}
	}
}

function EInterruptionStatus GetContextInterruptionStatus()
{
	return StateChangeContext.InterruptionStatus;
}

function bool FindParentOfType(class CheckType, optional out X2Action OutActionActor)
{
	local int Index, ParentIndex;
	local array<X2Action> CheckParents;
	local array<X2Action> NextCheckParents;

	//Start with our own parents
	CheckParents = ParentActions;

	//Iterate up the tree looking for a parent of the type specified
	while (CheckParents.Length > 0)
	{
		NextCheckParents.Length = 0;
		for (Index = 0; Index < CheckParents.Length; ++Index)
		{
			if (CheckParents[Index].Class == CheckType)
			{
				OutActionActor = CheckParents[Index];
				return true;
			}
						
			if (CheckParents[Index].ParentActions.Length > 0)
			{
				for (ParentIndex = 0; ParentIndex < CheckParents[Index].ParentActions.Length; ++ParentIndex)
				{
					NextCheckParents.AddItem(CheckParents[Index].ParentActions[ParentIndex]);
				}
			}
		}

		CheckParents = NextCheckParents;
	}

	return false;
}

/// <summary>
/// IsNextActionTypeOf is a helper method that X2Actions can utilize to interact with and gather information
/// about the next action that will be run. Returns TRUE if the next action is of the type specified by the
/// CheckType parameter.
/// </summary>
/// <param name="CheckType">The class we want the next action to be</param>
/// <param name="OutActionActor">Optional return parameter that will be filled out with a matching action actor</param>
function bool IsNextActionTypeOf(class CheckType, optional out X2Action OutActionActor)
{
	local X2Action Action;
	
	foreach ChildActions(Action)
	{
		if(Action.Class == CheckType)
		{			
			OutActionActor = Action;
			return true;
		}
	}

	return false;
}

/// <summary>
/// IsPreviousActionTypeOf operates in a similar fasion to IsNextActionTypeOf except that it checks the previous 
/// action instead of the next.
/// </summary>
/// <param name="CheckType">The class we want the next action to be</param>
/// <param name="OutActionActor">Optional return parameter that will be filled out with a matching action actor</param>
function bool IsPreviousActionTypeOf(class CheckType, optional out X2Action OutActionActor)
{
	local X2Action Action;

	foreach ParentActions(Action)
	{
		if (Action.Class == CheckType)
		{
			OutActionActor = Action;
			return true;
		}
	}

	return false;
}

/// <summary>
/// Override and handle in derived classes to handle notifies coming in from animations that occur on the visualizer / actor associated with this action
/// </summary>
event OnAnimNotify(AnimNotify ReceiveNotify)
{
}

/// <summary>
/// Change how long the action waits before auto-completing, if the default isn't good enough.
/// </summary>
function SetCustomTimeOutSeconds(float fSeconds)
{
	TimeoutSeconds = fSeconds;
}

/// <summary>
/// X2Actions may override this method to indicate to the tactical system that something they are doing should prevent 
/// the user from activating a new ability (or not). For example: when watching the result of a weapon shot we do not
/// want player inputs to result in actions happening off camera. Conversely, when the player puts a unit into over watch
/// the sound and flyover action should not block additional inputs
/// </summary>
event bool BlocksAbilityActivation()
{
	return class'X2TacticalGameRuleset'.default.ActionsBlockAbilityActivation;
}

/// <summary>
/// X2Actions may override this method to indicate to the XComGameStateVisualizationMgr that something has gone wrong and the action has taken longer
/// than expected to complete.
/// </summary>
function bool IsTimedOut()
{
	local bool HasTimeOut;

	HasTimeOut = TimeoutSeconds >= 0.0f;
	return (HasTimeOut && (ExecutingTime >= TimeoutSeconds)) || bForceImmediateTimeout;
}

event bool IsTimedOutNativeHook()
{
	return IsTimedOut();
}

/// <summary>
/// X2Actions must override this to correctly handle being interrupted. See documentation on MarkVisualizationBlockInterrupted in the visualization mgr
/// for more information on how interruptions are handled by the visualizer.
/// </summary>
function bool CheckInterrupted();

/// <summary>
/// Called when an X2Action becomes interrupted
/// </summary>
function BeginInterruption()
{
	bInterrupted = true;
	++InterruptedCount;
}

/// <summary>
/// Called to determine if our action will be interrupted or is already interrupted
/// </summary>
function bool HasNonEmptyInterruption()
{
	local int ScanChild;
	local X2Action_MarkerInterruptBegin BeginInterrupt;
	local X2Action_MarkerInterruptEnd EndInterrupt;
	
	for( ScanChild = 0; ScanChild < ChildActions.Length; ++ScanChild )
	{
		BeginInterrupt = X2Action_MarkerInterruptBegin(ChildActions[ScanChild]);
		if( BeginInterrupt != None && BeginInterrupt.ChildActions.Length >= 1 )
		{
			EndInterrupt = X2Action_MarkerInterruptEnd(BeginInterrupt.ChildActions[0]);
			if( EndInterrupt == None )
			{
				return true;
			}
		}
	}

	return false;
}

/// <summary>
/// Called to force action to run in a non-latent way
/// </summary>
function ForceImmediateTimeout()
{
	bForceImmediateTimeout = true;
}

function bool IsImmediateMode()
{
	return bForceImmediateTimeout;
}

/// <summary>
/// This function allows individual X2Actions to indicate whether they should cause time dilation if they are part of a visualization block that is interrupting another. For instance:
/// A moving character alerts some enemies to their presence, which triggers changes to the unit flags on the enemies. The visualization block that changes the unit flags should not cause the
/// character to go into slow motion (Time Dilation), so the action that changes the unit flags should return FALSE.
///
/// We default to returning TRUE, since in general X2Actions that interrupt do something we want the player to see as an interrupt which necessitates slowing down / pausing the interruptee.
///
/// To decide whether a visualization block that is interrupting should cause time dilation, the visualization manager will scan all tracks of the visualization block. If any of the track
/// actions for any of the tracks want to cause time dilation then the system will time dilate for the interruptee.
/// </summary>
event bool GetShouldCauseTimeDilationIfInterrupting()
{	
	return bCauseTimeDilationWhenInterrupting;
}

//Allows visualization setup code to indicate whether the visualization should cause time dilation
function SetShouldCauseTimeDilationIfInterrupting(bool bSetting)
{
	bCauseTimeDilationWhenInterrupting = bSetting;
}

event HandleNewUnitSelection()
{
	// do nothing by default
}

/// <summary>
/// Called when an X2Action resumes from being interrupted. The passed in history index can be used to gather / update information in the action and is the index for the resuming history frame
/// </summary>
function ResumeFromInterrupt(int HistoryIndex)
{
	local XComGameState HistoryFrame;
	local int Index;

	//Send the message up the chain of parents, as the tree topology may have changed since we were originaly connected with our interruptee
	for (Index = 0; Index < ParentActions.Length; ++Index)
	{
		if (ParentActions[Index].GetStateName() != 'Finished')
		{
			ParentActions[Index].ResumeFromInterrupt(HistoryIndex);
		}
	}

	//Update the VisualizationBlockContext so that it matches where we are now
	HistoryFrame = `XCOMHISTORY.GetGameStateFromHistory(HistoryIndex);
	VisualizationBlockContext = XComGameStateContext_Ability(HistoryFrame.GetContext());	
	CurrentHistoryIndex = HistoryIndex;
	
	if (InterruptedCount > 0)
	{
		--InterruptedCount;

		if (InterruptedCount == 0)
		{
			bInterrupted = false;
		}
	}
}

/// <summary>
/// Determine if this action should force complete when stopping all previous actions (such as on Death). 
/// Used for actions like messaging that should always try to complete as normal.
/// </summary>
event bool ShouldForceCompleteWhenStoppingAllPreviousActions()
{
	return true;
}

/// <summary>
/// Called by the visualization mgr when it needs to shut an action down, such as an when an interrupt block completes that has no resume.
/// </summary>
event ForceComplete()
{
	CompleteAction();
}

/// <summary>
/// X2Actions call this at the conclusion of their behavior to signal to the visualization mgr that they are done
/// </summary>
function CompleteAction()
{
	local X2VisualizerInterface VisualizerInterface;
	local Object ThisObj;
	local int i, scan;
	local XGUnit TempUnit;
	local XComUnitPawn TempPawn;
	local XComGameStateVisualizationMgr VisMgr;
	local X2Action CurrentAction;

	VisMgr = `XCOMVISUALIZATIONMGR;

	if( !bCompleted )
	{
		bCompleted = true;
		GotoState('Finished');

		CurrentAction = VisMgr.GetCurrentActionForVisualizer(Unit);
		if( CurrentAction == None || CurrentAction.bCompleted == true )
		{
			if( UnitPawn != None )
			{
				UnitPawn.SetUpdateSkelWhenNotRendered(false);
			}
		}

		for( scan = 0; scan < Metadata.AdditionalVisualizeActors.Length; ++scan )
		{
			TempUnit = XGUnit(Metadata.AdditionalVisualizeActors[scan]);
			if( TempUnit != None )
			{
				CurrentAction = VisMgr.GetCurrentActionForVisualizer(TempUnit);
				if( CurrentAction == None || CurrentAction.bCompleted == true )
				{
					TempPawn = TempUnit.GetPawn();
					if( TempPawn != None )
					{
						TempPawn.SetUpdateSkelWhenNotRendered(false);
					}
				}
			}
		}

		`XEVENTMGR.TriggerEvent('X2Action_Completed', self, self);
		
		VisualizerInterface = X2VisualizerInterface(MetaData.VisualizeActor);
		if( VisualizerInterface != none )
		{
			VisualizerInterface.OnActionCompleted();
		}

		// Loop over the additional actors and call OnActionCompleted
		for( i = 0; i < Metadata.AdditionalVisualizeActors.Length; ++i )
		{
			VisualizerInterface = X2VisualizerInterface(Metadata.AdditionalVisualizeActors[i]);
			if (VisualizerInterface != none)
			{
				VisualizerInterface.OnActionCompleted();
			}
		}

		VisualizationMgr.OnActionCompleted(self);

		//Unregister from all events once we complete
		ThisObj = self;
		`XEVENTMGR.UnRegisterFromAllEvents(ThisObj);
	}
	else
	{
		GotoState('Finished');
	}
}   

/// <summary>
/// Alternate version of CompleteAction() which does not automatically goto the 'Finished' state
/// </summary>
function CompleteActionWithoutExitingExecution()
{
	local X2VisualizerInterface VisualizerInterface;
	local Object ThisObj;
	local XComGameStateVisualizationMgr VisMgr;
	local X2Action CurrentAction;
	local int scan;
	local XGUnit TempUnit;
	local XComUnitPawn TempPawn;

	VisMgr = `XCOMVISUALIZATIONMGR;

	if( !bCompleted )
	{
		bCompleted = true;

		CurrentAction = VisMgr.GetCurrentActionForVisualizer(Unit);
		if( CurrentAction == None || CurrentAction.bCompleted == true )
		{
			if( UnitPawn != None )
			{
				UnitPawn.SetUpdateSkelWhenNotRendered(false);
			}
		}

		for( scan = 0; scan < Metadata.AdditionalVisualizeActors.Length; ++scan )
		{
			TempUnit = XGUnit(Metadata.AdditionalVisualizeActors[scan]);
			if( TempUnit != None )
			{
				CurrentAction = VisMgr.GetCurrentActionForVisualizer(TempUnit);
				if( CurrentAction == None || CurrentAction.bCompleted == true )
				{
					TempPawn = TempUnit.GetPawn();
					if( TempPawn != None )
					{
						TempPawn.SetUpdateSkelWhenNotRendered(false);
					}
				}
			}
		}

		`XEVENTMGR.TriggerEvent('X2Action_Completed', self, self);

		VisualizerInterface = X2VisualizerInterface(MetaData.VisualizeActor);
		if (VisualizerInterface != none)
		{
			VisualizerInterface.OnActionCompleted();
		}

		VisualizationMgr.OnActionCompleted(self);

		//Unregister from all events once we complete
		ThisObj = self;
		`XEVENTMGR.UnRegisterFromAllEvents(ThisObj);
	}
}

function DoNotifyTargetsAbilityAppliedWithMultipleHitLocations(XComGameState NotifyVisualizeGameState, XComGameStateContext_Ability NotifyAbilityContext,
									   int HistoryIndex, Vector HitLocation, array<Vector> allHitLocations, int PrimaryTargetID = 0, bool bNotifyMultiTargetsAtOnce = true )
{
	local StateObjectReference Target;
	local XComGameState_Unit TargetUnit;
	local Vector TargetUnitPos;
	local Vector HitLocationsIter;
	local float shortestDistSq;
	local float currDistSq;
	local int HitLocationIndex;
	local bool bSingleHitLocation;
	local bool TargetNotified;
	local bool bIsClosestTarget;
	
	if(!bNotifiedTargets)
	{
		if(allHitLocations.length <= 1)
		{
			bSingleHitLocation = true;
		}

		if (bNotifyMultiTargetsAtOnce && !bSingleHitLocation)
		{
			for(HitLocationIndex = 0; HitLocationIndex < NotifyAbilityContext.InputContext.MultiTargets.length; ++HitLocationIndex)
			{
				Target = NotifyAbilityContext.InputContext.MultiTargets[HitLocationIndex];
				TargetUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Target.ObjectID));
				TargetUnitPos = `XWORLD.GetPositionFromTileCoordinates(TargetUnit.TileLocation);
				//initialize shortestDistance to be the slightly more than the distance of the first element
				shortestDistSq = VSizeSq(allHitLocations[0] - TargetUnitPos) + 1.0f;

				foreach allHitLocations(HitLocationsIter)
				{
					//checking if this explosion is the closest hitlocations to the unit, if it is, we go ahead and notify the unit
					currDistSq = VSizeSq(HitLocationsIter - TargetUnitPos);
					if( currDistSq < shortestDistSq )
					{
						shortestDistSq = currDistSq;
						//HitLocationsIter == HitLocation check
						if( abs(HitLocationsIter.X - HitLocation.X) < EPSILON_ZERO &&  abs(HitLocationsIter.Y - HitLocation.Y) < EPSILON_ZERO && abs(HitLocationsIter.Z - HitLocation.Z) < EPSILON_ZERO )
						{
							bIsClosestTarget = true;
						}
						else
						{
							bIsClosestTarget = false;
						}
					}
				}

				if(bIsClosestTarget)
				{
					//notify the unit, and mark that we have notified the unit					
					NotifyAbilityContext.InputContext.MultiTargetsNotified[HitLocationIndex] = true;
				}
			}
		}

		if(!bNotifiedEnv) //for now we immediately notify all environment of the damage on the first projectile hit
		{
			DoNotifyTargetsAbilityApplied(NotifyVisualizeGameState, NotifyAbilityContext, HistoryIndex, PrimaryTargetID, bNotifyMultiTargetsAtOnce, bSingleHitLocation);
			bNotifiedEnv = true;
		}
		
		//check if all units have been notified
		bNotifiedTargets = true;
		foreach NotifyAbilityContext.InputContext.MultiTargetsNotified(TargetNotified)
		{
			if( !TargetNotified )
			{
				bNotifiedTargets = false;
			}
		}

		`XEVENTMGR.TriggerEvent('Visualizer_AbilityHit', self, self);
	}
}

function DoNotifyTargetsAbilityApplied(XComGameState NotifyVisualizeGameState, XComGameStateContext_Ability NotifyAbilityContext,
									   int HistoryIndex, int PrimaryTargetID = 0, bool bNotifyMultiTargetsAtOnce = true, bool bSingleHitLocation = true)
{
	local XComGameState_EnvironmentDamage EnvironmentDamageEvent;
	local XComGameState_InteractiveObject InteractiveObject;

	if( !bNotifiedTargets )
	{
		if( PrimaryTargetID > 0 )
		{
			`XEVENTMGR.TriggerEvent('Visualizer_AbilityHit', self, self);
		}

		if( bNotifyMultiTargetsAtOnce && bSingleHitLocation && NotifyAbilityContext != None)
		{
			`XEVENTMGR.TriggerEvent('Visualizer_AbilityHit', self, self);
		}

		foreach NotifyVisualizeGameState.IterateByClassType(class'XComGameState_EnvironmentDamage', EnvironmentDamageEvent)
		{
			`XEVENTMGR.TriggerEvent('Visualizer_WorldDamage', EnvironmentDamageEvent, self);
			`XEVENTMGR.TriggerEvent('Visualizer_ProjectileHit', EnvironmentDamageEvent, self);
		}

		foreach NotifyVisualizeGameState.IterateByClassType(class'XComGameState_InteractiveObject', InteractiveObject)
		{
			`XEVENTMGR.TriggerEvent('Visualizer_ProjectileHit', InteractiveObject, self);
		}

		//If any of the targets have not been notified, we set it to false
		if(bSingleHitLocation)
		{
			bNotifiedTargets = true;
		}
	}
}

// convert a path point into an index into the movement tile data
// with the string pulling, some times we need to figure it out as the PathTileIndex is -1
static private function int GetPathTileIndex( X2Action_MoveBegin MoveBeginAction, PathPoint RelevantPathPoint )
{
	local float DistanceSqr, ClosestDistanceSqr;
	local int Index, ClosestIndex;
	local TTile Diff, RelevantTile;

	if (RelevantPathPoint.PathTileIndex > -1)
		return RelevantPathPoint.PathTileIndex;

	ClosestIndex = -1;
	ClosestDistanceSqr = 1000000000;

	RelevantTile = `XWORLD.GetTileCoordinatesFromPosition( RelevantPathPoint.Position );

	for (Index = 0; Index < MoveBeginAction.CurrentMoveData.MovementTiles.Length; ++Index)
	{
		Diff = MoveBeginAction.CurrentMoveData.MovementTiles[ Index ];

		Diff.X -= RelevantTile.X;
		Diff.Y -= RelevantTile.Y;
		Diff.Z -= RelevantTile.Z;

		DistanceSqr = (Diff.X * Diff.X) + (Diff.Y * Diff.Y) + (Diff.Z * Diff.Z);

		if (DistanceSqr < ClosestDistanceSqr)
		{
			ClosestDistanceSqr = DistanceSqr;
			ClosestIndex = Index;
		}
	}

	`assert( ClosestIndex > -1 );
	return ClosestIndex;
}

// For the most part, every move action should have a move action as an immediate parent.
// For the ones that don't, I'm not sure it matters much for the move action matching below
static private function X2Action_Move GetParentMoveAction( X2Action_Move MoveAction )
{
	local X2Action ParentAction;

	foreach MoveAction.ParentActions(ParentAction)
	{
		if (X2Action_Move(ParentAction) != none)
			return X2Action_Move(ParentAction);
	}

	return none;
}

// Utility method for actions to use in determining what to do ( ie. don't play full body anim when moving )
simulated function bool PerformingInterruptedMove()
{
	local array<X2Action> ExistingMoveActions;
	local X2Action MoveAction;
	local bool bMoveInterrupted;

	VisualizationMgr.IsRunningAction(Unit, class'X2Action_Move', ExistingMoveActions);

	foreach ExistingMoveActions(MoveAction)
	{
		//One of the move actions will be this one. If there is another, we are considered to be "interrupting" it.
		if (MoveAction != self)
		{
			bMoveInterrupted = true;
			break;
		}

	}

	return bMoveInterrupted;
}

static function int CheckMoveActionForMatch(X2Action PossibleParent, out VisualizationActionMetadata CheckMetadata)
{
	local int Index, Length;
	local int PathIndex;
	local int PathTileIndex, PrevPathTileIndex;
	local X2Action_Move MoveAction, ParentAction;
	local X2Action_MoveBegin MoveBeginAction;	
	local PathPoint RelevantPathPoint, PrevPathPoint;
	local ActorIdentifier ActorID;		
	local bool bUseActorID;
	local bool bDirectMoveAction;
	local XComGameState_EnvironmentDamage DamageEvent;
	local TTile PathTile;
	
	//Large bonus to score if we are the the actor associated with a particular move action
	MoveAction = X2Action_Move(PossibleParent);
	if (MoveAction != none)
	{
		MoveBeginAction = MoveAction.MoveBeginAction;

		//Get the actor ID that is associated with this break action		
		if(CheckMetadata.VisualizeActor != none)
		{			
			bUseActorID = true;
			ActorID = CheckMetadata.VisualizeActor.GetActorId();
		}
		else if(XComGameState_EnvironmentDamage(CheckMetadata.StateObject_NewState) != none)
		{
			DamageEvent = XComGameState_EnvironmentDamage(CheckMetadata.StateObject_NewState);

			if (MoveAction.IsA('X2Action_MoveEnd')) // move end should be our last resort action
				return 1;
		}

		//Prefer actions other than the move / fly direct actions - tiebreaker in case both have an association to the same actor 
		bDirectMoveAction = MoveAction.IsA('X2Action_MoveDirect') || MoveAction.IsA('X2Action_MoveFlying');

		//See if the path points associated with the possible parent move action reference the 
		//interact actor this break action is representing.
		if (MoveAction.PathIndex > -1)
		{
			RelevantPathPoint = MoveBeginAction.CurrentMoveData.MovementData[MoveAction.PathIndex];
			if (bUseActorID)
			{
				//Directly compare the visualization actors to the actor in the path point
				if (RelevantPathPoint.ActorId == ActorID)
				{
					return bDirectMoveAction ? 2 : 4; //Found a match, increase the score
				}
			}
			else if( DamageEvent != none )
			{ 
				PathTileIndex = GetPathTileIndex( MoveBeginAction, RelevantPathPoint );
				PathTile = MoveBeginAction.CurrentMoveData.MovementTiles[ PathTileIndex ];
				if (DamageEvent.HitLocationTile == PathTile)
					return bDirectMoveAction ? 2 : 4; //Found a match, increase the score
				if (DamageEvent.IsAffectedDestructibleActor( RelevantPathPoint.ActorId ))
					return bDirectMoveAction ? 2 : 4; //Found a match, increase the score
			}
		}
		else if (MoveAction.PathIndices.Length > 0) //The possible parent move action encapsulates more than one path point 
		{
			for (Index = 0; Index < MoveAction.PathIndices.Length; ++Index)
			{
				RelevantPathPoint = MoveBeginAction.CurrentMoveData.MovementData[MoveAction.PathIndices[Index]];
				if (bUseActorID)
				{
					//Directly compare the visualization actors to the actor in the path point
					if (RelevantPathPoint.ActorId == ActorID)
					{
						return bDirectMoveAction ? 2 : 4; //Found a match, increase the score
					}
				}
				else if (DamageEvent != none)
				{
					if (DamageEvent.IsAffectedDestructibleActor( RelevantPathPoint.ActorId ))
						return bDirectMoveAction ? 2 : 4; //Found a match, increase the score
					// determine the previous location we were at
					if (Index > 0) // we already have the previous
						PrevPathPoint = MoveBeginAction.CurrentMoveData.MovementData[ MoveAction.PathIndices[ Index - 1 ] ];
					else
					{
						ParentAction = class'X2Action_Move'.static.GetParentMoveAction( MoveAction );
						if (ParentAction == none)
						{
							continue; // no movement parent, skip
						}
						else if (ParentAction.PathIndex > -1)
						{
							// one index, not much choice in path points
							PrevPathPoint = MoveBeginAction.CurrentMoveData.MovementData[ ParentAction.PathIndex ];
						}
						else if (ParentAction.PathIndices.Length > 0)
						{
							// use the last path point as that would be where the action ended
							Length = ParentAction.PathIndices.Length;
							PrevPathPoint = MoveBeginAction.CurrentMoveData.MovementData[ ParentAction.PathIndices[Length - 1] ];
						}
						else
						{
							// PathIndex is -1 and the PathIndices is empty, use the start of the path
							PrevPathPoint = MoveBeginAction.CurrentMoveData.MovementData[ 0 ];
						}
					}

					PathTileIndex = GetPathTileIndex( MoveBeginAction, RelevantPathPoint );
					PrevPathTileIndex = GetPathTileIndex( MoveBeginAction, PrevPathPoint );

					// they are a valid parent if any of the intervening tiles are the damage events hit location
					for (PathIndex = PrevPathTileIndex; PathIndex <= PathTileIndex; ++PathIndex)
					{
						PathTile = MoveBeginAction.CurrentMoveData.MovementTiles[ PathIndex ];
						if (DamageEvent.HitLocationTile == PathTile)
							return bDirectMoveAction ? 2 : 4; //Found a match, increase the score
					}
				}
			}
		}
	}

	return 0;
}

//Searches the children of our parent for actions of the specified type
native function bool HasSiblingOfType(class<X2Action> CheckForClass, optional out array<X2Action> OutActions);

//Searches the children of this node for actions of the specified type
native function bool HasChildOfType(class<X2Action> CheckForClass, optional out array<X2Action> OutActions);

cpptext
{
	virtual void AddChild(class AX2Action*& ChildNode);
	virtual void AddParent(class AX2Action*& Parent);
	virtual void RemoveChild(class AX2Action*& ChildNode);
	virtual void RemoveParent(class AX2Action*& Parent);
	virtual void RemoveAllParents();
	virtual void RemoveAllChildren();
	virtual void UpdateChildActionsRoot();

	void UpdateExecutingTime(FLOAT fDeltaT, class UXComEngine* Engine);
}

auto state WaitingToStart
{
}

simulated state Executing
{
	simulated function BeginState(name PrevStateName)
	{
		local XComGameStateHistory History;
		local XComGameState_Unit UnitState;

		History = `XCOMHISTORY;
		foreach History.IterateByClassType(class'XComGameState_Unit', UnitState)
		{
			if (UnitState.ReflexActionState == eReflexActionState_SelectAction)
				return;
		}
		//issue #188 - remove this function because it doesn't really serve a purpose at all, espeically with us reusing reflex action for team one's turn overlay
		/*
		//  @TODO - there doesn't seem to be a screen effect in play at all aside from the "reflex" overlay, so this code may no longer be needed if there is no longer a post process for reflex
		if (`PRES != none)
		{
			EnablePostProcessEffect(name(class'X2Action_Reflex'.default.PostProcessName), false);
			`PRES.UIHideReflexOverlay();
		}
		*/
	}
}

simulated function EnablePostProcessEffect(name EffectName, bool bEnable)
{
	`PRES.EnablePostProcessEffect(EffectName, bEnable);
}

simulated state Finished
{
begin:
	if( bInterrupted )
	{
		ResumeFromInterrupt(StateChangeContext.AssociatedState.HistoryIndex);
	}
	`assert(bCompleted);
}

function float GetDelayModifier()
{
	if( ShouldPlayZipMode() || ZombieMode() )
		return class'X2TacticalGameRuleset'.default.ZipModeDelayModifier;
	else
		return 1.0;
}

function float GetNonCriticalAnimationSpeed()
{
	if( ShouldPlayZipMode() )
		return class'X2TacticalGameRuleset'.default.ZipModeTrivialAnimSpeed;
	else
		return 1.0;
}

function float GetMoveAnimationSpeed()
{
	if( ShouldPlayZipMode() )
		return class'X2TacticalGameRuleset'.default.ZipModeMoveSpeed;
	else
		return 1.0;
}

function bool ShouldPlayZipMode()
{
	return `XPROFILESETTINGS.Data.bEnableZipMode && !`REPLAY.bInTutorial;
}

function bool ZombieMode()
{
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState;
	local XComGameStateContext_Ability AbilityContext;

	AbilityContext = XComGameStateContext_Ability(StateChangeContext);
	if( AbilityContext != None )
	{
		History = `XCOMHISTORY;

		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(AbilityContext.InputContext.PrimaryTarget.ObjectID));
		if( UnitState != None && UnitState.GetTeam() == eTeam_TheLost )
		{
			return true;
		}

		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(AbilityContext.InputContext.SourceObject.ObjectID));
		if( UnitState != None && UnitState.GetTeam() == eTeam_TheLost )
		{
			return true;
		}
	}

	return false;
}

function bool ShouldAddCameras()
{
	return (VisualizationBlockContext == None || !VisualizationBlockContext.ShouldImmediateSelectNextTarget());
}

function bool IsWaitingOnActionTrigger()
{
	return false;
}

function TriggerWaitCondition();

DefaultProperties
{
	ExecutingTime = 0.0	
	TimeoutSeconds = 10.0
	bNotifiedTargets=false
	bCauseTimeDilationWhenInterrupting=false
}
