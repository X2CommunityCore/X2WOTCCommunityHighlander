//---------------------------------------------------------------------------------------
//  FILE:    CHXComGameVersion.uc
//  AUTHOR:  X2CommunityCore
//  PURPOSE: Version information for the Community Highlander. 
//
//  Issue #1
// 
//  Creates a template to hold the version number info for the Community Highlander
//  XComGame replacement. This version is incremented separately to the Long War
//  Game Version to express our own releases to mods depending on them.
//
//---------------------------------------------------------------------------------------
class CHXComGameVersion extends X2StrategyElement;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;
	local CHXComGameVersionTemplate XComGameVersion;
	`log("Creating CHXCOMGameVersionTemplate...", , 'X2WOTCCommunityHighlander');
	`CREATE_X2TEMPLATE(class'CHXComGameVersionTemplate', XComGameVersion, 'CHXComGameVersion');
	`log("Created CHXCOMGameVersionTemplate with version" @ XComGameVersion.MajorVersion $ "." $ XComGameVersion.MinorVersion $ "." $ XComGameVersion.PatchVersion, , 'X2WOTCCommunityHighlander');
	Templates.AddItem(XComGameVersion);

	return Templates;
}
