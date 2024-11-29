//---------------------------------------------------------------------------------------
//  FILE:    XComGameState_Haven.uc
//  AUTHOR:  Mark Nauta
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComGameState_Haven extends XComGameState_ScanningSite
	config(GameBoard);

var int									AmountForFlyoverPopup;

var bool								bAlertOnXCOMArrival; // Show the Resistance Goods Available popup on arrival
var bool								bOpenOnXCOMArrival; // Open the Resistance Goods window on arrival

var StateObjectReference				FactionRef; // Some havens are linked to a faction

var localized string                    m_ResHQString;

var config array<int>					MinScanIntelReward;
var config array<int>					MaxScanIntelReward;
var config name							ResHQScanResource; // The name of the resource provided by scanning at the Haven

//#############################################################################################
//----------------   INTIALIZATION   ----------------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
static function SetUpHavens(XComGameState StartState)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Haven HavenState;

	foreach StartState.IterateByClassType(class'XComGameState_HeadquartersXCom', XComHQ)
	{
		break;
	}

	foreach StartState.IterateByClassType(class'XComGameState_Haven', HavenState)
	{
		// Initialize the continent this haven lives on
		if(HavenState.Continent.ObjectID == 0)
		{
			HavenState.Continent = HavenState.GetWorldRegion().GetContinent().GetReference();
		}
		
		if(HavenState.Region != XComHQ.StartingRegion)
		{
			HavenState.bNeedsLocationUpdate = true;
		}
	}
}

//#############################################################################################
//----------------   UPDATE   -----------------------------------------------------------------
//#############################################################################################

// THIS FUNCTION SHOULD RETURN TRUE IN ALL THE SAME CASES AS Update
function bool ShouldUpdate( )
{
	local UIStrategyMap StrategyMap;

	StrategyMap = `HQPRES.StrategyMap2D;

	// Do not trigger anything while the Avenger or Skyranger are flying, or if another popup is already being presented
	if (StrategyMap != none && StrategyMap.m_eUIState != eSMS_Flight && !`HQPRES.ScreenStack.IsCurrentClass( class'UIAlert' ))
	{
		if (IsScanComplete( ))
		{
			return true;
		}
	}

	return false;
}

//---------------------------------------------------------------------------------------
// IF ADDING NEW CASES WHERE bUpdated = true, UPDATE FUNCTION ShouldUpdate ABOVE
function bool Update(XComGameState NewGameState)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_HeadquartersResistance ResHQ;
	local UIStrategyMap StrategyMap;
	local bool bUpdated;
	local int IntelRewardAmt;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	ResHQ = class'UIUtilities_Strategy'.static.GetResistanceHQ();
	StrategyMap = `HQPRES.StrategyMap2D;
	bUpdated = false;

	// Do not trigger anything while the Avenger or Skyranger are flying, or if another popup is already being presented
	if (StrategyMap != none && StrategyMap.m_eUIState != eSMS_Flight && !`HQPRES.ScreenStack.IsCurrentClass(class'UIAlert'))
	{
		if (IsScanComplete())
		{
			if (ResHQ.bIntelMode)
			{
				//Give intel reward for scanning
				IntelRewardAmt = GetScanIntelReward();

				if (IntelRewardAmt > 0)
				{
					XComHQ.AddResource(NewGameState, 'Intel', IntelRewardAmt);
					AmountForFlyoverPopup = IntelRewardAmt;
				}
			}

			ResetScan();
			bUpdated = true;

			`XEVENTMGR.TriggerEvent( 'HavenScanComplete', self, , NewGameState );
		}
	}

	return bUpdated;
}

function HandleResistanceLevelChange(XComGameState NewGameState, EResistanceLevelType NewResLevel, EResistanceLevelType OldResLevel)
{
	local UIStrategyMapItem MapItem;
	local XComGameState_GeoscapeEntity ThisEntity;

	if(!NewGameState.GetContext().IsStartState())
	{
		// Update the tooltip on the map pin
		ThisEntity = self;

		if(`HQPRES != none && `HQPRES.StrategyMap2D != none)
		{
			MapItem = `HQPRES.StrategyMap2D.GetMapItem(ThisEntity, NewGameState);

			if(MapItem != none)
			{
				MapItem.GenerateTooltip(MapItem.MapPin_Tooltip);
			}
		}
	}
}

