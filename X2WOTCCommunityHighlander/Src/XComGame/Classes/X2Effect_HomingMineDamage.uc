class X2Effect_HomingMineDamage extends X2Effect_ApplyWeaponDamage;

function WeaponDamageValue GetBonusEffectDamageValue(XComGameState_Ability AbilityState, XComGameState_Unit SourceUnit, XComGameState_Item SourceWeapon, StateObjectReference TargetRef)
{
	local WeaponDamageValue MineDamage;

	if (SourceUnit.HasSoldierAbility('Shrapnel'))
	{
		MineDamage = class'X2Ability_ReaperAbilitySet'.default.HomingShrapnelDamage;
	}
	else
	{
		MineDamage = class'X2Ability_ReaperAbilitySet'.default.HomingMineDamage;
	}
	
	return MineDamage;
}

DefaultProperties
{
	bExplosiveDamage = true
	bIgnoreBaseDamage = true
}