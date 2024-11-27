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
	if(TargetUnit != none)
	{ 
		if (TargetUnit.IsPanicked() || TargetUnit.IsUnconscious() || TargetUnit.IsDazed())
			return 'AA_Success';
	}

    return 'AA_UnitIsNotImpaired';
}

event name CallMeetsConditionWithSource(XComGameState_BaseObject kTarget, XComGameState_BaseObject kSource)
{
	local XComGameState_Unit SourceUnit, TargetUnit;

	SourceUnit = XComGameState_Unit(kSource);
	TargetUnit = XComGameState_Unit(kTarget);

	if (SourceUnit == none || TargetUnit == none)
		return 'AA_NotAUnit';	

	if (!SourceUnit.IsEnemyUnit(TargetUnit))
			return 'AA_Success';
		
	return 'AA_UnitIsHostile';
}
// End Issue #1235
