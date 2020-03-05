class X2WOTCCH_UIScreenListener_ShellSplash extends UIScreenListener config(Game);

var config bool bEnableVersionDisplay;

var string HelpLink;

event OnInit(UIScreen Screen)
{
	if(UIShell(Screen) == none || !bEnableVersionDisplay)  // this captures UIShell and UIFinalShell
		return;

	// This is a circular problem: The main menu info accessible on controller
	// using this input hook is most useful when the HL *isn't* working -- but then,
	// this input hook doesn't exist. Not much we can do other than ensuring the
	// user makes it to the main menu screen, sees the error message and checks the log.
	if (Function'XComGame.UIScreenStack.SubscribeToOnInputForScreen' != none)
	{
		Screen.Movie.Stack.SubscribeToOnInputForScreen(Screen, OnInputHook);
	}

	RealizeVersionText(UIShell(Screen));
}

event OnReceiveFocus(UIScreen Screen)
{
	if(UIShell(Screen) == none || !bEnableVersionDisplay)  // this captures UIShell and UIFinalShell
		return;

	RealizeVersionText(UIShell(Screen));
}

function RealizeVersionText(UIShell ShellScreen)
{
	local array<CHLComponent> Comps;
	local string VersionString;
	local int i;
	local CHLComponentStatus WorstStatus;
	local UIText VersionText;
	local string TooltipStr;
	local EUIState ColorStatus;
	local UIBGBox TooltipHitbox;
	local UIBGBox TooltipBG;
	local UIText TooltipText;

	Comps = class'X2WOTCCH_Components'.static.GetComponentInfo();
	WorstStatus = class'X2WOTCCH_Components'.static.FindHighestErrorLevel(Comps);

	VersionString = "X2WOTCCommunityHighlander";

	ColorStatus = ColorForStatus(WorstStatus);
	switch (WorstStatus)
	{
		case eCHLCS_OK:
			VersionString = class'UIUtilities_Text'.static.GetColoredText(VersionString @ Comps[0].DisplayVersion, ColorStatus, 22);
			break;
		case eCHLCS_VersionMismatch:
			VersionString = class'UIUtilities_Text'.static.GetColoredText(VersionString @ class'X2WOTCCH_Components'.default.WarningsLabel, ColorStatus, 22);
			break;
		case eCHLCS_RequiredNotFound:
			`log("Required packages were not loaded. Please consult" @ HelpLink @ "for further information", , 'X2WOTCCommunityHighlander');
			VersionString = class'UIUtilities_Text'.static.GetColoredText(VersionString @ class'X2WOTCCH_Components'.default.ErrorsLabel, ColorStatus, 22);
			break;
	}

	VersionText = UIText(ShellScreen.GetChildByName('theVersionText', false));
	if (VersionText == none)
	{
		VersionText = ShellScreen.Spawn(class'UIText', ShellScreen);
		VersionText.InitText('theVersionText');
		// This code aligns the version text to the Main Menu Ticker
		VersionText.AnchorBottomRight();
		VersionText.SetY(-ShellScreen.TickerHeight + 10);
	}

	if (`ISCONTROLLERACTIVE)
	{
		VersionText.SetHTMLText(class'UIUtilities_Text'.static.InjectImage(class'UIUtilities_Input'.static.GetGamepadIconPrefix() 
								$ class'UIUtilities_Input'.const.ICON_RSCLICK_R3, 20, 20, -10) 
								@ VersionString, OnTextSizeRealized);
	}
	else
	{
		VersionText.SetHTMLText(VersionString, OnTextSizeRealized);
	}

	TooltipStr = "";

	// Add a tooltip
	for (i = 0; i < Comps.Length; i++)
	{
		if (i != 0)
		{
			TooltipStr $= "<br />";
		}
		TooltipStr $= "-" @ class'UIUtilities_Text'.static.GetColoredText(Comps[i].DisplayName @ Comps[i].DisplayVersion, ColorForStatus(Comps[i].CompStatus), 22);
	}


	TooltipHitbox = UIBGBox(ShellScreen.GetChildByName('theVersionHitbox', false));
	if (TooltipHitbox == none)
	{
		// Create an invisible hitbox above the text with a tooltip
		TooltipHitbox = ShellScreen.Spawn(class'UIBGBox', ShellScreen);
		TooltipHitbox.InitBG('theVersionHitbox', 0, 0, 1, 1);
		TooltipHitbox.AnchorBottomRight();
		TooltipHitbox.SetAlpha(0.00001f);
		TooltipHitbox.ProcessMouseEvents(OnHitboxMouseEvent);
	}

	TooltipBG = UIBGBox(ShellScreen.GetChildByName('theTooltipBG', false));
	if (TooltipBG == none)
	{
		TooltipBG = ShellScreen.Spawn(class'UIBGBox', ShellScreen);
		TooltipBG.InitBG('theTooltipBG', 0, 0, 1, 1);
		TooltipBG.AnchorBottomRight();
		TooltipBG.Hide();
	}

	TooltipText = UIText(ShellScreen.GetChildByName('theTooltipText', false));
	if (TooltipText == none)
	{
		TooltipText = ShellScreen.Spawn(class'UIText', ShellScreen);
		TooltipText.InitText('theTooltipText');
		TooltipText.AnchorBottomRight();
		TooltipText.Hide();
	}

	TooltipText.SetHTMLText(TooltipStr, OnTooltipTextSizeRealized);
}

