//---------------------------------------------------------------------------------------
//  FILE:    XComGameState_RegionLink.uc
//  AUTHOR:  Jake Solomon
// 
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComGameState_RegionLink extends XComGameState_GeoscapeEntity
	config(GameBoard);

struct RegionDFSNode
{
	var XComGameState_WorldRegion RegionState;
	var bool bVisited;
};

var EResistanceLevelType				ResistanceLevel;  
var array<StateObjectReference>			LinkedRegions;
var float LinkLength;
var float LinkLocLerp;


var config int							MinLinksPerRegion;
var config int							MaxLinksPerRegion;
var config array<RegionLinkLength>		RegionLinkLengths;

var private vector WorldPosA;
var private vector WorldPosB;
var private bool WorldLocationsComputed;

//#############################################################################################
//----------------   INITIALIZATION   ---------------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
static function X2StrategyElementTemplateManager GetMyTemplateManager()
{
	return class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
}

//---------------------------------------------------------------------------------------
// Region Links created and activated randomly
static function SetUpRegionLinks(XComGameState StartState)
{
	local XComGameState_RegionLink LinkState;
	local XComGameState_WorldRegion RegionState;

	VerifyTemplateLinks();
	CreateAllLinks(StartState);
	RandomizeLinks(StartState);

	foreach StartState.IterateByClassType(class'XComGameState_RegionLink', LinkState)
	{
		RegionState = XComGameState_WorldRegion(StartState.GetGameStateForObjectID(LinkState.LinkedRegions[0].ObjectID));
		LinkState.Location = RegionState.Location;
		LinkState.Location.z = 0.2;
	}
}

//---------------------------------------------------------------------------------------
static function CreateAllLinks(XComGameState StartState)
{
	local X2StrategyElementTemplateManager StratMgr;
	local array<X2StrategyElementTemplate> RegionTemplates;
	local X2WorldRegionTemplate RegionTemplateA, RegionTemplateB;
	local int iRegion, iLink;

	StratMgr = GetMyTemplateManager();
	RegionTemplates = StratMgr.GetAllTemplatesOfClass(class'X2WorldRegionTemplate');

	for(iRegion = 0; iRegion < RegionTemplates.Length; iRegion++)
	{
		RegionTemplateA = X2WorldRegionTemplate(RegionTemplates[iRegion]);

		for(iLink = 0; iLink < RegionTemplateA.LinkedRegions.Length; iLink++)
		{
			RegionTemplateB = X2WorldRegionTemplate(StratMgr.FindStrategyElementTemplate(RegionTemplateA.LinkedRegions[iLink]));
			CreateLink(StartState, RegionTemplateA, RegionTemplateB);
		}
	}
}

//---------------------------------------------------------------------------------------
static function CreateLink(XComGameState StartState, X2WorldRegionTemplate RegionTemplateA, X2WorldRegionTemplate RegionTemplateB)
{
	local XComGameState_WorldRegion RegionState, RegionStateA, RegionStateB;
	local XComGameState_RegionLink RegionLinkState;
	local int RegionLinkLengthIndex;

	// Grab the two relevant regions
	foreach StartState.IterateByClassType(class'XComGameState_WorldRegion', RegionState)
	{
		if(RegionState.GetMyTemplateName() == RegionTemplateA.DataName)
		{
			RegionStateA = RegionState;
		}
		else if(RegionState.GetMyTemplateName() == RegionTemplateB.DataName)
		{
			RegionStateB = RegionState;
		}
	}

	if(RegionStateA == none || RegionStateB == none)
	{
		return;
	}

	// Check if link already exists, and add link if not
	if(RegionStateA.LinkedRegions.Find('ObjectID', RegionStateB.ObjectID) == INDEX_NONE)
	{
		RegionStateA.LinkedRegions.AddItem(RegionStateB.GetReference());
		RegionStateB.LinkedRegions.AddItem(RegionStateA.GetReference());

		RegionLinkState = XComGameState_RegionLink(StartState.CreateNewStateObject(class'XComGameState_RegionLink'));
		RegionLinkState.LinkedRegions.AddItem(RegionStateA.GetReference());
		RegionLinkState.LinkedRegions.AddItem(RegionStateB.GetReference());
		RegionLinkLengthIndex = RegionLinkState.FindRegionLinkLengthIndex(RegionStateA.GetMyTemplateName(), RegionStateB.GetMyTemplateName());
		if (RegionLinkLengthIndex != INDEX_NONE)
		{
			RegionLinkState.LinkLength = default.RegionLinkLengths[RegionLinkLengthIndex].LinkLength;
			RegionLinkState.LinkLocLerp = default.RegionLinkLengths[RegionLinkLengthIndex].LinkLocLerp;
		}
	}
}

