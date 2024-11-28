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

	// Issue #1235 - add IsStunned() check to allow Revival Protocol to target stunned units.
	if (TargetUnit.IsPanicked() || TargetUnit.IsUnconscious() || TargetUnit.IsDisoriented() || TargetUnit.IsDazed() || TargetUnit.IsStunned())
		return 'AA_Success';

	return 'AA_UnitIsNotImpaired';
}

event name CallMeetsConditionWithSource(XComGameState_BaseObject kTarget, XComGameState_BaseObject kSource)
{
	local XComGameState_Unit SourceUnit, TargetUnit;

	SourceUnit = XComGameState_Unit(kSource);
	TargetUnit = XComGameState_Unit(kTarget);

	if (SourceUnit == none || TargetUnit == none)
		return 'AA_NotAUnit';

	// Start Issue #1235
	// Replace the controlling player check with a hostility check,
	// allowing Revival Protocol to target all friendly units instead of just player-controlled units.
	// if (SourceUnit.ControllingPlayer == TargetUnit.ControllingPlayer)
	if (SourceUnit.IsFriendlyUnit(TargetUnit))
		return 'AA_Success';
	// End Issue #1235

	return 'AA_UnitIsHostile';
}