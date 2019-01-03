//---------------------------------------------------------------------------------------
//  FILE:    XComGameState_ResistanceFaction.uc
//  AUTHOR:  Mark Nauta  --  04/25/2016
//  PURPOSE: This object represents the instance data for a Resistance faction 
//           in the XCOM 2 strategy game
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComGameState_ResistanceFaction extends XComGameState_GeoscapeCharacter config(GameData);

// Template info
var protected name								  m_TemplateName;
var protected X2ResistanceFactionTemplate         m_Template;

// Basic Info
var string										  FactionName;
var string										  FlagBackgroundImage;
var string										  FlagForegroundImage;
var bool										  bMetXCom; // Covert Action completed where you get a soldier and reveal the HQ
var bool										  bNeedsFactionHQReveal;
var bool										  bSeenFactionHQReveal; // Has the Faction HQ reveal sequence been displayed yet
var int											  Strength;
var int											  InfluenceScore;
var EFactionInfluence							  Influence;
var int											  PopSupport;
var array<name>									  Traits;
var array<StateObjectReference>					  TerritoryRegions; // List of Regions for faction activities and rival chosen activities
var StateObjectReference						  FactionHQ; // The Haven which is this Faction's HQ on the Geoscape

// Covert Actions
var array<name>									  AvailableCovertActions;
var array<name>									  CompletedCovertActions;
var array<StateObjectReference>					  CovertActions; // The Covert Actions which can be run by this Faction in the facility
var array<StateObjectReference>					  GoldenPathActions;
var bool										  bNewFragmentActionAvailable; // Used for alerting the player that a new Fragment Action is available in the facility
var bool										  bFirstFaction;
var bool										  bFarthestFaction;
var TDateTime									  MetXComDate;

// Rival Chosen
var StateObjectReference						  RivalChosen;

// Card Vars
var array<StateObjectReference>					  CardSlots; // Holds active strategy cards (can be empty)
var array<StateObjectReference>					  OldCardSlots; // Store old cards so we don't reactivate them if played in consecutive months
var array<StateObjectReference>					  PlayableCards; // Faction cards that can be played
var array<StateObjectReference>					  NewPlayableCards; // Playable cards which the player has not seen an alert for

// Config Values
var config int									  NumStartingFacilityActions;
var config int									  MaxHeroesPerFaction;
var config int									  NumCardsOnMeet;
var config int									  StartingCardSlots;
var config int									  RequiredScoreForInfluence[EFactionInfluence.EnumCount]<BoundEnum = EFactionInfluence>;
var config int									  CovertActionsPerInfluence[EFactionInfluence.EnumCount]<BoundEnum = EFactionInfluence>;
var config array<int>							  MissionInfluenceMinReward;
var config array<int>							  MissionInfluenceMaxReward;

var localized array<string>						  FactionInfluenceStrings;

var config	StackedUIIconData					  FactionIconData; //User interface icon image information

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
simulated function X2ResistanceFactionTemplate GetMyTemplate()
{
	if(m_Template == none)
	{
		m_Template = X2ResistanceFactionTemplate(GetMyTemplateManager().FindStrategyElementTemplate(m_TemplateName));
	}
	return m_Template;
}

//---------------------------------------------------------------------------------------
event OnCreation(optional X2DataTemplate Template)
{
	local int idx;

	super.OnCreation( Template );

	m_Template = X2ResistanceFactionTemplate(Template);
	m_TemplateName = Template.DataName;

	for(idx = 0; idx < default.StartingCardSlots; idx++)
	{
		// Add Slots with empty entries
		AddCardSlot();
	}
}

//---------------------------------------------------------------------------------------
function InitializeHQ(XComGameState NewGameState, int idx)
{
	local X2ResistanceModeTemplate ResMode;
	local XComGameState_Haven HavenState;

	if(idx == 0)
	{
		// First haven is outpost of starting region, activate the res mode scanning bonus
		ResMode = GetResistanceMode();

		if(ResMode.OnActivatedFn != none)
		{
			ResMode.OnActivatedFn(NewGameState, self.GetReference());
		}

		foreach NewGameState.IterateByClassType(class'XComGameState_Haven', HavenState)
		{
			if(HavenState.Region == Region)
			{
				break;
			}
		}
	}
	else
	{
		HavenState = XComGameState_Haven(NewGameState.CreateNewStateObject(class'XComGameState_Haven'));
		HavenState.Continent = Continent;
	}

	HavenState.FactionRef = self.GetReference();
	HavenState.SetScanHoursRemaining(`ScaleStrategyArrayInt(HavenState.MinScanDays), `ScaleStrategyArrayInt(HavenState.MaxScanDays));
	HavenState.MakeScanRepeatable();
	
	FactionHQ = HavenState.GetReference(); // Save the HQ location
}

