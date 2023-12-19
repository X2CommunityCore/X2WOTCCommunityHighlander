class X2Effect_Pillar extends X2Effect_SpawnDestructible;

function int GetStartingNumTurns(const out EffectAppliedData ApplyEffectParameters)
{
	local XComGameState_Unit SourceUnit;

	SourceUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ApplyEffectParameters.SourceStateObjectRef.ObjectID));
	return SourceUnit.GetTemplarFocusLevel();
}

DefaultProperties
{
	EffectName = "Pillar"
	DuplicateResponse = eDupe_Allow
	bDestroyOnRemoval = true
}