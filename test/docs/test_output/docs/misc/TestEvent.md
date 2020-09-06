Title: TestEvent

<h1>TestEvent</h1>

Tracking Issue: [#10](https://github.com/X2CommunityCore/X2WOTCCommunityHighlander/issues/10)

Tags: [events](../events.md)

## Event specification

```event
EventID: NameOfTheEvent,
EventData: [in enum[EMyEnum] Enum1, inout class[class<Actor>] SomeClass, out bool bResult, inout array<string> Labels],
EventSource: XComHQPresentationLayer (Pres),
NewGameState: no
```

### Listener template

```unrealscript
static function EventListenerReturn OnNameOfTheEvent(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackObject)
{
	local XComHQPresentationLayer Pres;
	local XComLWTuple Tuple;
	local EMyEnum Enum1;
	local class<Actor> SomeClass;
	local bool bResult;
	local array<string> Labels;

	Pres = XComHQPresentationLayer(EventSource);
	Tuple = XComLWTuple(EventData);

	if (Tuple == None || Tuple.Id != 'NameOfTheEvent') return ELR_NoInterrupt;

	Enum1 = EMyEnum(Tuple.Data[0].i);
	SomeClass = class<Actor>(Tuple.Data[1].o);
	Labels = Tuple.Data[3].as;

	// Your code here

	Tuple.Data[1].o = SomeClass;
	Tuple.Data[2].b = bResult;
	Tuple.Data[3].as = Labels;

	return ELR_NoInterrupt;
}
```

## Source code references

* [UnrealScriptFile1.uc:30-35](https://github.com/X2CommunityCore/X2WOTCCommunityHighlander/blob/master/test_src/UnrealScriptFile1.uc#L30-L35)