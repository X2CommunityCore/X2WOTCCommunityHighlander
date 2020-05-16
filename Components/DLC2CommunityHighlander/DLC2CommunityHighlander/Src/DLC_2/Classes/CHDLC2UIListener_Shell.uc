// Used to show a warning when the player is missing the main CHL
// Not part of the public API - mods should not rely on its existence

class CHDLC2UIListener_Shell extends UIScreenListener;

var localized string strMissingCHL_Title;
var localized string strMissingCHL_Text;

event OnInit (UIScreen Screen)
{
	if (!Screen.IsA(class'UIShell'.Name)) return;

	if (
		class'CHXComGameVersionTemplate' == none && // We depend on the XComGame replacement, so check that mainly
		!IsDLCLoaded("X2WOTCCommunityHighlander") // However, do not complain when the companion package is loaded - it will handle the complaining

		// Note that the replacement may be present without the companion when running with -noSeekFreeLoading and the last mod compiled was not the main CHL
	)
	{
		Screen.SetTimer(1.0, false, nameof(ShowMissingCHL), self);
	}
}

static private function bool IsDLCLoaded (coerce string DLCName)
{
	local array<string> DLCs;
  
	DLCs = class'Helpers'.static.GetInstalledDLCNames();

	return DLCs.Find(DLCName) != INDEX_NONE;
}

simulated private function ShowMissingCHL ()
{
	local TDialogueBoxData DialogData;

	DialogData.eType = eDialog_Warning;
	DialogData.strTitle = strMissingCHL_Title;
	DialogData.strText = strMissingCHL_Text;
	DialogData.strAccept = class'UIUtilities_Text'.default.m_strGenericAccept;

	`SCREENSTACK.Pres.UIRaiseDialog(DialogData);
}
