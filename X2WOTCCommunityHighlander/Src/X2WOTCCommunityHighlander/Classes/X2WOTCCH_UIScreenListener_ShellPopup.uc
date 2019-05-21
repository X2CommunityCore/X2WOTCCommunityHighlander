/**
 * Issue #524
 * Check mods required and incompatible mods against the actually loaded mod and display a popup
 **/
class X2WOTCCH_UIScreenListener_ShellPopup extends UIScreenListener dependson (X2WOTCCH_ModDependencies);

event OnInit(UIScreen Screen)
{
	if(UIShell(Screen) != none)
	{
		Screen.SetTimer(1.5f, false, nameof(MakePopup), self);
	}
}

simulated function MakePopup()
{
	local TDialogueBoxData kDialogData;

	kDialogData.eType = eDialog_Warning;
	kDialogData.strText = GetText();
	kDialogData.fnCallback = OKClickedCB;

	kDialogData.strAccept = class'UIUtilities_Text'.default.m_strGenericAccept;

	`LOG(kDialogData.strText,, 'X2WOTCCommunityHighlander');

	if (kDialogData.strText != "")
	{
		`PRESBASE.UIRaiseDialog(kDialogData);
	}
}

simulated function OKClickedCB(Name eAction)
{
	`PRESBASE.PlayUISound(eSUISound_MenuSelect);
}

simulated function string GetText()
{
	local array<ModDependency> IncompatibleMods, RequiredMods;
	local ModDependency Dep;
	local string Buffer;

	class'X2WOTCCH_ModDependencies'.static.GetModDependencies(IncompatibleMods, RequiredMods);

	foreach IncompatibleMods(Dep)
	{
		Buffer $= class'UIUtilities_Text'.static.GetColoredText("["  $ Dep.ModName $ "]", eUIState_Good) @ 
			class'UIUtilities_Text'.static.GetColoredText(class'X2WOTCCH_ModDependencies'.default.ModIncompatible, eUIState_Disabled) @ 
			class'UIUtilities_Text'.static.GetColoredText(Join(Dep.Children, ", "), eUIState_Bad) $ "<br />";
	}

	foreach RequiredMods(Dep)
	{
		Buffer $= class'UIUtilities_Text'.static.GetColoredText("["  $ Dep.ModName $ "]", eUIState_Good) @ 
			class'UIUtilities_Text'.static.GetColoredText(class'X2WOTCCH_ModDependencies'.default.ModRequired, eUIState_Disabled) @ 
			class'UIUtilities_Text'.static.GetColoredText(Join(Dep.Children, ", "), eUIState_Warning) $ "<br />";
	}

	return Buffer;
}

function string Join(array<string> StringArray, string Delimiter, optional bool bIgnoreBlanks = true)
{
	local string Result;

	JoinArray(StringArray, Result, Delimiter, bIgnoreBlanks);

	return Result;
}