//---------------------------------------------------------------------------------------
private function int FindRegionLinkLengthIndex(name RegionATemplateName, name RegionBTemplateName)
{
	local int idx;

	for(idx = 0; idx < default.RegionLinkLengths.Length; idx++)
	{
		if((RegionLinkLengths[idx].RegionA == RegionATemplateName && RegionLinkLengths[idx].RegionB == RegionBTemplateName) ||
		   (RegionLinkLengths[idx].RegionA == RegionBTemplateName && RegionLinkLengths[idx].RegionB == RegionATemplateName))
		{
			return idx;
		}
	}

	`RedScreen("Could not find region link length between" @ RegionATemplateName @ "and" @ RegionBTemplateName $ ". @gameplay -mnauta");
	return INDEX_NONE;
}

//---------------------------------------------------------------------------------------
static function RandomizeLinks(XComGameState StartState)
{
	local XComGameState_WorldRegion RegionState, StartRegion;
	local array<XComGameState_WorldRegion> AllRegions;
	local int idx, RollChance, RandIndex;

	// First pick a potential starting region
	foreach StartState.IterateByClassType(class'XComGameState_WorldRegion', RegionState)
	{
		if(IsEligibleStartRegion(StartState, RegionState))
		{
			AllRegions.AddItem(RegionState);
		}
	}

	// Ensure it only has links to continental regions
	RandIndex = `SYNC_RAND_STATIC(AllRegions.Length);
	StartRegion = AllRegions[RandIndex];
	RemoveNonContinentLinks(StartState, StartRegion);

	// repeat until graph is valid
	while(!GraphIsValid(StartState))
	{
		AllRegions.Remove(RandIndex, 1);

		if(AllRegions.Length == 0)
		{
			`RedScreen("Could not find valid starting region. @gameplay -mnauta");
			break;
		}

		// Restore All Links
		CreateAllLinks(StartState);

		// Try a different potential starting region
		RandIndex = `SYNC_RAND_STATIC(AllRegions.Length);
		StartRegion = AllRegions[RandIndex];
		RemoveNonContinentLinks(StartState, StartRegion);
	}

	// Grab all regions except starting region
	foreach StartState.IterateByClassType(class'XComGameState_WorldRegion', RegionState)
	{
		if(RegionState.ObjectID != StartRegion.ObjectID)
		{
			AllRegions.AddItem(RegionState);
		}
	}

	AllRegions.Sort(SortRegions);

	for(idx = 0; idx < AllRegions.Length; idx++)
	{
		RegionState = AllRegions[idx];

		// First get down to max links if above the limit
		while(RegionState.LinkedRegions.Length > default.MaxLinksPerRegion)
		{
			if(!RemoveRandomLink(StartState, RegionState, StartRegion))
			{
				break;
			}
		}

		// Next roll to remove more
		if(RegionState.LinkedRegions.Length == (default.MinLinksPerRegion + 1))
		{
			RollChance = 10;
		}
		else
		{
			RollChance = 20;
		}

		while(class'X2StrategyGameRulesetDataStructures'.static.Roll(RollChance) && RegionState.LinkedRegions.Length > default.MinLinksPerRegion)
		{
			if(!RemoveRandomLink(StartState, RegionState, StartRegion))
			{
				break;
			}
		}
	}
}

//---------------------------------------------------------------------------------------
static function bool IsEligibleStartRegion(XComGameState StartState, XComGameState_WorldRegion RegionState)
{
	local XComGameState_WorldRegion LinkedRegionState;
	local int idx, Count;

	Count = 0;

	for(idx = 0; idx < RegionState.LinkedRegions.Length; idx++)
	{
		LinkedRegionState = XComGameState_WorldRegion(StartState.GetGameStateForObjectID(RegionState.LinkedRegions[idx].ObjectID));

		if(LinkedRegionState != none && TriggerOverrideAllowStartingRegionLink(StartState, RegionState, LinkedRegionState) /* Issue #774 */)
		{
			Count++;
		}
	}

	return (Count > 1);
}

// Start Issue #774
//
/// HL-Docs: feature:OverrideAllowStartingRegionLink; issue:774; tags:strategy
/// This event allows mods to override the default behavior for whether a region
/// can be linked to a potential starting region. The default behavior is that
/// the two regions must be in the same continent if they are to be linked.
///
/// To override that behavior, add a listener that has `RegisterInCampaignStart`
/// set to `true` and within the listener function simply change the value of the
/// `AllowLink` field in the given tuple data. For example, you could always set
/// it to `true` to remove the constraints completely, so that a starting region
/// can be linked to any neighboring region.
///
/// This event is triggered during a start state, which you can access via
/// `XComGameStateHistory:GetStartState()`.
///
/// ```event
/// EventID: OverrideAllowStartingRegionLink,
/// EventData: [ in XComGameState_WorldRegion LinkedRegion, inout bool AllowLink ],
/// EventSource: XComGameState_WorldRegion (PotentialStartRegion),
/// NewGameState: none
/// ```
//
// **NOTE** This function is public so that it can be called from `XComGameState_WorldRegion`.
// It is not intended to be used by mods and hence it is **not** part of the highlander's
// public API. Backwards compatibility is not guaranteed.
static function bool TriggerOverrideAllowStartingRegionLink(
	XComGameState StartState,
	XComGameState_WorldRegion RegionState,
	XComGameState_WorldRegion LinkedRegionState)
{
	local XComLWTuple OverrideTuple;

	OverrideTuple = new class'XComLWTuple';
	OverrideTuple.Id = 'OverrideAllowStartingRegionLink';
	OverrideTuple.Data.Add(2);
	OverrideTuple.Data[0].kind = XComLWTVObject;
	OverrideTuple.Data[0].o = LinkedRegionState;
	OverrideTuple.Data[1].kind = XComLWTVBool;
	OverrideTuple.Data[1].b = LinkedRegionState.Continent == RegionState.Continent; // Regions must be on same continent by default

	`XEVENTMGR.TriggerEvent(OverrideTuple.Id, OverrideTuple, RegionState);

	return OverrideTuple.Data[1].b;
}
// End Issue #774

//---------------------------------------------------------------------------------------
static function RemoveNonContinentLinks(XComGameState StartState, XComGameState_WorldRegion RegionState)
{
	local XComGameState_WorldRegion LinkedRegionState;
	local int idx;

	for(idx = 0; idx < RegionState.LinkedRegions.Length; idx++)
	{
		LinkedRegionState = XComGameState_WorldRegion(StartState.GetGameStateForObjectID(RegionState.LinkedRegions[idx].ObjectID));

		if(LinkedRegionState != none && !TriggerOverrideAllowStartingRegionLink(StartState, RegionState, LinkedRegionState) /* Issue #774 */)
		{
			RemoveLink(StartState, RegionState, LinkedRegionState);
		}
	}
}

//---------------------------------------------------------------------------------------
private function int SortRegions(XComGameState_WorldRegion RegionStateA, XComGameState_WorldRegion RegionStateB)
{
	return (RegionStateA.LinkedRegions.Length - RegionStateB.LinkedRegions.Length);
}

//---------------------------------------------------------------------------------------
static function bool RemoveRandomLink(XComGameState StartState, XComGameState_WorldRegion RegionState, XComGameState_WorldRegion StartRegion)
{
	local XComGameState_WorldRegion LinkedRegion;
	local array<StateObjectReference> RegionLinks;
	local int RandIndex;
	local bool bSuccess;

	bSuccess = false;
	RegionLinks = RegionState.LinkedRegions;

	while(!bSuccess && RegionLinks.Length > 0)
	{
		RandIndex = `SYNC_RAND_STATIC(RegionLinks.Length);
		LinkedRegion = XComGameState_WorldRegion(StartState.GetGameStateForObjectID(RegionLinks[RandIndex].ObjectID));
		RegionLinks.Remove(RandIndex, 1);

		RemoveLink(StartState, RegionState, LinkedRegion);

		if(GraphIsValid(StartState, StartRegion))
		{
			bSuccess = true;
		}
		else
		{
			CreateLink(StartState, RegionState.GetMyTemplate(), LinkedRegion.GetMyTemplate());
		}
	}

	return bSuccess;
}

