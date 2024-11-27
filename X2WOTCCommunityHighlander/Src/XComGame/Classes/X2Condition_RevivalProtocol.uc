//---------------------------------------------------------------------------------------
//  FILE:    X2Condition_RevivalProtocol.uc
//  AUTHOR:  Joshua Bouscher
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2Condition_RevivalProtocol extends X2Condition;

event name CallMeetsCondition(XComGameState_BaseObject kTarget)
{
	local XComGameState_Unit TargetUnit;

	TargetUnit = XComGameState_Unit(kTarget);
	if (TargetUnit == none)
		return 'AA_NotAUnit';

	if (!TargetUnit.GetMyTemplate().bCanBeRevived || TargetUnit.IsBeingCarried() )
		return 'AA_UnitIsImmune';
	// Add stunned condition for Issue #1235
		if (TargetUnit.IsPanicked() || TargetUnit.IsUnconscious() || TargetUnit.IsDisoriented() || TargetUnit.IsDazed() || TargetUnit.IsStunned())
		return 'AA_Success';

	return 'AA_UnitIsNotImpaired';
}

event name CallMeetsConditionWithSource(XComGameState_BaseObject kTarget, XComGameState_BaseObject kSource)
{
	local XComGameState_Unit SourceUnit, TargetUnit;
	// Start Issue #1235
	/// Add XCGS_Players for source and target teams
	local XComGameState_Player SourceTeam, TargetTeam;

	SourceUnit = XComGameState_Unit(kSource);
	TargetUnit = XComGameState_Unit(kTarget);

	/// Get source & target teams
	SourceTeam = XComGameState_Player(`XCOMHISTORY.GetGameStateForObjectID(SourceUnit.GetAssociatedPlayerID()));
	TargetTeam = XComGameState_Player(`XCOMHISTORY.GetGameStateForObjectID(TargetUnit.GetAssociatedPlayerID()));

	if (SourceUnit == none || TargetUnit == none)
		return 'AA_NotAUnit';

	/// If the source team is not an enemy of the target team then revival protocol can target them
	if (!SourceTeam.IsEnemyPlayer(TargetTeam))
		return 'AA_Success';
	// End Issue #1235

	return 'AA_UnitIsHostile';
}
