//---------------------------------------------------------------------------------------
//  FILE:    XComGameState_PointOfInterest.uc
//  AUTHOR:  Ryan McFall  --  02/18/2014
//  PURPOSE: This object represents the instance data for a point of interest within the strategy
//           game of X-Com 2. For more information on the design spec for points of interest, refer to
//           https://arcade/sites/2k/Studios/Firaxis/XCOM2/Shared%20Documents/World%20Map%20and%20Strategy%20AI.docx
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComGameState_PointOfInterest extends XComGameState_ScanningSite 
	config(GameBoard)
	native(Core);

var() protected name                        m_TemplateName;
var() protected X2PointOfInterestTemplate   m_Template;

var() int									Weight;
var() int									Delta; // the amount the weight will be decreased each time this POI is spawned
var() int									NumSpawns; // the number of times this POI has been spawned
var() TDateTime								NextWeightUpdateDate; // the date when the next weight and delta will be applied
var() int									CurrentWeightIndex; // the index of the current weight / delta pair
var() bool									bCheckForWeightUpdate; // if the poi still has weights left to apply

var() int									POIDataIndex;
var() array<int>							AvailablePOIs;

var() bool									bAvailable;
var() bool									bTriggerAppearedPopup; // Should the POI Appeared popup be triggered at the next available time
var() bool									bNeedsAppearedPopup; // Does this POI need to show its popup for appearing for the first time
var() bool									bNeedsScanCompletePopup; // Does this POI need to show its completed popup
var() TDateTime								DespawnTime; // The time this POI will disappear if not scanned
var() StateObjectReference					ResistanceRegion; // The region which spawned this POI
var() array<StateObjectReference>			RewardRefs; // The reference to the rewards this POI will give the player

var() config array<int>						MinDespawnHours; // Lower limit of how long until the POI despawns
var() config array<int>						MaxDespawnHours; // Upper limit of how long until the POI despawns

//#############################################################################################
//----------------   INITIALIZATION   ---------------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
static function X2StrategyElementTemplateManager GetMyTemplateManager()
{
	return class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
}

//---------------------------------------------------------------------------------------
simulated function name GetMyTemplateName()
{
	return m_TemplateName;
}

//---------------------------------------------------------------------------------------
simulated function X2PointOfInterestTemplate GetMyTemplate()
{
	if (m_Template == none)
	{
		m_Template = X2PointOfInterestTemplate(GetMyTemplateManager().FindStrategyElementTemplate(m_TemplateName));
	}
	return m_Template;
}

//---------------------------------------------------------------------------------------
static function SetUpPOIs(XComGameState StartState, optional int UseTemplateGameArea=-1)
{
	local array<X2StrategyElementTemplate> POITemplates;
	local int idx;

	// Grab all DarkEvent Templates
	POITemplates = GetMyTemplateManager().GetAllTemplatesOfClass(class'X2PointOfInterestTemplate', UseTemplateGameArea);

	// Iterate through the templates and build each POI State Object
	for (idx = 0; idx < POITemplates.Length; idx++)
	{
		X2PointOfInterestTemplate(POITemplates[idx]).CreateInstanceFromTemplate(StartState);
	}
}

//---------------------------------------------------------------------------------------
event OnCreation(optional X2DataTemplate InTemplate)
{
	local int idx;

	super.OnCreation(InTemplate);

	m_Template = X2PointOfInterestTemplate(InTemplate);
	m_TemplateName = m_Template.DataName;

	if (m_Template.Weights.Length == 0)
	{
		`RedScreen("POI Template does not have weight data: " @ m_Template.Name);
	}
	else
	{
		UpdateWeightAndDelta(m_Template);
	}

	bAvailable = false;

	if (m_Template.DisplayNames.Length != m_Template.CompletedSummaries.Length ||
		m_Template.DisplayNames.Length != m_Template.POIImages.Length)
	{
		`RedScreen("POI Template does not have equal display, summary, or image string arrays: " @ m_Template.Name);
	}
	else
	{
		// Generate the list of POI information indices
		for (idx = 0; idx < m_Template.DisplayNames.Length; idx++)
		{
			AvailablePOIs.AddItem(idx);
		}
	}
}

//#############################################################################################
//----------------   SPAWNING   ======---------------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
function bool CanAppear()
{
	// Check template specific function
	if (GetMyTemplate().CanAppearFn != none)
	{
		return GetMyTemplate().CanAppearFn(self);
	}

	return true;
}

