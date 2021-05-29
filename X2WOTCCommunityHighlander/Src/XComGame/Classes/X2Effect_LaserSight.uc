class X2Effect_LaserSight extends X2Effect_Persistent config(GameData_SoldierSkills);

var config array<int> CritBoostArray;
var bool bBenefitFromEmpoweredUpgrades; // Issue #896 - if "true", crit chance bonus will be increased if XCOM has empowered weapon upgrades.

var int CritBonus;

function GetToHitModifiers(XComGameState_Effect EffectState, XComGameState_Unit Attacker, XComGameState_Unit Target, XComGameState_Ability AbilityState, class<X2AbilityToHitCalc> ToHitType, bool bMelee, bool bFlanking, bool bIndirectFire, out array<ShotModifierInfo> ShotModifiers)
{
	local int Tiles;
	local XComGameState_Item SourceWeapon;
	local ShotModifierInfo ShotInfo;

	SourceWeapon = AbilityState.GetSourceWeapon();
	if (SourceWeapon != none && SourceWeapon.ObjectID == EffectState.ApplyEffectParameters.ItemStateObjectRef.ObjectID)
	{
		Tiles = Attacker.TileDistanceBetween(Target);
		if (CritBoostArray.Length > 0)
		{
			if (Tiles < CritBoostArray.Length)
				ShotInfo.Value = CritBoostArray[Tiles];
			else  //  if this tile is not configured, use the last configured tile	
				ShotInfo.Value = CritBoostArray[CritBoostArray.Length - 1];

			ShotInfo.Value += CritBonus;

			// Start Issue #896
			/// HL-Docs: ref:Bugfixes; issue:896
			///	Add bonus crit if Insider Knowledge is present.
			if (bBenefitFromEmpoweredUpgrades && `XCOMHQ.bEmpoweredUpgrades)
			{
				ShotInfo.Value += class'X2Item_DefaultUpgrades'.default.CRIT_UPGRADE_EMPOWER_BONUS;
			}
			// End Issue #896

			ShotInfo.ModType = eHit_Crit;
			ShotInfo.Reason = FriendlyName;
			ShotModifiers.AddItem(ShotInfo);
		}
	}
}

DefaultProperties
{
	bBenefitFromEmpoweredUpgrades = true // Issue #896 - we assume this effect is normally used for Laser Sight weapon upgrade.
	DuplicateResponse = eDupe_Ignore
	EffectName = "LaserSight"
}
