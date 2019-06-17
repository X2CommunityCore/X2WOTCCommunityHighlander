//---------------------------------------------------------------------------------------
//  FILE:    X2SitRepEffectTemplate.uc
//  AUTHOR:  Joe Weinhoffer
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2SitRepEffectTemplate extends X2DataTemplate
	native(Core);

var protected const localized string FriendlyName; // Title of this SitRep Effect. e.g. "Longer Mission Timers"
var protectedwrite const localized string Description; // Effect description, e.g. "Timers on this mission increased by 2."

var int DifficultyModifier; // The amount the difficulty score of a mission will be modified when this effect is added

function string GetFriendlyName()
{
	if (FriendlyName != "")
	{
		return FriendlyName;
	}
	else
	{
		return string(DataName) $ " has no name!";
	}
}

// Override to allow the effect to modify whether or not the mission can be launched
function bool CanLaunchMission(XComGameState_MissionSite Mission, out string FailReason)
{
	return true;
}

// Override to allow the effect to modify the battle data state just before we transition to tactical gameplay
function ModifyPreMissionBattleDataState(XComGameState_BattleData BattleData);