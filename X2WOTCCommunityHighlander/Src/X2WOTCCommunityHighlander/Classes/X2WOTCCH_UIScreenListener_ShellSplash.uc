class X2WOTCCH_UIScreenListener_ShellSplash extends UIScreenListener config(Game);

var config bool bEnableVersionDisplay;

var string HelpLink;

event OnInit(UIScreen Screen)
{
	local UIShell ShellScreen;
	local array<CHLComponent> Comps;
	local string VersionString;
	local int i;
	local CHLComponentStatus WorstStatus;
	local UIText VersionText;

	if(UIShell(Screen) == none || !bEnableVersionDisplay)  // this captures UIShell and UIFinalShell
		return;

	ShellScreen = UIShell(Screen);

	Comps = class'X2WOTCCH_Components'.static.GetComponentInfo();
	
	// Find our worst error level
	WorstStatus = eCHLCS_OK;
	for (i = 0; i < Comps.Length; i++)
	{
		if (Comps[i].CompStatus > WorstStatus)
		{
			WorstStatus = Comps[i].CompStatus;
		}
	}

	VersionString = "X2WOTCCommunityHighlander";

	switch (WorstStatus)
	{
		case eCHLCS_OK:
		case eCHLCS_NotExpectedNotFound:
			VersionString = class'UIUtilities_Text'.static.GetColoredText(VersionString @ Comps[0].DisplayVersion, eUIState_Normal, 22);
			break;
		case eCHLCS_VersionMismatch:
		case eCHLCS_ExpectedNotFound:
			VersionString = class'UIUtilities_Text'.static.GetColoredText(VersionString @ class'X2WOTCCH_Components'.default.WarningsLabel, eUIState_Warning, 22);
			break;
		case eCHLCS_RequiredNotFound:
			`log("Required packages were not loaded. Please consult" @ HelpLink @ "for further information");
			VersionString = class'UIUtilities_Text'.static.GetColoredText(VersionString @ class'X2WOTCCH_Components'.default.ErrorsLabel, eUIState_Bad, 22);
			break;
	}

	VersionText = ShellScreen.Spawn(class'UIText', ShellScreen);
	VersionText.InitText('theVersionText');
	VersionText.SetHTMLText(VersionString, OnTextSizeRealized);
	// This code aligns the version text to the Main Menu Ticker
	VersionText.AnchorBottomRight();
	VersionText.SetY(-ShellScreen.TickerHeight + 10);
}

function OnTextSizeRealized()
{
	local UIText VersionText;
	local UIShell ShellScreen;

	ShellScreen = UIShell(`SCREENSTACK.GetFirstInstanceOf(class'UIShell'));
	VersionText = UIText(ShellScreen.GetChildByName('theVersionText'));
	VersionText.SetX(-10 - VersionText.Width);
	// this makes the ticker shorter -- if the text gets long enough to interfere, it will automatically scroll
	ShellScreen.TickerText.SetWidth(ShellScreen.Movie.m_v2ScaledFullscreenDimension.X - VersionText.Width - 20);
}

defaultProperties
{
	ScreenClass = none
	HelpLink = "https://github.com/X2CommunityCore/X2WOTCCommunityHighlander/wiki/Troubleshooting"
}
