/**
 * Issue #524
 * Check mods required and incompatible mods against the actually loaded mod and display a popup
 **/
class X2WOTCCH_ModDependencies extends Object;

struct ModDependency
{
	var string ModName;
	var name DLCIdentifier;
	var array<String> Children;
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

static function array<ModDependency> GetRequiredMods()
{
	local array<X2DownloadableContentInfo> DLCInfos;
	local X2DownloadableContentInfo DLCInfo;
	local array<string> DependendDLCIdentifiers;
	local array<ModDependency> RequiredMods;

	DLCInfos = `ONLINEEVENTMGR.GetDLCInfos(false);

	foreach DLCInfos(DLCInfo)
	{
		DependendDLCIdentifiers = DLCInfo.GetRequiredDLCIdentifiers();

		AddModDependenies(DLCInfo, DependendDLCIdentifiers, true, RequiredMods);
	}

	return RequiredMods;
}

static function array<ModDependency> GetIncompatbleMods()
{
	local array<X2DownloadableContentInfo> DLCInfos;
	local X2DownloadableContentInfo DLCInfo;
	local array<string> DependendDLCIdentifiers;
	local array<ModDependency> IncompatibleMods;

	DLCInfos = `ONLINEEVENTMGR.GetDLCInfos(false);

	foreach DLCInfos(DLCInfo)
	{
		DependendDLCIdentifiers = DLCInfo.GetIncompatibleDLCIdentifiers();
		AddModDependenies(DLCInfo, DependendDLCIdentifiers, false, IncompatibleMods);
	}

	return IncompatibleMods;
}

static function GetIgnoreMods(out array<string> IgnoreRequired, out array<string> IgnoreIncompatible)
{
	local array<X2DownloadableContentInfo> DLCInfos;
	local X2DownloadableContentInfo DLCInfo;
	local array<string> IgnoreRequiredMods, IgnoreIncompatibleMods;
	local string Mod;

	DLCInfos = `ONLINEEVENTMGR.GetDLCInfos(false);

	foreach DLCInfos(DLCInfo)
	{
		IgnoreRequiredMods = DLCInfo.GetIgnoreRequiredDLCIdentifiers();
		foreach IgnoreRequiredMods(Mod)
		{
			IgnoreRequired.AddItem(Mod);
		}

		IgnoreIncompatibleMods = DLCInfo.GetIgnoreIncompatibleDLCIdentifiers();
		foreach IgnoreIncompatibleMods(Mod)
		{
			IgnoreIncompatible.AddItem(Mod);
		}
	}
}



private static function AddModDependenies(
	X2DownloadableContentInfo DLCInfo,
	array<string> DependendDLCIdentifiers,
	bool bRequired,
	out array<ModDependency> IncompatibleMods
)
{
	local ModDependency ModDependencyToAdd;

	if (GetModDependency(DLCInfo, DependendDLCIdentifiers, bRequired, ModDependencyToAdd))
	{
		if (ModDependencyToAdd.Children.Length > 0)
		{
			IncompatibleMods.AddItem(ModDependencyToAdd);
		}
	}
}

private static function bool GetModDependency(
	X2DownloadableContentInfo DLCInfo,
	array<string> DependendDLCIdentifiers,
	bool bRequired,
	out ModDependency ModDependencyToAdd
	)
{
	local string DependendDLCIdentifier;
	local bool bIsInstalled;
	local array<string> IgnoreRequiredMods, IgnoreIncompatibleMods;

	GetIgnoreMods(IgnoreRequiredMods, IgnoreIncompatibleMods);

	if (DependendDLCIdentifiers.Length > 0)
	{
		ModDependencyToAdd.ModName = GetModDisplayName(DLCInfo);
		ModDependencyToAdd.DLCIdentifier = name(DLCInfo.DLCIdentifier);
		foreach DependendDLCIdentifiers(DependendDLCIdentifier)
		{
			bIsInstalled = IsDLCInstalled(name(DependendDLCIdentifier));
			if (!bIsInstalled && bRequired && IgnoreRequiredMods.Find(DependendDLCIdentifier) == INDEX_NONE)
			{
				ModDependencyToAdd.Children.AddItem(DependendDLCIdentifier);
				`LOG(GetFuncName() @ GetModDisplayName(DLCInfo) @ "Add required" @ DependendDLCIdentifier,, 'X2WOTCCommunityHighlander');
			}
			if (bIsInstalled && !bRequired && IgnoreIncompatibleMods.Find(DependendDLCIdentifier) == INDEX_NONE)
			{
				ModDependencyToAdd.Children.AddItem(DependendDLCIdentifier);
				`LOG(GetFuncName() @ GetModDisplayName(DLCInfo) @ "Add incompatible" @ DependendDLCIdentifier,, 'X2WOTCCommunityHighlander');
			}
		}
		return true;
	}
	return false;
}

private static function bool IsDLCInstalled(name DLCName)
{
	local XComOnlineEventMgr EventManager;
	local int i;
		
	EventManager = `ONLINEEVENTMGR;
	for(i = 0; i < EventManager.GetNumDLC(); ++i)
	{
		if (DLCName == EventManager.GetDLCNames(i))
		{
			return true;
		}
	}
	return false;
}


private static function string GetModDisplayName(X2DownloadableContentInfo DLCInfo)
{
	if (DLCInfo.GetDisplayName() != "")
	{
		return DLCInfo.GetDisplayName();
	}

	if (DLCInfo.PartContentLabel != "")
	{
		return DLCInfo.PartContentLabel;
	}

	return DLCInfo.DLCIdentifier;
}

function static string Join(array<string> StringArray, optional string Delimiter = ",", optional bool bIgnoreBlanks = true)
{
	local string Result;

	JoinArray(StringArray, Result, Delimiter, bIgnoreBlanks);

	return Result;
}

// Begin Issue #909
static final function GetModsThatRequireNewerCHLVersion(out array<CHModDependency> ModsThatRequireNewerCHLVersion)
{
	local array<X2DownloadableContentInfo> DLCInfos;
	local X2DownloadableContentInfo        DLCInfo;
	local CHModDependency                  ModDependencyObj;
	local CHLVersionStruct                 CurrentCHLVersion;

	GetCurrentCHLVersion(CurrentCHLVersion);
	DLCInfos = `ONLINEEVENTMGR.GetDLCInfos(false);
	
	foreach DLCInfos(DLCInfo)
	{
		ModDependencyObj = DLCInfo.GetMyCHModDependency();

		if (IsCurrentCHLVersionOlderThanRequired(CurrentCHLVersion, ModDependencyObj.RequiredHighlanderVersion))
		{
			ModsThatRequireNewerCHLVersion.AddItem(ModDependencyObj);
		}
	}
}	

static final function GetCurrentCHLVersion(out CHLVersionStruct CurrentCHLVersion)
{
	CurrentCHLVersion.MajorVersion = class'CHXComGameVersionTemplate'.default.MajorVersion;
	CurrentCHLVersion.MinorVersion = class'CHXComGameVersionTemplate'.default.MinorVersion;
	CurrentCHLVersion.PatchVersion = class'CHXComGameVersionTemplate'.default.PatchVersion;
}

static private function bool IsCurrentCHLVersionOlderThanRequired(const out CHLVersionStruct CurrentCHLVersion, const out CHLVersionStruct RequiredCHLVersion)
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