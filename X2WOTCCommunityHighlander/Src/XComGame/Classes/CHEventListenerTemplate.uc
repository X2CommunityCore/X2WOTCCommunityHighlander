// Issue #4 Allow to specify EventListenerDeferral for X2EventListenerTemplates
/// HL-Docs: feature:CHEventListenerTemplate; issue:4; tags:events
/// Allows mods to set up Event Listener classes with specified Deferral and Priority, similar to X2AbilityTrigger_EventListener.
///	The `AddCHEvent` function accepts up to four arguments: 
///
///	1. Name of the Event to listen for.
///	2. EventFn to run when the event is triggered.
///	3. Optional: Deferral (default deferral is ELD_OnStateSubmitted). 
///	Visit the [r/xcom2mods wiki](https://www.reddit.com/r/xcom2mods/wiki/index/events#wiki_deferral) for info on Deferrals.
///	4. Optional: Priority (default priority is 50). Event listeners with the larger priority number are executed first.
///
/// Example use:
/// ```unrealscript
/// class X2EventListener_YourEventListener extends X2EventListener;
/// 
/// static function array<X2DataTemplate> CreateTemplates()
/// {
/// 	local array<X2DataTemplate> Templates;
/// 
/// 	// You can create any number of Event Listener templates within one X2EventListener class.
/// 	Templates.AddItem(CreateListenerTemplate_YourListener());
/// 
/// 	return Templates;
/// }
/// 
/// static function CHEventListenerTemplate CreateListenerTemplate_OnBestGearLoadoutApplied()
/// {
/// 	local CHEventListenerTemplate Template;
/// 
/// 	`CREATE_X2TEMPLATE(class'CHEventListenerTemplate', Template, 'Your_Custom_BestGearApplied_Listener');
/// 
/// 	// Whether this Listener should be active during tactical missions.
/// 	Template.RegisterInTactical = true;
/// 	// Whether this Listener should be active on the strategic layer (while on Avenger)
/// 	Template.RegisterInStrategy = true;
///	
/// 	Template.AddCHEvent('EventName', YourEventFn_Listener, ELD_Immediate, 50);
/// 
/// 	return Template;
/// }
/// 
/// static function EventListenerReturn YourEventFn_Listener(Object EventData, Object EventSource, XComGameState NewGameState, Name Event, Object CallbackData)
/// {
/// 	if (GameState.GetContext().InterruptionStatus == eInterruptionStatus_Interrupt)
/// 	{
/// 		// Perform actions if the event was triggered during interruption stage.
/// 	}
/// 	else
/// 	{
/// 		// Perform actions outside interruption stage (after an ability was successfully activated, for example)
/// 	}
///
/// 	return ELR_NoInterrupt;
/// }
/// ```

class CHEventListenerTemplate extends X2EventListenerTemplate;

struct CHEventListenerTemplate_Event extends X2EventListenerTemplate_EventCallbackPair
{
	var EventListenerDeferral Deferral;
	var int Priority;
};

// Variable for issue #869
//
/// HL-Docs: feature:RegisterInCampaignStart; issue:869; tags:strategy
/// Specifies that a listener template should be registered before campaign
/// initialization occurs so that it can respond to events fired during
/// that initialization (strategy listeners don't receive those events).
var bool RegisterInCampaignStart;

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
