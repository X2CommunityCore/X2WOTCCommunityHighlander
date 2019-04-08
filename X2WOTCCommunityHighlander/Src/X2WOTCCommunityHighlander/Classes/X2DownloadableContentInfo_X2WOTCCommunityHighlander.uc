//---------------------------------------------------------------------------------------
//  FILE:   X2DownloadableContentInfo_X2CommunityHighlander.uc                                    
//           
//	Use the X2DownloadableContentInfo class to specify unique mod behavior when the 
//  player creates a new campaign or loads a saved game.
//  
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2DownloadableContentInfo_X2WOTCCommunityHighlander extends X2DownloadableContentInfo config(Game) dependson(X2WOTCCH_Components);

/// Called after the Templates have been created (but before they are validated) while this DLC / Mod is installed.
/// </summary>
static event OnPostTemplatesCreated()
{
	local array<CHLComponent> Comps;
	local int i;
	local CHLComponentStatus WorstStatus;

	`log("Companion script package loaded", , 'X2WOTCCommunityHighlander');

	Comps = class'X2WOTCCH_Components'.static.GetComponentInfo();
	WorstStatus = class'X2WOTCCH_Components'.static.FindHighestErrorLevel(Comps);

	`log("Components:", , 'X2WOTCCommunityHighlander');
	for (i = 0; i < Comps.Length; i++)
	{
		`log("  " $ Comps[i].DisplayName @ "--" @ Comps[i].DisplayVersion, , 'X2WOTCCommunityHighlander');
	}

	if (WorstStatus == eCHLCS_RequiredNotFound)
	{
		`log("Required packages were not loaded. Please consult" @ class'X2WOTCCH_UIScreenListener_ShellSplash'.default.HelpLink @ "for further information", , 'X2WOTCCommunityHighlander');
	}

	// We don't want to crash when not loaded.
	if (class'CHHelpers' != none)
	{
		// Begin Issue #123
		class'CHHelpers'.static.RebuildPerkContentCache();
		// End Issue #123
	}
}
