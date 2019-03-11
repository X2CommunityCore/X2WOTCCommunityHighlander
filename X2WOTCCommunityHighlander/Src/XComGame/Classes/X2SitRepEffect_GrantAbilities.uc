//---------------------------------------------------------------------------------------
//  FILE:    X2SitRepEffect_GrantAbilities.uc
//  AUTHOR:  David Burchanowski  --  11/1/2016
//  PURPOSE: Allows sitreps to give abilities to units
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2SitRepEffect_GrantAbilities extends X2SitRepEffectTemplate;

var array<name> CharacterTemplateNames; // Characters to grant abilities to
var array<name> AbilityTemplateNames; // Abilities to grant
var array<ETeam> Teams; //CHL issue #445 allow mods to decide which team(s) receive this ability

var bool GrantToSoldiers; // If true, will grant the specified abilities to all soldier classes

// If you need differet/more precise control of which units get which abilities, you can override
// this function with a subclass
function GetAbilitiesToGrant(XComGameState_Unit UnitState, out array<name> AbilityTemplates)
{
	local bool GrantToAllUnits;

	AbilityTemplates.Length = 0;
	
	GrantToAllUnits = CharacterTemplateNames.Length == 0 && GrantToSoldiers == false;
	if( GrantToAllUnits
		|| CharacterTemplateNames.Find(UnitState.GetMyTemplateName()) != INDEX_NONE
		|| (GrantToSoldiers && UnitState.IsSoldier()))
	{
		AbilityTemplates = AbilityTemplateNames;
	}
}