//---------------------------------------------------------------------------------------
static function RemoveLink(XComGameState StartState, XComGameState_WorldRegion RegionStateA, XComGameState_WorldRegion RegionStateB)
{
	local XComGameState_RegionLink LinkState;

	RegionStateA.LinkedRegions.RemoveItem(RegionStateB.GetReference());
	RegionStateB.LinkedRegions.RemoveItem(RegionStateA.GetReference());

	foreach StartState.IterateByClassType(class'XComGameState_RegionLink', LinkState)
	{
		if(LinkState.LinkedRegions.Find('ObjectID', RegionStateA.ObjectID) != INDEX_NONE &&
		   LinkState.LinkedRegions.Find('ObjectID', RegionStateB.ObjectID) != INDEX_NONE)
		{
			break;
		}
	}

	StartState.PurgeGameStateForObjectID(LinkState.ObjectID);
}

//---------------------------------------------------------------------------------------
static function bool GraphIsValid(XComGameState StartState, optional XComGameState_WorldRegion StartRegion = none)
{
	local array<RegionDFSNode> Nodes;
	local RegionDFSNode Node;
	local XComGameState_WorldRegion RegionState, LinkedRegion;
	local int idx;
	local bool bSameContinent;

	// Start Region must still be eligible to be a start region
	if(StartRegion != none)
	{
		if(!IsEligibleStartRegion(StartState, StartRegion))
		{
			return false;
		}
	}

	foreach StartState.IterateByClassType(class'XComGameState_WorldRegion', RegionState)
	{
		// Must be linked to at least one region on same continent
		bSameContinent = false;
		for(idx = 0; idx < RegionState.LinkedRegions.Length; idx++)
		{
			LinkedRegion = XComGameState_WorldRegion(StartState.GetGameStateForObjectID(RegionState.LinkedRegions[idx].ObjectID));

			if(LinkedRegion.Continent == RegionState.Continent)
			{
				bSameContinent = true;
				break;
			}
		}

		if(!bSameContinent)
		{
			return false;
		}

		Node.RegionState = RegionState;
		Nodes.AddItem(Node);
	}

	RegionDepthFirstSearch(StartState, 0, Nodes);

	for(idx = 0; idx < Nodes.Length; idx++)
	{
		if(!Nodes[idx].bVisited)
		{
			return false;
		}
	}

	return true;
}

