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
	
	class'X2TacticalGameRuleset'.static.ReleaseScriptLog("X2WOTCCommunityHighlander: Creating CHXCOMGameVersionTemplate...");
	`CREATE_X2TEMPLATE(class'CHXComGameVersionTemplate', XComGameVersion, 'CHXComGameVersion');
	class'X2TacticalGameRuleset'.static.ReleaseScriptLog("X2WOTCCommunityHighlander: Created CHXCOMGameVersionTemplate with version" @ XComGameVersion.MajorVersion $ "." $ XComGameVersion.MinorVersion $ "." $ XComGameVersion.PatchVersion);
	Templates.AddItem(XComGameVersion);

	if (class'Core.CHCoreVersion' != none)
	{
		class'X2TacticalGameRuleset'.static.ReleaseScriptLog("X2WOTCCommunityHighlander: Creating Core version template...");
		`CREATE_X2TEMPLATE(class'CHXComGameVersionTemplate', XComGameVersion, 'CHCoreVersion');
		XComGameVersion.MajorVersion = class'Core.CHCoreVersion'.default.MajorVersion;
		XComGameVersion.MinorVersion = class'Core.CHCoreVersion'.default.MinorVersion;
		XComGameVersion.PatchVersion = class'Core.CHCoreVersion'.default.PatchVersion;
		XComGameVersion.Commit = class'Core.CHCoreVersion'.default.Commit;
		class'X2TacticalGameRuleset'.static.ReleaseScriptLog("X2WOTCCommunityHighlander: Created Core version template with version" @ XComGameVersion.MajorVersion $ "." $ XComGameVersion.MinorVersion $ "." $ XComGameVersion.PatchVersion);
		Templates.AddItem(XComGameVersion);
	}

	if (class'Engine.CHEngineVersion' != none)
	{
		class'X2TacticalGameRuleset'.static.ReleaseScriptLog("X2WOTCCommunityHighlander: Creating Engine version template...");
		`CREATE_X2TEMPLATE(class'CHXComGameVersionTemplate', XComGameVersion, 'CHEngineVersion');
		XComGameVersion.MajorVersion = class'Engine.CHEngineVersion'.default.MajorVersion;
		XComGameVersion.MinorVersion = class'Engine.CHEngineVersion'.default.MinorVersion;
		XComGameVersion.PatchVersion = class'Engine.CHEngineVersion'.default.PatchVersion;
		XComGameVersion.Commit = class'Engine.CHEngineVersion'.default.Commit;
		class'X2TacticalGameRuleset'.static.ReleaseScriptLog("X2WOTCCommunityHighlander: Created Engine version template with version" @ XComGameVersion.MajorVersion $ "." $ XComGameVersion.MinorVersion $ "." $ XComGameVersion.PatchVersion);
		Templates.AddItem(XComGameVersion);
	}

	return Templates;
}