//---------------------------------------------------------------------------------------
function bool IsNeeded()
{
	// Check template specific function
	if (GetMyTemplate().IsRewardNeededFn != none)
	{
		return GetMyTemplate().IsRewardNeededFn(self);
	}

	return false;
}

//---------------------------------------------------------------------------------------
function Spawn(XComGameState NewGameState)
{
	// If we are in the tutorial sequence, the POI will be revealed after the Blacksite tutorial sequence
	if (class'XComGameState_HeadquartersXCom'.static.GetObjectiveStatus('T0_M8_ReturnToAvengerPt2') != eObjectiveState_InProgress)
	{
		bAvailable = true;
	}

	bTriggerAppearedPopup = true;
	bNeedsAppearedPopup = false;

	if (class'XComGameState_HeadquartersXCom'.static.GetObjectiveStatus('S1_ShortenFirstPOI') == eObjectiveState_InProgress)
	{
		// If this is the first POI, set the scan time to the minimum amount
		SetScanHoursRemaining(`ScaleStrategyArrayInt(MinScanDays), `ScaleStrategyArrayInt(MinScanDays));
	}
	else
	{
		SetScanHoursRemaining(`ScaleStrategyArrayInt(MinScanDays), `ScaleStrategyArrayInt(MaxScanDays));
	}

	ChooseInformation();
	SetContinent();
	GenerateRewards(NewGameState);
	
	if (!GetMyTemplate().bNeverExpires)
	{
		SetDespawnTime();
	}
}

//---------------------------------------------------------------------------------------
function ChooseInformation()
{
	local int idx, RandIndex;
	
	RandIndex = `SYNC_RAND_STATIC(AvailablePOIs.Length);
	POIDataIndex = AvailablePOIs[RandIndex];	
	AvailablePOIs.Remove(RandIndex, 1); // Remove the POI number which was just picked

	Weight -= Delta;
	Weight = max(Weight, 0); // ensure non-negative weight
	NumSpawns++;
	
	if (AvailablePOIs.Length == 0)
	{
		// If there are no available POIs (they have all been used already), regenerate the list
		for (idx = 0; idx < GetMyTemplate().DisplayNames.Length; idx++)
		{
			AvailablePOIs.AddItem(idx);
		}
	}
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

	ResistanceRegion = RegionState.GetReference();
	Continent = RegionState.GetContinent().GetReference();
	SetLocation(RegionState.GetContinent());
}

//---------------------------------------------------------------------------------------
function SetLocation(XComGameState_Continent ContinentState)
{
	Location = ContinentState.GetRandomLocationInContinent(, self);
}

//---------------------------------------------------------------------------------------
function SetDespawnTime()
{
	local int HoursToAdd, MinHours, MaxHours;

	MinHours = `ScaleStrategyArrayInt(MinDespawnHours);
	MaxHours = `ScaleStrategyArrayInt(MaxDespawnHours);

	HoursToAdd = MinHours + `SYNC_RAND(MaxHours - MinHours + 1);
	DespawnTime = GetCurrentTime();
	class'X2StrategyGameRulesetDataStructures'.static.AddHours(DespawnTime, HoursToAdd);
}

function GenerateRewards(XComGameState NewGameState)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local X2StrategyElementTemplateManager StratMgr;
	local XComGameState_Reward RewardState;
	local X2RewardTemplate RewardTemplate;
	local array<name> RewardTypes;
	local int RewardInstancesToGive, MinInstances, MaxInstances, idx, iInstance;
	local float HQScalar, BonusScalar;
		
	StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
	RewardTypes = GetMyTemplate().RewardTypes;
	RewardRefs.Length = 0; // Reset the rewards
	
	// Certain rewards are given multiple times per state (ex: Rookies)
	MinInstances = `ScaleStrategyArrayInt(GetMyTemplate().MinRewardInstanceAmount);
	MaxInstances = `ScaleStrategyArrayInt(GetMyTemplate().MaxRewardInstanceAmount);
	RewardInstancesToGive = MinInstances + `SYNC_RAND(MaxInstances - MinInstances + 1);

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	HQScalar = 1.0f;

	if(XComHQ.BonusPOIScalar > 0)
	{
		HQScalar = XComHQ.BonusPOIScalar;
	}
	
	for (iInstance = 0; iInstance < RewardInstancesToGive; iInstance++)
	{
		for (idx = 0; idx < RewardTypes.Length; idx++)
		{
			RewardTemplate = X2RewardTemplate(StratMgr.FindStrategyElementTemplate(RewardTypes[idx]));

			// If XComHQ Bonus POI scalar is active, apply it only if the reward is a resource
			BonusScalar = (RewardTemplate.bResourceReward) ? HQScalar : 1.0f;

			RewardState = RewardTemplate.CreateInstanceFromTemplate(NewGameState);
			RewardState.GenerateReward(NewGameState, (`ScaleStrategyArrayFloat(GetMyTemplate().RewardScalar) * BonusScalar), ResistanceRegion);
			RewardRefs.AddItem(RewardState.GetReference());
		}
	}
}

