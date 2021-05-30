// Used to show a warning when the player is missing the game CHL
// Not part of the public API - mods should not rely on its existence

class CHDLC2UIListener_Shell extends UIScreenListener;

var localized string strMissingCHL_Title;
var localized string strMissingCHL_Text;

event OnInit (UIScreen Screen)
{
	if (!Screen.IsA(class'UIShell'.Name)) return;

	if (
		class'CHXComGameVersionTemplate' == none && // We depend on the XComGame replacement, so check that mainly
		FindObject("X2WOTCCommunityHighlander.X2WOTCCH_Components", class'Class') == none // However, do not complain when the companion package is loaded - it will handle the complaining

		// Note 1) the XComGame replacement may be present without the companion when running with -noSeekFreeLoading and the last mod compiled was not the main CHL
		// Note 2) we don't want an import (reference) to the X2WOTCCommunityHighlander package, so we can't use the class'' syntax in the check
	)
	{
		Screen.SetTimer(1.0, false, nameof(ShowMissingCHL), self);

		`log(" ",, 'CHDLC2');
		`log(" ",, 'CHDLC2');
		`log("FATAL: Core X2WOTCCommunityHighlander is missing, will crash during gameplay!",, 'CHDLC2');
		`log(" ",, 'CHDLC2');
		`log(" ",, 'CHDLC2');
	}
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