//---------------------------------------------------------------------------------------
static function RegionDepthFirstSearch(XComGameState StartState, int GraphIndex, out array<RegionDFSNode> Nodes)
{
	local int iLink, iNode;

	Nodes[GraphIndex].bVisited = true;

	for(iLink = 0; iLink < Nodes[GraphIndex].RegionState.LinkedRegions.Length; iLink++)
	{
		for(iNode = 0; iNode < Nodes.Length; iNode++)
		{
			if(Nodes[iNode].RegionState.GetReference() == Nodes[GraphIndex].RegionState.LinkedRegions[iLink] &&
			   !Nodes[iNode].bVisited)
			{
				RegionDepthFirstSearch(StartState, iNode, Nodes);
				break;
			}
		}
	}
}

//---------------------------------------------------------------------------------------
// Check that there isn't inconsistent region link data in the Region templates
static function VerifyTemplateLinks()
{
	local X2StrategyElementTemplateManager StratMgr;
	local array<X2StrategyElementTemplate> RegionTemplates;
	local X2WorldRegionTemplate RegionTemplateA, RegionTemplateB;
	local bool bInconsistent;
	local int iRegion, iLink;
	local string ErrorMsg;

	StratMgr = GetMyTemplateManager();
	RegionTemplates = StratMgr.GetAllTemplatesOfClass(class'X2WorldRegionTemplate');
	bInconsistent = false;
	ErrorMsg = "";

	// Iterate through all region templates
	for(iRegion = 0; iRegion < RegionTemplates.Length; iRegion++)
	{
		RegionTemplateA = X2WorldRegionTemplate(RegionTemplates[iRegion]);

		// Iterate through possible links to flag inconsistencies
		for(iLink = 0; iLink < RegionTemplateA.LinkedRegions.Length; iLink++)
		{
			RegionTemplateB = X2WorldRegionTemplate(StratMgr.FindStrategyElementTemplate(RegionTemplateA.LinkedRegions[iLink]));

			// Check for bad region name
			if(RegionTemplateB == none)
			{
				bInconsistent = true;
				ErrorMsg $= "Bad Region name (" $ string(RegionTemplateA.LinkedRegions[iLink]) $ ") in" @ string(RegionTemplateA.DataName) $ "'s LinkedRegions list.\n";
			}
			else if(RegionTemplateB.LinkedRegions.Find(RegionTemplateA.DataName) == INDEX_NONE)
			{
				// Link not reciprocated
				bInconsistent = true;
				ErrorMsg $= "Inconsistent Region Link Data:" @ string(RegionTemplateA.DataName) @ "links to" @ string(RegionTemplateB.DataName) $ ", but not vice-versa.\n";
			}
		}
	}

	// if inconsistencies redscreen, so that region templates can be repaired
	if(bInconsistent)
	{
		`Redscreen(ErrorMsg);
	}
}

//#############################################################################################
//----------------   Geoscape Entity Implementation   -----------------------------------------
//#############################################################################################

function class<UIStrategyMapItem> GetUIClass()
{
	return class'UIStrategyMapItem_RegionLink';
}

function string GetUIWidgetFlashLibraryName()
{
	return string(class'UIPanel'.default.LibID);
}

function string GetUIPinImagePath()
{
	return "";
}

// The static mesh for this entities 3D UI
function StaticMesh GetStaticMesh()
{
	return StaticMesh'Strat_HoloOverworld.RegionLinkMesh';
}

// Scale adjustment for the 3D UI static mesh
function vector GetMeshScale()
{
	local vector ScaleVector;

	ScaleVector.X = GetLinkDistance();
	ScaleVector.Y = 1;
	ScaleVector.Z = 1;

	return ScaleVector;
}

function Rotator GetMeshRotator()
{
	local XComGameState_RegionLink LinkState;
	local Rotator MeshRotator;

	LinkState = ComputeWorldLocations();

	MeshRotator = rotator(LinkState.WorldPosB - LinkState.WorldPosA);
	return MeshRotator;
}

function float GetOldWorldLocationLerp()
{
	local XComGameState_WorldRegion RegionStateA, RegionStateB;
	local Vector2D v2Start, v2End;
	local vector WorldA, WorldB, BorderClippedA;

	RegionStateA = XComGameState_WorldRegion(`XCOMHISTORY.GetGameStateForObjectID(LinkedRegions[0].ObjectID));
	RegionStateB = XComGameState_WorldRegion(`XCOMHISTORY.GetGameStateForObjectID(LinkedRegions[1].ObjectID));

	v2Start = RegionStateA.Get2DLocation();
	v2End = GetClosestWrappedCoordinate(v2Start, RegionStateB.Get2DLocation());
	WorldA = `EARTH.ConvertEarthToWorld(v2Start, false);
	WorldB = `EARTH.ConvertEarthToWorld(v2End, false);
	BorderClippedA = RegionStateA.GetBorderIntersectionPoint(WorldA, WorldB);

	return VSize(BorderClippedA - WorldA) / VSize(WorldB - WorldA);
}

function UpdateWorldLocation()
{
	local XComGameState_WorldRegion RegionStateA, RegionStateB;
	local Vector2D v2Start, v2End;

	RegionStateA = XComGameState_WorldRegion(`XCOMHISTORY.GetGameStateForObjectID(LinkedRegions[0].ObjectID));
	RegionStateB = XComGameState_WorldRegion(`XCOMHISTORY.GetGameStateForObjectID(LinkedRegions[1].ObjectID));

	v2Start = RegionStateA.Get2DLocation();
	v2End = GetClosestWrappedCoordinate(v2Start, RegionStateB.Get2DLocation());
	WorldPosA = `EARTH.ConvertEarthToWorld(v2Start, false);
	WorldPosB = `EARTH.ConvertEarthToWorld(v2End, false);
	WorldPosA = WorldPosA * (1.0f - LinkLocLerp) + WorldPosB * LinkLocLerp;
	v2Start = `EARTH.ConvertWorldToEarth(WorldPosA);
	Location.X = v2Start.X;
	Location.Y = v2Start.Y;
}

function XComGameState_RegionLink ComputeWorldLocations()
{
	local XComGameState NewGameState;
	local XComGameState_RegionLink LinkState;
	local XComGameState_WorldRegion RegionStateA, RegionStateB;
	local Vector2D v2Start, v2End;

	if (WorldLocationsComputed)
		return self;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Compute Region Link World Locations");
	LinkState = XComGameState_RegionLink(NewGameState.ModifyStateObject(class'XComGameState_RegionLink', self.ObjectID));

	RegionStateA = XComGameState_WorldRegion(`XCOMHISTORY.GetGameStateForObjectID(LinkState.LinkedRegions[0].ObjectID));
	RegionStateB = XComGameState_WorldRegion(`XCOMHISTORY.GetGameStateForObjectID(LinkState.LinkedRegions[1].ObjectID));

	v2Start = RegionStateA.Get2DLocation();
	v2End = GetClosestWrappedCoordinate(v2Start, RegionStateB.Get2DLocation());
	LinkState.WorldPosA = `EARTH.ConvertEarthToWorld(v2Start, false);
	LinkState.WorldPosB = `EARTH.ConvertEarthToWorld(v2End, false);
	LinkState.WorldPosA = LinkState.WorldPosA * (1.0f - LinkState.LinkLocLerp) + LinkState.WorldPosB * LinkState.LinkLocLerp;
	v2Start = `EARTH.ConvertWorldToEarth(WorldPosA);
	Location.X = v2Start.X;
	Location.Y = v2Start.Y;
	LinkState.WorldLocationsComputed = true;

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	return LinkState;
}

function vector GetWorldLocation()
{
	local XComGameState_RegionLink LinkState;
	LinkState = ComputeWorldLocations();
	return LinkState.WorldPosA;
}

function float GetLinkDistance()
{
	return LinkLength;
}

function UpdateGameBoard()
{
}

protected function bool CanInteract()
{
	// functionality moved to Haven
	return false;
}

function bool ShouldBeVisible()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_WorldRegion RegionState;
	local UIStrategyMap kMap;
	local int idx;

	kMap = UIStrategyMap(`SCREENSTACK.GetScreen(class'UIStrategyMap'));

	if(kMap != none && kMap.m_eUIState == eSMS_Resistance)
	{
		return true;
	}

	if (IsOnGPOrAlienFacilityPath()) // If this link is on the critical path to a mission, always display it
	{
		return true;
	}

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	if(XComHQ.IsContactResearched())
	{
		for(idx = 0; idx < LinkedRegions.Length; idx++)
		{
			RegionState = XComGameState_WorldRegion(History.GetGameStateForObjectID(LinkedRegions[idx].ObjectID));

			if(RegionState != none && RegionState.HaveMadeContact())
			{
				return true;
			}
		}
	}
	

	return false;
}

function bool IsOnGPOrAlienFacilityPath()
{
	local XComGameStateHistory History;
	local XComGameState_WorldRegion RegionStateA, RegionStateB;

	History = `XCOMHISTORY;
	RegionStateA = XComGameState_WorldRegion(History.GetGameStateForObjectID(LinkedRegions[0].ObjectID));
	RegionStateB = XComGameState_WorldRegion(History.GetGameStateForObjectID(LinkedRegions[1].ObjectID));

	if (RegionStateA.bOnGPOrAlienFacilityPath && RegionStateB.bOnGPOrAlienFacilityPath && (!RegionStateA.HaveMadeContact() || !RegionStateB.HaveMadeContact()))
	{
		return true;
	}

	return false;
}

DefaultProperties
{

}
