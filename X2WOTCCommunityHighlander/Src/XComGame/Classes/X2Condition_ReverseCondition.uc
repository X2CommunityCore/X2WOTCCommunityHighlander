//---------------------------------------------------------------------------------------
//  FILE:    X2Condition_ReverseCondition.uc
//  AUTHOR:  X2CommunityCore
//  PURPOSE: Reverse return code output of a provided X2Condition.
//---------------------------------------------------------------------------------------
class X2Condition_ReverseCondition extends X2Condition_MappingDecorator;

defaultproperties
{
	bReverseCanEverBeValid = true

	MappingDecorations(0) = (OriginalCode = "AA_Success", ReplacementCode = "AA_AbilityUnavailable")

	UnmappedCode = "AA_Success"
}