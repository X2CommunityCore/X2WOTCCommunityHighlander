class X2WOTCCH_UIScreenListener_Shell_DLCIntro extends UIScreenListener
	config(X2WOTCCommunityHighlander_NullConfig);

// We want the popup to show up only until the player installs the component.
// After that, even if they remove it, we trust that they will be able to
// understand the red component readout in the bottom right of the shell.
var config bool bEverHadDLC2HL;

var localized string strDLC2HLIntroduction_Title;
var localized string strDLC2HLIntroduction_Body;

event OnInit (UIScreen Screen)
{
	if (!Screen.IsA(class'UIShell'.Name)) return;

	CheckDLC2(Screen);
}

simulated private function CheckDLC2 (UIScreen Screen)
{
	if (default.bEverHadDLC2HL) return;
	if (!IsDLCLoaded("DLC_2")) return;

	if (class'CHDLC2Version' == none)
	{
		Screen.SetTimer(1.0, false, nameof(ShowDLC2HLIntroduction), self);
	}
	else
	{
		default.bEverHadDLC2HL = true;
		StaticSaveConfig();
	}
}

simulated private function ShowDLC2HLIntroduction ()
{
	local TDialogueBoxData DialogData;

	DialogData.eType = eDialog_Alert;
	DialogData.strTitle = default.strDLC2HLIntroduction_Title;
	DialogData.strText = `XEXPAND.ExpandString(default.strDLC2HLIntroduction_Body);
	DialogData.strAccept = class'UIUtilities_Text'.default.m_strGenericAccept;

	`SCREENSTACK.Pres.UIRaiseDialog(DialogData);
}

static private function bool IsDLCLoaded (coerce string DLCName)
{
	local array<string> DLCs;
  
	DLCs = class'Helpers'.static.GetInstalledDLCNames();

	return DLCs.Find(DLCName) != INDEX_NONE;
}
