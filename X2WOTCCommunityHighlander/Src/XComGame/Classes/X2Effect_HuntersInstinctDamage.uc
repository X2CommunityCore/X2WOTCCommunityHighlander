class X2Effect_HuntersInstinctDamage extends X2Effect_Persistent;

var int BonusDamage;
var int BonusCritChance;

function int GetAttackingDamageModifier(XComGameState_Effect EffectState, XComGameState_Unit Attacker, Damageable TargetDamageable, XComGameState_Ability AbilityState, const out EffectAppliedData AppliedData, const int CurrentDamage, optional XComGameState NewGameState)
{
	local XComGameState_Unit TargetUnit;
	local GameRulesCache_VisibilityInfo VisInfo;

	TargetUnit = XComGameState_Unit(TargetDamageable);
	if (!AbilityState.IsMeleeAbility() && TargetUnit != None && class'XComGameStateContext_Ability'.static.IsHitResultHit(AppliedData.AbilityResultContext.HitResult))
	{
		if (AbilityState.GetSourceWeapon() != none && AbilityState.GetSourceWeapon().InventorySlot == eInvSlot_PrimaryWeapon)
		{
			if (`TACTICALRULES.VisibilityMgr.GetVisibilityInfo(Attacker.ObjectID, TargetUnit.ObjectID, VisInfo))
			{
				if (Attacker.CanFlank() && TargetUnit.CanTakeCover() && VisInfo.TargetCover == CT_None)
				{
					return BonusDamage;
				}
			}
		}
	}
	return 0;
}

function GetToHitModifiers(XComGameState_Effect EffectState, XComGameState_Unit Attacker, XComGameState_Unit Target, XComGameState_Ability AbilityState, class<X2AbilityToHitCalc> ToHitType, bool bMelee, bool bFlanking, bool bIndirectFire, out array<ShotModifierInfo> ShotModifiers)
{
	local ShotModifierInfo ShotMod;

	if (AbilityState.IsMeleeAbility() && Target != none)
	{
		ShotMod.ModType = eHit_Crit;
		ShotMod.Reason = FriendlyName;
		ShotMod.Value = BonusCritChance;
		ShotModifiers.AddItem(ShotMod);
	}
}

DefaultProperties
{
	DuplicateResponse = eDupe_Ignore
	bDisplayInSpecialDamageMessageUI = true
}
