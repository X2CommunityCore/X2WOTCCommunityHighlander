class X2Condition_RevivalProtocolAP extends X2Condition;

// Start Issue# 1235
/// This condition is used for determining the conditions under which revival protocol and restorative mist
/// grant action points to units - this condition is necessarily different to the targetting conditions used in X2Condition_RevivialProtocol
/// Specifically, disoriented units should not be granted extra action points when revival protocol is used on them.
/// Action points will also be restored to other friendly units who are now valid targets for the protocols.

event name CallMeetsCondition(XComGameState_BaseObject kTarget)
{
	local XComGameState_Unit TargetUnit;

	TargetUnit = XComGameState_Unit(kTarget);
	 
	if (TargetUnit.IsPanicked() || TargetUnit.IsUnconscious() || TargetUnit.IsDazed())
        return 'AA_Success';

    return 'AA_UnitIsNotImpaired';
}

event name CallMeetsConditionWithSource(XComGameState_BaseObject kTarget, XComGameState_BaseObject kSource)
{
	local XComGameState_Unit SourceUnit, TargetUnit;
	local XComGameState_Player SourceTeam, TargetTeam;

	SourceUnit = XComGameState_Unit(kSource);
	TargetUnit = XComGameState_Unit(kTarget);

	SourceTeam = XComGameState_Player(`XCOMHISTORY.GetGameStateForObjectID(SourceUnit.GetAssociatedPlayerID()));
	TargetTeam = XComGameState_Player(`XCOMHISTORY.GetGameStateForObjectID(TargetUnit.GetAssociatedPlayerID()));

	if (SourceUnit == none || TargetUnit == none)
		return 'AA_NotAUnit';

	if (!SourceTeam.IsEnemyPlayer(TargetTeam))
		return 'AA_Success';

	return 'AA_UnitIsHostile';
}

// End Issue #1235