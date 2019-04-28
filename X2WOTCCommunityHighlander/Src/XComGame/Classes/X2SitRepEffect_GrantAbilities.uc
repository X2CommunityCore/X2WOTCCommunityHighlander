//---------------------------------------------------------------------------------------
//  FILE:    X2SitRepEffect_GrantAbilities.uc
//  AUTHOR:  David Burchanowski  --  11/1/2016. CHL: Reworked by Xymanek
//  PURPOSE: Allows sitreps to give abilities to units
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
// Issue #445: Rework this class to be more sensible and flexible and document it better

class X2SitRepEffect_GrantAbilities extends X2SitRepEffectTemplate;

// Abilities to grant
var array<name> AbilityTemplateNames;

// If true, will grant to soldiers only. All other checks are ignored
// This is a bit weird, but that's how FXS implemeted it and we cannot change that
var bool GrantToSoldiers; 

// If GrantToSoldiers is false, the unit will be subjected to following tests.
// Note that if an array is empty, the check will be skipped

var array<name> CharacterTemplateNames; // List of characters templates that are allowed
var array<ETeam> Teams; // Issue #445: List of teams that are allowed
var bool RequireRobotic; // Issue #445

// If you need different/more precise control of which units get which abilities, you can override
// this function with a subclass
function GetAbilitiesToGrant(XComGameState_Unit UnitState, out array<name> AbilityTemplates)
{
	AbilityTemplates.Length = 0;
	
	if (GrantToSoldiers)
	{
		// Skip all checks and grant the abilities based on soldier or not (see above)
		
		if (UnitState.IsSoldier())
		{
			AbilityTemplates = AbilityTemplateNames;
		}

		return;
	}

	if (RequireRobotic && !UnitState.IsRobotic())
	{
		return;
	}

	if (CharacterTemplateNames.Length > 0 && CharacterTemplateNames.Find(UnitState.GetMyTemplateName()) == INDEX_NONE)
	{
		return;
	}

	if (Teams.Length > 0 && Teams.Find(UnitState.GetTeam()) == INDEX_NONE)
	{
		return;
	}

	// All checks passed
	AbilityTemplates = AbilityTemplateNames;
}