// Start Issue #1235
// This condition determines whether Revival Protocol and Restoration should restore Action Points to the targeted units, 
// which is necessarily different from the X2Condition_RevivialProtocol, which determines whether these abilities
// can target these units at all. 
// For example, these abilities can be used to remove Disorientation, but doing so should not restore units' Action Points.
class X2Condition_RevivalProtocolRestoreAP extends X2Condition;

event name CallMeetsCondition(XComGameState_BaseObject kTarget)
{
	local XComGameState_Unit TargetUnit;

	TargetUnit = XComGameState_Unit(kTarget);
	if (TargetUnit == none)
		return 'AA_NotAUnit';

	if (TargetUnit.IsPanicked() || TargetUnit.IsUnconscious() || TargetUnit.IsDazed())
	{
		return 'AA_Success';
	}
	return 'AA_UnitIsNotImpaired';
}
// End Issue #1235
