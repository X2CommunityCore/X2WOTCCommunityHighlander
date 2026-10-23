class X2Effect_Solace extends X2Effect_Persistent;

var private array<name> DamageTypeImmunities;

function bool IsEffectCurrentlyRelevant(XComGameState_Effect EffectGameState, XComGameState_Unit TargetUnit)
{
	local XComGameState_Unit SourceUnit;

	SourceUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(EffectGameState.ApplyEffectParameters.SourceStateObjectRef.ObjectID));
	
	if (SourceUnit == none || SourceUnit.IsDead() || TargetUnit == none || TargetUnit.IsDead())
		return false;

	if (SourceUnit.ObjectID != TargetUnit.ObjectID)
	{
		//  jbouscher: uses tile range rather than unit range so the visual check can match this logic
		if (!class'Helpers'.static.IsTileInRange(SourceUnit.TileLocation, TargetUnit.TileLocation, class'X2Ability_PsiOperativeAbilitySet'.default.SOLACE_DISTANCE_SQ))
			return false;
	}

	return true;
}

function bool ProvidesDamageImmunity(XComGameState_Effect EffectState, name DamageType)
{
	local XComGameState_Unit TargetUnit;

	if (DamageTypeImmunities.Find(DamageType) != INDEX_NONE)
	{
		TargetUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(EffectState.ApplyEffectParameters.TargetStateObjectRef.ObjectID));
		return IsEffectCurrentlyRelevant(EffectState, TargetUnit);
	}
	return false;
}

function OnUnitChangedTile(const out TTile NewTileLocation, XComGameState_Effect EffectState, XComGameState_Unit TargetUnit)
{
	local XComGameStateHistory History;
	local XComGameState_Unit SourceUnit;
	local XComGameState_Effect OtherEffect;
	local bool bAddTarget;
	local int i;

	History = `XCOMHISTORY;
	if (TargetUnit.ObjectID != EffectState.ApplyEffectParameters.SourceStateObjectRef.ObjectID)
	{
		SourceUnit = XComGameState_Unit(History.GetGameStateForObjectID(EffectState.ApplyEffectParameters.SourceStateObjectRef.ObjectID));
		if (SourceUnit != none && SourceUnit.IsAlive() && TargetUnit.IsAlive())
		{
			bAddTarget = class'Helpers'.static.IsTileInRange(SourceUnit.TileLocation, NewTileLocation, class'X2Ability_PsiOperativeAbilitySet'.default.SOLACE_DISTANCE_SQ);
			EffectState.UpdatePerkTarget(bAddTarget);
		}
	}
	else
	{
		//  When the source moves, check all other targets and update them
		SourceUnit = TargetUnit;
		for (i = 0; i < EffectState.ApplyEffectParameters.AbilityInputContext.MultiTargets.Length; ++i)
		{
			if (EffectState.ApplyEffectParameters.AbilityInputContext.MultiTargets[i].ObjectID != SourceUnit.ObjectID)
			{
				TargetUnit = XComGameState_Unit(History.GetGameStateForObjectID(EffectState.ApplyEffectParameters.AbilityInputContext.MultiTargets[i].ObjectID));
				OtherEffect = TargetUnit.GetUnitAffectedByEffectState(default.EffectName);
				if (OtherEffect != none)
				{
					bAddTarget = class'Helpers'.static.IsTileInRange(NewTileLocation, TargetUnit.TileLocation, class'X2Ability_PsiOperativeAbilitySet'.default.SOLACE_DISTANCE_SQ);
					OtherEffect.UpdatePerkTarget(bAddTarget);
				}
			}
		}
	}
}

DefaultProperties
{
	EffectName="Solace"
	DuplicateResponse=eDupe_Ignore
	DamageTypeImmunities(0)="Mental"
	DamageTypeImmunities(1)="Disorient"
	DamageTypeImmunities(2)="stun"
	DamageTypeImmunities(3)="Unconscious"
}