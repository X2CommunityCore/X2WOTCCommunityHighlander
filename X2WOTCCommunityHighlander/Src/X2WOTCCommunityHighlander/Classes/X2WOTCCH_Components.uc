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

//var config bool DLC2ReplacementEnabled;
//var config bool DLC3ReplacementEnabled;

var localized string VersionFormat;
var localized string RequiredNotFound;
var localized string ExpectedNotFound;
var localized string NotExpectedNotFound;

var localized string VersionMismatches;
var localized string WarningsLabel;
var localized string ErrorsLabel;

static function array<CHLComponent> GetComponentInfo()
{
	local X2StrategyElementTemplateManager Manager;
	local X2StrategyElementTemplate SelfVersion;
	local array<string> DLCNames;
	local array<CHLComponent> Comps;

	Manager = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
	DLCNames = class'Helpers'.static.GetInstalledDLCNames();

	SelfVersion = Manager.FindStrategyElementTemplate('CHWOTCVersion');
	Comps.AddItem(BuildComponent(SelfVersion, none, "X2WOTCCommunityHighlander", true, true));
	Comps.AddItem(BuildComponent(Manager.FindStrategyElementTemplate('CHEngineVersion'), SelfVersion, "Engine", true, true));
	Comps.AddItem(BuildComponent(Manager.FindStrategyElementTemplate('CHXComGameVersion'), SelfVersion, "XComGame", true, true));

	/* FIXME: Uncomment when a DLC 2 Highlander is added
	if (DLCNames.Find("DLC_2") != INDEX_NONE)
	{
		Comps.AddItem(BuildComponent(Manager.FindStrategyElementTemplate('CHDLC2Version'), SelfVersion, "DLC_2", false, default.DLC2ReplacementEnabled));
	}
	*/

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