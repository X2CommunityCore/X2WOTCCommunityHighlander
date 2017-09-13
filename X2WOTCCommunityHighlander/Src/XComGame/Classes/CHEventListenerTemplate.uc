// Issue #4 Allow to specify EventListenerDeferral for X2EventListenerTemplates
class CHEventListenerTemplate extends X2EventListenerTemplate;

struct CHEventListenerTemplate_Event extends X2EventListenerTemplate_EventCallbackPair
{
	var EventListenerDeferral Deferral;
	var int Priority;
};

var protected array<CHEventListenerTemplate_Event> CHEventsToRegister;

function AddCHEvent(name Event, delegate<X2EventManager.OnEventDelegate> EventFn, optional EventListenerDeferral Deferral = ELD_OnStateSubmitted, optional int Priority = 50)
{
	local CHEventListenerTemplate_Event EventListener;

	EventListener.EventName = Event;
	EventListener.Callback = EventFn;
	EventListener.Deferral = Deferral;
	EventListener.Priority = Priority;
	CHEventsToRegister.AddItem(EventListener);
}

function RemoveEvent(name Event)
{
	local int Index;

	super.RemoveEvent(Event);

	Index = CHEventsToRegister.Find('EventName', Event);
	if (Index != INDEX_NONE)
	{
		CHEventsToRegister.Remove(Index, 1);
	}
}

function RegisterForEvents()
{
	local X2EventManager EventManager;
	local Object selfObject;
	local CHEventListenerTemplate_Event EventListener;

	EventManager = `XEVENTMGR;
	selfObject = self;

	super.RegisterForEvents();

	foreach CHEventsToRegister(EventListener)
	{
		if(EventListener.Callback != none)
		{
			EventManager.RegisterForEvent(selfObject, EventListener.EventName, EventListener.Callback, EventListener.Deferral, EventListener.Priority);
		}
	}
}