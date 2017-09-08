//---------------------------------------------------------------------------------------
//  FILE:    X2EventListenerTemplate.uc
//  AUTHOR:  David Burchanowsk
//
//  Allows mods and various systems to setup template based callbacks that will automatically register for
//  the specified events at the specified times
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2EventListenerTemplate extends X2DataTemplate
	dependson(X2EventManager)
	native(Core);

struct native X2EventListenerTemplate_EventCallbackPair
{
	var name EventName;
	var delegate<X2EventManager.OnEventDelegate> Callback;
};

var bool RegisterInTactical;             // if true, this template will listen for events in tactical
var bool RegisterInStrategy;             // if true, this template will listen for events in strategy
var protected array<X2EventListenerTemplate_EventCallbackPair> EventsToRegister; // array of event names to listen for

function AddEvent(name Event, delegate<X2EventManager.OnEventDelegate> EventFn)
{
	local X2EventListenerTemplate_EventCallbackPair Pair;

	Pair.EventName = Event;
	Pair.Callback = EventFn;

	EventsToRegister.AddItem(Pair);
}

// Start Issue #4 
function RemoveEvent(name Event)
{
	local int Index;

	Index = EventsToRegister.Find('EventName', Event);
	if (Index != INDEX_NONE)
	{
		EventsToRegister.Remove(Index, 1);
	}
}
// End Issue #4

function RegisterForEvents()
{
	local X2EventManager EventManager;
	local X2EventListenerTemplate_EventCallbackPair EventPair;
	local Object selfObject;

	EventManager = `XEVENTMGR;
	selfObject = self;

	foreach EventsToRegister(EventPair)
	{
		if(EventPair.Callback != none)
		{
			EventManager.RegisterForEvent(selfObject, EventPair.EventName, EventPair.Callback, ELD_OnStateSubmitted);
		}
	}
}

function UnRegisterFromEvents()
{
	local X2EventManager EventManager;
	local Object selfObject;

	EventManager = `XEVENTMGR;

	selfObject = self;
	EventManager.UnRegisterFromAllEvents(selfObject);
}