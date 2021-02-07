//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    X2SoldierClassTemplateManager.uc
//  AUTHOR:  Timothy Talley  --  01/18/2014
//---------------------------------------------------------------------------------------
//  Copyright (c) 2014 Firaxis Games Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class X2SoldierClassTemplateManager extends X2DataTemplateManager
	native(Core) config(ClassData);

var config name     DefaultSoldierClass;
var config int      NickNameRank;
var config array<SoldierClassAbilityType> ExtraCrossClassAbilities;
var config array<SoldierClassStatType> GlobalStatProgression;           //  used for every rank > 0

native static function X2SoldierClassTemplateManager GetSoldierClassTemplateManager();

function bool AddSoldierClassTemplate(X2SoldierClassTemplate Template, bool ReplaceDuplicate = false)
{
	return AddDataTemplate(Template, ReplaceDuplicate);
}

function X2SoldierClassTemplate FindSoldierClassTemplate(name DataName)
{
	local X2DataTemplate kTemplate;

	kTemplate = FindDataTemplate(DataName);
	if (kTemplate != none)
		return X2SoldierClassTemplate(kTemplate);
	return none;
}

function array<X2SoldierClassTemplate> GetAllSoldierClassTemplates(optional bool bExcludeMultiplayer = true)
{
	local array<X2SoldierClassTemplate> arrClassTemplates;
	local X2DataTemplate Template;
	local X2SoldierClassTemplate ClassTemplate;

	foreach IterateTemplates(Template, none)
	{
		ClassTemplate = X2SoldierClassTemplate(Template);

		if(ClassTemplate != none)
		{
			if(!bExcludeMultiplayer || !ClassTemplate.bMultiplayerOnly)
			{
				arrClassTemplates.AddItem(ClassTemplate);
			}
		}
	}

	return arrClassTemplates;
}

function array<SoldierClassAbilityType> GetCrossClassAbilities(optional X2SoldierClassTemplate ExcludeClass)
{
	local X2AbilityTemplateManager AbilityMgr;
	local X2AbilityTemplate AbilityTemplate;
	local array<X2SoldierClassTemplate> arrClassTemplates;
	local X2SoldierClassTemplate ClassTemplate;
	local array<SoldierClassAbilityType> CrossClassAbilities, AbilityTree;
	local int idx;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	arrClassTemplates = GetAllSoldierClassTemplates();
	CrossClassAbilities.Length = 0;

	foreach arrClassTemplates(ClassTemplate)
	{
		if(ClassTemplate.DataName != DefaultSoldierClass && ClassTemplate != ExcludeClass && ClassTemplate.bAllowAWCAbilities)
		{
			AbilityTree = ClassTemplate.GetAllPossibleAbilities();
			for(idx = 0; idx < AbilityTree.Length; idx++)
			{
				AbilityTemplate = AbilityMgr.FindAbilityTemplate(AbilityTree[idx].AbilityName);

				if(AbilityTemplate != none && AbilityTemplate.bCrossClassEligible && CrossClassAbilities.Find('AbilityName', AbilityTree[idx].AbilityName) == INDEX_NONE)
				{
					CrossClassAbilities.AddItem(AbilityTree[idx]);
				}
			}
		}
	}

	for(idx = 0; idx < default.ExtraCrossClassAbilities.Length; idx++)
	{
		AbilityTemplate = AbilityMgr.FindAbilityTemplate(default.ExtraCrossClassAbilities[idx].AbilityName);

		if(AbilityTemplate != none && AbilityTemplate.bCrossClassEligible && CrossClassAbilities.Find('AbilityName', default.ExtraCrossClassAbilities[idx].AbilityName) == INDEX_NONE)
		{
			CrossClassAbilities.AddItem(default.ExtraCrossClassAbilities[idx]);
		}
	}

	return CrossClassAbilities;
}

