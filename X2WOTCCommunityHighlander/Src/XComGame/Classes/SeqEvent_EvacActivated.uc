class SeqEvent_EvacActivated extends SeqEvent_GameEventTriggered;

function EventListenerReturn EventTriggered(Object EventData, Object EventSource, XComGameState GameState, Name InEventID, Object CallbackData)
{
	// fire an evac event for all units in the associated state. This will normally be just the evac'ing unit,
	// but it's possible he is carrying someone as well
	foreach GameState.IterateByClassType(class'XComGameState_Unit', RelevantUnit)
	{
		CheckActivate(RelevantUnit.GetVisualizer(), none);
	}

	return ELR_NoInterrupt;
}

DefaultProperties
{
	ObjName="Evac Activated"
	EventID="EvacActivated"
}