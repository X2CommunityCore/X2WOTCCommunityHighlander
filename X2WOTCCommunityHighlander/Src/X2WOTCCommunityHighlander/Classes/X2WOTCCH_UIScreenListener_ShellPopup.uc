// Issue #524, Issue #511
// * Check mods required and incompatible mods against the actually loaded mod and display a popup for each mod
// * Check run order configuration errors and display popups
class X2WOTCCH_UIScreenListener_ShellPopup
	extends UIScreenListener
	dependson (X2WOTCCH_ModDependencies)
	config (X2WOTCCommunityHighlander_NullConfig);


var config array<name> HideIncompatibleModWarnings;
var config array<name> HideRequiredModWarnings;
var X2WOTCCH_ModDependencies DependencyChecker;

var config array<string> HideGroupWarnings;

var localized string CycleErrorTitle, CycleErrorText;
var localized string GroupErrorTitle, GroupErrorText;
var localized string BlameText;

event OnInit(UIScreen Screen)
{
	// if UIShell(Screen).DebugMenuContainer is set do NOT show since were not on the final shell
	if(UIShell(Screen) != none && UIShell(Screen).DebugMenuContainer == none)
	{
		DependencyChecker = new class'X2WOTCCH_ModDependencies';
		if (DependencyChecker.HasHLSupport())
		{
			DependencyChecker.Init();
			Screen.SetTimer(2.5f, false, nameof(IncompatibleModsPopups), self);
			Screen.SetTimer(2.6f, false, nameof(RequiredModsPopups), self);
		}
		Screen.SetTimer(2.7f, false, nameof(RunOrderPopups), self);
	}
}

