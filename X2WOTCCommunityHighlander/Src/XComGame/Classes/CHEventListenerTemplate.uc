// Issue #4 Allow to specify EventListenerDeferral for X2EventListenerTemplates
class CHEventListenerTemplate extends X2EventListenerTemplate;

struct native CHEventListenerTemplate_EventDeferralPair
{
	var name EventName;
	var EventListenerDeferral Deferral;
};

var protected array<CHEventListenerTemplate_EventDeferralPair> EventDeferrals;

function AddEventWithDeferral(name Event, delegate<X2EventManager.OnEventDelegate> EventFn, EventListenerDeferral Deferral = ELD_OnStateSubmitted)
{
	local CHEventListenerTemplate_EventDeferralPair DeferralPair;

	super.AddEvent(Event, EventFn);

	DeferralPair.EventName = Event;
	DeferralPair.Deferral = Deferral;
	EventDeferrals.AddItem(DeferralPair);
}

function RegisterForEvents()
{
	local X2EventManager EventManager;
	local X2EventListenerTemplate_EventCallbackPair EventPair;
	local Object selfObject;
	local CHEventListenerTemplate_EventDeferralPair DeferralPair;
	local int DeferralIndex;

	EventManager = `XEVENTMGR;
	selfObject = self;

	foreach EventsToRegister(EventPair)
	{
		if(EventPair.Callback != none)
		{
			DeferralIndex = EventDeferrals.Find('EventName', EventPair.EventName);
			if (DeferralIndex != INDEX_NONE)
			{
				EventManager.RegisterForEvent(selfObject, EventPair.EventName, EventPair.Callback, EventDeferrals[DeferralIndex].Deferral);
			}
			else
			{
				EventManager.RegisterForEvent(selfObject, EventPair.EventName, EventPair.Callback, ELD_OnStateSubmitted);
			}
		}
	}
}