// Start Issue #62
/// HL-Docs: feature:GetCrossClassAbilities_CH; issue:62; tags:
/// The CH variant of GetCrossClassAbilities compared to vanilla does two things differently:
///  - Adds a check to ensure that the ability to be added to the CrossClassAbilities list isn't already
///    in the soldiers default ability tree.
///  - This variant supersedes issue #30 by checking against the actual abilities in the current soldiers
///    tree, instead of comparing against all the potential abilities the soldier could have had available.
///    This is especially important when classes uses the RandomAbilityDecks, since otherwise in the worst
///    case scenario, you could end up with no available cross class abilities.
///
/// The old function is kept in case mods call it, but is otherwise ignored
/// throughout the XComGame codebase
function array<SoldierClassAbilityType> GetCrossClassAbilities_CH(array <SoldierRankAbilities> SoldierAbilityTree)	
{
	local X2AbilityTemplateManager AbilityMgr;
	local X2AbilityTemplate AbilityTemplate;
	local array<X2SoldierClassTemplate> arrClassTemplates;
	local X2SoldierClassTemplate ClassTemplate;
	local array<SoldierClassAbilityType> CrossClassAbilities, AbilityTree;
	local int idx;
	
	// Variables for Issue #62
	local array<SoldierClassAbilityType> CurrentSoldierAbilities;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	arrClassTemplates = GetAllSoldierClassTemplates();
	CrossClassAbilities.Length = 0;

	if (SoldierAbilityTree.Length > 0)
		CurrentSoldierAbilities = GetAllCurrentSoldierAbilities(SoldierAbilityTree);

	foreach arrClassTemplates(ClassTemplate)
	{
		if(ClassTemplate.DataName != DefaultSoldierClass && ClassTemplate.bAllowAWCAbilities)
		{
			AbilityTree = ClassTemplate.GetAllPossibleAbilities();
			for(idx = 0; idx < AbilityTree.Length; idx++)
			{
				AbilityTemplate = AbilityMgr.FindAbilityTemplate(AbilityTree[idx].AbilityName);

				if(AbilityTemplate != none && AbilityTemplate.bCrossClassEligible && CrossClassAbilities.Find('AbilityName', AbilityTree[idx].AbilityName) == INDEX_NONE)
				{
					if (CurrentSoldierAbilities.Find('AbilityName', AbilityTree[idx].AbilityName) == INDEX_NONE)
					{
						CrossClassAbilities.AddItem(AbilityTree[idx]);
					}
				}
			}
		}
	}

	for(idx = 0; idx < default.ExtraCrossClassAbilities.Length; idx++)
	{
		AbilityTemplate = AbilityMgr.FindAbilityTemplate(default.ExtraCrossClassAbilities[idx].AbilityName);

		if(AbilityTemplate != none && AbilityTemplate.bCrossClassEligible && CrossClassAbilities.Find('AbilityName', default.ExtraCrossClassAbilities[idx].AbilityName) == INDEX_NONE)
		{
			if (CurrentSoldierAbilities.Find('AbilityName', default.ExtraCrossClassAbilities[idx].AbilityName) == INDEX_NONE)
			{
				CrossClassAbilities.AddItem(default.ExtraCrossClassAbilities[idx]);
			}
		}
	}

	return CrossClassAbilities;
}

// Truncates the list of ranks each containing a list abilities into a single list
function array<SoldierClassAbilityType> GetAllCurrentSoldierAbilities(array <SoldierRankAbilities> SoldierAbilityTree)
{
	local array<SoldierClassAbilityType> CurrentSoldierAbilities;
	local int i, j;

	for(i = 0; i < SoldierAbilityTree.Length; i++)
	{
		for(j = 0; j < SoldierAbilityTree[i].Abilities.Length; j++)
		{
			CurrentSoldierAbilities.AddItem(SoldierAbilityTree[i].Abilities[j]);
		}
	}

	return CurrentSoldierAbilities;
}
// End Issue #62

DefaultProperties
{
	TemplateDefinitionClass=class'X2SoldierClass'
}
