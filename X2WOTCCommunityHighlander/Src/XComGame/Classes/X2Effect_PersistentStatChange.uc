//---------------------------------------------------------------------------------------
//  FILE:    X2Effect_PersistentStatChange.uc
//  AUTHOR:  Timothy Talley
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2Effect_PersistentStatChange extends X2Effect_ModifyStats;

var array<StatChange>	m_aStatChanges;

simulated function AddPersistentStatChange(ECharStatType StatType, float StatAmount, optional EStatModOp InModOp=MODOP_Addition )
{
	local StatChange NewChange;
	
	NewChange.StatType = StatType;
	NewChange.StatAmount = StatAmount;
	NewChange.ModOp = InModOp;

	m_aStatChanges.AddItem(NewChange);
}

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local int idx;
	local StatChange Change;

	NewEffectState.StatChanges = m_aStatChanges;

	for (idx = 0; idx < NewEffectState.StatChanges.Length; ++idx)
	{
		Change = NewEffectState.StatChanges[ idx ];

		if (`SecondWaveEnabled('BetaStrike') && (Change.StatType == eStat_HP) && (Change.ModOp == MODOP_Addition))
		{
			NewEffectState.StatChanges[ idx ].StatAmount *= class'X2StrategyGameRulesetDataStructures'.default.SecondWaveBetaStrikeHealthMod;
		}
	}

	super.OnEffectAdded(ApplyEffectParameters, kNewTargetState, NewGameState, NewEffectState);
}