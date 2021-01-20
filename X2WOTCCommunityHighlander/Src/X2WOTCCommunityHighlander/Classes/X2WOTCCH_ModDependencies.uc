/**
 * Issue #524
 * Check mods required and incompatible mods against the actually loaded mod and display a popup
 **/
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
	var array<String> Children; // The set of mods required by or incompatible with the cause
};

var localized string ModRequired;
var localized string ModIncompatible;
var localized string ModRequiredPopupTitle;
var localized string ModIncompatiblePopupTitle;
var localized string DisablePopup;

var config array<name> AdditionalDepInfoNames;

// Mods may install themselves as a fix mod that fixes an incompatibility
// or a missing dependency (in case that mod provides functionality that
// would otherwise be missing).
var array<string> IgnoreRequiredMods;
var array<string> IgnoreIncompatibleMods;

// Faster than retrieving from OnlineEventMgr all the time, and enables `.Find()`
var array<name> EnabledDLCNames;
var array<CHModDependency> DepInfos;

function Init()
{
	local XComOnlineEventMgr OnlineEventMgr;
	local X2DownloadableContentInfo DLCInfo;
	local CHModDependency DepInfo;
	local array<X2DownloadableContentInfo> DLCInfos;
	local name AddDepInfo;
	local string Mod;
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
			DepInfo = new(none, DLCInfo.DLCIdentifier) class'CHModDependency';
			if (DepInfo.DisplayName == "")
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
			self.DepInfos.AddItem(DepInfo);
		}
	}

	foreach default.AdditionalDepInfoNames(AddDepInfo)
	{
		DepInfo = new(none, string(AddDepInfo)) class'CHModDependency';
		self.DepInfos.AddItem(DepInfo);
	}

	foreach self.DepInfos(DepInfo)
	{
		foreach DepInfo.IgnoreRequiredMods(Mod)
		{
			self.IgnoreRequiredMods.AddItem(Mod);
		}

		foreach DepInfo.IgnoreIncompatibleMods(Mod)
		{
			self.IgnoreIncompatibleMods.AddItem(Mod);
		}
	}
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

private function bool GetModDependencies(
	CHModDependency DepInfo,
	array<string> DependencyDLCNames,
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
						DepData.Children.AddItem(DependencyDLCName);
						`LOG(GetFuncName() @ DepData.ModName @ "Add required" @ DependencyDLCName,, 'X2WOTCCommunityHighlander');
					}
					break;
				case ePolarity_Incompatibility:
					if (bIsInstalled && self.IgnoreIncompatibleMods.Find(DependencyDLCName) == INDEX_NONE)
					{
						DepData.Children.AddItem(DependencyDLCName);
						`LOG(GetFuncName() @ DepData.ModName @ "Add incompatible" @ DependencyDLCName,, 'X2WOTCCommunityHighlander');
					}
					break;
			}
		}
	}

	return DepData.Children.Length > 0;
}
