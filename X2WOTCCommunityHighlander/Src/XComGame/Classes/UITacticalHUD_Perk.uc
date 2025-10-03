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
	// Start Issue #1509
	// 
	// Adds an event that allows listeners to override the icon color
	// To achieve this, the default case has been decoupled from the 'eAbilitySource_Item' and 'eAbilitySource_Standard' cases.
		Icon.SetBGColorState(eUIState_Normal);
	
	default:
		TriggerOverrideEffectIconColor(Summary);
	// End Issue #1509
	}
}

// Start Issue #1509
/// HL-Docs: feature:OverrideEffectIconColor; issue:1509; tags:tactical
/// The `OverrideEffectIconColor` event allows mods to override the background and foreground
/// colors of icons from `X2Effect_Persistent` set as `ePerkBuff_Passive`.
/// The "background" color is hexadecimal string for the color of the icon itself, and normally varies 
/// depending on the `AbilitySourceName` property set on the `X2Effect_Persistent`
/// The "foreground" color is normally always black.
/// Default colors used by the game can be found in the `UIUtilities_Colors` class.
///
/// Listeners should use the Effect's `AbilitySourceName` provided in the `EventData` as a filter
/// to ensure maximum compatibility.
///
/// Performance note: this event gets triggered *a lot*, 
/// so try to avoid complex computations in listeners to reduce the performance hit. 
///
/// ```event
/// EventID: OverrideEffectIconColor,
/// EventData: [in name AbilitySourceName, out string BackgroundColor, out string ForegroundColor],
/// EventSource: none,
/// NewGameState: none
/// ```
simulated function TriggerOverrideEffectIconColor(UISummary_UnitEffect Summary)
{
	local XComLWTuple Tuple;
	local X2EventManager EventMGR;

	Tuple = new class'XComLWTuple';
	Tuple.Data.Add(3);
	
	Tuple.Id = 'OverrideEffectIconColor';
	Tuple.Data[0].kind = XComLWTVName;
	Tuple.Data[0].n = Summary.AbilitySourceName;
	Tuple.Data[1].kind = XComLWTVString;
	Tuple.Data[1].s = "";
	Tuple.Data[2].kind = XComLWTVString;
	Tuple.Data[2].s = "";

	EventMGR = `XEVENTMGR;
	EventMGR.TriggerEvent('OverrideEffectIconColor', Tuple);
	
	if (Tuple.Data[1].s != "")
	{
		Icon.SetBGColor(Tuple.Data[1].s);
	}
	else
	{
		// no color code was provided, set the original "default" eUIState
		Icon.SetBGColorState(eUIState_Normal);
	}
	
	// only set the ForegroundColor if a custom one was provided by the event
	if (Tuple.Data[2].s != "")
	{
		Icon.SetForegroundColor(Tuple.Data[2].s);
	}
}
// End Issue #1509

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