//---------------------------------------------------------------------------------------
function MeetXCom(XComGameState NewGameState)
{
	local XComGameState_HeadquartersResistance ResHQ;
	local array<Name> ExclusionList;
	local int idx;

	ResHQ = XComGameState_HeadquartersResistance(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersResistance'));
	ResHQ = XComGameState_HeadquartersResistance(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersResistance', ResHQ.ObjectID));
 	ExclusionList = ResHQ.CovertActionExclusionList; // Get the current list of covert actions for other factions from Res HQ

	bMetXCom = true;
	bNewFragmentActionAvailable = true;
	MetXComDate = GetCurrentTime();

	CleanUpFactionCovertActions(NewGameState);
	CreateGoldenPathActions(NewGameState);
	GenerateCovertActions(NewGameState, ExclusionList);
	AddFactionEquipmentToInventory(NewGameState);

	for(idx = 0; idx < default.NumCardsOnMeet; idx++)
	{
		GenerateNewPlayableCard(NewGameState);
	}

	DisplayResistancePlaque(NewGameState);

	ResHQ.CovertActionExclusionList = ExclusionList; // Save the updated Exclusion List to ResHQ

	// Ensure a Rookie Covert Action exists
	if (!ResHQ.IsRookieCovertActionAvailable(NewGameState))
	{
		ResHQ.CreateRookieCovertAction(NewGameState);
	}
}

//---------------------------------------------------------------------------------------
private function AddFactionEquipmentToInventory(XComGameState NewGameState)
{
	local XComGameStateHistory History;
	local X2ItemTemplateManager ItemMgr;
	local XComGameState_Item ItemState;
	local X2ItemTemplate ItemTemplate;
	local XComGameState_HeadquartersXCom XComHQ;
	local array<name> FactionEquipment;
	local int idx;

	History = `XCOMHISTORY;

	foreach NewGameState.IterateByClassType(class'XComGameState_HeadquartersXCom', XComHQ)
	{
		break;
	}

	if (XComHQ == none)
	{
		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
		XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
	}

	ItemMgr = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	FactionEquipment = GetMyTemplate().FactionEquipment;

	// Iterate through the Faction Equipment, find their templates, and build and activate the Item State Object for each
	for (idx = 0; idx < FactionEquipment.Length; idx++)
	{
		ItemTemplate = ItemMgr.FindItemTemplate(FactionEquipment[idx]);
		if (ItemTemplate != none && !XComHQ.HasItem(ItemTemplate))
		{
			ItemState = ItemTemplate.CreateInstanceFromTemplate(NewGameState);
			XComHQ.AddItemToHQInventory(ItemState);
		}
	}
}

//---------------------------------------------------------------------------------------
private function DisplayResistancePlaque(XComGameState NewGameState)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_FacilityXCom FacilityState;

	XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	FacilityState = XComHQ.GetFacilityByName('ResistanceRing');
	
	if (FacilityState != none) // If the Ring has been built
	{
		FacilityState = XComGameState_FacilityXCom(NewGameState.ModifyStateObject(class'XComGameState_FacilityXCom', FacilityState.ObjectID));
		FacilityState.ActivateUpgrade(NewGameState, GetRingPlaqueUpgradeName());
	}
}

//#############################################################################################
//----------------   DISPLAY INFO  ------------------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
function string GetFactionTitle()
{
	return GetMyTemplate().FactionTitle;
}

//---------------------------------------------------------------------------------------
function string GetFactionName()
{
	return ("'" $ FactionName $ "'");
}

//---------------------------------------------------------------------------------------
function StackedUIIconData GetFactionIcon()
{
	return FactionIconData;
}

//---------------------------------------------------------------------------------------
function GenerateFactionIcon()
{
	local XComGameStateHistory History;
	local XComGameState_CampaignSettings CampaignSettingsStateObject;

	History = `XCOMHISTORY;
		CampaignSettingsStateObject = XComGameState_CampaignSettings(History.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings', true));

	//Leave the default config data in ChosenIconData if we are in the very first playthrough, Game0 
	if( CampaignSettingsStateObject.GameIndex != 0 )
		FactionIconData = GetMyTemplate().GenerateFactionIcon();
}

//---------------------------------------------------------------------------------------
simulated function string GetLeaderImage()
{
	return GetMyTemplate().LeaderImage;
}

//---------------------------------------------------------------------------------------
function string GetLeaderQuote()
{
	return GetMyTemplate().LeaderQuote;
}

//---------------------------------------------------------------------------------------
function string GetInfluenceMediumQuote()
{
	return GetMyTemplate().InfluenceMediumQuote;
}

//---------------------------------------------------------------------------------------
function string GetInfluenceHighQuote()
{
	return GetMyTemplate().InfluenceHighQuote;
}

//---------------------------------------------------------------------------------------
function name GetChampionClassName()
{
	return GetMyTemplate().ChampionSoldierClass;
}

//---------------------------------------------------------------------------------------
function name GetChampionCharacterName()
{
	return GetMyTemplate().ChampionCharacterClass;
}

//---------------------------------------------------------------------------------------
function name GetFactionLeaderCinEvent()
{
	return GetMyTemplate().FactionLeaderCinEvent;
}

//---------------------------------------------------------------------------------------
function string GetFanfareEvent()
{
	return GetMyTemplate().FanfareEvent;
}

//---------------------------------------------------------------------------------------
function name GetMetEvent()
{
	return GetMyTemplate().MetEvent;
}

//---------------------------------------------------------------------------------------
function name GetRevealHQEvent()
{
	return GetMyTemplate().RevealHQEvent;
}

//---------------------------------------------------------------------------------------
function name GetInfluenceIncreasedMedEvent()
{
	return GetMyTemplate().InfluenceIncreasedMedEvent;
}

//---------------------------------------------------------------------------------------
function name GetInfluenceIncreasedHighEvent()
{
	return GetMyTemplate().InfluenceIncreasedHighEvent;
}

//---------------------------------------------------------------------------------------
function name GetNewCovertActionAvailableEvent()
{
	return GetMyTemplate().NewCovertActionAvailableEvent;
}

//---------------------------------------------------------------------------------------
function name GetConfirmCovertActionEvent()
{
	return GetMyTemplate().ConfirmCovertActionEvent;
}

//---------------------------------------------------------------------------------------
function name GetCovertActionAmbushEvent()
{
	return GetMyTemplate().CovertActionAmbushEvent;
}

//---------------------------------------------------------------------------------------
function name GetCovertActionCompletedEvent()
{
	return GetMyTemplate().CovertActionCompletedEvent;
}

//---------------------------------------------------------------------------------------
function name GetChosenFragmentEvent()
{
	return GetMyTemplate().ChosenFragmentEvent;
}

//---------------------------------------------------------------------------------------
function name GetResistanceOpSpawnedEvent()
{
	return GetMyTemplate().ResistanceOpSpawnedEvent;
}

//---------------------------------------------------------------------------------------
function name GetPositiveFeedbackEvent()
{
	return GetMyTemplate().PositiveFeedbackEvent;
}

//---------------------------------------------------------------------------------------
function name GetNegativeFeedbackEvent()
{
	return GetMyTemplate().NegativeFeedbackEvent;
}

//---------------------------------------------------------------------------------------
function name GetHeroOnMissionEvent()
{
	return GetMyTemplate().HeroOnMissionEvent;
}

//---------------------------------------------------------------------------------------
function name GetChosenFoughtEvent()
{
	return GetMyTemplate().ChosenFoughtEvent;
}

//---------------------------------------------------------------------------------------
function name GetChosenDefeatedEvent()
{
	return GetMyTemplate().ChosenDefeatedEvent;
}

//---------------------------------------------------------------------------------------
function name GetGreatMissionEvent()
{
	return GetMyTemplate().GreatMissionEvent;
}

//---------------------------------------------------------------------------------------
function name GetToughMissionEvent()
{
	return GetMyTemplate().ToughMissionEvent;
}

//---------------------------------------------------------------------------------------
function name GetHeroKilledEvent()
{
	return GetMyTemplate().HeroKilledEvent;
}

//---------------------------------------------------------------------------------------
function name GetHeroCapturedEvent()
{
	return GetMyTemplate().HeroCapturedEvent;
}

//---------------------------------------------------------------------------------------
function name GetSoldierRescuedEvent()
{
	return GetMyTemplate().SoldierRescuedEvent;
}

//---------------------------------------------------------------------------------------
function name GetNewFactionSoldierEvent()
{
	return GetMyTemplate().NewFactionSoldierEvent;
}

//---------------------------------------------------------------------------------------
function name GetNewResistanceOrderEvent()
{
	return GetMyTemplate().NewResistanceOrderEvent;
}

//---------------------------------------------------------------------------------------
function name GetFirstOrderSlotEvent()
{
	return GetMyTemplate().FirstOrderSlotEvent;
}

//---------------------------------------------------------------------------------------
function name GetSecondOrderSlotEvent()
{
	return GetMyTemplate().SecondOrderSlotEvent;
}

//---------------------------------------------------------------------------------------
function name GetConfirmPoliciesEvent()
{
	return GetMyTemplate().ConfirmPoliciesEvent;
}

//---------------------------------------------------------------------------------------
function name GetRingPlaqueUpgradeName()
{
	return GetMyTemplate().RingPlaqueUpgradeName;
}

//---------------------------------------------------------------------------------------
function XComGameState_AdventChosen GetRivalChosen()
{
	return XComGameState_AdventChosen(`XCOMHISTORY.GetGameStateForObjectID(RivalChosen.ObjectID));
}

//---------------------------------------------------------------------------------------
function array<XComGameState_WorldRegion> GetTerritoryRegions()
{
	local XComGameStateHistory History;
	local array<XComGameState_WorldRegion> Territory;
	local XComGameState_WorldRegion RegionState;
	local StateObjectReference RegionRef;

	History = `XCOMHISTORY;
	Territory.Length = 0;

	foreach TerritoryRegions(RegionRef)
	{
		RegionState = XComGameState_WorldRegion(History.GetGameStateForObjectID(RegionRef.ObjectID));

		if(RegionState != none)
		{
			Territory.AddItem(RegionState);
		}
	}

	return Territory;
}

//---------------------------------------------------------------------------------------
function XComGameState_Haven GetFactionHQ()
{
	return XComGameState_Haven(`XCOMHISTORY.GetGameStateForObjectID(FactionHQ.ObjectID));
}

//#############################################################################################
//----------------   FACTION SOLDIERS ---------------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
function int GetNumFactionSoldiers(optional XComGameState NewGameState)
{
	local XComGameState_HeadquartersXCom XComHQ;

	foreach NewGameState.IterateByClassType(class'XComGameState_HeadquartersXCom', XComHQ)
	{
		break;
	}

	if (XComHQ == none)
	{
		XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	}

	return XComHQ.GetNumberOfSoldiersOfTemplate(GetMyTemplate().ChampionCharacterClass);
}

//---------------------------------------------------------------------------------------
function bool IsFactionSoldierRewardAllowed(XComGameState NewGameState)
{
	// XCom is only allowed to gain more faction soldiers after they have officially met
	// and XCom no longer has any Heroes of the Faction, aka they died
	return (bMetXCom && GetNumFactionSoldiers(NewGameState) == 0);
}

//---------------------------------------------------------------------------------------
function bool IsExtraFactionSoldierRewardAllowed(XComGameState NewGameState)
{
	local int NumFactionSoldiers;

	NumFactionSoldiers = GetNumFactionSoldiers(NewGameState);

	// XCom is only allowed to gain more faction soldiers for the first Faction met,
	// and only if they have less than the max amount and have actually met that Faction
	return (bMetXCom && bFirstFaction && NumFactionSoldiers > 0 && NumFactionSoldiers < default.MaxHeroesPerFaction);
}

//#############################################################################################
//----------------   FACTION INFLUENCE   ------------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
function EFactionInfluence GetInfluence()
{
	return Influence;
}

//---------------------------------------------------------------------------------------
// Increase Influence to the next level
function IncreaseInfluenceLevel(XComGameState NewGameState)
{	
	local int NewIndex;

	NewIndex = int(Influence) + 1;
	InfluenceScore = default.RequiredScoreForInfluence[NewIndex];

	UpdateInfluence(NewGameState);
}

//---------------------------------------------------------------------------------------
function ModifyInfluenceScore(XComGameState NewGameState, int DeltaScore)
{
	InfluenceScore += DeltaScore;
	InfluenceScore = Clamp(InfluenceScore, 0, default.RequiredScoreForInfluence[eFactionInfluence_Influential]);
	UpdateInfluence(NewGameState);
}

//---------------------------------------------------------------------------------------
private function UpdateInfluence(XComGameState NewGameState)
{
	local EFactionInfluence OldInfluence, NewInfluence;

	OldInfluence = GetInfluence();
	NewInfluence = CalculateInfluence();

	if (OldInfluence != NewInfluence)
	{
		Influence = NewInfluence;
		HandleInfluenceChange(NewGameState, OldInfluence, NewInfluence);
	}
}

//---------------------------------------------------------------------------------------
private function EFactionInfluence CalculateInfluence()
{
	local int idx;

	for (idx = eFactionInfluence_MAX-1; idx >= 0; idx--)
	{
		if (InfluenceScore >= default.RequiredScoreForInfluence[idx])
		{
			return EFactionInfluence(idx);
		}
	}

	return eFactionInfluence_Minimal;
}

//---------------------------------------------------------------------------------------
private function HandleInfluenceChange(XComGameState NewGameState, EFactionInfluence OldInfluence, EFactionInfluence NewInfluence)
{	
	local XComGameStateHistory History;
	local XComGameState_HeadquartersResistance ResHQ;
	local XComGameState_HeadquartersXCom XComHQ;
	local array<Name> ExclusionList;
	local int NumActionsToAdd;
	
	if (NewInfluence > OldInfluence)
	{
		// Each time a Faction levels up influence, they gain a card slot and a new card
		AddCardSlot();
		GenerateNewPlayableCard(NewGameState);

		History = `XCOMHISTORY;
		ResHQ = XComGameState_HeadquartersResistance(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersResistance'));
		ResHQ = XComGameState_HeadquartersResistance(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersResistance', ResHQ.ObjectID));
		ExclusionList = ResHQ.CovertActionExclusionList; // Get the current list of covert actions for other factions from Res HQ
		
		// Add new Covert Actions
		RefreshAvailableCovertActions(NewGameState, ExclusionList, false); // Update the available Covert Action list with any which unlocked at the new influence level
		bNewFragmentActionAvailable = true; // Influence increasing always unlocks a new Hunt Chosen action

		// Only add new covert actions if the Ring is built, otherwise limited to 1 per Faction
		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
		if (XComHQ.HasFacilityByName('ResistanceRing'))
		{
			NumActionsToAdd = (default.CovertActionsPerInfluence[NewInfluence] - default.CovertActionsPerInfluence[OldInfluence]);
			AddNewCovertActions(NewGameState, NumActionsToAdd, ExclusionList);
		}

		ResHQ.CovertActionExclusionList = ExclusionList; // Save the updated Exclusion List to ResHQ

		// Event trigger for achievement tracking
		`XEVENTMGR.TriggerEvent('FactionInfluenceIncreased', self, self, NewGameState);

	}
}

//---------------------------------------------------------------------------------------
//function GivePostMissionInfluenceReward(XComGameState NewGameState)
//{
//	local int RewardAmount;
//
//	RewardAmount = Round(GetMissionInfluenceMinReward() + `SYNC_RAND_STATIC(GetMissionInfluenceMaxReward() - GetMissionInfluenceMinReward() + 1));
//	ModifyInfluenceScore(NewGameState, RewardAmount);
//}

//---------------------------------------------------------------------------------------
function string GetInfluenceString()
{
	return FactionInfluenceStrings[Influence];
}

//---------------------------------------------------------------------------------------
//private function int GetMissionInfluenceMinReward()
//{
//	return `ScaleStrategyArrayInt(default.MissionInfluenceMinReward);
//}

//---------------------------------------------------------------------------------------
//private function int GetMissionInfluenceMaxReward()
//{
//	return `ScaleStrategyArrayInt(default.MissionInfluenceMaxReward);
//}

//#############################################################################################
//-----------------   COVERT ACTIONS  ---------------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
// Creates the Golden Path actions for the Faction, if they do not already exist
function CreateGoldenPathActions(XComGameState NewGameState)
{
	local X2StrategyElementTemplateManager StratMgr;
	local array<X2StrategyElementTemplate> AllActionTemplates;
	local X2StrategyElementTemplate DataTemplate;
	local X2CovertActionTemplate ActionTemplate;

	// Only perform this setup once
	if (GoldenPathActions.Length == 0)
	{
		StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
		AllActionTemplates = StratMgr.GetAllTemplatesOfClass(class'X2CovertActionTemplate');

		foreach AllActionTemplates(DataTemplate)
		{
			ActionTemplate = X2CovertActionTemplate(DataTemplate);
			if (ActionTemplate != none && ActionTemplate.bGoldenPath)
			{
				GoldenPathActions.AddItem(CreateCovertAction(NewGameState, ActionTemplate, ActionTemplate.RequiredFactionInfluence));
			}
		}
	}
}

//---------------------------------------------------------------------------------------
function GenerateCovertActions(XComGameState NewGameState, out array<Name> ActionExclusionList)
{	
	local XComGameState_HeadquartersXCom XComHQ;
	local int NumActionsToAdd;

	XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	NumActionsToAdd = 1; // Limit to 1 action per Faction if the Ring is not built
	if (XComHQ.HasFacilityByName('ResistanceRing'))
	{
		NumActionsToAdd = default.CovertActionsPerInfluence[Influence];
	}

	CovertActions.Length = 0; // Reset the stored covert actions list
	RefreshAvailableCovertActions(NewGameState, ActionExclusionList); // Refresh which covert actions are available for this Faction	
	AddNewCovertActions(NewGameState, NumActionsToAdd, ActionExclusionList);
}

//---------------------------------------------------------------------------------------
private function RefreshAvailableCovertActions(XComGameState NewGameState, out array<Name> ExclusionList, optional bool bClearList = true)
{
	local X2StrategyElementTemplateManager StratMgr;
	local array<X2StrategyElementTemplate> AllActionTemplates;
	local X2StrategyElementTemplate DataTemplate;
	local X2CovertActionTemplate ActionTemplate;

	StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
	AllActionTemplates = StratMgr.GetAllTemplatesOfClass(class'X2CovertActionTemplate');
	
	if (bClearList)
	{
		AvailableCovertActions.Length = 0; // Reset the available list so it can be regenerated
	}

	if (bMetXCom)
	{
		foreach AllActionTemplates(DataTemplate)
		{
			ActionTemplate = X2CovertActionTemplate(DataTemplate);
			if (ActionTemplate.AreActionRewardsAvailable(self, NewGameState) && AvailableCovertActions.Find(ActionTemplate.DataName) == INDEX_NONE &&
				ExclusionList.Find(ActionTemplate.DataName) == INDEX_NONE)
			{
				if (!ActionTemplate.bGoldenPath && (ActionTemplate.RequiredFactionInfluence <= Influence || ActionTemplate.bDisplayIgnoresInfluence) &&
					(!ActionTemplate.bUnique || CompletedCovertActions.Find(ActionTemplate.DataName) == INDEX_NONE))
				{
					// Add to the list of possible covert actions
					AvailableCovertActions.AddItem(ActionTemplate.DataName);
				}
			}
		}
	}
}

//---------------------------------------------------------------------------------------
function AddNewCovertActions(XComGameState NewGameState, int NumActionsToCreate, out array<Name> ExclusionList)
{
	local X2StrategyElementTemplateManager StratMgr;
	local X2CovertActionTemplate ActionTemplate;
	local int idx, iRand;

	StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();

	// First iterate through the available actions list and check for any that are forced to be created
	for (idx = AvailableCovertActions.Length - 1; idx >= 0; idx--)
	{
		ActionTemplate = X2CovertActionTemplate(StratMgr.FindStrategyElementTemplate(AvailableCovertActions[idx]));
		if (ActionTemplate != none && ActionTemplate.bForceCreation && ExclusionList.Find(ActionTemplate.DataName) == INDEX_NONE)
		{
			AddCovertAction(NewGameState, ActionTemplate, ExclusionList);
			NumActionsToCreate--;
			
			AvailableCovertActions.Remove(idx, 1); // Remove the name from the available actions list
		}
	}

	// Randomly choose available actions from the deck
	while (AvailableCovertActions.Length > 0 && NumActionsToCreate > 0)
	{
		iRand = `SYNC_RAND(AvailableCovertActions.Length);
		ActionTemplate = X2CovertActionTemplate(StratMgr.FindStrategyElementTemplate(AvailableCovertActions[iRand]));
		if (ActionTemplate != none && ExclusionList.Find(ActionTemplate.DataName) == INDEX_NONE)
		{
			AddCovertAction(NewGameState, ActionTemplate, ExclusionList);
			NumActionsToCreate--;			
		}
		
		AvailableCovertActions.Remove(iRand, 1); // Remove the name from the available actions list
	}
}

//---------------------------------------------------------------------------------------
function AddCovertAction(XComGameState NewGameState, X2CovertActionTemplate ActionTemplate, out array<Name> ExclusionList)
{
	local EFactionInfluence ReqInfluenceLevel;

	ReqInfluenceLevel = ActionTemplate.bDisplayIgnoresInfluence ? ActionTemplate.RequiredFactionInfluence : eFactionInfluence_Minimal;
	CovertActions.AddItem(CreateCovertAction(NewGameState, ActionTemplate, ReqInfluenceLevel));

	// Add to exclusion list if this Covert Action cannot be presented simultaneously from different factions
	if (!ActionTemplate.bMultiplesAllowed)
	{
		ExclusionList.AddItem(ActionTemplate.DataName);
	}
}

//---------------------------------------------------------------------------------------
function StateObjectReference CreateCovertAction(XComGameState NewGameState, X2CovertActionTemplate ActionTemplate, optional EFactionInfluence UnlockLevel)
{
	local XComGameState_CovertAction ActionState;

	ActionState = ActionTemplate.CreateInstanceFromTemplate(NewGameState, GetReference());
	ActionState.Spawn(NewGameState);
	ActionState.RequiredFactionInfluence = UnlockLevel; // Set the Influence level required to unlock this Action
	ActionState.bNewAction = true;

	return ActionState.GetReference();
}

//---------------------------------------------------------------------------------------
function array<name> GetCovertActionExclusionList()
{
	local XComGameStateHistory History;
	local XComGameState_CovertAction ActionState;
	local array<name> ExclusionList;
	local int idx;

	History = `XCOMHISTORY;

	for (idx = 0; idx < CovertActions.Length; idx++)
	{
		ActionState = XComGameState_CovertAction(History.GetGameStateForObjectID(CovertActions[idx].ObjectID));
		if (ActionState != none && !ActionState.GetMyTemplate().bMultiplesAllowed)
		{
			ExclusionList.AddItem(ActionState.GetMyTemplateName());
		}
	}

	return ExclusionList;
}

//---------------------------------------------------------------------------------------
function string GetNowAvailableCovertActionListString()
{
	local XComGameStateHistory History;
	local XComGameState_CovertAction ActionState;
	local StateObjectReference ActionRef;
	local string NewActionList;

	History = `XCOMHISTORY;

	foreach GoldenPathActions(ActionRef)
	{
		ActionState = XComGameState_CovertAction(History.GetGameStateForObjectID(ActionRef.ObjectID));
		if (ActionState.bNewAction && ActionState.RequiredFactionInfluence <= Influence && ActionState.CanActionBeDisplayed())
		{
			if (NewActionList != "")
			{
				NewActionList $= ", ";
			}

			NewActionList $= ActionState.GetObjective();
		}
	}

	foreach CovertActions(ActionRef)
	{
		ActionState = XComGameState_CovertAction(History.GetGameStateForObjectID(ActionRef.ObjectID));
		if (ActionState.bNewAction && ActionState.RequiredFactionInfluence <= Influence)
		{
			if (NewActionList != "")
			{
				NewActionList $= ", ";
			}

			NewActionList $= ActionState.GetObjective();			
		}
	}

	return class'UIUtilities_Text'.static.FormatCommaSeparatedNouns(NewActionList);
}

//---------------------------------------------------------------------------------------
function RemoveCovertAction(StateObjectReference ActionRef)
{
	local int ActionIdx;

	ActionIdx = GoldenPathActions.Find('ObjectID', ActionRef.ObjectID);
	if (ActionIdx != INDEX_NONE)
	{
		GoldenPathActions.Remove(ActionIdx, 1);
	}

	ActionIdx = CovertActions.Find('ObjectID', ActionRef.ObjectID);
	if (ActionIdx != INDEX_NONE)
	{
		CovertActions.Remove(ActionIdx, 1);
	}
}

//---------------------------------------------------------------------------------------
function CleanUpFactionCovertActions(XComGameState NewGameState)
{
	local XComGameStateHistory History;
	local XComGameState_CovertAction ActionState;
	local int idx;

	History = `XCOMHISTORY;
	for(idx = 0; idx < CovertActions.Length; idx++)
	{
		// Clean up any non-started actions created for the facility.
		ActionState = XComGameState_CovertAction(History.GetGameStateForObjectID(CovertActions[idx].ObjectID));
		if (ActionState != none && !ActionState.bStarted)
		{
			ActionState = XComGameState_CovertAction(NewGameState.ModifyStateObject(class'XComGameState_CovertAction', ActionState.ObjectID));
			ActionState.RemoveEntity(NewGameState);
		}
	}
}

//---------------------------------------------------------------------------------------
function OnEndOfMonth(XComGameState NewGameState, out array<Name> ActionExclusionList)
{
	// Regenerate Covert Actions
	CleanUpFactionCovertActions(NewGameState);
	CreateGoldenPathActions(NewGameState);
	GenerateCovertActions(NewGameState, ActionExclusionList);
}

//#############################################################################################
//----------------   MONTHLY CARD GAME  -------------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
// Generate faction specific cards for this month
function array<XComGameState_StrategyCard> GetCurrentMonthCards()
{
	local array<XComGameState_StrategyCard> FactionCards;

	// TODO: @mnauta - Algorithm for picking faction specific cards
	FactionCards.Length = 0;
	return FactionCards;
}

//---------------------------------------------------------------------------------------
// How many cards can be played on this faction per month
function int GetNumCardSlots()
{
	return CardSlots.Length;
}

//---------------------------------------------------------------------------------------
function PlaceCardInSlot(StateObjectReference CardRef, int SlotIndex)
{
	if(SlotIndex < 0 || SlotIndex >= CardSlots.Length)
	{
		return;
	}

	RemoveCardFromSlot(SlotIndex);
	CardSlots[SlotIndex] = CardRef;
}

//---------------------------------------------------------------------------------------
function RemoveCardFromSlot(int SlotIndex)
{
	local StateObjectReference EmptyRef;

	if(SlotIndex < 0 || SlotIndex >= CardSlots.Length)
	{
		return;
	}

	CardSlots[SlotIndex] = EmptyRef;
}

//---------------------------------------------------------------------------------------
// Returns true if a new card was played
function bool PlayAllNewCards(XComGameState NewGameState, array<StateObjectReference> OldWildCards)
{
	local XComGameState_StrategyCard CardState;
	local StateObjectReference CardRef;
	local bool bCardPlayed;

	foreach CardSlots(CardRef)
	{
		// Only Play the card if it's not already in play
		if(OldCardSlots.Find('ObjectID', CardRef.ObjectID) == INDEX_NONE &&
		   OldWildCards.Find('ObjectID', CardRef.ObjectID) == INDEX_NONE &&
		   CardRef.ObjectID != 0)
		{
			CardState = XComGameState_StrategyCard(NewGameState.ModifyStateObject(class'XComGameState_StrategyCard', CardRef.ObjectID));
			CardState.ActivateCard(NewGameState);
			bCardPlayed = true;
		}
	}

	return bCardPlayed;
}

//---------------------------------------------------------------------------------------
function DeactivateRemovedCards(XComGameState NewGameState, array<StateObjectReference> NewWildCards)
{
	local XComGameState_StrategyCard CardState;
	local StateObjectReference CardRef;

	foreach OldCardSlots(CardRef)
	{
		// Only Deactivate the old card if it has been removed
		if(CardSlots.Find('ObjectID', CardRef.ObjectID) == INDEX_NONE &&
		   NewWildCards.Find('ObjectID', CardRef.ObjectID) == INDEX_NONE &&
		   CardRef.ObjectID != 0)
		{
			CardState = XComGameState_StrategyCard(NewGameState.ModifyStateObject(class'XComGameState_StrategyCard', CardRef.ObjectID));
			CardState.DeactivateCard(NewGameState);
		}
	}
}

//---------------------------------------------------------------------------------------
// Call before making changes on the card screen
function StoreOldCards()
{
	OldCardSlots = CardSlots;
}

//---------------------------------------------------------------------------------------
function AddCardSlot()
{
	local StateObjectReference EmptyRef;

	CardSlots.AddItem(EmptyRef);
}

//---------------------------------------------------------------------------------------
function array<StateObjectReference> GetCardSlots()
{
	return CardSlots;
}

//---------------------------------------------------------------------------------------
function bool HasEmptyCardSlot()
{
	local StateObjectReference CardRef;
	
	foreach CardSlots(CardRef)
	{
		if (CardRef.ObjectID == 0)
		{
			return true;
		}
	}

	return false;
}

//---------------------------------------------------------------------------------------
function array <StateObjectReference> GetHandCards()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersResistance ResHQ;
	local array<StateObjectReference> HandCards;
	local StateObjectReference CardRef;

	// Return playable cards minus cards that are already in play
	HandCards = PlayableCards;

	foreach CardSlots(CardRef)
	{
		HandCards.RemoveItem(CardRef);
	}

	History = `XCOMHISTORY;
	ResHQ = XComGameState_HeadquartersResistance(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersResistance'));

	foreach ResHQ.WildCardSlots(CardRef)
	{
		HandCards.RemoveItem(CardRef);
	}

	return HandCards;
}

//---------------------------------------------------------------------------------------
function array<XComGameState_StrategyCard> GetAllPlayableCards()
{
	local XComGameStateHistory History;
	local array<XComGameState_StrategyCard> AllPlayableCards;
	local StateObjectReference CardRef;

	History = `XCOMHISTORY;
	AllPlayableCards.Length = 0;

	foreach PlayableCards(CardRef)
	{
		AllPlayableCards.AddItem(XComGameState_StrategyCard(History.GetGameStateForObjectID(CardRef.ObjectID)));
	}

	return AllPlayableCards;
}

//---------------------------------------------------------------------------------------
function GenerateNewPlayableCard(XComGameState NewGameState)
{
	local XComGameState_StrategyCard CardState;

	CardState = GetRandomCardToMakePlayable(NewGameState);

	if(CardState != none)
	{
		AddPlayableCard(NewGameState, CardState.GetReference());
	}
}

//---------------------------------------------------------------------------------------
function bool IsCardAvailableToMakePlayable(optional int CardStrength = Influence + 1)
{
	local XComGameStateHistory History;
	local XComGameState_StrategyCard CardState;

	if (CardStrength <= 0)
	{
		return false;
	}

	History = `XCOMHISTORY;

	// Find and add all appropriate cards
	foreach History.IterateByClassType(class'XComGameState_StrategyCard', CardState)
	{
		if (IsCardAvailable(CardState, CardStrength))
		{
			return true;
		}
	}

	// If we came up empty, try to find a lower strength card
	return IsCardAvailableToMakePlayable(CardStrength - 1);
}

//---------------------------------------------------------------------------------------
function XComGameState_StrategyCard GetRandomCardToMakePlayable(XComGameState NewGameState, optional int CardStrength = Influence + 1)
{
	local XComGameStateHistory History;
	local XComGameState_StrategyCard CardState, NewCardState;
	local array<XComGameState_StrategyCard> AllPlayableCards;

	if(CardStrength <= 0)
	{
		return none;
	}

	History = `XCOMHISTORY;
	AllPlayableCards.Length = 0;

	// Find and add all appropriate cards
	foreach History.IterateByClassType(class'XComGameState_StrategyCard', CardState)
	{
		if(IsCardAvailable(CardState, CardStrength))
		{
			// Check to see if the available card was already modified in the NewGameState, and if it is still available
			NewCardState = XComGameState_StrategyCard(NewGameState.GetGameStateForObjectID(CardState.ObjectID));
			if (NewCardState == none || IsCardAvailable(NewCardState, CardStrength))
			{
				AllPlayableCards.AddItem(CardState);
			}
		}
	}

	// If we came up empty, try to find a lower strength card
	if(AllPlayableCards.Length == 0)
	{
		return GetRandomCardToMakePlayable(NewGameState, CardStrength - 1);
	}

	return AllPlayableCards[`SYNC_RAND(AllPlayableCards.Length)];
}

//---------------------------------------------------------------------------------------
function bool IsCardAvailable(XComGameState_StrategyCard CardState, int CardStrength)
{
	if (CardState.IsResistanceCard() && CardState.GetAssociatedFactionName() == GetMyTemplateName()
		&& CardState.GetMyTemplate().Strength == CardStrength && CardState.CanBePlayed() && CardState.CanBeDrawn()
		&& PlayableCards.Find('ObjectID', CardState.ObjectID) == INDEX_NONE)
	{
		return true;
	}

	return false;
}

//---------------------------------------------------------------------------------------
function AddPlayableCard(XComGameState NewGameState, StateObjectReference CardRef)
{
	local XComGameState_StrategyCard CardState;

	if(PlayableCards.Find('ObjectID', CardRef.ObjectID) == INDEX_NONE)
	{
		CardState = XComGameState_StrategyCard(NewGameState.ModifyStateObject(class'XComGameState_StrategyCard', CardRef.ObjectID));
		CardState.bNewCard = true; // Flag the card as newly acquired for UI

		PlayableCards.AddItem(CardRef);
		NewPlayableCards.AddItem(CardRef);
	}
}

//---------------------------------------------------------------------------------------
// Pulls a card from the deck and marks it as drawn, but doesn't make it playable
function XComGameState_StrategyCard DrawRandomPlayableCard(XComGameState NewGameState)
{
	local XComGameState_StrategyCard CardState;
	
	CardState = GetRandomCardToMakePlayable(NewGameState);
	if (CardState != none)
	{
		CardState = XComGameState_StrategyCard(NewGameState.ModifyStateObject(class'XComGameState_StrategyCard', CardState.ObjectID));
		CardState.bDrawn = true;
	}

	return CardState;
}

//---------------------------------------------------------------------------------------
function string GetNewStrategyCardsListString()
{
	local XComGameStateHistory History;
	local XComGameState_StrategyCard CardState;
	local StateObjectReference CardRef;
	local string NewCardList;

	History = `XCOMHISTORY;

	foreach NewPlayableCards(CardRef)
	{
		CardState = XComGameState_StrategyCard(History.GetGameStateForObjectID(CardRef.ObjectID));
		
		if (NewCardList != "")
		{
			NewCardList $= ", ";
		}
		
		NewCardList $= CardState.GetDisplayName();
	}

	return class'UIUtilities_Text'.static.FormatCommaSeparatedNouns(NewCardList);
}

function string GetColumnHint()
{
	return ""; //TODO: @mnauta: if this faction should show a hint, send the relevant string back here. 
}


function DisplayNewStrategyCardPopups()
{
	local XComGameState NewGameState;
	local XComGameState_ResistanceFaction FactionState;
	local StateObjectReference CardRef;
	local int idx;

	if (NewPlayableCards.Length > 0)
	{
		// Queue popups for each new card received
		foreach NewPlayableCards(CardRef, idx)
		{
			// Only play the "new card" VO on the last card added to the stack, which will be the first card displayed to the player
			`HQPRES.UIStrategyCardReceived(CardRef, (idx == NewPlayableCards.Length - 1));
		}

		// Then clear the new playable card array since the player has now seen the info about them
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Clear New Faction Cards Array");
		FactionState = XComGameState_ResistanceFaction(NewGameState.ModifyStateObject(class'XComGameState_ResistanceFaction', ObjectID));
		FactionState.NewPlayableCards.Length = 0;
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
}

//#############################################################################################
//----------------  RESISTANCE MODE  ----------------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
function X2ResistanceModeTemplate GetResistanceMode()
{
	return X2ResistanceModeTemplate(GetMyTemplateManager().FindStrategyElementTemplate(GetMyTemplate().ResistanceMode));
}

//---------------------------------------------------------------------------------------
function string GetResistanceModeLabel()
{
	return GetResistanceMode().ScanLabel;
}

//#############################################################################################
//-------------------------  UPDATE  ----------------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
// THIS FUNCTION SHOULD RETURN TRUE IN ALL THE SAME CASES AS Update
function bool ShouldUpdate()
{
	local UIStrategyMap StrategyMap;

	StrategyMap = `HQPRES.StrategyMap2D;

	// Do not trigger anything while the Avenger or Skyranger are flying, or if another popup is already being presented
	if (StrategyMap != none && StrategyMap.m_eUIState != eSMS_Flight && !`HQPRES.ScreenStack.IsCurrentClass(class'UIAlert'))
	{
		if (bMetXCom && !bSeenFactionHQReveal)
		{
			return true;
		}
	}

	return false;
}

//---------------------------------------------------------------------------------------
// IF ADDING NEW CASES WHERE bModified = true, UPDATE FUNCTION ShouldUpdate ABOVE
function bool Update(XComGameState NewGameState)
{
	local UIStrategyMap StrategyMap;
	local bool bModified;

	StrategyMap = `HQPRES.StrategyMap2D;
	bModified = false;

	// Do not trigger anything while the Avenger or Skyranger are flying, or if another popup is already being presented
	if (StrategyMap != none && StrategyMap.m_eUIState != eSMS_Flight && !`HQPRES.ScreenStack.IsCurrentClass(class'UIAlert'))
	{
		if (bMetXCom && !bSeenFactionHQReveal)
		{
			bNeedsFactionHQReveal = true;
			bModified = true;
		}
	}

	return bModified;
}

//---------------------------------------------------------------------------------------
function UpdateGameBoard()
{
	local XComGameState NewGameState;
	local XComGameState_ResistanceFaction NewFactionState;
	local UIStrategyMap StrategyMap;
	local bool bUpdated;

	if (ShouldUpdate())
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Update Resistance Faction");

		NewFactionState = XComGameState_ResistanceFaction(NewGameState.ModifyStateObject(class'XComGameState_ResistanceFaction', ObjectID));

		bUpdated = NewFactionState.Update(NewGameState);
		`assert(bUpdated); // why did Update & ShouldUpdate return different bools?

		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
		`HQPRES.StrategyMap2D.UpdateMissions();
	}

	StrategyMap = `HQPRES.StrategyMap2D;
	if (StrategyMap != none && StrategyMap.m_eUIState != eSMS_Flight)
	{
		if (bNeedsFactionHQReveal)
		{
			`HQPRES.BeginFactionRevealSequence(self);
		}
	}
}

//---------------------------------------------------------------------------------------
DefaultProperties
{
}