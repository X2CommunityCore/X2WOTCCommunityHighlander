class X2AbilityToHitCalc_StatCheck extends X2AbilityToHitCalc abstract;

struct StatContestResultToEffectInfo
{
	var array<int> EffectIndices;
};

struct StatContestOverrideData
{
	var array<int> MultiTargetEffectsNumHits;
	var array<StatContestResultToEffectInfo> StatContestResultToEffectInfos;
};

var int BaseValue;

function int GetAttackValue(XComGameState_Ability kAbility, StateObjectReference TargetRef) { return -1; }
function int GetDefendValue(XComGameState_Ability kAbility, StateObjectReference TargetRef) { return -1; }

protected function int GetHitChance(XComGameState_Ability kAbility, AvailableTarget kTarget, optional out ShotBreakdown m_ShotBreakdown, optional bool bDebugLog = false)
{
	local int AttackVal, DefendVal;
	local ShotBreakdown EmptyShotBreakdown;
	// variables added for issue #467
	local XComGameState_Unit UnitState, TargetState;
	local XComGameState_Effect EffectState;
	local XComGameStateHistory History;
	local X2Effect_Persistent PersistentEffect;
	local StateObjectReference EffectRef;
	local array<ShotModifierInfo> ShotModifiers;
	local ShotModifierInfo ShotModifier;
	// end issue #467

	//reset shot breakdown
	m_ShotBreakdown = EmptyShotBreakdown;

	AttackVal = GetAttackValue(kAbility, kTarget.PrimaryTarget);
	DefendVal = GetDefendValue(kAbility, kTarget.PrimaryTarget);

	// start issue #467: added conditions for X2Effect_ToHitModifier::GetHit(AsTarget)ModifiersForStatCheck
	History = `XCOMHISTORY;
	UnitState = XComGameState_Unit(History.GetGameStateForObjectID(kAbility.OwnerStateObject.ObjectID));
	TargetState = XComGameState_Unit(History.GetGameStateForObjectID(kTarget.PrimaryTarget.ObjectID));

	// now lets check attacker's current effects
	foreach UnitState.AffectedByEffects(EffectRef)
	{
		EffectState = XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID));

		// check this effect's sub-class by attempting to cast it to what we need
		if (EffectState != None)
		{
			PersistentEffect = EffectState.GetX2Effect();

			if (PersistentEffect == None)
			{
				continue;
			}
		}
		// everything checked out let's add it to the list
		PersistentEffect.GetToHitModifiersForStatCheck(EffectState, UnitState, TargetState, kAbility, self.Class, ShotModifiers);
	}
	// repeat same process for the target's current effects
	foreach TargetState.AffectedByEffects(EffectRef)
	{
		EffectState = XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID));

		if (EffectState != None)
		{
			PersistentEffect = EffectState.GetX2Effect();

			if (PersistentEffect == None)
			{
				continue;
			}
		}

		PersistentEffect.GetToHitAsTargetModifiersForStatCheck(EffectState, UnitState, TargetState, kAbility, self.Class, ShotModifiers);
	}

	foreach ShotModifiers(ShotModifier)
	{
		AddModifier(ShotModifier.Value, ShotModifier.Reason, m_ShotBreakdown, ShotModifier.ModType, bDebugLog);
	}
	// end issue #467

	AddModifier(BaseValue, GetBaseString(), m_ShotBreakdown, eHit_Success, bDebugLog);
	AddModifier(AttackVal, GetAttackString(), m_ShotBreakdown, eHit_Success, bDebugLog);
	AddModifier(-DefendVal, GetDefendString(), m_ShotBreakdown, eHit_Success, bDebugLog);

	// Issue #467: modified the method of getting a final result from vanilla
	return m_ShotBreakdown.FinalHitChance;
}

function string GetBaseString() { return class'XLocalizedData'.default.BaseChance; }
function string GetAttackString() { return class'XLocalizedData'.default.OffenseStat; }
function string GetDefendString() { return class'XLocalizedData'.default.DefenseStat; }

function RollForAbilityHit(XComGameState_Ability kAbility, AvailableTarget kTarget, out AbilityResultContext ResultContext)
{
	local int MultiTargetIndex, AttackVal, DefendVal, TargetRoll, RandRoll, StatContestResultValue;
	local OverriddenEffectsByType EmptyOverriddenByType;
	local StatContestOverrideData StatContestOverrideInfo;
	local X2AbilityTemplate AbilityTemplate;

	`log("===RollForAbilityHit===",,'XCom_HitRolls');
	`log("Ability:" @ kAbility.GetMyTemplateName() @ "Target:" @ kTarget.PrimaryTarget.ObjectID,,'XCom_HitRolls');

	if (kTarget.PrimaryTarget.ObjectID > 0)
	{
		AttackVal = GetAttackValue(kAbility, kTarget.PrimaryTarget);
		DefendVal = GetDefendValue(kAbility, kTarget.PrimaryTarget);
		TargetRoll = BaseValue + AttackVal - DefendVal;
		`log("Attack Value:" @ AttackVal @ "Defend Value:" @ DefendVal @ "Target Roll:" @ TargetRoll,,'XCom_HitRolls');
		if (TargetRoll < 100)
		{
			RandRoll = `SYNC_RAND(100);
			`log("Random roll:" @ RandRoll,,'XCom_HitRolls');
			if (RandRoll < TargetRoll)
				ResultContext.HitResult = eHit_Success;
			else
				ResultContext.HitResult = eHit_Miss;
		}
		else
		{
			ResultContext.HitResult = eHit_Success;
		}
		`log("Result:" @ ResultContext.HitResult,,'XCom_HitRolls');
		if (class'XComGameStateContext_Ability'.static.IsHitResultHit(ResultContext.HitResult))
		{
			ResultContext.StatContestResult = RollForEffectTier(kAbility, kTarget.PrimaryTarget, false);
		}
	}
	else
	{
		ResultContext.HitResult = eHit_Success;         //  mark success for the ability to go off
	}

	if( `CHEATMGR != None && `CHEATMGR.bDeadEyeStats )
	{
		`log("DeadEyeStats cheat forcing a hit.", true, 'XCom_HitRolls');
		ResultContext.HitResult = eHit_Success;
	}
	else if( `CHEATMGR != None && `CHEATMGR.bNoLuckStats )
	{
		`log("NoLuckStats cheat forcing a miss.", true, 'XCom_HitRolls');
		ResultContext.HitResult = eHit_Miss;
	}
	if( `CHEATMGR != None && `CHEATMGR.bForceAttackRollValue )
	{
		ResultContext.HitResult = eHit_Success;
		ResultContext.StatContestResult = `CHEATMGR.iForcedRollValue;
	}

	// Set up the lookups to more quickly find the correct Effects values based on Tiers
	StatContestOverrideInfo.MultiTargetEffectsNumHits.Length = 0;
	StatContestOverrideInfo.StatContestResultToEffectInfos.Length = 0;

	AbilityTemplate = kAbility.GetMyTemplate();
	SetStatContestResultToEffectInfos(AbilityTemplate.AbilityMultiTargetEffects, GetHighestTierPossible(AbilityTemplate.AbilityMultiTargetEffects), StatContestOverrideInfo);

	for (MultiTargetIndex = 0; MultiTargetIndex < kTarget.AdditionalTargets.Length; ++MultiTargetIndex)
	{
		`log("Roll against multi target" @ kTarget.AdditionalTargets[MultiTargetIndex].ObjectID,,'XCom_HitRolls');
		AttackVal = GetAttackValue(kAbility, kTarget.AdditionalTargets[MultiTargetIndex]);
		DefendVal = GetDefendValue(kAbility, kTarget.AdditionalTargets[MultiTargetIndex]);
		TargetRoll = BaseValue + AttackVal - DefendVal;
		`log("Attack Value:" @ AttackVal @ "Defend Value:" @ DefendVal @ "Target Roll:" @ TargetRoll,,'XCom_HitRolls');
		if (TargetRoll < 100)
		{
			RandRoll = `SYNC_RAND(100);
			`log("Random roll:" @ RandRoll,,'XCom_HitRolls');
			if (RandRoll < TargetRoll)
				ResultContext.MultiTargetHitResults.AddItem(eHit_Success);
			else
				ResultContext.MultiTargetHitResults.AddItem(eHit_Miss);
		}
		else
		{
			ResultContext.MultiTargetHitResults.AddItem(eHit_Success);
		}
		`log("Result:" @ ResultContext.HitResult,,'XCom_HitRolls');
		if (class'XComGameStateContext_Ability'.static.IsHitResultHit(ResultContext.HitResult))
		{
			StatContestResultValue = RollForEffectTier(kAbility, kTarget.AdditionalTargets[MultiTargetIndex], true);
			ResultContext.MultiTargetStatContestResult.AddItem(StatContestResultValue);

			if (ResultContext.MultiTargetEffectsOverrides.Length <= MultiTargetIndex)
			{
				// A new Override needs to be added
				ResultContext.MultiTargetEffectsOverrides.AddItem(EmptyOverriddenByType);
			}

			// Check to see if this value needs to be changed
			// Ignore if the StatContestResultValue is 0
			// AND
			// If there are no Effects that need to be Overridden
			// AND
			// This StatContestResultValue does not map to Effects that may be Overridden
			if ((StatContestResultValue > 0) &&
				(StatContestOverrideInfo.StatContestResultToEffectInfos.Length > StatContestResultValue) &&
				(StatContestOverrideInfo.StatContestResultToEffectInfos[StatContestResultValue].EffectIndices.Length > 0))
			{
				DoStatContestResultOverrides(MultiTargetIndex, StatContestResultValue, kAbility, StatContestOverrideInfo, ResultContext);
			}
		}
		else
		{
			ResultContext.MultiTargetStatContestResult.AddItem(0);
		}
	}
}

function int RollForEffectTier(XComGameState_Ability kAbility, StateObjectReference TargetRef, bool bMultiTarget)
{
	local X2AbilityTemplate AbilityTemplate;
	local int MaxTier, MiddleTier, Idx, AttackVal, DefendVal;
	local array<float> TierValues;
	local float TierValue, LowTierValue, HighTierValue, TierValueSum, RandRoll;

	AbilityTemplate = kAbility.GetMyTemplate();
	if (TargetRef.ObjectID > 0)
	{
		`log("=RollForEffectTier=");
		AttackVal = GetAttackValue(kAbility, TargetRef);
		DefendVal = GetDefendValue(kAbility, TargetRef);
		if (bMultiTarget)
			MaxTier = GetHighestTierPossible(AbilityTemplate.AbilityMultiTargetEffects);
		else
			MaxTier = GetHighestTierPossible(AbilityTemplate.AbilityTargetEffects);
		`log("Attack Value:" @ AttackVal @ "Defend Value:" @ DefendVal @ "Max Tier:" @ MaxTier,,'XCom_HitRolls');

		//  It's possible the ability only cares about success or failure and has no specified ladder of results
		if (MaxTier < 0)
		{
			return 0;
		}

		MiddleTier = MaxTier / 2 + MaxTier % 2;		
		TierValue = 100.0f / float(MaxTier);
		LowTierValue = TierValue * (float(DefendVal) / float(AttackVal));
		HighTierValue = TierValue * (float(AttackVal) / float(DefendVal));
		for (Idx = 1; Idx <= MaxTier; ++Idx)
		{			
			if (Idx < MiddleTier)
			{
				TierValues.AddItem(LowTierValue);
			}
			else if (Idx == MiddleTier)
			{
				TierValues.AddItem(TierValue);
			}
			else
			{
				TierValues.AddItem(HighTierValue);
			}			
			TierValueSum += TierValues[TierValues.Length - 1];
			`log("Tier" @ Idx $ ":" @ TierValues[TierValues.Length - 1],,'XCom_HitRolls');
		}
		//  Normalize the tier values
		for (Idx = 0; Idx < TierValues.Length; ++Idx)
		{
			TierValues[Idx] = TierValues[Idx] / TierValueSum;
			if (Idx > 0)
				TierValues[Idx] += TierValues[Idx - 1];

			`log("Normalized Tier" @ Idx $ ":" @ TierValues[Idx],,'XCom_HitRolls');
		}
		RandRoll = `SYNC_FRAND;
		`log("Random roll:" @ RandRoll,,'XCom_HitRolls');
		for (Idx = 0; Idx < TierValues.Length; ++Idx)
		{
			if (RandRoll < TierValues[Idx])
			{
				`log("Matched tier" @ Idx,,'XCom_HitRolls');
				return Idx + 1;     //  the lowest possible tier is 1, not 0
			}
		}
		`log("Matched highest tier",,'XCom_HitRolls');
		return TierValues.Length;
	}
	return 0;
}

protected function int GetHighestTierPossible(const array<X2Effect> TargetEffects)
{
	local int Highest, Idx;

	Highest = -1;
	for (Idx = 0; Idx < TargetEffects.Length; ++Idx)
	{
		//  ignore a minimum of 0 as the effect should always be applied
		if (TargetEffects[Idx].MinStatContestResult > 0 && TargetEffects[Idx].MinStatContestResult > Highest)
			Highest = TargetEffects[Idx].MinStatContestResult;

		//  ignore a maximum of 0 as the effect should always be applied (assuming min is also 0, but if it isn't, then that was already checked above)
		if (TargetEffects[Idx].MaxStatContestResult > 0 && TargetEffects[Idx].MaxStatContestResult > Highest)
			Highest = TargetEffects[Idx].MaxStatContestResult;
	}
	return Highest;
}

protected function SetStatContestResultToEffectInfos(const array<X2Effect> TargetEffects, int NumTiers, out StatContestOverrideData StatContestOverrideInfo)
{
	local int Idx, i;
	local bool bFoundAMaxNumberAllowedEffect;

	StatContestOverrideInfo.StatContestResultToEffectInfos.Length = NumTiers + 1;   // Just to make things easier, ignore the 0 index and use the StatResultContext values
	bFoundAMaxNumberAllowedEffect = false;

	StatContestOverrideInfo.MultiTargetEffectsNumHits.Length = 0;
	for (Idx = 0; Idx < TargetEffects.Length; ++Idx)
	{
		// This section is used to store data that may be needed for MultiTargetEffects that have a limited number of hits allowed
		// Ignore MinStatContestResults of 0
		if ((TargetEffects[Idx].MinStatContestResult > 0) && (TargetEffects[Idx].MultiTargetStatContestInfo.MaxNumberAllowed > 0))
		{
			bFoundAMaxNumberAllowedEffect = true;

			i = TargetEffects[Idx].MinStatContestResult;
			StatContestOverrideInfo.StatContestResultToEffectInfos[i].EffectIndices.AddItem(Idx);

			for (i = i + 1; i <= TargetEffects[Idx].MaxStatContestResult; ++i)
			{
				StatContestOverrideInfo.StatContestResultToEffectInfos[i].EffectIndices.AddItem(Idx);
			}
		}

		// Zero out the NumHits for this Effect
		StatContestOverrideInfo.MultiTargetEffectsNumHits.AddItem(0);
	}

	if (!bFoundAMaxNumberAllowedEffect)
	{
		// Clear the length since this is used to early out future checks
		StatContestOverrideInfo.StatContestResultToEffectInfos.Length = 0;
	}
}

protected function DoStatContestResultOverrides(int MultiTargetIndex, int StatContestResultValue, XComGameState_Ability kAbility, 
												out StatContestOverrideData StatContestOverrideInfo, out AbilityResultContext ResultContext)
{
	local int Index, EffectIdx, ReplaceWithIdx;
	local X2AbilityTemplate AbilityTemplate;
	local bool bContinueLooking;
	local int TypeIndex;
	local OverriddenEffectsInfo NewOverrideInfo;

	TypeIndex = ResultContext.MultiTargetEffectsOverrides[MultiTargetIndex].OverrideInfo.Find('OverrideType', 'EffectOverride_StatContest');
	if (TypeIndex == INDEX_NONE)
	{
		TypeIndex = ResultContext.MultiTargetEffectsOverrides[MultiTargetIndex].OverrideInfo.Length;
		NewOverrideInfo.OverrideType = 'EffectOverride_StatContest';
		ResultContext.MultiTargetEffectsOverrides[MultiTargetIndex].OverrideInfo.AddItem(NewOverrideInfo);
	}

	AbilityTemplate = kAbility.GetMyTemplate();

	for (Index = 0; Index < StatContestOverrideInfo.StatContestResultToEffectInfos[StatContestResultValue].EffectIndices.Length; ++Index)
	{
		// Loop over the Effects found at this StatContestResult and decide what effect should
		// actually be applied
		EffectIdx = StatContestOverrideInfo.StatContestResultToEffectInfos[StatContestResultValue].EffectIndices[Index];

		ReplaceWithIdx = EffectIdx;
		bContinueLooking = true;
		while ((ReplaceWithIdx != INDEX_NONE) &&
				(ReplaceWithIdx < StatContestOverrideInfo.MultiTargetEffectsNumHits.Length) &&
				bContinueLooking)
		{
			++StatContestOverrideInfo.MultiTargetEffectsNumHits[ReplaceWithIdx];

			// Continue Looking if the Effect has a MaxNumberAllowed (>0)
			// AND
			// That MaxNumberAllowed has been exceeded 
			bContinueLooking = (AbilityTemplate.AbilityMultiTargetEffects[ReplaceWithIdx].MultiTargetStatContestInfo.MaxNumberAllowed > 0) &&
							   (StatContestOverrideInfo.MultiTargetEffectsNumHits[ReplaceWithIdx] > AbilityTemplate.AbilityMultiTargetEffects[ReplaceWithIdx].MultiTargetStatContestInfo.MaxNumberAllowed);
			if (bContinueLooking)
			{
				// The max number of this Effect is applied, change what Effect will actually get applied here
				ReplaceWithIdx = AbilityTemplate.AbilityMultiTargetEffects[ReplaceWithIdx].MultiTargetStatContestInfo.EffectIdxToApplyOnMaxExceeded;
			}
		}

		if (EffectIdx != ReplaceWithIdx)
		{
			// This MultiTarget Effect has been applied too many times and needs to be replaced
			ResultContext.MultiTargetEffectsOverrides[MultiTargetIndex].OverrideInfo[TypeIndex].OverriddenEffects.AddItem(AbilityTemplate.AbilityMultiTargetEffects[EffectIdx]);
			if (ReplaceWithIdx != INDEX_NONE)
			{
				ResultContext.MultiTargetEffectsOverrides[MultiTargetIndex].OverrideInfo[TypeIndex].OverriddingEffects.AddItem(AbilityTemplate.AbilityMultiTargetEffects[ReplaceWithIdx]);
			}
		}
	}
}

DefaultProperties
{
	BaseValue = 75
}