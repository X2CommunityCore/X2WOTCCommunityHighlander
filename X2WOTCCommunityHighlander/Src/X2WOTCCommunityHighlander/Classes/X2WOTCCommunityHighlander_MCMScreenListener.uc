class X2WOTCCommunityHighlander_MCMScreenListener extends UIScreenListener;

event OnInit(UIScreen Screen)
{
	local X2WOTCCommunityHighlander_MCMScreen MCMScreen;

	if (ScreenClass==none)
	{
		if (MCM_API(Screen) != none)
			ScreenClass=Screen.Class;
		else return;
	}

	MCMScreen = new class'X2WOTCCommunityHighlander_MCMScreen';
	MCMScreen.OnInit(Screen);
}

defaultproperties
{
    ScreenClass = none;
}
