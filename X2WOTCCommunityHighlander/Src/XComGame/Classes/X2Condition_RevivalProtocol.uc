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
	//Revival protocol can target stunned units
		if (TargetUnit.IsPanicked() || TargetUnit.IsUnconscious() || TargetUnit.IsDisoriented() || TargetUnit.IsDazed() || TargetUnit.IsStunned())
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

	//Revival protocol can now target resistance forces
	if (!SourceTeam.IsEnemyPlayer(TargetTeam))
		return 'AA_Success';

	return 'AA_UnitIsHostile';
}