class SeqEvent_EvacActivated extends SeqEvent_GameEventTriggered;

function EventListenerReturn EventTriggered(Object EventData, Object EventSource, XComGameState GameState, Name InEventID, Object CallbackData)
{
	// Variables for issue #1027
	local array<XComGameState_Unit> EvacUnits;
	local int i;

	// fire an evac event for all units in the associated state. This will normally be just the evac'ing unit,
	// but it's possible he is carrying someone as well
	foreach GameState.IterateByClassType(class'XComGameState_Unit', RelevantUnit)
	{
		// Issue #1027: store in a local array so we can process the units
		// in a different order.
		EvacUnits.AddItem(RelevantUnit);
	}

	// Start Issue #1027
	/// HL-Docs: ref:Bugfixes; issue:1027
	/// VIPs that are carried by the last soldier to evacuate will now register
	/// as having evacuated, which is particularly important for the Neutralize
	/// VIP mission as it will grant the bonus reward.
	//
	// Process in reverse order so that the unit activating the ability
	// is handled last. This ensures that carried units - such as VIPs -
	// are processed before the carrier in the Kismet.
	for (i = EvacUnits.Length - 1; i >= 0; i--)
	{
		RelevantUnit = EvacUnits[i];
		CheckActivate(RelevantUnit.GetVisualizer(), none);
	}
	// End Issue #1027

	return ELR_NoInterrupt;
}

DefaultProperties
{
	ObjName="Evac Activated"
	EventID="EvacActivated"
}