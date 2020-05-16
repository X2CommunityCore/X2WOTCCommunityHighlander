class X2WOTCCH_Components extends Object config(CHLComponents);

enum CHLComponentStatus
{
	// OK
	eCHLCS_OK,
	// Warnings
	eCHLCS_VersionMismatch,
	// Errors
	eCHLCS_RequiredNotFound,
};

struct CHLComponent
{
	var string DisplayName;
	var string DisplayVersion;
	var CHLComponentStatus CompStatus;
};

struct CHLComponentVersion 
{
	var int MajorVersion;
	var int MinorVersion;
	var int PatchVersion;
	var string Commit;

	structdefaultproperties
	{
		MajorVersion = -1
		MinorVersion = -1
		PatchVersion = -1
	}
};

var localized string VersionFormat;
var localized string RequiredNotFound;

var localized string VersionMismatches;
var localized string WarningsLabel;
var localized string ErrorsLabel;

delegate bool VersionInfoFetcher (out CHLComponentVersion VersionInfo);

static function array<CHLComponent> GetComponentInfo()
{
	local CHLComponentVersion SelfVersion;
	local array<string> DLCNames;
	local array<CHLComponent> Comps;

	DLCNames = class'Helpers'.static.GetInstalledDLCNames();

	CompanionVersionInfoFetcher(SelfVersion);
	Comps.AddItem(BuildComponent(CompanionVersionInfoFetcher, "X2WOTCCommunityHighlander"));
	Comps.AddItem(BuildComponent(CoreVersionInfoFetcher, "Core", SelfVersion));
	Comps.AddItem(BuildComponent(EngineVersionInfoFetcher, "Engine", SelfVersion));
	Comps.AddItem(BuildComponent(XComVersionInfoFetcher, "XComGame", SelfVersion));

	if (DLCNames.Find("DLC_2") != INDEX_NONE)
	{
		Comps.AddItem(BuildComponent(DLC2VersionInfoFetcher, "DLC_2", SelfVersion));
	}

	return Comps;
}

static function CHLComponent BuildComponent (delegate<VersionInfoFetcher> VersionFn, string ComponentName,  optional CHLComponentVersion CompareVersion)
{
	local CHLComponentVersion VersionInfo;
	local CHLComponent Comp;

	Comp.DisplayName = ComponentName;

	if (GetCDO().CallVersionInfoFetcher(VersionFn, VersionInfo))
	{
		Comp.DisplayVersion = FormatVersion(VersionInfo);

		if (CompareVersion.MajorVersion > -1)
		{
			if (GetVersionNumber(VersionInfo) == GetVersionNumber(CompareVersion))
			{
				Comp.CompStatus = eCHLCS_OK;
			}
			else
			{
				Comp.CompStatus = eCHLCS_VersionMismatch;
			}
		}
		else
		{
			Comp.CompStatus = eCHLCS_OK;
		}
	}
	else
	{
		Comp.DisplayVersion = default.RequiredNotFound;
		Comp.CompStatus = eCHLCS_RequiredNotFound;
	}

	return Comp;
}

static function CHLComponentStatus FindHighestErrorLevel(const out array<CHLComponent> Components)
{
	local CHLComponentStatus WorstStatus;
	local int i;

	WorstStatus = eCHLCS_OK;
	for (i = 0; i < Components.Length; i++)
	{
		if (Components[i].CompStatus > WorstStatus)
		{
			WorstStatus = Components[i].CompStatus;
		}
	}

	return WorstStatus;
}

static function string FormatVersion (CHLComponentVersion Version)
{
	local string Ret;

	Ret = default.VersionFormat;
	Ret = Repl(Ret, "%MAJOR", Version.MajorVersion);
	Ret = Repl(Ret, "%MINOR", Version.MinorVersion);
	Ret = Repl(Ret, "%PATCH", Version.PatchVersion);

	if (Version.Commit != "")
	{
		Ret @= "(" $ Version.Commit $ ")";
	}

	return Ret;
}

////////////////////////
/// Version fetchers ///
////////////////////////
// Used by the new (non-template) version info system (see #765)

`define MakeVersionFetcher(FuncName, ClassName) \
	static protected function bool `{FuncName} (out CHLComponentVersion VersionInfo) \n\
	{ \n\
		if (class'`{ClassName}' == none) return false; \n\
		VersionInfo.MajorVersion = class'`{ClassName}'.default.MajorVersion; \n\
		VersionInfo.MinorVersion = class'`{ClassName}'.default.MinorVersion; \n\
		VersionInfo.PatchVersion = class'`{ClassName}'.default.PatchVersion; \n\
		VersionInfo.Commit = class'`{ClassName}'.default.Commit; \n\
		return true; \n\
	}

`MakeVersionFetcher(DLC2VersionInfoFetcher, CHDLC2Version)
`MakeVersionFetcher(CoreVersionInfoFetcher, CHCoreVersion)
`MakeVersionFetcher(EngineVersionInfoFetcher, CHEngineVersion)
`MakeVersionFetcher(XComVersionInfoFetcher, CHXComGameVersionTemplate)
`MakeVersionFetcher(CompanionVersionInfoFetcher, CHX2WOTCCHVersion)

///////////////
/// Helpers ///
///////////////

static protected function int GetVersionNumber (CHLComponentVersion VersionInfo)
{
    return (VersionInfo.MajorVersion * 100000000) + (VersionInfo.MinorVersion * 10000) + (VersionInfo.PatchVersion);
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////
/// Hack to workaround "Error, Can't call instance functions from within static functions" for delegates ///
////////////////////////////////////////////////////////////////////////////////////////////////////////////

static function X2WOTCCH_Components GetCDO ()
{
	return X2WOTCCH_Components(class'XComEngine'.static.GetClassDefaultObjectByName(default.Class.Name));
}

protected function bool CallVersionInfoFetcher (delegate<VersionInfoFetcher> VersionFn, out CHLComponentVersion VersionInfo)
{
	return VersionFn(VersionInfo);
}