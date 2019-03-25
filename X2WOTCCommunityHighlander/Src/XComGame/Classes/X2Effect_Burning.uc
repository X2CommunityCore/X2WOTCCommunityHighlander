//---------------------------------------------------------------------------------------
//  FILE:    X2Effect_Burning.uc
//  AUTHOR:  Joshua Bouscher  --  5/15/2014
//  PURPOSE: Handles unique burning effect rules - always has a damage effect to apply,
//           and being hit with a 2nd burning effect causes the greater of two damages
//           to apply, while refreshing the duration no matter what.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2Effect_Burning extends X2Effect_Persistent 
	config(GameCore); //Issue #89

var privatewrite name BurningEffectAddedEventName;
var config bool BURNED_IGNORES_SHIELDS; //Issue #89

function bool IsThisEffectBetterThanExistingEffect(const out XComGameState_Effect ExistingEffect)
{
	local X2Effect_Burning ExistingBurningEffectTemplate;

	ExistingBurningEffectTemplate = X2Effect_Burning(ExistingEffect.GetX2Effect());
	`assert( ExistingBurningEffectTemplate != None );

	if( ExistingBurningEffectTemplate.GetBurnDamage().EffectDamageValue.Damage < GetBurnDamage().EffectDamageValue.Damage )
	{
		return true;
	}

	return false;
}

simulated function ApplyEffectToWorld(const out EffectAppliedData ApplyEffectParameters, XComGameState NewGameState)
{
	
}

simulated function SetBurnDamage(int Damage, int Spread, name DamageType)
{
	local X2Effect_ApplyWeaponDamage BurnDamage;

	BurnDamage = new class'X2Effect_ApplyWeaponDamage';
	BurnDamage.bAllowFreeKill = false;
	BurnDamage.bIgnoreArmor = true;
	BurnDamage.bBypassShields = BURNED_IGNORES_SHIELDS; //Issue #89

	BurnDamage.EffectDamageValue.Damage = Damage;
	BurnDamage.EffectDamageValue.Spread = Spread;
	BurnDamage.EffectDamageValue.DamageType = DamageType;
	BurnDamage.bIgnoreBaseDamage = true;
	BurnDamage.DamageTag = self.Name;

	ApplyOnTick.AddItem(BurnDamage);
	`assert( ApplyOnTick.Length == 1 );
}

simulated function X2Effect_ApplyWeaponDamage GetBurnDamage()
{
	return X2Effect_ApplyWeaponDamage(ApplyOnTick[0]);
}

DefaultProperties
{
	DamageTypes(0)="Fire"
	DuplicateResponse=eDupe_Refresh
	bCanTickEveryAction=true

	BurningEffectAddedEventName="BurningEffectAdded"
}