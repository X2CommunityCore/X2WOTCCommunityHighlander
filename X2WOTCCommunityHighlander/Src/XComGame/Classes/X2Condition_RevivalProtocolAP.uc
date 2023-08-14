class X2Condition_RevivalProtocolAP extends X2Condition;

event name CallMeetsCondition(XComGameState_BaseObject kTarget)
{
	local XComGameState_Unit TargetUnit;

    // This condition applies to the effect, so we can assume the target is a unit.
    // In other words, we are relying on the ability targeting ensuring that the
    // target is valid for Revival Protocol.
    TargetUnit = XComGameState_Unit(kTarget);

    // Only allow action points to be restored for units that aren't disoriented
    // (stunned is handled by X2Effect_StunRecover).
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

	if (!SourceTeam.IsEnemyPlayer(TargetTeam)) //this will catch eTeam_Resistance in addition to XCOM
		return 'AA_Success';

	return 'AA_UnitIsHostile';
}