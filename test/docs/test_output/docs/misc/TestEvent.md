Title: TestEvent

# TestEvent

Tracking Issue: [#10](https://github.com/X2CommunityCore/X2WOTCCommunityHighlander/issues/10)

Tags: [events](../events.md)

## NameOfTheEvent event

| Param | Value |
| - | - |
| EventID | NameOfTheEvent |
| EventData | XComLWTuple |
| EventSource | XComHQPresentationLayer |
| NewGameState | none |

### Tuple contents

| Index | Name | Type | Direction|
| - | - | - | - |
| 0 | Enum1 | enum (EMyEnum) | in |
| 1 | SomeClass | class (class&lt;Actor&gt;) | inout |
| 2 | bResult | bool | out |
| 3 | Labels | array&lt;string&gt; | inout |


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

* [UnrealScriptFile1.uc:27-33](https://github.com/X2CommunityCore/X2WOTCCommunityHighlander/blob/master/test_src/UnrealScriptFile1.uc#L27-L33)
