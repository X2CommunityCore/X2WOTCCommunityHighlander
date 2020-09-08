Title: BadEventSyntax

# BadEventSyntax

Tracking Issue: [#11](https://github.com/X2CommunityCore/X2WOTCCommunityHighlander/issues/11)

Tags: [events](../events.md)

Event triggers, some with errors

First, an empty event


## OnlyAnID event

| Param | Value |
| - | - |
| EventID | OnlyAnID |
| EventData | None |
| EventSource | None |
| NewGameState | no |


### Listener template

```unrealscript
static function EventListenerReturn OnOnlyAnID(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackObject)
{
	// Your code here

	return ELR_NoInterrupt;
}
```








## Source code references

* [UnrealScriptFile2.uc:41-88](https://github.com/X2CommunityCore/X2WOTCCommunityHighlander/blob/master/test_src/UnrealScriptFile2.uc#L41-L88)
