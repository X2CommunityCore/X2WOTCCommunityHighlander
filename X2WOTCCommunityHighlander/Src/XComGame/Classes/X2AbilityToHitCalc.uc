//---------------------------------------------------------------------------------------
//  FILE:    X2AbilityToHitCalc.uc
//  AUTHOR:  Joshua Bouscher
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2AbilityToHitCalc extends Object
	abstract
	editinlinenew
	hidecategories(Object);

var() array<ShotModifierInfo> HitModifiers;       // Configured in the ability template to provide always-on modifiers.


function RollForAbilityHit(XComGameState_Ability kAbility, AvailableTarget kTarget, out AbilityResultContext ResultContext);
protected function int GetHitChance(XComGameState_Ability kAbility, AvailableTarget kTarget, optional out ShotBreakdown m_ShotBreakdown, optional bool bDebugLog=false);
function bool NoGameStateOnMiss() { return false; }

function AddHitModifier(const int ModValue, const string ModReason, optional EAbilityHitResult ModType=eHit_Success)
{
	local ShotModifierInfo Mod;
	Mod.Value = ModValue;
	Mod.Reason = ModReason;
	Mod.ModType = ModType;
	HitModifiers.AddItem(Mod);
}

function int GetShotBreakdown(XComGameState_Ability kAbility, AvailableTarget kTarget, optional out ShotBreakdown m_ShotBreakdown, optional bool bDebugLog = false)
{
	GetHitChance(kAbility, kTarget, m_ShotBreakdown, bDebugLog);
	return m_ShotBreakdown.FinalHitChance;
}

