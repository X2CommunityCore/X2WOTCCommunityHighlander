/// HL-Docs: ref:ModDependencyCheck
class X2WOTCCH_ModDependencies extends Object config(Game);

enum CHPolarity
{
	ePolarity_Requirement,
	ePolarity_Incompatibility,
};

struct ModDependencyData
{
	var string ModName; // The display name of the mod causing this error.
	var name SourceName; // The stored name of the mod in case user presses "ok, please ignore"
	var CHPolarity Polarity; // Whether these mods are required and not installed, or incompatible but present
	var array<string> Children; // The set of mods required by or incompatible with the cause

	var CHLVersionStruct RequiredHighlanderVersion; // Issue #909
};

var localized string ModRequired;
var localized string ModIncompatible;
var localized string ModRequiredPopupTitle;
var localized string ModIncompatiblePopupTitle;
var localized string DisablePopup;

// Begin Issue #909
var localized string ModRequiresNewerHighlanderVersionTitle;
var localized string ModRequiresNewerHighlanderVersionText;
var localized string CurrentHighlanderVersionTitle;
var localized string RequiredHighlanderVersionTitle;
var localized string ModRequiresNewerHighlanderVersionExtraText;
// End Issue #909

// Mods may install themselves as a fix mod that fixes an incompatibility
// or a missing dependency (in case that mod provides functionality that
// would otherwise be missing).
var array<string> IgnoreRequiredMods;
var array<string> IgnoreIncompatibleMods;

// Faster than retrieving from OnlineEventMgr all the time, and enables `.Find()`
var array<name> EnabledDLCNames;
var array<CHModDependency> DepInfos;

function bool HasHLSupport()
{
	// Check whether XComGame replacement is active at all.
	// The internal refactoring in #965 works with older versions of `CHModDependency` too.
	return Class'XComGame.CHModDependency' != none;
}

