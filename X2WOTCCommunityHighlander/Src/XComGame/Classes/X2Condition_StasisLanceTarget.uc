class X2Condition_StasisLanceTarget extends X2Condition;

var() Name HackAbilityName;

event name CallMeetsCondition(XComGameState_BaseObject kTarget)
{
	local XComGameState_Unit UnitTarget;
	local X2CharacterTemplate CharacterTemplate;
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComTacticalCheatManager CheatMan;
	local array<Name> PossibleHackRewards;
	local bool TargetMustBeSKULLJACKED;

	UnitTarget = XComGameState_Unit(kTarget);
	if (UnitTarget == none)
	{
		return 'AA_NotAUnit';
	}

	if (UnitTarget.IsDead())
	{
		return 'AA_UnitIsDead';
	}

	if (UnitTarget.IsStasisLanced())
	{
		return 'AA_UnitIsImmune';
	}

	if( UnitTarget.IsTurret() )
	{
		return 'AA_UnitIsImmune';
	}

	PossibleHackRewards = UnitTarget.GetHackRewards(HackAbilityName);

	if( PossibleHackRewards.Length > 0 )
	{
		CheatMan = `CHEATMGR;
		if( CheatMan != None && CheatMan.bGoldenPathHacks )
		{
			return 'AA_Success';
		}

		TargetMustBeSKULLJACKED = false;

		History = `XCOMHISTORY;
		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom', true));

		if( XComHQ != None )
		{
			CharacterTemplate = UnitTarget.GetMyTemplate();
			// Advent captains are always SKULLJACKable only during the GP missions which requires it
			if( CharacterTemplate.CharacterGroupName == 'AdventCaptain' )
			{
				if( XComHQ.GetObjectiveStatus('T1_M2_S3_SKULLJACKCaptain') == eObjectiveState_InProgress ||
				   XComHQ.GetObjectiveStatus('T1_M3_KillCodex') == eObjectiveState_InProgress )
				{
					TargetMustBeSKULLJACKED = true;
				}
			}
			// Codex is SKULLJACKable only during the GP missions which requires it
			else if( CharacterTemplate.DataName == 'Cyberus' )
			{
				if( XComHQ.GetObjectiveStatus('T1_M5_SKULLJACKCodex') == eObjectiveState_InProgress ||
				   XComHQ.GetObjectiveStatus('T1_M6_KillAvatar') == eObjectiveState_InProgress )
				{
					TargetMustBeSKULLJACKED = true;
				}
			}
		}

		if( HackAbilityName == 'FinalizeSKULLJACK' )
		{
			if( TargetMustBeSKULLJACKED )
			{
				return 'AA_Success';
			}
		}
		// all advent are always SKULLMINEable
		else if( !TargetMustBeSKULLJACKED )
		{
			return 'AA_Success';
		}
	}

	return 'AA_UnitIsImmune';
}

event name CallMeetsConditionWithSource(XComGameState_BaseObject kTarget, XComGameState_BaseObject kSource)
{
	local XComGameState_Unit UnitSource, UnitTarget;

	UnitSource = XComGameState_Unit(kSource);
	UnitTarget = XComGameState_Unit(kTarget);

	if (UnitTarget == none || UnitSource == none)
		return 'AA_NotAUnit';

	if (!UnitTarget.IsEnemyUnit(UnitSource))
		return 'AA_UnitIsFriendly';

	return 'AA_Success';
}