//---------------------------------------------------------------------------------------
//  FILE:    X2Condition_MappingDecorator.uc
//  AUTHOR:  X2CommunityCore
//  PURPOSE: Remap return codes of a provided X2Condition.
//---------------------------------------------------------------------------------------
class X2Condition_MappingDecorator extends X2Condition;

struct MappingDecorationStruct
{
	var name OriginalCode;
	var name ReplacementCode;
};

var X2Condition InnerCondition;

var bool bUseCanEverBeValid;
var bool bReverseCanEverBeValid;

// If specified, will be used as the default return code for return codes that do not have mapping decoration config.
var name UnmappedCode;

var array<MappingDecorationStruct> MappingDecorations;

function AddMappingDecoration(const name OriginalCode, const name ReplacementCode)
{
	local MappingDecorationStruct NewMappingDecoration;

	NewMappingDecoration.OriginalCode = OriginalCode;
	NewMappingDecoration.ReplacementCode = ReplacementCode;

	MappingDecorations.AddItem(NewMappingDecoration);
}

private function name RemapCondition(const name OriginalCode)
{
	local int Index;

	Index = MappingDecorations.Find('OriginalCode', OriginalCode);

	if (Index != INDEX_NONE)
	{
		return MappingDecorations[Index].ReplacementCode;
	}
	return UnmappedCode == '' ? OriginalCode : UnmappedCode;
}

event name CallMeetsCondition(XComGameState_BaseObject kTarget) 
{
	return RemapCondition(InnerCondition.CallMeetsCondition(kTarget));
}

event name CallMeetsConditionWithSource(XComGameState_BaseObject kTarget, XComGameState_BaseObject kSource) 
{ 
	return RemapCondition(InnerCondition.CallMeetsConditionWithSource(kTarget, kSource));
}

event name CallAbilityMeetsCondition(XComGameState_Ability kAbility, XComGameState_BaseObject kTarget) 
{
	return RemapCondition(InnerCondition.CallAbilityMeetsCondition(kAbility, kTarget));
}

function bool CanEverBeValid(XComGameState_Unit SourceUnit, bool bStrategyCheck)
{
	local bool bCanEverBeValid;

	if (bUseCanEverBeValid)
	{	
		bCanEverBeValid = InnerCondition.CanEverBeValid(SourceUnit, bStrategyCheck);

		if (bReverseCanEverBeValid)
		{
			return !bCanEverBeValid;
		}
		return bCanEverBeValid;
	}
	return true;
}

defaultproperties
{
	bUseCanEverBeValid = true
}