simulated function IncompatibleModsPopups()
{
	local TDialogueBoxData kDialogData;
	local array<ModDependencyData> ModsWithIncompats;
	local ModDependencyData Mod;
	local X2WOTCCH_DialogCallbackData CallbackData;

	ModsWithIncompats = DependencyChecker.GetModsWithEnabledIncompatibilities();

	foreach ModsWithIncompats(Mod)
	{
		if (HideIncompatibleModWarnings.Find(Mod.SourceName) == INDEX_NONE)
		{
			CallbackData = new class'X2WOTCCH_DialogCallbackData';
			CallbackData.DependencyData = Mod;

			kDialogData.strTitle = Mod.ModName @ class'X2WOTCCH_ModDependencies'.default.ModIncompatiblePopupTitle;
			kDialogData.eType = eDialog_Warning;
			kDialogData.strText = GetIncompatibleModsText(Mod);
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
	local array<ModDependencyData> ModsWithMissing;
	local ModDependencyData Mod;
	local X2WOTCCH_DialogCallbackData CallbackData;

	ModsWithMissing = DependencyChecker.GetModsWithMissingRequirements();

	foreach ModsWithMissing(Mod)
	{
		if (HideRequiredModWarnings.Find(Mod.SourceName) == INDEX_NONE)
		{
			CallbackData = new class'X2WOTCCH_DialogCallbackData';
			CallbackData.DependencyData = Mod;

			kDialogData.strTitle = Mod.ModName @ class'X2WOTCCH_ModDependencies'.default.ModRequiredPopupTitle;
			kDialogData.eType = eDialog_Warning;
			kDialogData.strText = GetRequiredModsText(Mod);
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
		HideIncompatibleModWarnings.AddItem(CallbackData.DependencyData.SourceName);

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
		HideRequiredModWarnings.AddItem(CallbackData.DependencyData.SourceName);

		`PRESBASE.PlayUISound(eSUISound_MenuSelect);
		
		self.SaveConfig();
	}
	else
	{
		`PRESBASE.PlayUISound(eSUISound_MenuSelect);
	}
}

simulated function string GetIncompatibleModsText(const out ModDependencyData Dep)
{
	return class'UIUtilities_Text'.static.GetColoredText(Repl(class'X2WOTCCH_ModDependencies'.default.ModIncompatible, "%s", Dep.ModName, true), eUIState_Header) $ "\n\n" $
			class'UIUtilities_Text'.static.GetColoredText(MakeBulletList(Dep.Children), eUIState_Bad) $ "\n";
}

simulated function string GetRequiredModsText(const out ModDependencyData Dep)
{
	return class'UIUtilities_Text'.static.GetColoredText(Repl(class'X2WOTCCH_ModDependencies'.default.ModRequired, "%s", Dep.ModName, true), eUIState_Header) $ "\n\n" $
			class'UIUtilities_Text'.static.GetColoredText(MakeBulletList(Dep.Children), eUIState_Bad) $ "\n";
}

simulated function RunOrderPopups()
{
	local CHOnlineEventMgr OnlineEventMgr;
	local CHDLCRunOrderDiagnostic Diag;
	local array<string> Blamed;

	OnlineEventMgr = CHOnlineEventMgr(`ONLINEEVENTMGR);
	// Guard against older XComGame versions
	if (OnlineEventMgr != none && ArrayProperty'XComGame.CHOnlineEventMgr.Diagnostics' != none)
	{
		foreach OnlineEventMgr.Diagnostics(Diag)
		{
			switch (Diag.Kind)
			{
				case eCHROKW_Cycle:
					CyclePopup(Diag);
					break;
				case eCHROWK_OrderIncorrectDifferentGroup:
					Blamed = Diag.Blame();
					if (!AllGroupIgnored(Blamed))
					{
						GroupPopup(Diag);
					}
					break;
			}
		}
	}
}

simulated function CyclePopup(CHDLCRunOrderDiagnostic Diag)
{
	local TDialogueBoxData kDialogData;

	kDialogData.strTitle = default.CycleErrorTitle;
	kDialogData.eType = eDialog_Warning;
	kDialogData.strText = GetCycleText(Diag);
	kDialogData.strCancel = class'UIUtilities_Text'.default.m_strGenericAccept;

	`PRESBASE.UIRaiseDialog(kDialogData);
}

function string GetCycleText(CHDLCRunOrderDiagnostic Diag)
{
	local string Fmt, BlameBuf;
	local array<string> Facts;

	Facts = Diag.FormatEdgeFacts();

	Fmt = Repl(default.CycleErrorText, "%FACTS", MakeBulletList(Facts));
	Fmt $= "\n\n";
	JoinArray(Diag.Blame(), BlameBuf, ", ");
	Fmt $= Repl(default.BlameText, "%BLAME", BlameBuf);

	return Fmt;
}

simulated function GroupPopup(CHDLCRunOrderDiagnostic Diag)
{
	local TDialogueBoxData kDialogData;
	local X2WOTCCH_DialogCallbackData CallbackData;

	CallbackData = new class'X2WOTCCH_DialogCallbackData';
	CallbackData.Diag = Diag;

	kDialogData.strTitle = default.GroupErrorTitle;
	kDialogData.eType = eDialog_Warning;
	kDialogData.strText = GetGroupText(Diag);
	kDialogData.fnCallbackEx = GroupPopupCB;
	kDialogData.strAccept = class'X2WOTCCH_ModDependencies'.default.DisablePopup;
	kDialogData.strCancel = class'UIUtilities_Text'.default.m_strGenericAccept;
	kDialogData.xUserData = CallbackData;

	`PRESBASE.UIRaiseDialog(kDialogData);
}

function string GetGroupText(CHDLCRunOrderDiagnostic Diag)
{
	local string Fmt, BlameBuf;
	local array<string> Facts;

	Facts.AddItem(Diag.FormatSingleFact());
	Facts.AddItem(Diag.FormatGroups());

	Fmt = Repl(default.GroupErrorText, "%FACTS", MakeBulletList(Facts));
	Fmt $= "\n\n";
	JoinArray(Diag.Blame(), BlameBuf, ", ");
	Fmt $= Repl(default.BlameText, "%BLAME", BlameBuf);
	return Fmt;
}

simulated function GroupPopupCB(Name eAction, UICallbackData xUserData)
{
	local X2WOTCCH_DialogCallbackData CallbackData;
	local array<string> Blamed;

	if (eAction == 'eUIAction_Accept')
	{
		CallbackData = X2WOTCCH_DialogCallbackData(xUserData);
		Blamed = CallbackData.Diag.Blame();
		ExtendIgnoredGroups(Blamed);
		self.SaveConfig();

		`PRESBASE.PlayUISound(eSUISound_MenuSelect);
	}
	else
	{
		`PRESBASE.PlayUISound(eSUISound_MenuSelect);
	}
}

private function bool AllGroupIgnored(const out array<string> BlameArr)
{
	local string Blame;

	foreach BlameArr(Blame)
	{
		if (HideGroupWarnings.Find(Blame) == INDEX_NONE)
		{
			return false;
		}
	}
	return true;
}

private function ExtendIgnoredGroups(const out array<string> BlameArr)
{
	local string Blame;

	foreach BlameArr(Blame)
	{
		if (HideGroupWarnings.Find(Blame) == INDEX_NONE)
		{
			HideGroupWarnings.AddItem(Blame);
		}
	}
}

private static function string MakeBulletList(const out array<string> List)
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