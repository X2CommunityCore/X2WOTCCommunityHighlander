//---------------------------------------------------------------------------------------
//  FILE:    X2SitRepTemplate.uc
//  AUTHOR:  David Burchanowski
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2SitRepTemplate extends X2DataTemplate
	native(Core) config(GameData);

var protected const localized string FriendlyName; // Title of this SitRep. e.g. "Fireteam"
var protectedwrite const localized string Description; // Full sitrep description, e.g. "The squad size on this mission is limited to 2 soldiers."

// Values for determining if this sitrep can be used in a particular situation
var config int MinimumForceLevel; // if == 0, no minimum
var config int MaximumForceLevel; // if == 0, no maximum
var config array<string> ValidMissionFamilies; // If specified, this sitrep is only valid for the specified mission families
var config array<string> ValidMissionTypes; // If specified, this sitrep is only valid for the specified mission types
var config StrategyRequirement StrategyReqs; // Allows limiting sitreps based on the state of the strategy game
var config array<string> ExcludePlotTypes; // If this sitrep is selected mission cannot take place on these plot types
var config array<name> ExcludeGameplayTags; // If any of these tags are active on the mission then this sitrep is invalid (tags need to be held by the mission state)

var config array<name> PositiveEffects; // names of effect templates for the sitrep that make the mission easier
var config array<name> NegativeEffects; // names of effect templates for the sitrep that make the mission harder

var config array<name> TacticalGameplayTags; // this may be better as an X2SitRepEffectTemplate. Time will tell.

var config bool bNegativeEffect; // is this sitrep a bad thing (so it should show red)
var config array<name> DisplayEffects; // Effects to show where they are displayed (other effects are hidden)

var config string SquadSelectNarrative;

var config bool bExcludeFromStrategy;
var config bool bExcludeFromChallengeMode;
var config bool bOverrideCivilianHostility; // If true, civilians are not hostile toward XCom.

function string GetFriendlyName()
{
	if(FriendlyName != "")
	{
		return FriendlyName;
	}
	else
	{
		return string(DataName) $ " has no title!";
	}
}

// Returns true if this sitrep can be used
function bool MeetsRequirements(XComGameState_MissionSite MissionState)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersAlien AlienHQ; 
	local XComGameState_HeadquartersXCom XComHQ; 
	local MissionDefinition MissionDef;
	local name GameplayTag;
	local int ForceLevel;
	local name Tag;

	History = `XCOMHISTORY;
	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));
	ForceLevel = AlienHQ.GetForceLevel();
	MissionDef = MissionState.GeneratedMission.Mission;

	if((MinimumForceLevel > 0 && ForceLevel < MinimumForceLevel) || (MaximumForceLevel > 0 && ForceLevel > MaximumForceLevel))
	{
		return false;
	}

	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	foreach TacticalGameplayTags(Tag)
	{
		if(XComHQ.TacticalGameplayTags.Find(Tag) != INDEX_NONE)
		{
			return false;
		}
	}

	if(ValidMissionTypes.Length > 0 && ValidMissionTypes.Find(MissionDef.sType) == INDEX_NONE)
	{
		return false;
	}

	if(ValidMissionFamilies.Length > 0 && ValidMissionFamilies.Find(MissionDef.MissionFamily) == INDEX_NONE)
	{
		return false;
	}

	foreach MissionState.TacticalGameplayTags(GameplayTag)
	{
		if(ExcludeGameplayTags.Find(GameplayTag) != INDEX_NONE)
		{
			return false;
		}
	}

	if(!XComHQ.MeetsAllStrategyRequirements(StrategyReqs))
	{
		return false;
	}

	return true;
}

static function bool CanLaunchMission(XComGameState_MissionSite Mission, out string FailReason)
{
	local X2SitRepEffectTemplate SitRepEffectTemplate;

	foreach class'X2SitRepTemplateManager'.static.IterateEffects(class'X2SitRepEffectTemplate', SitRepEffectTemplate, Mission.GeneratedMission.SitReps)
	{
		if(!SitRepEffectTemplate.CanLaunchMission(Mission, FailReason))
		{
			return false;
		}
	}

	return true;
}

static function ModifyPreMissionBattleDataState(XComGameState_BattleData BattleData, const out array<name> ActiveSitRepTemplateNames)
{
	local X2SitRepEffectTemplate SitRepEffectTemplate;

	foreach class'X2SitRepTemplateManager'.static.IterateEffects(class'X2SitRepEffectTemplate', SitRepEffectTemplate, ActiveSitRepTemplateNames)
	{
		SitRepEffectTemplate.ModifyPreMissionBattleDataState(BattleData);
	}
}

defaultproperties
{
}