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

/// <summary>
/// Called after the Templates have been created (but before they are validated) while this DLC / Mod is installed.
/// </summary>
static event OnPostTemplatesCreated()
{
	`log("x2wotccommunityhighlander :: present and correct");

	// Begin Issue #123
	class'CHHelpers'.static.RebuildPerkContentCache();
	// End Issue #123
}

/// <summary>
/// This method is run when the player loads a saved game directly into Strategy while this DLC is installed
/// </summary>
static event OnLoadedSavedGameToStrategy()
{
	// Begin Issue #178
	class'CHTacticalCleanupHelper'.static.CleanupObsoleteTacticalGamestate();
	// End Issue #123
}

/// <summary>
/// Called after the player exits the post-mission sequence while this DLC / Mod is installed.
/// </summary>
static event OnExitPostMissionSequence()
{
	// Begin Issue #178
	class'CHTacticalCleanupHelper'.static.CleanupObsoleteTacticalGamestate();
	// End Issue #123
}