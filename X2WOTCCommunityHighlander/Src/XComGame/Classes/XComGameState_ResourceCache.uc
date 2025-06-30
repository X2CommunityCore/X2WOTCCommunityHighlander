//---------------------------------------------------------------------------------------
//  FILE:    XComGameState_ResourceCache.uc
//  AUTHOR:  Mark Nauta  --  07/29/2014
//  PURPOSE: This object represents the instance data for a resource cache on the
//		     world map in the strategy game
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComGameState_ResourceCache extends XComGameState_ScanningSite 
	native(Core) 
	dependson(X2StrategyGameRulesetDataStructures)
	config(GameBoard);

var bool								bNeedsScan; // When the Cache appears and has resources, it needs to be scanned to retrieve them
var bool								bTriggerAppearedPopup; // Should the Supply Drop Appeared popup be triggered for the Cache
var bool								bNeedsAppearedPopup; // Should the Supply Drop Appeared popup be displayed for the Cache
var bool								bNeedsCompletedPopup;  // Should the Supply Drop Completed popup be displayed for the Cache
var bool								bInstantScan; // Should the Supply Drop be picked up instantly
var float								NextRewardHour; // The hour at which the next scan reward will be given
var TDateTime							ExpirationTime;  // grab 'em while you can before they're gone
var int									AmountForFlyoverPopup;

// Resource Cache State
var() int ResourcesRemainingInCache; // The total number of resources remaining in this cache
var() int ResourcesToGiveNextScan; // The number of resources given when the next scan completes
var() int ResourcesPerScan; // The number of resources given to the player per scan
var() int NumScansCompleted; // Used to calculate the number of days remaining

//var config int						MinAvailableHours;
//var config int						MaxAvailableHours;

var config array<int>					NumScansPerCache; // The number of scan cycles that must pass be completed to get the full cache
var config name							ResourceCacheScanResource; // The name of the resource provided by scanning the Resource Cache

//#############################################################################################
//----------------   INITIALIZATION   ---------------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
static function SetUpResourceCache(XComGameState StartState)
{
	local XComGameState_ResourceCache CacheState;

	CacheState = XComGameState_ResourceCache(StartState.CreateNewStateObject(class'XComGameState_ResourceCache'));

	CacheState.bScanRepeatable = true;
}

//#############################################################################################
//----------------   SHOW/HIDE   --------------------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
function ShowResourceCache(XComGameState NewGameState, int ResourceAmount)
{
	// If the Supply Drop is not already active, move it to a new location
	if (!bNeedsScan)
	{
		bNeedsScan = true;
		SetContinent();
	}

	bTriggerAppearedPopup = true;
	bNeedsAppearedPopup = false;
	bScanHasStarted = false;
	bScanPaused = false;

	SetScanHoursRemaining(`ScaleStrategyArrayInt(default.MinScanDays), `ScaleStrategyArrayInt(default.MaxScanDays));
	
	// Set up the resource amounts for this cache
	ResourcesRemainingInCache += ResourceAmount + ResourcesToGiveNextScan;
	ResourcesPerScan = ResourcesRemainingInCache / `ScaleStrategyArrayInt(default.NumScansPerCache);
	ResourcesToGiveNextScan = Min(ResourcesRemainingInCache, ResourcesPerScan);
	ResourcesToGiveNextScan += (ResourcesRemainingInCache % `ScaleStrategyArrayInt(default.NumScansPerCache)); // add any remainder to the first drop
	ResourcesRemainingInCache -= ResourcesToGiveNextScan;
	
	NumScansCompleted = 0;

	//SetClosingTime();
}

