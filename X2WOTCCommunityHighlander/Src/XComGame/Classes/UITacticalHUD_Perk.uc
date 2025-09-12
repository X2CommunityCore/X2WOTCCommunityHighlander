//----------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UITacticalHUD_Perk.uc
//  AUTHOR:  Sam Batista
//  PURPOSE: Containers holding current soldier passive ability icons.
//----------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//----------------------------------------------------------------------------

class UITacticalHUD_Perk extends UIPanel;

var UIIcon Icon;

simulated function UITacticalHUD_Perk InitPerkItem(optional name InitName, optional name InitLibID)
{
	InitPanel(InitName, InitLibID);

	// Link up with existing IconControl in AbilityItem movieclip
	Icon = Spawn(class'UIIcon', self);
	Icon.InitIcon('IconMC',,false, true, 36); // 'IconMC' matches instance name of control in Flash's 'AbilityItem' Symbol
	
	// Start off hidden, visibility is controlled by PerkContainer.as
	Hide();
	return self;
}

simulated function UpdateData(const out UISummary_UnitEffect Summary)
{
	Icon.LoadIcon(Summary.Icon);
		
	//Key the color of the ability icon on the source of the ability
	switch(Summary.AbilitySourceName)
	{
	case 'eAbilitySource_Perk':
		Icon.SetBGColorState(eUIState_Warning);
		break;

	case 'eAbilitySource_Debuff':
		Icon.SetBGColorState(eUIState_Bad);
		break;

	case 'eAbilitySource_Psionic':
		Icon.SetBGColorState(eUIState_Psyonic);
		break;

	case 'eAbilitySource_Commander': 
		Icon.SetBGColorState(eUIState_Good);
		break;

	case 'eAbilitySource_Item':
	case 'eAbilitySource_Standard':
	default:
		Icon.SetBGColorState(eUIState_Normal);
	}
}

simulated function OnMouseEvent(int cmd, array<string> args)
{
	switch(cmd)
	{
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_IN:
		`log("Perk '" $ MCName $ "' mouse in",,'uixcom');
		break;
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_OUT:
		`log("Perk '" $ MCName $ "' mouse out",,'uixcom');
		break;
	}
}

defaultproperties
{
	LibID = "PerkItem";
	bProcessesMouseEvents = true;
	bAnimateOnInit = false;
}