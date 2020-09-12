# Events

Many of the Highlander's features utilize *Event Hooks*. Mods can subscribe to
any event by name, and then

* Read some of the data passed with the event
* Perform actions in response to the event
* Send data back to the sender of the event

Especially the last option is something many Highlander hooks expect mods to do.

This is done with the [`XComLWTuple`](misc/XComLWTuple.md) class. It can contain arbitrary
tagged data, can be read and written to by mods. Consider it a polymorphic tuple that is
compatible with any event trigger/listener signature.

## HL Event documentation

All Highlander-triggered events use a specification that looks like the following:

### OverridePromotionUIClass event

| Param | Value |
| - | - |
| EventID | OverridePromotionUIClass |
| EventData | XComLWTuple |
| EventSource | XComHQPresentationLayer |
| NewGameState | none |

#### Tuple contents

| Index | Name | Type | Direction|
| - | - | - | - |
| 0 | PromotionScreenType | enum (CHLPromotionScreenType) | in |
| 1 | PromotionUIClass | class (class&lt;UIArmory_Promotion&gt;) | inout |


#### Listener template

```unrealscript
static function EventListenerReturn OnOverridePromotionUIClass(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackObject)
{
	local XComHQPresentationLayer Pres;
	local XComLWTuple Tuple;
	local CHLPromotionScreenType PromotionScreenType;
	local class<UIArmory_Promotion> PromotionUIClass;

	Pres = XComHQPresentationLayer(EventSource);
	Tuple = XComLWTuple(EventData);

	PromotionScreenType = CHLPromotionScreenType(Tuple.Data[0].i);
	PromotionUIClass = class<UIArmory_Promotion>(Tuple.Data[1].o);

	// Your code here

	Tuple.Data[1].o = PromotionUIClass;

	return ELR_NoInterrupt;
}
```

The "$event_name event" paragraph describes which values a listener receives. `EventID` is the event name,
`EventData` and `EventSource` list the types of the objects passed along, and `NewGameState` describes whether
there is a `NewGameState` provided in the `TriggerEvent` call.

If the `EventData` is an `XComLWTuple`, the "Tuple contents" paragraph lists the type and name of every variable passed using
the tuple, along with its direction:

* An `in` variable has a meaningful value when the event is triggered, and mods may read it, usually to
  inspect the default value the game has determined.
	* If a variable is not `in`, it may not be initialized when read from.
* An `out` variable will be read from by the game after all event listeners have been executed, usually with the expectation
  that a mod may have changed it to control some behaviors of the game.
	*  If a variable is not `out`, assigning to it is a no-op.
* An `inout` variable has a meaningful default value and will be read from after the event listeners have been executed.

Note that exchanging data through an `XComLWTuple` requires subscribing to the event with the `ELD_Immediate` deferral.

The "Listener template" is a copy-pasteable function that you can copy into your own mod as a starting point for using the event.

**Note:** It is highly recommended that you use the [`CHEventListenerTemplate`](./misc/CHEventListenerTemplate.md) to subscribe
to such events, as it is robust against history changes and allows you to provide the `ELD_Immediate` deferral.

For this event, you would subscribe like this:

```unrealscript
Template.RegisterInStrategy = true;
Template.AddCHEvent('OverridePromotionUIClass', OnOverridePromotionUIClass, ELD_Immediate, 50);
```

## Event-relevant pages

The following is a list of all pages tagged "Events" due to their relevance to or
use of the event system.