//---------------------------------------------------------------------------------------
function SetContinent()
{
	local XComGameStateHistory History;
	local XComGameState_WorldRegion RegionState;
	local array<XComGameState_WorldRegion> AllRegions, ValidRegions;

	History = `XCOMHISTORY;

	foreach History.IterateByClassType(class'XComGameState_WorldRegion', RegionState)
	{
		AllRegions.AddItem(RegionState);

		if (RegionState.HaveMadeContact())
		{
			ValidRegions.AddItem(RegionState);
		}
	}

	if (ValidRegions.Length > 0)
	{
		RegionState = ValidRegions[`SYNC_RAND(ValidRegions.Length)];
	}
	else
	{
		RegionState = AllRegions[`SYNC_RAND(AllRegions.Length)];
	}

	Continent = RegionState.GetContinent().GetReference();
	SetLocation(RegionState.GetContinent());
}

//---------------------------------------------------------------------------------------
function SetLocation(XComGameState_Continent ContinentState)
{
	Location = ContinentState.GetRandomLocationInContinent(, self);
}

//---------------------------------------------------------------------------------------
//function SetClosingTime()
//{
//	local int HoursToAdd;
//
//	HoursToAdd = default.MinAvailableHours + `SYNC_RAND(default.MaxAvailableHours - default.MinAvailableHours + 1);
//	ExpirationTime = GetCurrentTime();
//	class'X2StrategyGameRulesetDataStructures'.static.AddHours(ExpirationTime, HoursToAdd);
//}

//#############################################################################################
//----------------   UPDATE   -----------------------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
function bool Update(XComGameState NewGameState)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local UIStrategyMap StrategyMap;
	local bool bModified;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	StrategyMap = `HQPRES.StrategyMap2D;
	bModified = false;

	// Do not trigger anything while the Avenger or Skyranger are flying, or if another popup is already being presented
	if (bNeedsScan && StrategyMap != none && StrategyMap.m_eUIState != eSMS_Flight && !`HQPRES.ScreenStack.IsCurrentClass(class'UIAlert'))
	{
		// If the Avenger is not at the location and time runs out, remove the cache
		/*if (XComHQ.GetCurrentScanningSite().GetReference().ObjectID != ObjectID && class'X2StrategyGameRulesetDataStructures'.static.LessThan(ExpirationTime, GetCurrentTime()))
		{
			bNeedsScan = false;
			bModified = true;
		}*/

		if (bTriggerAppearedPopup)
		{
			bNeedsAppearedPopup = true;
			bModified = true;
		}
		
		if (IsScanComplete())
		{
			// Give the supply reward
			XComHQ.AddResource(NewGameState, 'Supplies', ResourcesToGiveNextScan);
			AmountForFlyoverPopup = ResourcesToGiveNextScan;
			NumScansCompleted++;
			
			if (ResourcesRemainingInCache > 0)
			{
				ResourcesToGiveNextScan = Min(ResourcesRemainingInCache, ResourcesPerScan);
				ResourcesRemainingInCache -= ResourcesToGiveNextScan;

				ResetScan();
			}
			else
			{
				ResourcesToGiveNextScan = 0;

				bNeedsScan = false; // Cache has been depleted, time to hide the cache
				bNeedsCompletedPopup = true;
			}

			bModified = true;

			`XEVENTMGR.TriggerEvent( 'ResourceCacheSupplies', XComHQ, , NewGameState );
		}		
	}

	return bModified;
}

//---------------------------------------------------------------------------------------
function int GetNumScanDaysRemaining()
{
	local XComGameState_HeadquartersXCom XComHQ;
	local int ScanDaysRemaining;
		
	ScanDaysRemaining = (`ScaleStrategyArrayInt(default.MinScanDays) * `ScaleStrategyArrayInt(NumScansPerCache) - NumScansCompleted);

	XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom', true));
	if (XComHQ != none)
	{
		ScanDaysRemaining = float(ScanDaysRemaining) * XComHQ.CurrentScanRate;
	}

	return ScanDaysRemaining;
}

//#############################################################################################
//----------------   Geoscape Entity Implementation   -----------------------------------------
//#############################################################################################

function string GetDisplayName()
{
	return m_strDisplayLabel;
}

simulated function string GetUIButtonTooltipTitle()
{
	return class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS(GetDisplayName() $":" @ GetContinent().GetMyTemplate().DisplayName);
}

simulated function string GetUIButtonTooltipBody()
{
	local string TooltipStr, ScanTimeValue, ScanTimeLabel;
	local int DaysRemaining;

	DaysRemaining = GetNumScanDaysRemaining();
	ScanTimeValue = string(DaysRemaining);
	ScanTimeLabel = class'UIUtilities_Text'.static.GetDaysString(DaysRemaining);
	TooltipStr = GetTotalResourceAmount() $ ": " $ ScanTimeValue @ ScanTimeLabel @ m_strRemainingLabel;

	return TooltipStr;
}

function string GetTotalResourceAmount()
{
	return string(ResourcesRemainingInCache + ResourcesToGiveNextScan) @ class'X2ItemTemplateManager'.static.GetItemTemplateManager().FindItemTemplate('Supplies').GetItemFriendlyName();
}

function bool CanBeScanned()
{
	return bNeedsScan;
}

function bool ShouldBeVisible()
{
	return bNeedsScan;
}

function class<UIStrategyMapItem> GetUIClass()
{
	return class'UIStrategyMapItem_ResourceCache';
}

// The static mesh for this entities 3D UI
function StaticMesh GetStaticMesh()
{
	return StaticMesh'UI_3D.Overwold_Final.SupplyDrop';
}

// Scale adjustment for the 3D UI static mesh
function vector GetMeshScale()
{
	local vector ScaleVector;

	ScaleVector.X = 1;
	ScaleVector.Y = 1;
	ScaleVector.Z = 1;

	return ScaleVector;
}

protected function bool DisplaySelectionPrompt()
{
	local XComGameState_HeadquartersXCom XComHQ;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();

	// if click here and XComHQ is not in the region, fly to it
	if (XComHQ.CurrentLocation != GetReference())
	{
		return false;
	}

	return true;
}

function UpdateGameBoard()
{
	local XComGameState NewGameState;
	local XComGameState_ResourceCache CacheState;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Update Resource Cache");

	CacheState = XComGameState_ResourceCache(NewGameState.ModifyStateObject(class'XComGameState_ResourceCache', ObjectID));

	if (!CacheState.Update(NewGameState))
	{
		NewGameState.PurgeGameStateForObjectID(CacheState.ObjectID);
	}

	if (NewGameState.GetNumGameStateObjects() > 0)
	{
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
	else
	{
		History.CleanupPendingGameState(NewGameState);
	}

	if (AmountForFlyoverPopup > 0)
	{
		FlyoverPopup();
	}

	if (bNeedsAppearedPopup)
	{
		if(bInstantScan)
		{
			InstantScan();
		}
		else
		{
			ResourceCacheAppearedPopup();
		}	
	}
	else if (bNeedsCompletedPopup)
	{
		ResourceCacheEmptyPopup();
	}
}

//---------------------------------------------------------------------------------------
function InstantScan()
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_ResourceCache CacheState;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Instant Resource Cache Scan");
	CacheState = XComGameState_ResourceCache(NewGameState.ModifyStateObject(class'XComGameState_ResourceCache', self.ObjectID));
	XComHQ.AddResource(NewGameState, 'Supplies', (CacheState.ResourcesRemainingInCache + CacheState.ResourcesToGiveNextScan));
	CacheState.bNeedsScan = false;
	CacheState.bTriggerAppearedPopup = false;
	CacheState.bNeedsAppearedPopup = false;
	CacheState.bNeedsCompletedPopup = false;
	`XEVENTMGR.TriggerEvent('ResourceCacheSupplies', XComHQ, , NewGameState);
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	`HQPRES.UIInstantResourceCacheAlert();

	`GAME.GetGeoscape().Pause();
}

//---------------------------------------------------------------------------------------
simulated public function ResourceCacheAppearedPopup()
{
	local XComGameState NewGameState;
	local XComGameState_ResourceCache CacheState;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Toggle Resource Cache Appeared Popup");
	CacheState = XComGameState_ResourceCache(NewGameState.ModifyStateObject(class'XComGameState_ResourceCache', self.ObjectID));
	CacheState.bTriggerAppearedPopup = false;
	CacheState.bNeedsAppearedPopup = false;
	`XEVENTMGR.TriggerEvent('SupplyDropAppeared', , , NewGameState);
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	`HQPRES.UIResourceCacheAppearedAlert();

	`GAME.GetGeoscape().Pause();
}

//---------------------------------------------------------------------------------------
simulated public function ResourceCacheEmptyPopup()
{
	local XComGameState NewGameState;
	local XComGameState_ResourceCache CacheState;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Toggle Resource Cache Completed Popup");
	CacheState = XComGameState_ResourceCache(NewGameState.ModifyStateObject(class'XComGameState_ResourceCache', self.ObjectID));
	CacheState.bNeedsCompletedPopup = false;
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	`HQPRES.UIResourceCacheCompleteAlert();

	`GAME.GetGeoscape().Pause();
}

//---------------------------------------------------------------------------------------
simulated public function FlyoverPopup()
{
	local XComGameState NewGameState;
	local XComGameState_ResourceCache CacheState;
	local string FlyoverResourceName;
	local Vector2D MessageLocation;

	`XSTRATEGYSOUNDMGR.PlaySoundEvent("StrategyUI_Flyover_Supplies");
	
	FlyoverResourceName = class'UIUtilities_Strategy'.static.GetResourceDisplayName(ResourceCacheScanResource, AmountForFlyoverPopup);
	MessageLocation = Get2DLocation();
	MessageLocation.X += 0.006;
	MessageLocation.Y -= 0.006; //scoot above the pin
	`HQPRES.QueueWorldMessage(FlyoverResourceName $ " +" $ AmountForFlyoverPopup, `EARTH.ConvertEarthToWorld(MessageLocation), , , , , , , , 2.0);
	`HQPRES.m_kAvengerHUD.UpdateResources();

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Toggle Flyover Popup");
	CacheState = XComGameState_ResourceCache(NewGameState.ModifyStateObject(class'XComGameState_ResourceCache', self.ObjectID));
	CacheState.AmountForFlyoverPopup = 0;
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

simulated function string GetUIButtonIcon()
{
	return "img:///UILibrary_StrategyImages.X2StrategyMap.MissionIcon_SupplyDrop";
}

protected function bool CurrentlyInteracting()
{
	//If the avenger is landed here and the scan is available, then yes, we're interacting.
	return (CanBeScanned() && GetReference() == class'UIUtilities_Strategy'.static.GetXComHQ().CurrentLocation);
}

//#############################################################################################
DefaultProperties
{
	bCheckForOverlaps = false;
}