function GiveRewards(XComGameState NewGameState)
{
	local XComGameState_Reward RewardState;
	local int idx;

	for (idx = 0; idx < RewardRefs.Length; idx++)
	{
		RewardState = XComGameState_Reward(`XCOMHISTORY.GetGameStateForObjectID(RewardRefs[idx].ObjectID));
		RewardState.GiveReward(NewGameState, ResistanceRegion);
	}
}

//#############################################################################################
//----------------   UPDATE   -----------------------------------------------------------------
//#############################################################################################

function StartScan()
{
	super.StartScan();

	// Reset the despawn timer every time a player scans at a POI
	SetDespawnTime();
}

// THIS FUNCTION SHOULD RETURN TRUE IN ALL THE SAME CASES AS Update
function bool ShouldUpdate( )
{
	local UIStrategyMap StrategyMap;
	local XComGameState_HeadquartersXCom XComHQ;

	StrategyMap = `HQPRES.StrategyMap2D;

	// Do not trigger anything while the Avenger or Skyranger are flying, or if another popup is already being presented
	if (bAvailable && StrategyMap != none && StrategyMap.m_eUIState != eSMS_Flight && !`HQPRES.ScreenStack.IsCurrentClass( class'UIAlert' ))
	{
		XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ( );

		// If the Avenger is not at the location and time runs out, despawn the POI
		if (XComHQ.CurrentLocation.ObjectID != ObjectID && !GetMyTemplate( ).bNeverExpires && class'X2StrategyGameRulesetDataStructures'.static.LessThan( DespawnTime, GetCurrentTime( ) ))
		{
			return true;
		}

		if (bTriggerAppearedPopup)
		{
			return true;
		}

		// Check if scanning is complete
		if (IsScanComplete( ))
		{
			return true;
		}
	}

	if (bCheckForWeightUpdate && class'X2StrategyGameRulesetDataStructures'.static.LessThan( NextWeightUpdateDate, GetCurrentTime( ) ))
	{
		return true;
	}

	return false;
}

//---------------------------------------------------------------------------------------
// IF ADDING NEW CASES WHERE bModified = true, UPDATE FUNCTION ShouldUpdate ABOVE
function bool Update(XComGameState NewGameState)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local bool bModified;
	local XComNarrativeMoment ScanNarrative;
	local UIStrategyMap StrategyMap;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	StrategyMap = `HQPRES.StrategyMap2D;
	bModified = false;

	// Do not trigger anything while the Avenger or Skyranger are flying, or if another popup is already being presented
	if (bAvailable && StrategyMap != none && StrategyMap.m_eUIState != eSMS_Flight && !`HQPRES.ScreenStack.IsCurrentClass(class'UIAlert'))
	{
		// If the Avenger is not at the location and time runs out, despawn the POI
		if (XComHQ.GetCurrentScanningSite().GetReference().ObjectID != ObjectID && !GetMyTemplate().bNeverExpires && class'X2StrategyGameRulesetDataStructures'.static.LessThan(DespawnTime, GetCurrentTime()))
		{
			bAvailable = false;
			ResetPOI(NewGameState);
			bModified = true;
		}

		if (bTriggerAppearedPopup)
		{
			bNeedsAppearedPopup = true;
			bModified = true;
		}

		// Check if scanning is complete
		if (IsScanComplete())
		{
			GiveRewards(NewGameState);
			bAvailable = false;
			bNeedsScanCompletePopup = true;
			bModified = true;
			`XEVENTMGR.TriggerEvent('POICompleted', , , NewGameState);
			class'XComGameState_HeadquartersResistance'.static.RecordResistanceActivity(NewGameState, 'ResAct_RumorsInvestigated');

			if(GetMyTemplate().CompleteNarrative != "")
			{
				ScanNarrative = XComNarrativeMoment(`CONTENT.RequestGameArchetype(GetMyTemplate().CompleteNarrative));
				if(ScanNarrative != None)
				{
					`HQPRES.UINarrative(ScanNarrative);
				}
			}
		}
	}

	if (bCheckForWeightUpdate && class'X2StrategyGameRulesetDataStructures'.static.LessThan(NextWeightUpdateDate, GetCurrentTime()))
	{
		bModified = true;
		CurrentWeightIndex++;
		UpdateWeightAndDelta(GetMyTemplate());
	}

	return bModified;
}

//---------------------------------------------------------------------------------------
function UpdateWeightAndDelta(X2PointOfInterestTemplate POITemplate)
{
	local int HoursToAdd;
	local array<int> WeightPerDifficulty;

	WeightPerDifficulty = POITemplate.Weights[CurrentWeightIndex].Weight;
	Weight = `ScaleStrategyArrayInt(WeightPerDifficulty);
	Delta = Weight / POITemplate.DisplayNames.Length; // Delta is Weight divided by number of possible appearances
	Weight -= Delta * NumSpawns;

	if (POITemplate.Weights.Length > (CurrentWeightIndex + 1))
	{
		HoursToAdd = POITemplate.Weights[CurrentWeightIndex].DaysActive * 24;
		NextWeightUpdateDate = GetCurrentTime();
		class'X2StrategyGameRulesetDataStructures'.static.AddHours(NextWeightUpdateDate, HoursToAdd);
		bCheckForWeightUpdate = true;
	}
	else
	{
		bCheckForWeightUpdate = false;
	}
}

//---------------------------------------------------------------------------------------
function ResetPOI(optional XComGameState NewGameState)
{
	local XComGameState_HeadquartersResistance ResHQ;

	ResetScan();

	ResHQ = class'UIUtilities_Strategy'.static.GetResistanceHQ();
	ResHQ.DeactivatePOI(NewGameState, GetReference());
}

//#############################################################################################
//----------------   Geoscape Entity Implementation   -----------------------------------------
//#############################################################################################

function string GetDisplayName()
{
	return GetMyTemplate().DisplayNames[POIDataIndex];
}

function string GetImage()
{
	return GetMyTemplate().POIImages[POIDataIndex];
}

function string GetSummary()
{
	return GetMyTemplate().CompletedSummaries[POIDataIndex];
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
	TooltipStr = GetRewardDescriptionString() $ ": " $ ScanTimeValue @ ScanTimeLabel @ m_strRemainingLabel;

	return TooltipStr;
}

function string GetResistanceRegionName()
{
	return XComGameState_WorldRegion(`XCOMHISTORY.GetGameStateForObjectID(ResistanceRegion.ObjectID)).GetDisplayName();
}

function string GetRewardDescriptionString()
{
	local X2StrategyElementTemplateManager StratMgr;
	local X2RewardTemplate RewardTemplate;
	local array<name> RewardTypes;
	local string strRewards;
	local int idx;

	RewardTypes = GetMyTemplate().RewardTypes;

	for (idx = 0; idx < RewardTypes.Length; idx++)
	{
		StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
		RewardTemplate = X2RewardTemplate(StratMgr.FindStrategyElementTemplate(RewardTypes[idx]));

		strRewards $= RewardTemplate.DisplayName;
			
		if (idx < (RewardTypes.Length - 1))
			strRewards $= ", ";
	}

	return class'UIUtilities_Text'.static.FormatCommaSeparatedNouns(strRewards);
}

function string GetRewardValuesString()
{
	local XComGameStateHistory History;
	local XComGameState_Reward RewardState;
	local string strRewards;
	local int idx;

	History = `XCOMHISTORY;

	for (idx = 0; idx < RewardRefs.Length; idx++)
	{
		RewardState = XComGameState_Reward(History.GetGameStateForObjectID(RewardRefs[idx].ObjectID));

		strRewards $= RewardState.GetRewardString();

		if (idx < (RewardRefs.Length - 1))
			strRewards $= ", ";
	}

	return class'UIUtilities_Text'.static.FormatCommaSeparatedNouns(strRewards);
}

function string GetRewardIconString()
{
	local XComGameStateHistory History;
	local XComGameState_Reward RewardState;
	local int idx;

	History = `XCOMHISTORY;	
	for (idx = 0; idx < RewardRefs.Length; idx++)
	{
		RewardState = XComGameState_Reward(History.GetGameStateForObjectID(RewardRefs[idx].ObjectID));
		
		if (RewardState != none)
		{
			return RewardState.GetRewardIcon();
		}
	}

	return "";
}

function bool ShouldBeVisible()
{
	return bAvailable;
}

function bool CanBeScanned()
{
	return bAvailable;
}

function class<UIStrategyMapItem> GetUIClass()
{
	return class'UIStrategyMapItem_POI';
}

// The static mesh for this entities 3D UI
function StaticMesh GetStaticMesh()
{
	return StaticMesh'UI_3D.Overwold_Final.Rumors';
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

function OnXComEnterSite()
{
	local XComGameState NewGameState;

	super.OnXComEnterSite();

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Trigger Event: Avenger Landed POI");
	`XEVENTMGR.TriggerEvent('AvengerLandedScanPOI', , , NewGameState);
	`GAMERULES.SubmitGameState(NewGameState);
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
	local XComGameState_PointOfInterest NewPOIState;
	local UIStrategyMap StrategyMap;
	local bool bSuccess;

	if (ShouldUpdate())
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState( "Update Point of Interest" );

		NewPOIState = XComGameState_PointOfInterest( NewGameState.ModifyStateObject( class'XComGameState_PointOfInterest', ObjectID ) );

		bSuccess = NewPOIState.Update(NewGameState);
		`assert( bSuccess ); // why did Update & ShouldUpdate return different bools?

		`XCOMGAME.GameRuleset.SubmitGameState( NewGameState );
		`HQPRES.StrategyMap2D.UpdateMissions( );
	}

	StrategyMap = `HQPRES.StrategyMap2D;
	if (StrategyMap != none && StrategyMap.m_eUIState != eSMS_Flight)
	{
		if (bNeedsAppearedPopup)
		{
			POIAppearedPopup();
		}
		else if (bNeedsScanCompletePopup)
		{
			POICompletePopup();
		}
	}
}

//---------------------------------------------------------------------------------------
simulated public function POIAppearedPopup()
{
	local XComGameState NewGameState;
	local XComGameState_PointOfInterest POIState;

	// If we are in the tutorial sequence, it will be revealed in the specific Blacksite objective
	if (class'XComGameState_HeadquartersXCom'.static.GetObjectiveStatus('T0_M10_IntroToBlacksite') != eObjectiveState_InProgress && 
		class'XComGameState_HeadquartersXCom'.static.GetObjectiveStatus('T2_M1_L0_LookAtBlacksite') != eObjectiveState_InProgress)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Toggle POI Appeared Popup");
		POIState = XComGameState_PointOfInterest(NewGameState.ModifyStateObject(class'XComGameState_PointOfInterest', self.ObjectID));
		POIState.bTriggerAppearedPopup = false;
		POIState.bNeedsAppearedPopup = false;
		`XEVENTMGR.TriggerEvent('RumorAppeared', , , NewGameState);
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

		`HQPRES.UIPointOfInterestAlert(GetReference());

		`GAME.GetGeoscape().Pause();
	}
}

//---------------------------------------------------------------------------------------
simulated public function POICompletePopup()
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_PointOfInterest POIState;
	local StateObjectReference RewardRef;
	local XComGameState_Reward RewardState;
	
	History = `XCOMHISTORY;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Toggle POI Complete Popup");
	POIState = XComGameState_PointOfInterest(NewGameState.ModifyStateObject(class'XComGameState_PointOfInterest', self.ObjectID));
	POIState.bNeedsScanCompletePopup = false;
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	foreach RewardRefs(RewardRef)
	{
		RewardState = XComGameState_Reward(History.GetGameStateForObjectID(RewardRef.ObjectID));
		RewardState.DisplayRewardPopup();
	}

	TriggerPOICompletePopup();	
	
	`GAME.GetGeoscape().Pause();
}

// Separated from the POICompletePopup function so it can be easily overwritten by mods
simulated function TriggerPOICompletePopup()
{
	`HQPRES.UIPointOfInterestCompleted(GetReference());
}

simulated function string GetUIButtonIcon()
{
	return "img:///UILibrary_StrategyImages.X2StrategyMap.MissionIcon_POI";
}

protected function bool CurrentlyInteracting()
{
	//If the avenger is landed here and the scan is available, then yes, we're interacting.
	return (CanBeScanned() && GetReference() == class'UIUtilities_Strategy'.static.GetXComHQ().CurrentLocation);
}
//#############################################################################################
DefaultProperties
{    
}