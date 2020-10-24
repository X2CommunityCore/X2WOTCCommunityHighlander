//---------------------------------------------------------------------------------------
//  FILE:    CHXComGameVersion.uc
//  AUTHOR:  X2CommunityCore
//  PURPOSE: Version information for the Community Highlander. 
//
//  Issue #1
// 
//  Creates a template to hold the version number info for the Community Highlander
//  XComGame replacement. Created for legacy reasons.
//
//---------------------------------------------------------------------------------------
class CHXComGameVersion extends X2StrategyElement;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;
	local CHXComGameVersionTemplate XComGameVersion;
	
	// class'X2TacticalGameRuleset'.static.ReleaseScriptLog("X2WOTCCommunityHighlander: Creating CHXCOMGameVersionTemplate...");
	`CREATE_X2TEMPLATE(class'CHXComGameVersionTemplate', XComGameVersion, 'CHXComGameVersion');
	// class'X2TacticalGameRuleset'.static.ReleaseScriptLog("X2WOTCCommunityHighlander: Created CHXCOMGameVersionTemplate with version" @ XComGameVersion.MajorVersion $ "." $ XComGameVersion.MinorVersion $ "." $ XComGameVersion.PatchVersion);
	Templates.AddItem(XComGameVersion);

	return Templates;
}
