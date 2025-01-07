class X2Condition_Restoration extends X2Condition;

// Begin Issue #1436 
// This function adjusts the targetting conditions for the restoration ability. If the unit either:
// 1. Requires Healing
// 2. Has a mental status effect
// 3. Has an effect which can normally be removed by a medikit
// They are now valid targets for the ability.
event name CallMeetsCondition(XComGameState_BaseObject kTarget)
{
	local XComGameState_Unit TargetUnit;
	local name HealType;

	TargetUnit = XComGameState_Unit(kTarget);
	if (TargetUnit == none)
	{
		return 'AA_NotAUnit';
	}
	
	if (TargetUnit.IsBeingCarried() || TargetUnit.IsDead() || TargetUnit.IsBleedingOut())
	{
		return 'AA_UnitIsImmune';
	}
	
	if (TargetUnit.GetCurrentStat(eStat_HP) < TargetUnit.GetMaxStat(eStat_HP))
	{
		return 'AA_Success';
	}
	
	if (TargetUnit.IsPanicked() || TargetUnit.IsUnconscious() || TargetUnit.IsDisoriented() || TargetUnit.IsDazed() || TargetUnit.IsStunned())
	{
		return 'AA_Success';
	}
	
	foreach class'X2Ability_DefaultAbilitySet'.default.MedikitHealEffectTypes(HealType)
	{
		if (TargetUnit.IsUnitAffectedByDamageType(HealType))
		{
			return 'AA_Success';
		}
	}

	return 'AA_UnitIsImmune';
}
// End Issue #1436
