/// HL-Docs: feature:CHDLCHookManager; issue:212; tags:
/// The CHDLCHookManager class is an internal component of CHL that allows us 
/// to retrieve only DLCs (X2DownloadableContentInfo classes) that override a 
/// specific function or event by method name.
///
/// It was introduced to optimize the number of calls made on X2DownloadableContentInfo
/// classes. Instead of CHL calling X2DLCI methods on every known DLC class 
/// (which can grow large), it uses **\`DLCHOOKMGR.GetDLCInfos('MethodName')** 
/// to fetch only the DLCs that actually override a method with that name. Any 
/// base classes (except X2DownloadableContentInfo itself) that override a method 
/// with that name are also returned.
///
/// One very noticeable example is the UpdateHumanPawnMeshComponent/Material 
/// hook. UpdateHumanPawnMeshComponent has a default implementation that always loops 
/// through the materials of the mesh component, performs some type checking, and then 
/// forwards the call to the UpdateHumanPawnMeshMaterial method for backward
/// compatibility, which has an empty default implementation.
///
/// The unfortunate side effect of this, with large mod lists and calling 
/// UpdateHumanPawnMeshComponent on all DLC classes, is that it does a lot of work for 
/// nothing. Moreover, this method is actually called twice in a single 
/// frame due to the logic of XGunitNativeBase.ResetWeaponsToDefaultSockets, 
/// amplifying the effect even further.
///
/// Profiling using a large mod list has shown significantly reduced frame times
/// in places where these methods were called, especially the ones which have a 
/// default implementation.
/// 
/// Special care must be taken by CHL developers when making changes to the 
/// X2DownloadableContentInfo class, as they might need supporting changes to the
/// CHDLCHookManager class. This is especially important when introducing new versions
/// of existing hooks; follow the comments in the source of CHDLCHookManager.uc
class CHDLCHookManager extends Object config(Game);

// using a struct and cache DLCInfos by MethodName (a name)
// to get fast lookups using array.Find('Name', name)
struct DLCMethodHookInfo
{
	var name MethodName;
	var array<X2DownloadableContentInfo> DLCs;
};

var config array<DLCMethodHookInfo> m_arrDLCMethodInfos;

// returns all X2DLCI objects that implement the given method name as a function or event
// if it does not extend from X2DownloadableContentInfo directly, any base classes will
// also be checked for existence.
// 
// Note: if you need to call `ONLINEEVENTMGR.GetDLCInfos(true); (true, for new DLC only)
// the method here will NOT work for you, since it is cached and never reset!
public static final function array<X2DownloadableContentInfo> GetDLCInfos(name MethodName)
{
	local DLCMethodHookInfo DLCMethodInfo;
	local int idx;

	// lazily build up a cache of queried method names.
	idx = default.m_arrDLCMethodInfos.Find('MethodName', MethodName);
	if (idx == INDEX_NONE)
	{
		DLCMethodInfo.MethodName = MethodName;
		DLCMethodInfo.DLCs = GetDLCsWithMethod(MethodName);
		default.m_arrDLCMethodInfos.AddItem(DLCMethodInfo);
	}
	else
	{
		DLCMethodInfo = default.m_arrDLCMethodInfos[idx];
	}
	
	return DLCMethodInfo.DLCs;
}

private static function array<X2DownloadableContentInfo> GetDLCsWithMethod(name MethodName)
{
	local X2DownloadableContentInfo DLCToAdd, DLCInfo;
	local array<X2DownloadableContentInfo> DLCInfos, DLCInfosWithMethod;
	local int i;

	DLCInfos = `ONLINEEVENTMGR.GetDLCInfos(false);

	for(i = 0; i < DLCInfos.Length; ++i)
	{
		DLCToAdd = DLCInfos[i];

		// skip XComGame.X2DownloadableContentInfo itself, it serves only as a base class
		if (DLCToAdd.Class == class'X2DownloadableContentInfo')
		{
			continue;
		}

		// Start with the class of the given DLCInfo, check if it implements the method, 
		// if not, continue checking base classes until reaching the final base class
		DLCInfo = DLCToAdd;

		do
		{
			/*
				X2DownloadableContentInfo methods with default implementations that forward
				to their previous version. These are special cased here because:

				- the caller only has to call the latest version of a method
				- the caller does not have to decide which method to call and/or prevent 
					duplicate calls
				- DLCRunOrder stays intact!
				
				The pattern below should speak for itself
				- only compare the needed 'MethodName' to the name of the latest version 
					of the method in X2DLCI
				- check if the DLCInfo has that method, or one of up to 3 alternative 
					method names (previous versions)
				- if any of those methods were found on the DLCInfo (or its base classes),
					it will be used.
				
				Make sure that all the versions of a method have a default implementation
				forwarding to their previous version.
			 */ 
			if (MethodName == 'CanAddItemToInventory_CH_Improved' && HasAnyDLCMethod(DLCInfo, MethodName, 'CanAddItemToInventory_CH', 'CanAddItemToInventory'))
			{
				DLCInfosWithMethod.AddItem(DLCToAdd);
				break;
			}
			else if (MethodName == 'UpdateHumanPawnMeshComponent' && HasAnyDLCMethod(DLCInfo, MethodName, 'UpdateHumanPawnMeshMaterial'))
			{
				DLCInfosWithMethod.AddItem(DLCToAdd);
				break;
			}
			else if (MethodName == 'OverrideItemImage_Improved' && HasAnyDLCMethod(DLCInfo, MethodName, 'OverrideItemImage'))
			{
				DLCInfosWithMethod.AddItem(DLCToAdd);
				break;
			}
			else if (MethodName == 'PostReinforcementCreation' && HasAnyDLCMethod(DLCInfo, MethodName, 'PostEncounterCreation'))
			{
				DLCInfosWithMethod.AddItem(DLCToAdd);
				break;
			}
			else if (HasDLCMethod(DLCInfo, MethodName))
			{
				DLCInfosWithMethod.AddItem(DLCToAdd);
				break;
			}

			// continue checking any base class, until reaching X2DownloadableContentInfo, which it should obviously not check.
			DLCInfo = X2DownloadableContentInfo(DLCInfo.ObjectArchetype);
		}
		until(DLCInfo == none || DLCInfo.Class == class'X2DownloadableContentInfo');
	}

	return DLCInfosWithMethod;
}

private static function bool HasDLCMethod(X2DownloadableContentInfo DLCInfo, name MethodName)
{
	local string QualifiedName;

	QualifiedName = PathName(DLCInfo.Class) $ ":" $ MethodName;

	return FindObject(QualifiedName, class'Function') != none;
}

private static function bool HasAnyDLCMethod(X2DownloadableContentInfo DLCInfo, name MethodName, name MethodName2, optional name MethodName3, optional name MethodName4)
{
	local string QualifiedName;

	QualifiedName = PathName(DLCInfo.Class) $ ":" $ MethodName;
	if (FindObject(QualifiedName, class'Function') != none)
	{
		return true;
	}

	QualifiedName = PathName(DLCInfo.Class) $ ":" $ MethodName2;
	if (FindObject(QualifiedName, class'Function') != none)
	{
		return true;
	}

	if (MethodName3 != '')
	{
		QualifiedName = PathName(DLCInfo.Class) $ ":" $ MethodName3;
		if (FindObject(QualifiedName, class'Function') != none)
		{
			return true;
		}
	}

	if (MethodName4 != '')
	{
		QualifiedName = PathName(DLCInfo.Class) $ ":" $ MethodName4;
		if (FindObject(QualifiedName, class'Function') != none)
		{
			return true;
		}
	}

	return false;
}