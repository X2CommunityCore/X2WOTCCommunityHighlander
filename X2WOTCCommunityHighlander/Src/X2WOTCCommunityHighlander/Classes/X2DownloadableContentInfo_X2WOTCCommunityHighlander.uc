//---------------------------------------------------------------------------------------
//  FILE:   X2DownloadableContentInfo_X2CommunityHighlander.uc                                    
//           
//	Use the X2DownloadableContentInfo class to specify unique mod behavior when the 
//  player creates a new campaign or loads a saved game.
//  
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2DownloadableContentInfo_X2WOTCCommunityHighlander extends X2DownloadableContentInfo config(Game);

/// Called after the Templates have been created (but before they are validated) while this DLC / Mod is installed.
/// </summary>
static event OnPostTemplatesCreated()
{
	`log("x2wotccommunityhighlander :: present and correct");

	// Begin Issue #123
	class'CHHelpers'.static.RebuildPerkContentCache();
	// End Issue #123
}
