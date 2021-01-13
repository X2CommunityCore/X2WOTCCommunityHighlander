/**
 * Issue #524
 * Check mods required and incompatible mods against the actually loaded mod and display a popup for each mod
 **/
class X2WOTCCH_UIScreenListener_ShellPopup
	extends UIScreenListener
	dependson (X2WOTCCH_ModDependencies)
	config (X2WOTCCommunityHighlander_NullConfig);


var config array<name> HideIncompatibleModWarnings;
var config array<name> HideRequiredModWarnings;

// Single variable for Issue #909
var config array<name> HideRequiredNewerCHLVersionModWarnings;

event OnInit(UIScreen Screen)
{
	// if UIShell(Screen).DebugMenuContainer is set do NOT show since were not on the final shell
	if(UIShell(Screen) != none && UIShell(Screen).DebugMenuContainer == none)
	{
		Screen.SetTimer(2.5f, false, nameof(IncompatibleModsPopups), self);
		Screen.SetTimer(2.6f, false, nameof(RequiredModsPopups), self);
		Screen.SetTimer(2.7f, false, nameof(ModsRequireNewerCHLVersionPopups), self);
	}
}

simulated function IncompatibleModsPopups()
{
	local TDialogueBoxData kDialogData;
	local array<ModDependency> IncompatibleMods;
	local ModDependency Dep;
	local X2WOTCCH_DialogCallbackData CallbackData;
	local int Index;

	IncompatibleMods = class'X2WOTCCH_ModDependencies'.static.GetIncompatbleMods();

	foreach IncompatibleMods(Dep)
	{
		Index = HideIncompatibleModWarnings.Find(Dep.DLCIdentifier);

		if (Index == INDEX_NONE && Dep.ModName != "" && Dep.Children.Length > 0)
		{
			CallbackData = new class'X2WOTCCH_DialogCallbackData';
			CallbackData.DependencyData = Dep;

			kDialogData.strTitle = Dep.ModName @ class'X2WOTCCH_ModDependencies'.default.ModIncompatiblePopupTitle;
			kDialogData.eType = eDialog_Warning;
			kDialogData.strText = GetIncompatibleModsText(Dep);
			kDialogData.fnCallbackEx = IncompatibleModsCB;
			kDialogData.strAccept = class'X2WOTCCH_ModDependencies'.default.DisablePopup;
			kDialogData.strCancel = class'UIUtilities_Text'.default.m_strGenericAccept;
			kDialogData.xUserData = CallbackData;

			`LOG(kDialogData.strText,, 'X2WOTCCommunityHighlander');

			`PRESBASE.UIRaiseDialog(kDialogData);
		}
	}
}

simulated function RequiredModsPopups()
{
	local TDialogueBoxData kDialogData;
	local array<ModDependency> RequiredMods;
	local ModDependency Dep;
	local X2WOTCCH_DialogCallbackData CallbackData;
	local int Index;

	RequiredMods = class'X2WOTCCH_ModDependencies'.static.GetRequiredMods();

	foreach RequiredMods(Dep)
	{
		Index = HideRequiredModWarnings.Find(Dep.DLCIdentifier);
		if (Index == INDEX_NONE && Dep.ModName != "" && Dep.Children.Length > 0)
		{
			CallbackData = new class'X2WOTCCH_DialogCallbackData';
			CallbackData.DependencyData = Dep;

			kDialogData.strTitle = Dep.ModName @ class'X2WOTCCH_ModDependencies'.default.ModRequiredPopupTitle;
			kDialogData.eType = eDialog_Warning;
			kDialogData.strText = GetRequiredModsText(Dep);
			kDialogData.fnCallbackEx = RequiredModsCB;
			kDialogData.strAccept = class'X2WOTCCH_ModDependencies'.default.DisablePopup;
			kDialogData.strCancel = class'UIUtilities_Text'.default.m_strGenericAccept;
			kDialogData.xUserData = CallbackData;

			`LOG(kDialogData.strText,, 'X2WOTCCommunityHighlander');

			`PRESBASE.UIRaiseDialog(kDialogData);
		}
	}
}

simulated function IncompatibleModsCB(Name eAction, UICallbackData xUserData)
{
	local X2WOTCCH_DialogCallbackData CallbackData;

	if (eAction == 'eUIAction_Accept')
	{
		CallbackData = X2WOTCCH_DialogCallbackData(xUserData);
		HideIncompatibleModWarnings.AddItem(CallbackData.DependencyData.DLCIdentifier);

		`PRESBASE.PlayUISound(eSUISound_MenuSelect);
		
		self.SaveConfig();
	}
	else
	{
		`PRESBASE.PlayUISound(eSUISound_MenuSelect);
	}
}

simulated function RequiredModsCB(Name eAction, UICallbackData xUserData)
{
	local X2WOTCCH_DialogCallbackData CallbackData;

	if (eAction == 'eUIAction_Accept')
	{
		CallbackData = X2WOTCCH_DialogCallbackData(xUserData);
		HideRequiredModWarnings.AddItem(CallbackData.DependencyData.DLCIdentifier);

		`PRESBASE.PlayUISound(eSUISound_MenuSelect);
		
		self.SaveConfig();
	}
	else
	{
		`PRESBASE.PlayUISound(eSUISound_MenuSelect);
	}
}

