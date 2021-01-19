/**
 * Issue #524
 * Check mods required and incompatible mods against the actually loaded mod and display a popup
 **/
class X2WOTCCH_ModDependencies extends Object;

enum CHPolarity
{
	ePolarity_Requirement,
	ePolarity_Incompatibility,
};

struct ModDependencyData
{
	var string ModName; // The display name of the mod causing this error.
	var name SourceDLCIdentifier; // The stored name of the mod in case user presses "ok, please ignore"
	var CHPolarity Polarity; // Whether these mods are required and not installed, or incompatible but present
	var array<String> Children; // The set of mods required by or incompatible with the cause
};

var localized string ModRequired;
var localized string ModIncompatible;
var localized string ModRequiredPopupTitle;
var localized string ModIncompatiblePopupTitle;
var localized string DisablePopup;

// Mods may install themselves as a fix mod that fixes an incompatibility
// or a missing dependency (in case that mod provides functionality that
// would otherwise be missing).
var array<string> IgnoreRequiredMods;
var array<string> IgnoreIncompatibleMods;

// Faster than retrieving from OnlineEventMgr all the time, and enables `.Find()`
var array<name> EnabledDLCNames;
var array<X2DownloadableContentInfo> DLCInfos;

function Init()
{
	local XComOnlineEventMgr OnlineEventMgr;
	local X2DownloadableContentInfo DLCInfo;
	local array<string> IgnoreRequired, IgnoreIncompatible;
	local string Mod;
	local int i;

	OnlineEventMgr = `ONLINEEVENTMGR;
	self.DLCInfos = OnlineEventMgr.GetDLCInfos(false);

	foreach self.DLCInfos(DLCInfo)
	{
		IgnoreRequired = DLCInfo.GetIgnoreRequiredDLCNames();
		foreach IgnoreRequired(Mod)
		{
			self.IgnoreRequiredMods.AddItem(Mod);
		}

		IgnoreIncompatible = DLCInfo.GetIgnoreIncompatibleDLCNames();
		foreach IgnoreIncompatible(Mod)
		{
			self.IgnoreIncompatibleMods.AddItem(Mod);
		}
	}

	for (i = 0; i < OnlineEventMgr.GetNumDLC(); ++i)
	{
		self.EnabledDLCNames.AddItem(OnlineEventMgr.GetDLCNames(i));
	}
}

function array<ModDependencyData> GetModsWithMissingRequirements()
{
	local X2DownloadableContentInfo DLCInfo;
	local array<string> RequiredDLCNames;

	local ModDependencyData ReqData, DefaultData;
	local array<ModDependencyData> ModsWithReqs;

	foreach self.DLCInfos(DLCInfo)
	{
		RequiredDLCNames = DLCInfo.GetRequiredDLCNames();
		ReqData = DefaultData;
		if (GetModDependencies(DLCInfo, RequiredDLCNames, ePolarity_Requirement, ReqData))
		{
			ModsWithReqs.AddItem(ReqData);
		}
	}

	return ModsWithReqs;
}

function array<ModDependencyData> GetModsWithEnabledIncompatibilities()
{
	local X2DownloadableContentInfo DLCInfo;
	local array<string> IncompatibleDLCNames;
	local ModDependencyData IncompatData, DefaultData;

	local array<ModDependencyData> ModsWithIncompats;

	foreach self.DLCInfos(DLCInfo)
	{
		IncompatibleDLCNames = DLCInfo.GetIncompatibleDLCNames();
		IncompatData = DefaultData;
		if (GetModDependencies(DLCInfo, IncompatibleDLCNames, ePolarity_Incompatibility, IncompatData))
		{
			ModsWithIncompats.AddItem(IncompatData);
		}
	}

	return ModsWithIncompats;
}

private function bool GetModDependencies(
	X2DownloadableContentInfo DLCInfo,
	array<string> DependencyDLCNames,
	CHPolarity Polarity,
	out ModDependencyData ModDependencies
)
{
	local string DependencyDLCName;
	local bool bIsInstalled;

	if (DependencyDLCNames.Length > 0)
	{
		ModDependencies.ModName = GetModDisplayName(DLCInfo);
		ModDependencies.SourceDLCIdentifier = name(DLCInfo.DLCIdentifier);
		foreach DependencyDLCNames(DependencyDLCName)
		{
			bIsInstalled = self.EnabledDLCNames.Find(name(DependencyDLCName)) != INDEX_NONE;
			switch (Polarity) {
				case ePolarity_Requirement:
					if (!bIsInstalled && self.IgnoreRequiredMods.Find(DependencyDLCName) == INDEX_NONE)
					{
						ModDependencies.Children.AddItem(DependencyDLCName);
						`LOG(GetFuncName() @ GetModDisplayName(DLCInfo) @ "Add required" @ DependencyDLCName,, 'X2WOTCCommunityHighlander');
					}
					break;
				case ePolarity_Incompatibility:
					if (bIsInstalled && self.IgnoreIncompatibleMods.Find(DependencyDLCName) == INDEX_NONE)
					{
						ModDependencies.Children.AddItem(DependencyDLCName);
						`LOG(GetFuncName() @ GetModDisplayName(DLCInfo) @ "Add incompatible" @ DependencyDLCName,, 'X2WOTCCommunityHighlander');
					}
					break;
			}
		}
	}

	return ModDependencies.Children.Length > 0;
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