//  Inside of GetHitChance, m_ShotBreakdown should be initially reset, then all modifiers to the shot should be added via this function.
protected function AddModifier(const int ModValue, const string ModReason, out ShotBreakdown m_ShotBreakdown, EAbilityHitResult ModType=eHit_Success, bool bDebugLog = false)
{
	local ShotModifierInfo Mod;

	switch(ModType)
	{
	case eHit_Miss:
		//  Miss should never be modified, only Success
		`assert(false);
		return;
	}

	if (ModValue != 0)
	{
		Mod.ModType = ModType;
		Mod.Value = ModValue;
		Mod.Reason = ModReason;
		m_ShotBreakdown.Modifiers.AddItem(Mod);
		m_ShotBreakdown.ResultTable[ModType] += ModValue;
		m_ShotBreakdown.FinalHitChance = m_ShotBreakdown.ResultTable[eHit_Success];
	}
	`log("Modifying" @ ModType @ (ModValue >= 0 ? "+" : "") $ ModValue @ "(" $ ModReason $ "), New hit chance:" @ m_ShotBreakdown.FinalHitChance, bDebugLog, 'XCom_HitRolls');
}

protected function FinalizeHitChance(out ShotBreakdown m_ShotBreakdown, bool bDebugLog = false)
{
	local int i;
	local EAbilityHitResult HitResult;
	local float GrazeScale;
	local int FinalGraze;

	// Start Issue #555
	if (TriggerOverrideFinalHitChance(m_ShotBreakdown))
	{
		return;
	}
	// End Issue #555

	`log("==" $ GetFuncName() $ "==\n", bDebugLog, 'XCom_HitRolls');
	`log("Starting values...", bDebugLog, 'XCom_HitRolls');
	for (i = 0; i < eHit_MAX; ++i)
	{
		HitResult = EAbilityHitResult(i);
		`log(HitResult $ ":" @ m_ShotBreakdown.ResultTable[i], bDebugLog, 'XCom_HitRolls');
	}

	m_ShotBreakdown.FinalHitChance = m_ShotBreakdown.ResultTable[eHit_Success];
	//  if crit goes negative, hit would get a boost, so restrict it to 0
	if (m_ShotBreakdown.ResultTable[eHit_Crit] < 0)
		m_ShotBreakdown.ResultTable[eHit_Crit] = 0;
	//  cap success at 100 so it can be fully overridden by crit
	m_ShotBreakdown.ResultTable[eHit_Success] = min(m_ShotBreakdown.ResultTable[eHit_Success], 100);
	//  Crit is folded into the chance to hit, so lower accordingly
	m_ShotBreakdown.ResultTable[eHit_Success] -= m_ShotBreakdown.ResultTable[eHit_Crit];
	//  Graze is scaled against Success - but ignored if success is 100%
	if (m_ShotBreakdown.ResultTable[eHit_Graze] > 0) 
	{
		if (m_ShotBreakdown.FinalHitChance < 100)
		{
			GrazeScale = float(m_ShotBreakdown.ResultTable[eHit_Graze]) / 100.0f;
			GrazeScale *= float(m_ShotBreakdown.FinalHitChance);
			FinalGraze = Round(GrazeScale);
			m_ShotBreakdown.ResultTable[eHit_Success] -= FinalGraze;
			m_ShotBreakdown.ResultTable[eHit_Graze] = FinalGraze;
		}
		else
		{
			m_ShotBreakdown.ResultTable[eHit_Graze] = 0;
		}
	}

	if (m_ShotBreakdown.FinalHitChance >= 100)
	{
		m_ShotBreakdown.ResultTable[eHit_Miss] = 0;
	}
	else
	{
		m_ShotBreakdown.ResultTable[eHit_Miss] = 100 - m_ShotBreakdown.FinalHitChance;
	}
	
	`log("Calculated values...", bDebugLog, 'XCom_HitRolls');
	for (i = 0; i < eHit_MAX; ++i)
	{
		HitResult = EAbilityHitResult(i);
		`log(HitResult $ ":" @ m_ShotBreakdown.ResultTable[i], bDebugLog, 'XCom_HitRolls');
	}
	`log("Final hit chance (success + crit + graze) =" @ m_ShotBreakdown.FinalHitChance, bDebugLog, 'XCom_HitRolls');

	//"Negative chance to hit" is used as a token in UI code - don't ever report that.
	if (m_ShotBreakdown.FinalHitChance < 0)
	{
		`log("FinalHitChance was less than 0 (" $ m_ShotBreakdown.FinalHitChance $ ") and was clamped to avoid confusing the UI (@btopp).", bDebugLog, 'XCom_HitRolls');
		m_ShotBreakdown.FinalHitChance = 0;
	}
}

// Start Issue #555
//
// Fires an 'OverrideFinalHitChance' event that allows listeners to override
// the final shot breakdown for an ability. LW2 uses this to implement its
// graze band mechanic for example.
//
// The event takes the form:
//
//  {
//     ID: OverrideFinalHitChance,
//     Data: [out bool OverrideHitChance, inout CHShotBreakdown ShotBreakdown],
//     Source: self (X2AbilityToHitCalc)
//  }
//
function bool TriggerOverrideFinalHitChance(out ShotBreakdown ShotBreakdown)
{
	local XComLWTuple OverrideTuple;
	local CHShotBreakdownWrapper Wrapper;

	// As ShotBreakdown is a struct and its default behavior is to pass by value,
	// wrap it in a pass-by-reference object so we can see the listeners' changes.
	Wrapper = new class'CHShotBreakdownWrapper';
	Wrapper.m_ShotBreakdown = ShotBreakdown;

	//set up a Tuple for return value - true means the to-hit calcs were overridden, so you should simply exit
	OverrideTuple = new class'XComLWTuple';
	OverrideTuple.Id = 'OverrideFinalHitChance';
	OverrideTuple.Data.Add(2);
	OverrideTuple.Data[0].kind = XComLWTVBool;
	OverrideTuple.Data[0].b = false;
	OverrideTuple.Data[1].kind = XComLWTVObject;
	OverrideTuple.Data[1].o = Wrapper;
	`XEVENTMGR.TriggerEvent('OverrideFinalHitChance', OverrideTuple, self);

	// Again, as structs are pass by value, ShotBreakdown itself hasn't been
	// modified by the listeners, so we have to copy over the updated values.
	ShotBreakdown = Wrapper.m_ShotBreakdown;
	return OverrideTuple.Data[0].b;
}