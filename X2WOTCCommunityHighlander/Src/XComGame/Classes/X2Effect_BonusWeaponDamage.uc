//---------------------------------------------------------------------------------------
//  FILE:    X2Effect_BonusWeaponDamage.uc
//  AUTHOR:  Joshua Bouscher
//  DATE:    17 Jun 2015
//  PURPOSE: Add a flat damage amount if the ability's source weapon matches
//           the source weapon of this effect.
//           Since weapons can define their own damage, this is really for when
//           the damage is temporary, or is coming from a specific soldier ability 
//           and therefore not everyone with the same weapon gets the bonus.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2Effect_BonusWeaponDamage extends X2Effect_Persistent;

var int BonusDmg;

function int GetAttackingDamageModifier(XComGameState_Effect EffectState, XComGameState_Unit Attacker, Damageable TargetDamageable, XComGameState_Ability AbilityState, const out EffectAppliedData AppliedData, const int CurrentDamage, optional XComGameState NewGameState) 
{
	local X2Effect_ApplyWeaponDamage DamageEffect;

	if (!class'XComGameStateContext_Ability'.static.IsHitResultHit(AppliedData.AbilityResultContext.HitResult) || CurrentDamage == 0)
		return 0;

	// only limit this when actually applying damage (not previewing)
	if( NewGameState != none )
	{
		//	only add the bonus damage when the damage effect is applying the weapon's base damage
		DamageEffect = X2Effect_ApplyWeaponDamage(class'X2Effect'.static.GetX2Effect(AppliedData.EffectRef));
		if( DamageEffect == none || DamageEffect.bIgnoreBaseDamage )
		{
			return 0;
		}
	}

	if( AbilityState.SourceWeapon == EffectState.ApplyEffectParameters.ItemStateObjectRef )
	{
		return BonusDmg;
	}

	return 0; 
}

defaultproperties
{
	bDisplayInSpecialDamageMessageUI = true
}