//---------------------------------------------------------------------------------------
function bool IsFactionHQ()
{
	return (GetResistanceFaction() != none);
}

//---------------------------------------------------------------------------------------
function XComGameState_ResistanceFaction GetResistanceFaction()
{
	return XComGameState_ResistanceFaction(`XCOMHISTORY.GetGameStateForObjectID(FactionRef.ObjectID));
}

//---------------------------------------------------------------------------------------
function bool IsResistanceFactionMet()
{
	local XComGameState_ResistanceFaction FactionState;

	FactionState = GetResistanceFaction();

	return (FactionState != none && FactionState.bMetXCom);
}

//---------------------------------------------------------------------------------------
function X2ResistanceModeTemplate GetResistanceMode()
{
	return GetResistanceFaction().GetResistanceMode();
}

//#############################################################################################
//----------------   REWARDS   ----------------------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
function int GetScanIntelReward()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersResistance ResistanceHQ;
	local int IntelReward;

	IntelReward = `ScaleStrategyArrayInt(default.MinScanIntelReward) + `SYNC_RAND(`ScaleStrategyArrayInt(default.MaxScanIntelReward) - `ScaleStrategyArrayInt(default.MinScanIntelReward) + 1);
	
	// Check for Spy Ring Continent Bonus
	History = `XCOMHISTORY;
	ResistanceHQ = XComGameState_HeadquartersResistance(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersResistance'));

	IntelReward += Round(float(IntelReward) * (float(ResistanceHQ.IntelRewardPercentIncrease) / 100.0));

	return IntelReward;
}

//#############################################################################################
//----------------   Geoscape Entity Implementation   -----------------------------------------
//#############################################################################################

function string GetDisplayName()
{
	local XComGameState_ResistanceFaction FactionState;

	FactionState = GetResistanceFaction();

	if(FactionState != none)
	{
		return FactionState.GetMyTemplate().FactionHQDisplayName;
	}

	return "";
}

function string GetScanDescription()
{
	local XComGameState_ResistanceFaction FactionState;

	FactionState = GetResistanceFaction();

	if(FactionState != none)
	{
		return FactionState.GetResistanceModeLabel();
	}

	return "";
}

function string GetScanTooltip()
{
	local XComGameState_ResistanceFaction FactionState;

	FactionState = GetResistanceFaction();

	if(FactionState != none)
	{
		return FactionState.GetResistanceMode().ScanTooltip;
	}

	return "";
}

function bool CanBeScanned()
{
	return IsResistanceFactionMet();
}

function bool HasTooltipBounds()
{
	// Placed at the start of the game, so need to always have bounds active
	return (IsFactionHQ() || GetWorldRegion().IsStartingRegion());
}

function MakeScanRepeatable()
{
	bScanRepeatable = true;
}

function bool ShouldBeVisible()
{
	local XComGameState_ResistanceFaction FactionState;
	local XComGameState_WorldRegion RegionState;
	
	FactionState = GetResistanceFaction();
	RegionState = GetWorldRegion();

	if (FactionState == none)
	{
		return (ResistanceActive() && (RegionState != none && RegionState.ResistanceLevel == eResLevel_Outpost));
	}
	else
	{
		return IsResistanceFactionMet();
	}
}

function class<UIStrategyMapItem> GetUIClass()
{
	if (IsFactionHQ())
		return class'UIStrategyMapItem_ResistanceHQ';
	else
		return class'UIStrategyMapItem_Haven';
}

// The static mesh for this entities 3D UI
function StaticMesh GetStaticMesh()
{
	local Object MeshObject;

	if (IsFactionHQ())
	{
		MeshObject = `CONTENT.RequestGameArchetype(GetResistanceFaction().GetMyTemplate().OverworldMeshPath);
		if (MeshObject != none && MeshObject.IsA('StaticMesh'))
		{
			return StaticMesh(MeshObject);
		}
	}
	
	return StaticMesh'UI_3D.Overwold_Final.RadioTower';
}

// Scale adjustment for the 3D UI static mesh
function vector GetMeshScale()
{
	local vector ScaleVector;

	ScaleVector.X = 1.0;
	ScaleVector.Y = 1.0;
	ScaleVector.Z = 1.0;

	return ScaleVector;
}

// Rotation adjustment for the 3D UI static mesh
function Rotator GetMeshRotator()
{
	local Rotator MeshRotation;

	MeshRotation.Roll = 0;
	MeshRotation.Pitch = 0;
	MeshRotation.Yaw = 0;

	return MeshRotation;
}

protected function bool CanInteract()
{
	return (ResistanceActive() && IsResistanceFactionMet());
}

//---------------------------------------------------------------------------------------
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
	local XComGameState_Haven HavenState;
	local bool bSuccess;

	if (ShouldUpdate())
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Update Haven");

		HavenState = XComGameState_Haven(NewGameState.ModifyStateObject(class'XComGameState_Haven', ObjectID));

		bSuccess = HavenState.Update(NewGameState);
		`assert( bSuccess );

		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}

	if (AmountForFlyoverPopup > 0)
	{
		FlyoverPopup();
	}
}

//---------------------------------------------------------------------------------------
function DestinationReached()
{
	super.DestinationReached();
	OnXCOMArrives();
}

//---------------------------------------------------------------------------------------
function OnXCOMArrives()
{
	local XComGameState NewGameState;

	if(GetResistanceMode().OnXCOMArrivesFn != none)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Arrive Res HQ: Apply Scan Mode Bonus");
		GetResistanceMode().OnXCOMArrivesFn(NewGameState, self.GetReference());
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
}

function OnXComLeaveSite()
{
	super.OnXComLeaveSite();
	OnXCOMLeaves();
}

//---------------------------------------------------------------------------------------
function OnXCOMLeaves()
{
	local XComGameState NewGameState;

	if(GetResistanceMode().OnXCOMLeavesFn != none)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Leave Res HQ: Remove Scan Mode Bonus");
		GetResistanceMode().OnXCOMLeavesFn(NewGameState, self.GetReference());
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
}

simulated function OutpostBuiltCB(Name eAction, out DynamicPropertySet AlertData, optional bool bInstant = false)
{
	local XComGameState_HeadquartersXCom XComHQ;

	if( eAction == 'eUIAction_Accept' || eAction == 'eUIAction_Cancel' )
	{
		XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
		if( !XComHQ.bHasSeenSupplyDropReminder && XComHQ.IsSupplyDropAvailable() )
		{
			`HQPRES.UISupplyDropReminder();
		}

		`GAME.GetGeoscape().Resume();
	}
}

//---------------------------------------------------------------------------------------
simulated public function FlyoverPopup()
{
	local XComGameState NewGameState;
	local XComGameState_Haven HavenState;
	local string FlyoverResourceName;
	local Vector2D MessageLocation; 
		
	`XSTRATEGYSOUNDMGR.PlaySoundEvent("StrategyUI_Flyover_Intel");

	FlyoverResourceName = class'UIUtilities_Strategy'.static.GetResourceDisplayName(ResHQScanResource, AmountForFlyoverPopup);
	MessageLocation = Get2DLocation();
	MessageLocation.Y -= 0.006; //scoot above the pin
	`HQPRES.QueueWorldMessage(FlyoverResourceName $ " +" $ AmountForFlyoverPopup, `EARTH.ConvertEarthToWorld(MessageLocation), , , , , , , , 2.0);
	`HQPRES.m_kAvengerHUD.UpdateResources();

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Toggle Flyover Popup");
	HavenState = XComGameState_Haven(NewGameState.ModifyStateObject(class'XComGameState_Haven', self.ObjectID));
	HavenState.AmountForFlyoverPopup = 0;
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

simulated function string GetUIButtonTooltipTitle()
{
	local XComGameState_WorldRegion WorldRegion;

	WorldRegion = GetWorldRegion();
	if (WorldRegion != none)
		return class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS(GetDisplayName()$":" @ GetWorldRegion().GetDisplayName());

	return class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS(GetDisplayName());
}

simulated function string GetUIButtonTooltipBody()
{
	return GetScanDescription();
}

simulated function string GetUIButtonIcon()
{
	if(CanBeScanned())
		return "img:///UILibrary_StrategyImages.X2StrategyMap.MissionIcon_ResHQ";
	else
		return "img:///UILibrary_XPACK_StrategyImages.Faction_unknown";
}

//---------------------------------------------------------------------------------------
DefaultProperties
{
	bCheckForOverlaps = false;
}