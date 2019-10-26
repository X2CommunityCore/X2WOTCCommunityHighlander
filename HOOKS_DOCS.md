# Strategy

## Events

```
Issue: #667
EventID: OverrideNextRetaliationDisplay
EventData: XComLWTuple {
  Data: [
    inout bool bShow,
    inout string strHeader,
    inout string strValue,
    inout string strFooter
  ]
}
EventSource: UIAdventOperations [self]
```

Allows mods to force show/hide the section (1st argument) and customize the text displayed (arguments 2-4) on the "Dark events" screen