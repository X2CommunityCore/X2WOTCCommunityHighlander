/// HL-Docs: ref:ModDependencyCheck
class X2WOTCCH_UIScreenListener_ShellPopup
	extends UIScreenListener
	dependson (X2WOTCCH_ModDependencies)
	config (X2WOTCCommunityHighlander_NullConfig);


var config array<name> HideIncompatibleModWarnings;
var config array<name> HideRequiredModWarnings;
var X2WOTCCH_ModDependencies DependencyChecker;

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
					GroupPopup(Diag);
					break;
			}
		}
	}
}

simulated function CyclePopup(CHDLCRunOrderDiagnostic Diag)
{
	local TDialogueBoxData kDialogData;

	kDialogData.strTitle = "Cycle in Run Order Detected";
	kDialogData.eType = eDialog_Warning;
	kDialogData.strText = GetCycleText(Diag);
	kDialogData.strCancel = class'UIUtilities_Text'.default.m_strGenericAccept;

	`PRESBASE.UIRaiseDialog(kDialogData);
}

function string GetCycleText(CHDLCRunOrderDiagnostic Diag)
{
	local string Fmt, BlameText;

	Fmt = "Mods specified a cyclic run order:\n\n";
	Fmt $= MakeBulletList(Diag.FormatEdgeFacts());
	Fmt $= "\n...completing the cycle. Until this is corrected, run order will be undefined.\n\n";
	Fmt $= "The following DLCIdentifiers provided config that lead to this problem: ";
	JoinArray(Diag.Blame(), BlameText, ", ");
	Fmt $= BlameText;
	Fmt $= "\n\nPlease inform the respective mod authors about this problem.";

	return Fmt;
}

simulated function GroupPopup(CHDLCRunOrderDiagnostic Diag)
{
	local TDialogueBoxData kDialogData;

	kDialogData.strTitle = "Conflicting Run Order data";
	kDialogData.eType = eDialog_Warning;
	kDialogData.strText = GetGroupText(Diag);
	kDialogData.strAccept = class'X2WOTCCH_ModDependencies'.default.DisablePopup;
	kDialogData.strCancel = class'UIUtilities_Text'.default.m_strGenericAccept;

	`PRESBASE.UIRaiseDialog(kDialogData);
}

function string GetGroupText(CHDLCRunOrderDiagnostic Diag)
{
	local string Fmt, BlameText;
	local array<string> Facts;

	Facts.AddItem(Diag.FormatSingleFact());
	Facts.AddItem(Diag.FormatGroups());

	Fmt = "Mods specified conflicting run order information:\n\n";
	Fmt $= MakeBulletList(Facts);
	Fmt $= "\nThis behavior is specified, but may indicate a configuration error.\n\n";
	Fmt $= "The following DLCIdentifiers provided config that lead to this problem: ";
	JoinArray(Diag.Blame(), BlameText, ", ");
	Fmt $= BlameText;
	Fmt $= "\n\nPlease inform the respective mod authors about this problem.";

	return Fmt;
}

final static function string MakeBulletList(const out array<string> List)
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