simulated function string GetIncompatibleModsText(ModDependency Dep)
{
	return class'UIUtilities_Text'.static.GetColoredText(Repl(class'X2WOTCCH_ModDependencies'.default.ModIncompatible, "%s", Dep.ModName, true), eUIState_Header) $ "\n\n" $
			class'UIUtilities_Text'.static.GetColoredText(MakeBulletList(Dep.Children), eUIState_Bad) $ "\n";
}

simulated function string GetRequiredModsText(ModDependency Dep)
{
	return class'UIUtilities_Text'.static.GetColoredText(Repl(class'X2WOTCCH_ModDependencies'.default.ModRequired, "%s", Dep.ModName, true), eUIState_Header) $ "\n\n" $
			class'UIUtilities_Text'.static.GetColoredText(MakeBulletList(Dep.Children), eUIState_Bad) $ "\n";
}

function static string MakeBulletList(array<string> List)
{
	local string Buffer;
	local int Index;

	if (List.Length == 0)
	{
		return "";
	}

	Buffer = "<ul>";
	for(Index=0; Index < List.Length; Index++)
	{
		Buffer $= "<li>" $ List[Index] $ "</li>";
	}
	Buffer $= "</ul>";
	
	return Buffer;
}

// Begin Issue #909
simulated function ModsRequireNewerCHLVersionPopups()
{
	local TDialogueBoxData            kDialogData;
	local X2WOTCCH_DialogCallbackData CallbackData;
	local int                         Index;
	local array<CHModDependency>      ModsForPopup;
	local CHModDependency             ModForPopup;
	local string                      strCurrentVersion;
	local string                      strRequiredVersion;

	class'X2WOTCCH_ModDependencies'.static.GetModsThatRequireNewerCHLVersion(ModsForPopup);
	strCurrentVersion = GetCurrentCHLVersionColoredText();
	
	foreach ModsForPopup(ModForPopup)
	{
		Index = HideRequiredNewerCHLVersionModWarnings.Find(ModForPopup.DLCIdentifier);

		if (Index == INDEX_NONE)
		{
			kDialogData.strTitle = class'X2WOTCCH_ModDependencies'.default.ModRequiresNewerHighlanderVersionTitle;

			strRequiredVersion = GetRequiredCHLVersionColoredText(ModForPopup.RequiredHighlanderVersion);
			kDialogData.strText = GetRequireNewerCHLVersionPopupText(ModForPopup, strCurrentVersion, strRequiredVersion);

			CallbackData = new class'X2WOTCCH_DialogCallbackData';
			CallbackData.DependencyData.DLCIdentifier = ModForPopup.DLCIdentifier;
			kDialogData.xUserData = CallbackData;
			kDialogData.fnCallbackEx = RequireNewerCHLVersionCB;
			kDialogData.strAccept = class'X2WOTCCH_ModDependencies'.default.DisablePopup;
			kDialogData.strCancel = class'UIUtilities_Text'.default.m_strGenericAccept;
			kDialogData.eType = eDialog_Warning;
			
			`PRESBASE.UIRaiseDialog(kDialogData);
		}
	}
}
static private function string GetRequireNewerCHLVersionPopupText(const out CHModDependency ModForPopup, string strCurrentVersion, string strRequiredVersion)
{
	local string strModDisplayName;
	
	strModDisplayName = ModForPopup.DisplayName == "" ? string(ModForPopup.DLCIdentifier) : ModForPopup.DisplayName;

	return class'X2WOTCCH_ModDependencies'.default.ModRequiresNewerHighlanderVersionText @ strModDisplayName $ "\n" $ 
	       strCurrentVersion $ 
		   strRequiredVersion $ "\n\n" $
           class'X2WOTCCH_ModDependencies'.default.ModRequiresNewerHighlanderVersionExtraText;
}
static private function string GetCurrentCHLVersionColoredText()
{
	local CHLVersionStruct CHLVersion;
	local string strVersionText;

	class'X2WOTCCH_ModDependencies'.static.GetCurrentCHLVersion(CHLVersion);

	strVersionText = CHLVersion.MajorVersion $ "." $ CHLVersion.MinorVersion $ "." $ CHLVersion.PatchVersion;
	
	return class'X2WOTCCH_ModDependencies'.default.CurrentHighlanderVersionTitle @ class'UIUtilities_Text'.static.GetColoredText(strVersionText, eUIState_Bad) $ "\n";
}
static private function string GetRequiredCHLVersionColoredText(const out CHLVersionStruct CHLVersion)
{
	local string strVersionText;

	strVersionText = CHLVersion.MajorVersion $ "." $ CHLVersion.MinorVersion $ "." $ CHLVersion.PatchVersion;
	
	return class'X2WOTCCH_ModDependencies'.default.RequiredHighlanderVersionTitle @ class'UIUtilities_Text'.static.GetColoredText(strVersionText, eUIState_Good);
}

simulated function RequireNewerCHLVersionCB(Name eAction, UICallbackData xUserData)
{
	local X2WOTCCH_DialogCallbackData CallbackData;

	if (eAction == 'eUIAction_Accept')
	{
		CallbackData = X2WOTCCH_DialogCallbackData(xUserData);
		HideRequiredNewerCHLVersionModWarnings.AddItem(CallbackData.DependencyData.DLCIdentifier);

		`PRESBASE.PlayUISound(eSUISound_MenuSelect);
		
		self.SaveConfig();
	}
	else
	{
		`PRESBASE.PlayUISound(eSUISound_MenuSelect);
	}
}
// End Issue #909