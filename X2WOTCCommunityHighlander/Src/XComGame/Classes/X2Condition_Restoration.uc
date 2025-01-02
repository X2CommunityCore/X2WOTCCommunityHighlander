class X2Condition_Restoration extends X2Condition;

event name CallMeetsCondition(XComGameState_BaseObject kTarget)
{
	local XComGameState_Unit TargetUnit;
	local name HealType;

	TargetUnit = XComGameState_Unit(kTarget);
	if (TargetUnit == none)
	{
		return 'AA_NotAUnit';
	}
	
	if (!TargetUnit.GetMyTemplate().bCanBeRevived || TargetUnit.IsBeingCarried() || TargetUnit.IsDead() || TargetUnit.IsBleedingOut())
	{
		return 'AA_UnitIsImmune';
	}
	
	if (TargetUnit.GetCurrentStat(eStat_HP) < TargetUnit.GetMaxStat(eStat_HP))
	{
		return 'AA_Success';
	}
	
	if(TargetUnit.IsPanicked() || TargetUnit.IsUnconscious() || TargetUnit.IsDisoriented() || TargetUnit.IsDazed() || TargetUnit.IsStunned())
	{
		return 'AA_Success';
	}
	
	foreach class'X2Ability_DefaultAbilitySet'.default.MedikitHealEffectTypes(HealType)
	{
		if(TargetUnit.IsUnitAffectedByDamageType(HealType))
		{
			return 'AA_Success';
		}
	}

	return 'AA_UnitIsImmune';
}

event name CallMeetsConditionWithSource(XComGameState_BaseObject kTarget, XComGameState_BaseObject kSource)
{
	local XComGameState_Unit SourceUnit, TargetUnit;

	SourceUnit = XComGameState_Unit(kSource);
	TargetUnit = XComGameState_Unit(kTarget);

	if (SourceUnit == none || TargetUnit == none)
	{
	return 'AA_NotAUnit';
	}

	if (SourceUnit.ControllingPlayer == TargetUnit.ControllingPlayer)
	{
	return 'AA_Success';
	}

	return 'AA_UnitIsHostile';
}
