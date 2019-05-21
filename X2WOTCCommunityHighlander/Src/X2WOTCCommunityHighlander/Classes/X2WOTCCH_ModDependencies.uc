/**
 * Issue #524
 * Check mods required and incompatible mods against the actually loaded mod and display a popup
 **/
class X2WOTCCH_ModDependencies extends Object;

struct ModDependency
{
	var string ModName;
	var array<String> Children;
};

var localized string ModRequired;
var localized string ModIncompatible;

static function GetModDependencies(out array<ModDependency> IncompatibleMods, out array<ModDependency> RequiredMods)
{
	local array<X2DownloadableContentInfo> DLCInfos;
	local X2DownloadableContentInfo DLCInfo;
	local array<string> DependendDLCIdentifiers;
	local ModDependency ModDependencyToAdd, EmptyModDependencyToAdd;

	DLCInfos = `ONLINEEVENTMGR.GetDLCInfos(false);

	foreach DLCInfos(DLCInfo)
	{
		DependendDLCIdentifiers = DLCInfo.GetIncompatibleDLCIdentifiers();

		ModDependencyToAdd = EmptyModDependencyToAdd;
		if (GetModDependency(DLCInfos, DLCInfo, DependendDLCIdentifiers, false, ModDependencyToAdd))
		{
			if (ModDependencyToAdd.Children.Length > 0)
			{
				IncompatibleMods.AddItem(ModDependencyToAdd);
			}
		}

		DependendDLCIdentifiers = DLCInfo.GetRequiredDLCIdentifiers();

		ModDependencyToAdd = EmptyModDependencyToAdd;
		if (GetModDependency(DLCInfos, DLCInfo, DependendDLCIdentifiers, true, ModDependencyToAdd))
		{
			if (ModDependencyToAdd.Children.Length > 0)
			{
				RequiredMods.AddItem(ModDependencyToAdd);
			}
		}
	}
}

function static string Join(array<string> StringArray, optional string Delimiter = ",", optional bool bIgnoreBlanks = true)
{
	local string Result;

	JoinArray(StringArray, Result, Delimiter, bIgnoreBlanks);

	return Result;
}

private static function bool GetModDependency(
	array<X2DownloadableContentInfo> DLCInfos,
	X2DownloadableContentInfo DLCInfo,
	array<string> DependendDLCIdentifiers,
	bool bIsRequired,
	out ModDependency ModDependencyToAdd
	)
{
	local string DependendDLCIdentifier;
	local X2DownloadableContentInfo Dependency;

	if (DependendDLCIdentifiers.Length > 0)
	{
		ModDependencyToAdd.ModName = GetModDisplayName(DLCInfo);
		foreach DependendDLCIdentifiers(DependendDLCIdentifier)
		{
			Dependency = FindDLCInfo(DLCInfos, DependendDLCIdentifier);
			if (bIsRequired && Dependency == none)
			{
				ModDependencyToAdd.Children.AddItem(DependendDLCIdentifier);
				`LOG(GetFuncName() @ GetModDisplayName(DLCInfo) @ "Add incompatible" @ DependendDLCIdentifier,, 'X2WOTCCommunityHighlander');
			}
			else if(!bIsRequired && Dependency != none)
			{
				ModDependencyToAdd.Children.AddItem(GetModDisplayName(Dependency));
				`LOG(GetFuncName() @ GetModDisplayName(DLCInfo) @ "Add incompatible" @ GetModDisplayName(Dependency),, 'X2WOTCCommunityHighlander');
			}
		}
		return true;
	}
	return false;
}

private static function X2DownloadableContentInfo FindDLCInfo(array<X2DownloadableContentInfo> Haystack, string Needle)
{
	local X2DownloadableContentInfo DLCInfo;

	foreach Haystack(DLCInfo)
	{
		if (DLCInfo.DLCIdentifier == Needle)
		{
			return DLCInfo;
		}
	}
	return None;
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