function EUIState ColorForStatus(CHLComponentStatus Status)
{
	switch (Status)
	{
		case eCHLCS_OK:
			return eUIState_Normal;
		case eCHLCS_VersionMismatch:
			return eUIState_Warning;
		case eCHLCS_RequiredNotFound:
			return eUIState_Bad;
	}
}

function OnTextSizeRealized()
{
	local UIText VersionText;
	local UIShell ShellScreen;
	local UIPanel TooltipHitbox;

	ShellScreen = UIShell(`SCREENSTACK.GetFirstInstanceOf(class'UIShell'));
	VersionText = UIText(ShellScreen.GetChildByName('theVersionText'));
	VersionText.SetX(-10 - VersionText.Width);
	// this makes the ticker shorter -- if the text gets long enough to interfere, it will automatically scroll
	ShellScreen.TickerText.SetWidth(ShellScreen.Movie.m_v2ScaledFullscreenDimension.X - VersionText.Width - 20);

	TooltipHitbox = ShellScreen.GetChildByName('theVersionHitbox');
	TooltipHitbox.SetPosition(VersionText.X, VersionText.Y);
	TooltipHitbox.SetSize(VersionText.Width, VersionText.Height);
}

function OnTooltipTextSizeRealized()
{
	local UIText TooltipText;
	local UIBGBox TooltipBG;
	local UIShell ShellScreen;

	ShellScreen = UIShell(`SCREENSTACK.GetFirstInstanceOf(class'UIShell'));
	TooltipBG = UIBGBox(ShellScreen.GetChildByName('theTooltipBG', false));
	TooltipText = UIText(ShellScreen.GetChildByName('theTooltipText', false));

	TooltipBG.SetSize(TooltipText.Width + 10, TooltipText.Height + 10);

	TooltipText.SetPosition(-TooltipBG.Width - 10, -TooltipBG.Height - 10 - ShellScreen.TickerHeight);
	TooltipBG.SetPosition(-TooltipBG.Width - 15, -TooltipBG.Height - 15 - ShellScreen.TickerHeight);
}

function OnHitboxMouseEvent(UIPanel control, int cmd)
{
	local UIText TooltipText;
	local UIBGBox TooltipBG;
	local UIShell ShellScreen;

	ShellScreen = UIShell(`SCREENSTACK.GetFirstInstanceOf(class'UIShell'));
	TooltipBG = UIBGBox(ShellScreen.GetChildByName('theTooltipBG', false));
	TooltipText = UIText(ShellScreen.GetChildByName('theTooltipText', false));

	switch (cmd)
	{
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_IN:
		TooltipText.Show();
		TooltipBG.Show();
		break;
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_OUT:
		TooltipText.Hide();
		TooltipBG.Hide();
		break;
	}
}

function bool OnInputHook(UIScreen Screen, int iInput, int ActionMask)
{
	local UIText TooltipText;
	local UIBGBox TooltipBG;
	local UIShell ShellScreen;

	if (iInput == class'UIUtilities_Input'.const.FXS_BUTTON_R3 && (ActionMask & class'UIUtilities_Input'.const.FXS_ACTION_RELEASE) != 0)
	{
		ShellScreen = UIShell(Screen);

		TooltipBG = UIBGBox(ShellScreen.GetChildByName('theTooltipBG', false));
		TooltipText = UIText(ShellScreen.GetChildByName('theTooltipText', false));

		TooltipBG.ToggleVisible();
		TooltipText.ToggleVisible();

		return true;
	}
	return false;
}

defaultProperties
{
	ScreenClass = none
	HelpLink = "https://github.com/X2CommunityCore/X2WOTCCommunityHighlander/wiki/Troubleshooting"
}
