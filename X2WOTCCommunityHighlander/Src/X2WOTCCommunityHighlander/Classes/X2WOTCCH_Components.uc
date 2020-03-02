class X2WOTCCH_Components extends Object config(CHLComponents);

enum CHLComponentStatus
{
	// OK
	eCHLCS_NotExpectedNotFound,
	eCHLCS_OK,
	// Warnings
	eCHLCS_VersionMismatch,
	eCHLCS_ExpectedNotFound,
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

//var config bool DLC3ReplacementEnabled;

var localized string VersionFormat;
var localized string RequiredNotFound;
var localized string ExpectedNotFound;
var localized string NotExpectedNotFound;

var localized string VersionMismatches;
var localized string WarningsLabel;
var localized string ErrorsLabel;

delegate bool VersionInfoFetcher (out CHLComponentVersion VersionInfo);

static function array<CHLComponent> GetComponentInfo()
{
	local X2StrategyElementTemplateManager Manager;
	local X2StrategyElementTemplate SelfVersion;
	local CHLComponentVersion SelfVersionNew;
	local array<string> DLCNames;
	local array<CHLComponent> Comps;

	Manager = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
	DLCNames = class'Helpers'.static.GetInstalledDLCNames();

	SelfVersion = Manager.FindStrategyElementTemplate('CHWOTCVersion');
	Comps.AddItem(BuildComponent(SelfVersion, none, "X2WOTCCommunityHighlander", true, true));
	Comps.AddItem(BuildComponent(Manager.FindStrategyElementTemplate('CHEngineVersion'), SelfVersion, "Engine", true, true));
	Comps.AddItem(BuildComponent(Manager.FindStrategyElementTemplate('CHXComGameVersion'), SelfVersion, "XComGame", true, true));

	if (DLCNames.Find("DLC_2") != INDEX_NONE)
	{
		CompanionVersionInfoFetcher(SelfVersionNew);
		Comps.AddItem(BuildComponentNew(DLC2VersionInfoFetcher, "DLC_2", true, true, SelfVersionNew));
	}

	/* FIXME: Uncomment when a DLC_3 Highlander is added
	if (DLCNames.Find("DLC_3") != INDEX_NONE)
	{
		Comps.AddItem(BuildComponent(Manager.FindStrategyElementTemplate('CHDLC3Version'), SelfVersion, "DLC_3", false, default.DLC3ReplacementEnabled));
	}
	*/

	return Comps;
}


static function CHLComponent BuildComponent(X2StrategyElementTemplate Template, X2StrategyElementTemplate CompareVersion, string ComponentName, bool Required, bool Expected)
{
	local CHLComponent Comp;

	Comp.DisplayName = ComponentName;

	if (Template != none)
	{
		Comp.DisplayVersion = FormatVersion(Template);
		if (CompareVersion != none)
		{
			if (CHXComGameVersionTemplate(Template).GetVersionNumber() == CHXComGameVersionTemplate(CompareVersion).GetVersionNumber())
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
		if (Required)
		{
			Comp.DisplayVersion = default.RequiredNotFound;
			Comp.CompStatus = eCHLCS_RequiredNotFound;
		}
		else if (Expected)
		{
			Comp.DisplayVersion = default.ExpectedNotFound;
			Comp.CompStatus = eCHLCS_ExpectedNotFound;
		}
		else
		{
			Comp.DisplayVersion = default.NotExpectedNotFound;
			Comp.CompStatus = eCHLCS_NotExpectedNotFound;
		}
	}

	return Comp;
}

static function CHLComponent BuildComponentNew (delegate<VersionInfoFetcher> VersionFn, string ComponentName, bool Required, bool Expected, optional CHLComponentVersion CompareVersion)
{
	local CHLComponentVersion VersionInfo;
	local CHLComponent Comp;

	Comp.DisplayName = ComponentName;

	if (GetCDO().CallVersionInfoFetcher(VersionFn, VersionInfo))
	{
		Comp.DisplayVersion = FormatVersionNew(VersionInfo);

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
		if (Required)
		{
			Comp.DisplayVersion = default.RequiredNotFound;
			Comp.CompStatus = eCHLCS_RequiredNotFound;
		}
		else if (Expected)
		{
			Comp.DisplayVersion = default.ExpectedNotFound;
			Comp.CompStatus = eCHLCS_ExpectedNotFound;
		}
		else
		{
			Comp.DisplayVersion = default.NotExpectedNotFound;
			Comp.CompStatus = eCHLCS_NotExpectedNotFound;
		}
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

static function string FormatVersion(X2StrategyElementTemplate Version)
{
	local string Ret;

	Ret = default.VersionFormat;
	Ret = Repl(Ret, "%MAJOR", CHXComGameVersionTemplate(Version).MajorVersion);
	Ret = Repl(Ret, "%MINOR", CHXComGameVersionTemplate(Version).MinorVersion);
	Ret = Repl(Ret, "%PATCH", CHXComGameVersionTemplate(Version).PatchVersion);

	if (CHXComGameVersionTemplate(Version).Commit != "")
	{
		Ret @= "(" $ CHXComGameVersionTemplate(Version).Commit $ ")";
	}

	return Ret;
}

static function string FormatVersionNew (CHLComponentVersion Version)
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

static protected function bool DLC2VersionInfoFetcher (out CHLComponentVersion VersionInfo)
{
	if (class'CHVersion_DLC2' == none) return false;

	VersionInfo.MajorVersion = class'CHVersion_DLC2'.default.MajorVersion;
	VersionInfo.MinorVersion = class'CHVersion_DLC2'.default.MinorVersion;
	VersionInfo.PatchVersion = class'CHVersion_DLC2'.default.PatchVersion;
	VersionInfo.Commit = class'CHVersion_DLC2'.default.Commit;

	return true;
}

static protected function bool CompanionVersionInfoFetcher (out CHLComponentVersion VersionInfo)
{
	VersionInfo.MajorVersion = class'CHVersion_X2WOTCCH'.default.MajorVersion;
	VersionInfo.MinorVersion = class'CHVersion_X2WOTCCH'.default.MinorVersion;
	VersionInfo.PatchVersion = class'CHVersion_X2WOTCCH'.default.PatchVersion;
	VersionInfo.Commit = class'CHVersion_X2WOTCCH'.default.Commit;

	return true;
}

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