function Init()
{
	local XComOnlineEventMgr OnlineEventMgr;
	local X2DownloadableContentInfo DLCInfo;
	local CHModDependency DepInfo;
	local array<X2DownloadableContentInfo> DLCInfos;
	local name AddDepInfo;
	local int i;

	OnlineEventMgr = `ONLINEEVENTMGR;

	for (i = 0; i < OnlineEventMgr.GetNumDLC(); ++i)
	{
		self.EnabledDLCNames.AddItem(OnlineEventMgr.GetDLCNames(i));
	}

	DLCInfos = OnlineEventMgr.GetDLCInfos(false);
	foreach DLCInfos(DLCInfo)
	{
		if (DLCInfo.DLCIdentifier != "")
		{
			DepInfo = CreateUniqueDepInfoForInstalled(DLCInfo.DLCIdentifier);
			if (DepInfo != none && DepInfo.DisplayName == "")
			{
				if (DLCInfo.PartContentLabel != "")
				{
					DepInfo.DisplayName = DLCInfo.PartContentLabel;
				}
				else
				{
					DepInfo.DisplayName = DLCInfo.DLCIdentifier;
				}
			}
		}
	}

	foreach self.EnabledDLCNames(AddDepInfo)
	{
		DepInfo = CreateUniqueDepInfoForInstalled(string(AddDepInfo));
		if (DepInfo != none && DepInfo.DisplayName == "")
		{
			DepInfo.DisplayName = string(AddDepInfo);
		}
	}
}

private function CHModDependency CreateUniqueDepInfoForInstalled(string DLCName)
{
	local string Mod;
	local CHModDependency DepInfo;

	// NB. since garbage collection runs between frames, `FindObject`
	// should even find objects that weren't added to `self.DepInfos`
	DepInfo = CHModDependency(FindObject("Transient." $ DLCName, class'CHModDependency'));
	if (DepInfo != none)
	{
		return None;
	}

	DepInfo = new(none, DLCName) class'CHModDependency';

	if (!IsInteresting(DepInfo))
	{
		return None;
	}

	foreach DepInfo.IgnoreRequiredMods(Mod)
	{
		self.IgnoreRequiredMods.AddItem(Mod);
	}

	foreach DepInfo.IgnoreIncompatibleMods(Mod)
	{
		self.IgnoreIncompatibleMods.AddItem(Mod);
	}

	self.DepInfos.AddItem(DepInfo);
	return DepInfo;
}

final function bool IsInteresting(CHModDependency DepInfo)
{
	return DepInfo.IncompatibleMods.Length > 0 || DepInfo.RequiredMods.Length > 0
		|| DepInfo.IgnoreIncompatibleMods.Length > 0 || DepInfo.IgnoreRequiredMods.Length > 0
		|| DepInfo.DisplayName != "";
}

function array<ModDependencyData> GetModsWithMissingRequirements()
{
	local CHModDependency DepInfo;

	local ModDependencyData ReqData, DefaultData;
	local array<ModDependencyData> ModsWithReqs;

	foreach self.DepInfos(DepInfo)
	{
		ReqData = DefaultData;
		if (GetModDependencies(DepInfo, DepInfo.RequiredMods, ePolarity_Requirement, ReqData))
		{
			ModsWithReqs.AddItem(ReqData);
		}
	}

	return ModsWithReqs;
}

function array<ModDependencyData> GetModsWithEnabledIncompatibilities()
{
	local CHModDependency DepInfo;

	local ModDependencyData IncompatData, DefaultData;
	local array<ModDependencyData> ModsWithIncompats;

	foreach self.DepInfos(DepInfo)
	{
		IncompatData = DefaultData;
		if (GetModDependencies(DepInfo, DepInfo.IncompatibleMods, ePolarity_Incompatibility, IncompatData))
		{
			ModsWithIncompats.AddItem(IncompatData);
		}
	}

	return ModsWithIncompats;
}

// Start Issue #909
function array<ModDependencyData> GetModsThatRequireNewerCHLVersion()
{
	local CHModDependency DepInfo;
	local CHLVersionStruct CurrentCHLVersion;
	local ModDependencyData DepData;
	local array<ModDependencyData> ModsThatRequireNewerCHLVersion;

	GetCurrentCHLVersion(CurrentCHLVersion);

	foreach self.DepInfos(DepInfo)
	{
		if (IsCurrentCHLVersionOlderThanRequired(CurrentCHLVersion, DepInfo.RequiredHighlanderVersion))
		{
			DepData.ModName = DepInfo.DisplayName;
			DepData.SourceName = DepInfo.Name;
			DepData.RequiredHighlanderVersion = DepInfo.RequiredHighlanderVersion;
			ModsThatRequireNewerCHLVersion.AddItem(DepData);
		}
	}

	return ModsThatRequireNewerCHLVersion;
}

static final function GetCurrentCHLVersion(out CHLVersionStruct CurrentCHLVersion)
{
	CurrentCHLVersion.MajorVersion = class'CHXComGameVersionTemplate'.default.MajorVersion;
	CurrentCHLVersion.MinorVersion = class'CHXComGameVersionTemplate'.default.MinorVersion;
	CurrentCHLVersion.PatchVersion = class'CHXComGameVersionTemplate'.default.PatchVersion;
}

static final function bool IsCurrentCHLVersionOlderThanRequired(const out CHLVersionStruct CurrentCHLVersion, const out CHLVersionStruct RequiredCHLVersion)
{
	if (CurrentCHLVersion.MajorVersion > RequiredCHLVersion.MajorVersion)
		return false;

	if (CurrentCHLVersion.MajorVersion < RequiredCHLVersion.MajorVersion)
		return true;

	if (CurrentCHLVersion.MinorVersion > RequiredCHLVersion.MinorVersion)
		return false;

	if (CurrentCHLVersion.MinorVersion < RequiredCHLVersion.MinorVersion)
		return true;

	return CurrentCHLVersion.PatchVersion < RequiredCHLVersion.PatchVersion;
}
// End Issue #909

private function bool GetModDependencies(
	CHModDependency DepInfo,
	const out array<string> DependencyDLCNames,
	CHPolarity Polarity,
	out ModDependencyData DepData
)
{
	local string DependencyDLCName;
	local bool bIsInstalled;

	if (DependencyDLCNames.Length > 0)
	{
		DepData.ModName = DepInfo.DisplayName;
		DepData.SourceName = DepInfo.Name;
		foreach DependencyDLCNames(DependencyDLCName)
		{
			bIsInstalled = self.EnabledDLCNames.Find(name(DependencyDLCName)) != INDEX_NONE;
			switch (Polarity) {
				case ePolarity_Requirement:
					if (!bIsInstalled && self.IgnoreRequiredMods.Find(DependencyDLCName) == INDEX_NONE)
					{
						DepData.Children.AddItem(FormatDepName(DependencyDLCName));
						`LOG(GetFuncName() @ DepData.ModName @ "Add required" @ DependencyDLCName,, 'X2WOTCCommunityHighlander');
					}
					break;
				case ePolarity_Incompatibility:
					if (bIsInstalled && self.IgnoreIncompatibleMods.Find(DependencyDLCName) == INDEX_NONE)
					{
						DepData.Children.AddItem(FormatDepName(DependencyDLCName));
						`LOG(GetFuncName() @ DepData.ModName @ "Add incompatible" @ DependencyDLCName,, 'X2WOTCCommunityHighlander');
					}
					break;
			}
		}
	}

	return DepData.Children.Length > 0;
}

private function string FormatDepName(string DLCName)
{
	local CHModDependency DepInfo;

	DepInfo = CHModDependency(FindObject("Transient." $ DLCName, class'CHModDependency'));
	if (DepInfo == none)
	{
		DepInfo = new(none, DLCName) class'CHModDependency';
	}

	if (DepInfo.DisplayName != "" && DepInfo.DisplayName != DLCName)
	{
		return DepInfo.DisplayName @ "(" $ DLCName $ ")";
	}

	return DLCName;
}