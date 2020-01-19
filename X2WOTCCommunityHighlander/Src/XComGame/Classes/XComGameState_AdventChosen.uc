//---------------------------------------------------------------------------------------
//  FILE:    XComGameState_AdventChosen.uc
//  AUTHOR:  Mark Nauta  --  04/25/2016
//  PURPOSE: This object represents the instance data for an ADVENT Chosen
//           in the XCOM 2 strategy game
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComGameState_AdventChosen extends XComGameState_GeoscapeCharacter config(GameData);

// Level of Hunting XCOM - DEPRECATED
enum EHuntXComLevel
{
	eHuntXComLevel_ReplacePod,
	eHuntXComLevel_Reinforce,
	eHuntXComLevel_CovertAction,
	eHuntXComLevel_AttackAvenger,
	eHuntXComLevel_MAX,
};

enum EChosenKnowledge
{
	eChosenKnowledge_Start,
	eChosenKnowledge_Saboteur,
	eChosenKnowledge_Sentinel,
	eChosenKnowledge_Collector,
	eChosenKnowledge_Raider,
	eChosenKnowledge_MAX,
};

const CHOSEN_STATE_UNACTIVATED = 0;
const CHOSEN_STATE_ACTIVATED = 1;
const CHOSEN_STATE_ENGAGED = 2;
const CHOSEN_STATE_DISABLED = -1;

// Used to get/set unit values on the Chosen
var privatewrite name ChosenActivatedStateUnitValue;

// Template info
var protected name								  m_TemplateName;
var protected X2AdventChosenTemplate			  m_Template;

// Basic Info vars
var string							FirstName;
var string							LastName;
var string							Nickname;
var StateObjectReference			RivalFaction;
var string							FlagBackgroundImage;
var string							FlagForegroundImage;
var array<name>						Strengths;
var array<name>						Weaknesses;
var array<name>						RevealedChosenTraits;
var array<StateObjectReference>		TerritoryRegions; // List of regions this Chosen operates in
var array<StateObjectReference>		ControlledContinents;
var bool							bOccupiesStartingContinent;
var StateObjectReference			StrongholdMission;

// Status vars
var bool							bMetXCom; // Chosen can appear to the player on map and in missions (will take strategy actions if AlienHQ bChosenActive)
var bool							bForcedMet; // The player did not make contact with a region or meet the Chosen in combat, forced to meet by the end of the first month
var bool							bDefeated; // Has the player defeated this Chosen permanently by killing them on a Stronghold?
var bool							bIsVisible; // Is the Chosen map icon visible on the Strategy map
var bool							bFavored; // Is this the favored Chosen
var bool							bJustLeveledUp; // Did this Chosen just level up? Used for VO triggers
var bool							bJustIncreasedKnowledgeLevel; // Did this Chosen just increase their knowledge level?
var bool							bNeedsLocationReveal; // Does this Chosen need to trigger a location reveal?
var bool							bSeenLocationReveal; // Has the player seen the Location reveal for this Chosen?
var EChosenKnowledge				CurrentKnowledgeLevel; // Thresholds unlock 
var int								Level; // The current power level of the Chosen
var int								KnowledgeScore; // Raw score for Chosen knowledge
var int								NumEncounters; // How many times has XCOM encountered this Chosen
var int								NumVictories; // How many times has this Chosen beaten XCOM in combat?
var int								NumDefeats; // How many times has this Chosen been defeated by XCOM in combat?
var float							KnowledgeGainScalar; // If non-zero, scales knowledge gain values
var int								MissionsSinceLastAppearance;
var int								CurrentAppearanceRoll;
var float							CaptureChanceScalar;
var int								NumAvengerAssaults;
var int								MonthsAsRaider;
var bool							bIgnoreWeaknesses;
var float							KnowledgeFromOtherChosenPercent; // From Loyalty Among Thieves Dark Event
var int								NumExtracts;
var int								KnowledgeFromLastAction;

// Post Mission vars
var bool bWasOnLastMission;
var bool bCapturedSoldier;
var bool bExtractedKnowledge;
var bool bKilledInCombat; // Was this Chosen killed on the previous mission (not permanent)
var bool bFailedStrongholdMission; // Don't spawn the mission again
var int MissionKnowledgeExtracted;

// Last Encounter Data - what happened the last time XCom fought this Chosen. Used for narrative triggers.
var ChosenEncounterData LastEncounter;

// Captured Soldiers
var array<StateObjectReference>		CapturedSoldiers;
var int								TotalCapturedSoldiers;

// Attack Region vars
var array<StateObjectReference>		RegionAttackDeck;

// Monthly Action vars
var array<StateObjectReference>		PreviousMonthActions; // List of all previous month actions
var StateObjectReference			CurrentMonthAction; // Current month action
var bool							bActionUsesTimer; // Some actions do not use the timer so it should be ignored
var bool							bActionCountered; // Did XCOM counter this monthly action?
var bool							bPerformedMonthlyAction; // Flag to true once Chosen performs their monthly action
var TDateTime						ActionDate; // When Chosen takes month action

// Assault Mission
var StateObjectReference			AssaultMissionRef;

// End of Month vars
var int								MonthKnowledgeDelta;
var array<string>					MonthActivities;

// Need to store sabotage data
var name							SabotageTemplateName;
var string							SabotageDescription;
var int								SabotageRoll; // Roll at the beginning of the month to make it less save-scummable

// Loc vars
var localized string				AttackRegionLabel;
var localized string				AttackRegionSuppliesString;
var localized string				AttackRegionIntelString;
var localized string				AttackRegionActivityString;
var	localized string				KnowledgeGainTitle[EChosenKnowledge.EnumCount]<BoundEnum = EChosenKnowledge>;
var localized string				KnowledgeGainFirstBullet[EChosenKnowledge.EnumCount]<BoundEnum = EChosenKnowledge>;
var localized string				KnowledgeGainSecondBullet[EChosenKnowledge.EnumCount]<BoundEnum = EChosenKnowledge>;
var localized string				KnowledgeGainThirdBullet[EChosenKnowledge.EnumCount]<BoundEnum = EChosenKnowledge>;
var localized string				SabotageFailedLabel;
var localized string				UnknownStrengthsString;
var localized string				UnknownWeaknessesString;
var localized string				EncounteredXComActivityString;

// Config vars
var config int						MaxScoreAtKnowledgeLevel[EChosenKnowledge.EnumCount]<BoundEnum = EChosenKnowledge>;
var config int						GuaranteedKnowledgeGainPerMonth;
var config int						StartingNumStrengths;
var config int						StartingNumWeaknesses;
var config int						NumStrengthsPerLevel;
var config int						CovertActionRiskIncrease;
var config int						MaxMissionsToWaitBeforeAttack;

var config array<name>				ChosenStrengths;
var config array<name>				ChosenWeaknesses;

var config int						KnowledgePerExtract;
var config int						KnowledgePerCapture;

var config int						NumStrengthsWhenFavored; // Gained
var config int						NumWeaknessesWhenFavored; // Lost
var config float					FavoredKnowledgeGainScalar;

var config array<AppearChance>		AppearChances;
var config array<int>				ForceMissionRegionCount;
var config int						MinChosenActionBufferDays;

var config							StackedUIIconData ChosenIconData; //User interface icon image information

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
simulated function X2AdventChosenTemplate GetMyTemplate()
{
	if(m_Template == none)
	{
		m_Template = X2AdventChosenTemplate(GetMyTemplateManager().FindStrategyElementTemplate(m_TemplateName));
	}
	return m_Template;
}

//---------------------------------------------------------------------------------------
event OnCreation(optional X2DataTemplate Template)
{
	super.OnCreation(Template);

	m_Template = X2AdventChosenTemplate(Template);
	m_TemplateName = Template.DataName;
}

//---------------------------------------------------------------------------------------
function AssignStartingTraits(out array<name> ExcludeStrengths, out array<name> ExcludeWeaknesses, XComGameState_ResistanceFaction FactionState, bool bNarrative)
{
	local array<name> AllStrengths, AllWeaknesses, AllSurvivabilityStrengths;
	local int idx, RandIndex;
	local X2AbilityTemplate TraitTemplate;
	local X2AbilityTemplateManager AbilityMgr;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();

	// Grab all strengths and weaknesses
	for(idx = 0; idx < default.ChosenStrengths.Length; idx++)
	{
		TraitTemplate = AbilityMgr.FindAbilityTemplate(default.ChosenStrengths[idx]);
		if(ExcludeStrengths.Find(default.ChosenStrengths[idx]) == INDEX_NONE && TraitTemplate.ChosenTraitForceLevelGate <= 1)
		{
			if(TraitTemplate.ChosenTraitType == 'Survivability' )
			{
				AllSurvivabilityStrengths.AddItem(default.ChosenStrengths[idx]);
			}
			else
			{
				AllStrengths.AddItem(default.ChosenStrengths[idx]);
			}
		}
	}

	for(idx = 0; idx < default.ChosenWeaknesses.Length; idx++)
	{
		if(ExcludeWeaknesses.Find(default.ChosenWeaknesses[idx]) == INDEX_NONE)
		{
			TraitTemplate = AbilityMgr.FindAbilityTemplate(default.ChosenWeaknesses[idx]);
			if(TraitTemplate.ChosenTraitType != 'Adversary')
			{
				AllWeaknesses.AddItem(default.ChosenWeaknesses[idx]);
			}
		}
	}

	// Pick weaknesses first because they could exclude some strengths
	// Adversary is their corresponding faction
	switch(FactionState.GetMyTemplateName())
	{
	case 'Faction_Reapers':
		Weaknesses.AddItem('ChosenReaperAdversary');
		RevealedChosenTraits.AddItem('ChosenReaperAdversary');
		ExcludeWeaknesses.AddItem('ChosenReaperAdversary');
		break;
	case 'Faction_Templars':
		Weaknesses.AddItem('ChosenTemplarAdversary');
		RevealedChosenTraits.AddItem('ChosenTemplarAdversary');
		ExcludeWeaknesses.AddItem('ChosenTemplarAdversary');
		break;
	case 'Faction_Skirmishers':
		Weaknesses.AddItem('ChosenSkirmisherAdversary');
		RevealedChosenTraits.AddItem('ChosenSkirmisherAdversary');
		ExcludeWeaknesses.AddItem('ChosenSkirmisherAdversary');
		break;
	default:
		`RedScreen("Chosen has no rival faction causing error in trait selection. @gameplay @mnauta");
		break;
	}

	// Start Issue #51: alter where the Assassin gets Shadowstep if
	// Lost and Abandoned is enabled, so other starting traits take into account
	// for it
	/// HL-Docs: ref:Bugfixes; issue:51
	/// Prevent Assassin from gaining perks incompatible with forced "Shadowstep" in Lost and Abandoned
	// Give the Chosen one survivability trait
	if(bNarrative && GetMyTemplateName() == 'Chosen_Assassin')
	{
		Strengths.AddItem('ChosenShadowstep');
		RevealedChosenTraits.AddItem('ChosenShadowstep');
		ExcludeStrengths.AddItem('ChosenShadowstep');
	}
	// End Issue #51
	
	FilterTraitList(AllStrengths);
	FilterTraitList(AllSurvivabilityStrengths);
	FilterTraitList(AllWeaknesses);

	// Pick remaining weaknesses
	for(idx = 0; idx < (default.StartingNumWeaknesses - 1); idx++)
	{
		RandIndex = `SYNC_RAND(AllWeaknesses.Length);
		Weaknesses.AddItem(AllWeaknesses[RandIndex]);
		RevealedChosenTraits.AddItem(AllWeaknesses[RandIndex]);
		ExcludeWeaknesses.AddItem(AllWeaknesses[RandIndex]);
		AllWeaknesses.Remove(RandIndex, 1);
		FilterTraitList(AllStrengths);
		FilterTraitList(AllSurvivabilityStrengths);
		FilterTraitList(AllWeaknesses);
	}

	// Condition for Issue #51
	// removed shadowstep block and altered conditional to do 'else' behaviour.
	if(!bNarrative || GetMyTemplateName() != 'Chosen_Assassin')
	{
		if(AllSurvivabilityStrengths.Length == 0)
		{
			`RedScreen("No Chosen survivablity traits to choose from. @gameplay @mnauta");
		}
		else
		{
			RandIndex = `SYNC_RAND(AllSurvivabilityStrengths.Length);
			Strengths.AddItem(AllSurvivabilityStrengths[RandIndex]);
			RevealedChosenTraits.AddItem(AllSurvivabilityStrengths[RandIndex]);
			ExcludeStrengths.AddItem(AllSurvivabilityStrengths[RandIndex]);
			FilterTraitList(AllStrengths);
		}
	}
	
	// Assign remaining strengths
	for(idx = 0; idx < (default.StartingNumStrengths - 1); idx++)
	{
		RandIndex = `SYNC_RAND(AllStrengths.Length);
		Strengths.AddItem(AllStrengths[RandIndex]);
		RevealedChosenTraits.AddItem(AllStrengths[RandIndex]);
		ExcludeStrengths.AddItem(AllStrengths[RandIndex]);
		AllStrengths.Remove(RandIndex, 1);
		FilterTraitList(AllStrengths);
	}
}

private function FilterTraitList(out array<name> TraitList)
{
	local name TraitName, ExcludeTraitName;
	local X2AbilityTemplate TraitTemplate;
	local X2AbilityTemplateManager AbilityMgr;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	
	foreach Strengths(TraitName)
	{
		TraitTemplate = AbilityMgr.FindAbilityTemplate(TraitName);

		if(TraitTemplate != none)
		{
			foreach TraitTemplate.ChosenExcludeTraits(ExcludeTraitName)
			{
				TraitList.RemoveItem(ExcludeTraitName);
			}
		}
	}

	foreach Weaknesses(TraitName)
	{
		TraitTemplate = AbilityMgr.FindAbilityTemplate(TraitName);

		if(TraitTemplate != none)
		{
			foreach TraitTemplate.ChosenExcludeTraits(ExcludeTraitName)
			{
				TraitList.RemoveItem(ExcludeTraitName);
			}
		}
	}
}

function AddTrait(name TraitToAdd)
{
	if( default.ChosenStrengths.Find(TraitToAdd) != INDEX_NONE && Strengths.Find(TraitToAdd) == INDEX_NONE )
	{
		Strengths.AddItem(TraitToAdd);
		RevealedChosenTraits.AddItem(TraitToAdd);
	}
	else if( default.ChosenWeaknesses.Find(TraitToAdd) != INDEX_NONE && Weaknesses.Find(TraitToAdd) == INDEX_NONE )
	{
		Weaknesses.AddItem(TraitToAdd);
		RevealedChosenTraits.AddItem(TraitToAdd);
	}
}

function RemoveTrait(name TraitToRemove)
{
	Strengths.RemoveItem(TraitToRemove);
	Weaknesses.RemoveItem(TraitToRemove);
	RevealedChosenTraits.RemoveItem(TraitToRemove);
}

//---------------------------------------------------------------------------------------
function GenerateChosenName()
{
	GetMyTemplate().GenerateName(FirstName, LastName, Nickname);
}
//---------------------------------------------------------------------------------------
function GenerateChosenIcon()
{
	local XComGameStateHistory History;
	local XComGameState_CampaignSettings CampaignSettingsStateObject;

	History = `XCOMHISTORY;
	CampaignSettingsStateObject = XComGameState_CampaignSettings(History.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings', true));

	//Leave the default config data in ChosenIconData if we are in the very first playthrough, Game0 
	if( CampaignSettingsStateObject.GameIndex != 0 )
		ChosenIconData = GetMyTemplate().GenerateChosenIcon();
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
function bool ChosenControlsRegion(StateObjectReference RegionRef)
{
	return (TerritoryRegions.Find('ObjectID', RegionRef.ObjectID) != INDEX_NONE);
}

//---------------------------------------------------------------------------------------
function ChooseLocation()
{
	local XComGameState_WorldRegion RegionState;

	RegionState = XComGameState_WorldRegion(`XCOMHISTORY.GetGameStateForObjectID(HomeRegion.ObjectID));
	if (RegionState != none)
	{
		Continent = RegionState.Continent; // Save the continent, then flag for location update once we generate the region meshes
		bNeedsLocationUpdate = true;
	}
}

//---------------------------------------------------------------------------------------
function CreateStrongholdMission(XComGameState NewGameState)
{
	local array<XComGameState_Reward> MissionRewards;
	local X2StrategyElementTemplateManager StratMgr;
	local X2RewardTemplate RewardTemplate;
	local X2MissionSourceTemplate MissionSource;
	local XComGameState_Reward MissionRewardState;
	local XComGameState_MissionSiteOutsideRegions MissionState;
	local XComGameState_WorldRegion RegionState;
	local Vector2D MissionLoc;

	StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
	MissionRewards.Length = 0;

	// Set up mission rewards
	RewardTemplate = X2RewardTemplate(StratMgr.FindStrategyElementTemplate('Reward_None'));
	MissionRewardState = RewardTemplate.CreateInstanceFromTemplate(NewGameState);
	MissionRewards.AddItem(MissionRewardState);

	// Grab the Chosen's home region
	RegionState = XComGameState_WorldRegion(`XCOMHISTORY.GetGameStateForObjectID(HomeRegion.ObjectID));

	MissionSource = X2MissionSourceTemplate(StratMgr.FindStrategyElementTemplate('MissionSource_ChosenStronghold'));
	MissionState = XComGameState_MissionSiteOutsideRegions(NewGameState.CreateNewStateObject(class'XComGameState_MissionSiteOutsideRegions'));
	MissionState.BuildMission(MissionSource, MissionLoc, RegionState.GetReference(), MissionRewards, false, false);
	MissionState.bNotAtThreshold = true;
	MissionState.bNeedsLocationUpdate = true;
	MissionState.Region.ObjectID = 0; // Strongholds don't live in regions, so clear it now that the mission is built

	// Set this mission as associated with the Chosen's rival Faction
	MissionState.ResistanceFaction = RivalFaction;

	StrongholdMission = MissionState.GetReference();
}

function MakeStrongholdMissionVisible(XComGameState NewGameState)
{
	local XComGameState_MissionSite MissionState;
	
	// Display the mission, but keep it locked
	MissionState = XComGameState_MissionSite(NewGameState.ModifyStateObject(class'XComGameState_MissionSite', StrongholdMission.ObjectID));
	MissionState.Continent = Continent; // Stronghold should match the Chosen's continent
	MissionState.Available = true;
	MissionState.bNeedsLocationUpdate = true; // Flag for location update on the Geoscape now that the mission is available
}

function MakeStrongholdMissionAvailable(XComGameState NewGameState)
{
	local XComGameState_MissionSite MissionState;

	// Unlock the Stronghold mission
	MissionState = XComGameState_MissionSite(NewGameState.ModifyStateObject(class'XComGameState_MissionSite', StrongholdMission.ObjectID));
	MissionState.bNotAtThreshold = false;
}

function bool IsStrongholdMissionAvailable()
{
	local XComGameState_MissionSite MissionState;

	MissionState = XComGameState_MissionSite(`XCOMHISTORY.GetGameStateForObjectID(StrongholdMission.ObjectID));
	return (!MissionState.bNotAtThreshold);
}

//#############################################################################################
//----------------   CHOSEN UNIT  -------------------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
function X2CharacterTemplate GetChosenTemplate()
{
	local X2CharacterTemplateManager CharMgr;
	
	CharMgr = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager();
	return CharMgr.FindCharacterTemplate(GetMyTemplate().GetProgressionTemplate(Level));
}

//---------------------------------------------------------------------------------------
function GainNewStrengths(XComGameState NewGameState, int NumStrengths)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersAlien AlienHQ;
	local XComGameState_AdventChosen ChosenState;
	local array<name> AllStrengths, ExcludeStrengths, FallbackStrengths, CurrentCategories, PreferredStrengths;
	local int idx, RandIndex;
	local X2AbilityTemplate TraitTemplate;
	local X2AbilityTemplateManager AbilityMgr;

	History = `XCOMHISTORY;
	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));
	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	ExcludeStrengths = Strengths;

	// Grab current strength categories
	for(idx = 0; idx < ExcludeStrengths.Length; idx++)
	{
		TraitTemplate = AbilityMgr.FindAbilityTemplate(ExcludeStrengths[idx]);

		if(TraitTemplate.ChosenTraitType != '' && CurrentCategories.Find(TraitTemplate.ChosenTraitType) == INDEX_NONE)
		{
			CurrentCategories.AddItem(TraitTemplate.ChosenTraitType);
		}
	}

	// Grab currently used strengths of the other Chosen
	// Need to check pending gamestate in case another Chosen is also gaining strengths at the same time
	foreach NewGameState.IterateByClassType(class'XComGameState_AdventChosen', ChosenState)
	{
		if(ChosenState.GetReference() != self.GetReference())
		{
			for(idx = 0; idx < ChosenState.Strengths.Length; idx++)
			{
				if(FallbackStrengths.Find(ChosenState.Strengths[idx]) == INDEX_NONE &&
				   ExcludeStrengths.Find(ChosenState.Strengths[idx]) == INDEX_NONE)
				{
					FallbackStrengths.AddItem(ChosenState.Strengths[idx]);
				}
			}
		}
	}

	foreach History.IterateByClassType(class'XComGameState_AdventChosen', ChosenState)
	{
		if(ChosenState.GetReference() != self.GetReference())
		{
			for(idx = 0; idx < ChosenState.Strengths.Length; idx++)
			{
				if(FallbackStrengths.Find(ChosenState.Strengths[idx]) == INDEX_NONE &&
				   ExcludeStrengths.Find(ChosenState.Strengths[idx]) == INDEX_NONE)
				{
					FallbackStrengths.AddItem(ChosenState.Strengths[idx]);
				}
			}
		}
	}

	// Grab all remaining strengths
	for(idx = 0; idx < default.ChosenStrengths.Length; idx++)
	{
		if(ExcludeStrengths.Find(default.ChosenStrengths[idx]) == INDEX_NONE &&
		   FallbackStrengths.Find(default.ChosenStrengths[idx]) == INDEX_NONE)
		{
			TraitTemplate = AbilityMgr.FindAbilityTemplate(default.ChosenStrengths[idx]);
			if(TraitTemplate.ChosenTraitForceLevelGate <= AlienHQ.GetForceLevel())
			{
				if(TraitTemplate.ChosenTraitType == '' || CurrentCategories.Find(TraitTemplate.ChosenTraitType) == INDEX_NONE)
				{
					PreferredStrengths.AddItem(default.ChosenStrengths[idx]);
				}
				else
				{
					AllStrengths.AddItem(default.ChosenStrengths[idx]);
				}
			}
		}
	}

	FilterTraitList(FallbackStrengths);
	FilterTraitList(AllStrengths);
	FilterTraitList(PreferredStrengths);

	// Assign random strengths to this Chosen
	for(idx = 0; idx < NumStrengths; idx++)
	{
		if(PreferredStrengths.Length > 0)
		{
			RandIndex = `SYNC_RAND(PreferredStrengths.Length);
			Strengths.AddItem(PreferredStrengths[RandIndex]);
			RevealedChosenTraits.AddItem(PreferredStrengths[RandIndex]);
			PreferredStrengths.Remove(RandIndex, 1);
			FilterTraitList(FallbackStrengths);
			FilterTraitList(AllStrengths);
			FilterTraitList(PreferredStrengths);
		}
		else if(AllStrengths.Length > 0)
		{
			RandIndex = `SYNC_RAND(AllStrengths.Length);
			Strengths.AddItem(AllStrengths[RandIndex]);
			RevealedChosenTraits.AddItem(AllStrengths[RandIndex]);
			AllStrengths.Remove(RandIndex, 1);
			FilterTraitList(FallbackStrengths);
			FilterTraitList(AllStrengths);
		}
		else if(FallbackStrengths.Length > 0)
		{
			RandIndex = `SYNC_RAND(FallbackStrengths.Length);
			Strengths.AddItem(FallbackStrengths[RandIndex]);
			RevealedChosenTraits.AddItem(FallbackStrengths[RandIndex]);
			FallbackStrengths.Remove(RandIndex, 1);
			FilterTraitList(FallbackStrengths);
		}
	}
}

//---------------------------------------------------------------------------------------
function LoseWeaknesses(int NumWeaknesses)
{
	local int idx;

	for(idx = 0; idx < NumWeaknesses; idx++)
	{
		if(Weaknesses.Length == 0)
		{
			break;
		}

		Weaknesses.Remove(`SYNC_RAND(Weaknesses.Length), 1);
	}
}

//---------------------------------------------------------------------------------------
function EventListenerReturn RevealChosenTrait(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
	local XComGameState_AdventChosen ChosenState;
	local X2AbilityTemplate AbilityTemplate;
	local XComGameState	NewGameState;
	local XComGameState_Ability AbilityState;

	AbilityState = XComGameState_Ability(CallbackData);
	AbilityTemplate = AbilityState.GetMyTemplate();

	if(RevealedChosenTraits.Find(AbilityTemplate.DataName) == INDEX_NONE)
	{
		if(AbilityTemplate.ShouldRevealChosenTraitFn == none || AbilityTemplate.ShouldRevealChosenTraitFn(EventData, EventSource, GameState, CallbackData))
		{
			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Chosen Trait Reveal: " $ AbilityTemplate.DataName);
			ChosenState = XComGameState_AdventChosen(NewGameState.ModifyStateObject(class'XComGameState_AdventChosen', ObjectID));
			ChosenState.RevealedChosenTraits.AddItem(AbilityTemplate.DataName);

			NewGameState.GetContext().PostBuildVisualizationFn.AddItem(AbilityState.ChosenTraitRevealed_PostBuildVisualization);

			`TACTICALRULES.SubmitGameState(NewGameState);
		}
	}

	return ELR_NoInterrupt;
}

//---------------------------------------------------------------------------------------
function OnDefeated(XComGameState NewGameState)
{
	local XComGameState_HeadquartersAlien AlienHQ;
	local XComGameState_HeadquartersResistance ResHQ;
	
	foreach NewGameState.IterateByClassType(class'XComGameState_HeadquartersAlien', AlienHQ)
	{
		break;
	}

	RemoveTacticalTagFromAllMissions(NewGameState, GetMyTemplate().GetSpawningTag(Level));
	
	`XEVENTMGR.TriggerEvent(GetKilledEvent(), , , NewGameState);
	if (!AlienHQ.bFirstChosenKilled)
	{
		// Only trigger the Elder Rage event once, since it leads to Elder Rage cinematic
		AlienHQ.bFirstChosenKilled = true;
		`XEVENTMGR.TriggerEvent(GetElderRageEvent(), , , NewGameState);
	}

	bJustLeveledUp = false;
	bJustIncreasedKnowledgeLevel = false;

	AlienHQ.RemoveDarkEventsRelatedToChosen(NewGameState, self);

	// Update the risks on all Covert Actions, since if the Chosen was killed some may no longer be available
	ResHQ = XComGameState_HeadquartersResistance(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersResistance'));
	ResHQ.UpdateCovertActionNegatedRisks(NewGameState);
}

//#############################################################################################
//----------------   DISPLAY INFO  ------------------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
function string GetChosenName()
{
	return  (FirstName @ LastName);
}

//---------------------------------------------------------------------------------------
function string GetChosenNickname()
{
	return  Nickname;
}

//---------------------------------------------------------------------------------------
function StackedUIIconData GetChosenIcon()
{
	return ChosenIconData;
}

//---------------------------------------------------------------------------------------
function array<X2AbilityTemplate> GetChosenStrengths()
{
	return GetChosenTraits(Strengths);
}

//---------------------------------------------------------------------------------------
function array<X2AbilityTemplate> GetChosenWeaknesses()
{
	local array<X2AbilityTemplate> WeaknessList;

	if(bIgnoreWeaknesses)
	{
		WeaknessList.Length = 0;
	}
	else
	{
		WeaknessList = GetChosenTraits(Weaknesses);
	}

	return WeaknessList;
}

//---------------------------------------------------------------------------------------
function array<X2AbilityTemplate> GetChosenTraits(const out array<Name> Traits)
{
	local X2AbilityTemplateManager AbilityMgr;
	local array<X2AbilityTemplate> AllTraits;
	local int idx;

	AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();

	for(idx = 0; idx < Traits.Length; idx++)
	{
		AllTraits.AddItem(AbilityMgr.FindAbilityTemplate(Traits[idx]));
	}

	return AllTraits;
}

//---------------------------------------------------------------------------------------
function string GetStrengthsList()
{
	local array<X2AbilityTemplate> AllTraits;

	AllTraits = GetChosenStrengths();

	return GetChosenTraitsList(AllTraits, UnknownStrengthsString);
}

//---------------------------------------------------------------------------------------
function string GetWeaknessesList()
{
	local array<X2AbilityTemplate> AllTraits;

	AllTraits = GetChosenWeaknesses();

	return GetChosenTraitsList(AllTraits, UnknownWeaknessesString);
}

//---------------------------------------------------------------------------------------
function string GetChosenTraitsList(const out array<X2AbilityTemplate> AllTraits, string UnknownString)
{
	local string TraitListString;
	local int idx;
	local int UnknownCount;
	local XComGameState_AdventChosen PreviousChosenState;
	local EUIState TextState;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;
	TraitListString = "";
	UnknownCount = 0;

	// to determine if we freshly revealed a trait, we compare the current state of this chosen 
	// to the state it was in at the start of this tactical session
	PreviousChosenState = XComGameState_AdventChosen(History.GetGameStateForObjectID(ObjectID, , History.FindStartStateIndex()));

	for(idx = 0; idx < AllTraits.Length; idx++)
	{
		if( AllTraits[idx].AbilityRevealEvent == '' || RevealedChosenTraits.Find(AllTraits[idx].DataName) != INDEX_NONE)
		{
			if( AllTraits[idx].AbilityRevealEvent == '' || PreviousChosenState == None || PreviousChosenState.RevealedChosenTraits.Find(AllTraits[idx].DataName) != INDEX_NONE )
			{
				TextState = eUIState_Normal;
			}
			else
			{
				TextState = eUIState_Good;
			}

			TraitListString $= class'UIUtilities_Text'.static.GetColoredText(AllTraits[idx].LocFriendlyName, TextState);

			if( idx != (AllTraits.Length - 1) )
			{
				TraitListString $= ", ";
			}
		}
		else
		{
			++UnknownCount;
		}
	}

	if( UnknownCount > 0 )
	{
		if( TraitListString != "" )
		{
			TraitListString $= ", ";
		}

		TraitListString $= class'UIUtilities_Text'.static.GetColoredText(UnknownCount $ UnknownString, eUIState_Bad);
	}

	return class'UIUtilities_Text'.static.FormatCommaSeparatedNouns(TraitListString);
}

//---------------------------------------------------------------------------------------
function string GetChosenNarrativeFlavor()
{
	local XComGameState_NarrativeManager NarrativeMgr;
	local XComGameStateHistory History;
	local X2DynamicNarrativeMomentTemplate MomentTemplate;
	local X2DynamicNarrativeTemplateManager TemplateMgr;
	local Name TemplateName;
	local array<X2DynamicNarrativeMomentTemplate> PossibleMoments;

	TemplateMgr = class'X2DynamicNarrativeTemplateManager'.static.GetDynamicNarrativeTemplateManager();
	History = `XCOMHISTORY;
	NarrativeMgr = XComGameState_NarrativeManager(History.GetSingleGameStateObjectForClass(class'XComGameState_NarrativeManager'));

	foreach NarrativeMgr.PlayedThisMission(TemplateName)
	{
		MomentTemplate = X2DynamicNarrativeMomentTemplate(TemplateMgr.FindDynamicNarrativeTemplate(TemplateName));
		if( MomentTemplate != None && MomentTemplate.ChosenEndOfMissionQuote != "" )
		{
			PossibleMoments.AddItem(MomentTemplate);
		}
	}

	// choose a moment at random from the eligible pool
	if (PossibleMoments.Length > 0)
	{
		MomentTemplate = PossibleMoments[`SYNC_RAND(PossibleMoments.Length)];
		return MomentTemplate.ChosenEndOfMissionQuote;
	}

	return "";
}

//---------------------------------------------------------------------------------------
function int GetNumEncounters()
{
	return NumEncounters;
}

//---------------------------------------------------------------------------------------
function int GetNumExtracts()
{
	return NumExtracts;
}

//---------------------------------------------------------------------------------------
function int GetNumSoldiersKilled()
{
	// TODO: @mnauta probably need to track this here instead of just on the unitstate
	return 99;
}

//---------------------------------------------------------------------------------------
function XComGameState_ResistanceFaction GetRivalFaction()
{
	return XComGameState_ResistanceFaction(`XCOMHISTORY.GetGameStateForObjectID(RivalFaction.ObjectID));
}

//---------------------------------------------------------------------------------------
function string GetChosenPortraitImage()
{
	return GetMyTemplate().ChosenImages[Level];
}

//---------------------------------------------------------------------------------------
function string GetChosenPosterImage()
{
	return GetMyTemplate().ChosenPoster;
}

//---------------------------------------------------------------------------------------
function string GetHuntChosenImage(int HuntLevel)
{
	return GetMyTemplate().HuntChosenImages[HuntLevel];
}

//---------------------------------------------------------------------------------------
function string GetChosenClassName()
{
	return GetMyTemplate().ChosenTitle;
}

//---------------------------------------------------------------------------------------
function name GetAvengerAssaultEvent()
{
	return GetMyTemplate().AvengerAssaultEvent;
}

//---------------------------------------------------------------------------------------
function name GetAvengerAssaultCommentEvent()
{
	return GetMyTemplate().AvengerAssaultCommentEvent;
}

//---------------------------------------------------------------------------------------
function name GetAmbushCommentEvent()
{
	return GetMyTemplate().AmbushCommentEvent;
}

//---------------------------------------------------------------------------------------
function name GetCancelledActivityEvent()
{
	return GetMyTemplate().CancelledActivityEvent;
}

//---------------------------------------------------------------------------------------
function name GetFavoredGeoscapeEvent()
{
	return GetMyTemplate().FavoredGeoscapeEvent;
}

//---------------------------------------------------------------------------------------
function name GetRevealLocationEvent()
{
	return GetMyTemplate().RevealLocationEvent;
}

//---------------------------------------------------------------------------------------
function name GetChosenMetEvent()
{
	return GetMyTemplate().MetEvent;
}

//---------------------------------------------------------------------------------------
function name GetRegionContactedEvent()
{
	return GetMyTemplate().RegionContactedEvent;
}

//---------------------------------------------------------------------------------------
function name GetRetributionEvent()
{
	return GetMyTemplate().RetributionEvent;
}

//---------------------------------------------------------------------------------------
function name GetSabotageSuccessEvent()
{
	return GetMyTemplate().SabotageSuccessEvent;
}

//---------------------------------------------------------------------------------------
function name GetSabotageFailedEvent()
{
	return GetMyTemplate().SabotageFailedEvent;
}

//---------------------------------------------------------------------------------------
function name GetSoldierCapturedEvent()
{
	return GetMyTemplate().SoldierCapturedEvent;
}

//---------------------------------------------------------------------------------------
function name GetSoldierRescuedEvent()
{
	return GetMyTemplate().SoldierRescuedEvent;
}

//---------------------------------------------------------------------------------------
function name GetDarkEventCompleteEvent()
{
	return GetMyTemplate().DarkEventCompleteEvent;
}

//---------------------------------------------------------------------------------------
function name GetRetaliationEvent()
{
	return GetMyTemplate().RetaliationEvent;
}

//---------------------------------------------------------------------------------------
function name GetThresholdIncreasedEvent()
{
	switch (GetKnowledgeLevel())
	{
	case eChosenKnowledge_Saboteur:
		return GetMyTemplate().ThresholdTwoEvent;
	case eChosenKnowledge_Sentinel:
		return GetMyTemplate().ThresholdThreeEvent;
	case eChosenKnowledge_Collector:
		return GetMyTemplate().ThresholdFourEvent;
	default:
		return '';
	}
}

//---------------------------------------------------------------------------------------
function name GetLeveledUpEvent()
{
	return GetMyTemplate().LeveledUpEvent;
}

//---------------------------------------------------------------------------------------
function name GetKilledEvent()
{
	return GetMyTemplate().KilledEvent;
}

//---------------------------------------------------------------------------------------
function name GetElderRageEvent()
{
	return GetMyTemplate().ElderRageEvent;
}


//#############################################################################################
//----------------   CAPTURED SOLDIERS   ------------------------------------------------------	
//#############################################################################################

//---------------------------------------------------------------------------------------
function CaptureSoldier(XComGameState NewGameState, StateObjectReference UnitRef)
{
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState;

	History = `XCOMHISTORY;
	UnitState = XComGameState_Unit(History.GetGameStateForObjectID(UnitRef.ObjectID));

	if(UnitState != none && CapturedSoldiers.Find('ObjectID', UnitRef.ObjectID) == INDEX_NONE)
	{
		UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', UnitRef.ObjectID));
		UnitState.bCaptured = true;
		UnitState.ChosenCaptorRef = GetReference();
		bCapturedSoldier = true;
		CapturedSoldiers.AddItem(UnitRef);
		TotalCapturedSoldiers++;
		ModifyKnowledgeScore(NewGameState, GetScaledKnowledgeDelta(default.KnowledgePerCapture));
	}
}

//---------------------------------------------------------------------------------------
function ReleaseSoldier(XComGameState NewGameState, StateObjectReference UnitRef)
{
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState;

	History = `XCOMHISTORY;
	UnitState = XComGameState_Unit(History.GetGameStateForObjectID(UnitRef.ObjectID));

	if(UnitState != none && CapturedSoldiers.Find('ObjectID', UnitRef.ObjectID) != INDEX_NONE)
	{
		CapturedSoldiers.RemoveItem(UnitRef);
	}
}

//---------------------------------------------------------------------------------------
function int GetNumSoldiersCaptured()
{
	return CapturedSoldiers.Length;
}

//---------------------------------------------------------------------------------------
function float GetCaptureChanceScalar()
{
	if(CaptureChanceScalar <= 0)
	{
		return 1.0f;
	}

	return CaptureChanceScalar;
}

//#############################################################################################
//----------------   ACTIONS   ----------------------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
function bool CanTakeAction()
{
	return (!bDefeated && bActionUsesTimer && !bPerformedMonthlyAction && !bActionCountered && class'X2StrategyGameRulesetDataStructures'.static.LessThan(ActionDate, GetCurrentTime()));
}

//---------------------------------------------------------------------------------------
// Geoscape action taken, depends on the Chosen's job
function TakeAction(XComGameState NewGameState)
{
	local XComGameState_ChosenAction ActionState;

	ActionState = XComGameState_ChosenAction(NewGameState.ModifyStateObject(class'XComGameState_ChosenAction', CurrentMonthAction.ObjectID));
	ActionState.ActivateAction(NewGameState);
	bPerformedMonthlyAction = true;
}

//---------------------------------------------------------------------------------------
function ChooseAction(XComGameState NewGameState, XComGameState_ChosenAction ActionState, out array<TDateTime> UsedDates)
{
	local int IterCount;

	// Set it as the current action
	CurrentMonthAction = ActionState.GetReference();
	ActionState.ChosenRef = self.GetReference();
	ActionState.SetKnowledgeGain();
	
	// Some actions have special behavior when chosen
	if(ActionState.GetMyTemplate().OnChooseActionFn != none)
	{
		ActionState.GetMyTemplate().OnChooseActionFn(NewGameState, ActionState);
	}

	// Some actions are activated immediately
	if(ActionState.GetMyTemplate().bPerformImmediately)
	{
		ActionState.ActivateAction(NewGameState);
		bPerformedMonthlyAction = true;
	}
	else if(!ActionState.GetMyTemplate().bPerformAtMonthEnd)
	{
		// If not a month end action, needs to be scheduled
		bActionUsesTimer = true;
		IterCount = 0;
		ActionDate = class'X2StrategyGameRulesetDataStructures'.static.GetDateFromMinMax(GetCurrentTime(), ActionState.GetMyTemplate().ActivationTime);

		while(IterCount < 25 && !ChosenActionDateValid(ActionDate, UsedDates))
		{
			ActionDate = class'X2StrategyGameRulesetDataStructures'.static.GetDateFromMinMax(GetCurrentTime(), ActionState.GetMyTemplate().ActivationTime);
			IterCount++;
		}

		UsedDates.AddItem(ActionDate);
	}
}

//---------------------------------------------------------------------------------------
private function bool ChosenActionDateValid(TDateTime TestDate, array<TDateTime> UsedDates)
{
	local int DayDiff;
	local TDateTime CurrentUsedDate;

	foreach UsedDates(CurrentUsedDate)
	{
		DayDiff = class'X2StrategyGameRulesetDataStructures'.static.DifferenceInDays(TestDate, CurrentUsedDate);

		if(DayDiff > -default.MinChosenActionBufferDays && DayDiff < default.MinChosenActionBufferDays)
		{
			return false;
		}
	}

	return true;
}

//---------------------------------------------------------------------------------------
function int GetMonthsSinceAction(name ActionTemplateName)
{
	local XComGameStateHistory History;
	local XComGameState_ChosenAction ActionState;
	local int Count, idx;

	History = `XCOMHISTORY;
		Count = 0;

	// Search backwards for action
	for(idx = (PreviousMonthActions.Length - 1); idx >= 0; idx--)
	{
		Count++;
		ActionState = XComGameState_ChosenAction(History.GetGameStateForObjectID(PreviousMonthActions[idx].ObjectID));

		if(ActionState != none && ActionState.GetMyTemplateName() == ActionTemplateName)
		{
			// found it, return the count
			return Count;
		}

		if(idx == 0)
		{
			// Never performed action flagged by negative
			return -1;
		}
	}

	// Only reached if no previous month actions
	return -1;
}

//---------------------------------------------------------------------------------------
function XComGameState_ChosenAction GetCurrentMonthAction()
{
	return XComGameState_ChosenAction(`XCOMHISTORY.GetGameStateForObjectID(CurrentMonthAction.ObjectID));
}

//---------------------------------------------------------------------------------------
function string GetCurrentMonthActionName()
{
	local XComGameState_ChosenAction ActionState;

	ActionState = GetCurrentMonthAction();

	if(ActionState == none)
	{
		return "";
	}

	return ActionState.GetDisplayName();
}

//#############################################################################################
//----------------   ENGAGE XCOM   ------------------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
function bool ShouldIncreaseCovertActionRisks()
{
	return (!bDefeated && (GetKnowledgeLevel() >= eChosenKnowledge_Sentinel));
}

//---------------------------------------------------------------------------------------
function bool GetFanfareSound(out String Fanfare)
{
	Fanfare = GetMyTemplate().FanfareEvent;

	if(Fanfare == "")
	{
		return false;
	}

	return true;
}


//#############################################################################################
//----------------   CHOSEN UNIT LEVEL   ------------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
function bool AtMaxLevel()
{
	if(Level >= (GetMyTemplate().ChosenProgressionData.CharTemplates.Length - 1))
	{
		return true;
	}

	return false;
}

//#############################################################################################
//----------------   KNOWLEDGE LEVEL   --------------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
function EChosenKnowledge GetKnowledgeLevel()
{
	return CurrentKnowledgeLevel;
}

//---------------------------------------------------------------------------------------
function int GetKnowledgeScore(optional bool bWithMonthDelta = false)
{
	if(bWithMonthDelta)
	{
		return KnowledgeScore + MonthKnowledgeDelta;
	}

	return KnowledgeScore;
}

//---------------------------------------------------------------------------------------
function int GetScaledKnowledgeDelta(int InDelta)
{
	if(KnowledgeGainScalar == 0)
	{
		// Knowledge gain not modified
		return InDelta;
	}

	return Round(float(InDelta) * KnowledgeGainScalar);
}

//---------------------------------------------------------------------------------------
function int GetKnowledgePercent(optional bool bWithMonthDelta = false, optional int DeltaVal = 0)
{
	return Round(float(GetKnowledgeScore(bWithMonthDelta) + DeltaVal) / float(GetMaxScoreAtKnowledgeLevel(eChosenKnowledge_Raider)) * 100.0f);
}

//---------------------------------------------------------------------------------------
function int GetMaxScoreAtKnowledgeLevel(int KnowledgeLevel)
{
	if(KnowledgeLevel < 0)
	{
		KnowledgeLevel = 0;
	}
	else if(KnowledgeLevel > eChosenKnowledge_Raider)
	{
		KnowledgeLevel = eChosenKnowledge_Raider;
	}

	return default.MaxScoreAtKnowledgeLevel[KnowledgeLevel];
}

//---------------------------------------------------------------------------------------
function ModifyKnowledgeScore(XComGameState NewGameState, int DeltaScore, optional bool bIgnoreGates = false, optional bool bIgnoreShare = false)
{
	local EChosenKnowledge MaxLevel;
	local int MinDelta, MaxDelta;

	// Can only gain 1 level per month
	MaxLevel = EChosenKnowledge(CurrentKnowledgeLevel + 1);

	if(bIgnoreGates)
	{
		MaxLevel = eChosenKnowledge_Raider;
	}

	MinDelta = 0 - KnowledgeScore;
	MaxDelta = GetMaxScoreAtKnowledgeLevel(int(MaxLevel)) - KnowledgeScore;
	MonthKnowledgeDelta += DeltaScore;
	MonthKnowledgeDelta = Clamp((MonthKnowledgeDelta), MinDelta, MaxDelta);

	// For the Loyalty Among Thieves Dark Event
	if(!bIgnoreShare)
	{
		ChosenShareKnowledge(NewGameState, DeltaScore);
	}
}

//---------------------------------------------------------------------------------------
private function ChosenShareKnowledge(XComGameState NewGameState, int DeltaScore)
{
	local XComGameStateHistory History;
	local XComGameState_AdventChosen ChosenState;

	if(DeltaScore > 0)
	{
		History = `XCOMHISTORY;
		foreach History.IterateByClassType(class'XComGameState_AdventChosen', ChosenState)
		{
			if(ChosenState.ObjectID != self.ObjectID && !ChosenState.bDefeated && ChosenState.bMetXCom && ChosenState.KnowledgeFromOtherChosenPercent > 0)
			{
				ChosenState = XComGameState_AdventChosen(NewGameState.ModifyStateObject(class'XComGameState_AdventChosen', ChosenState.ObjectID));
				ChosenState.ModifyKnowledgeScore(NewGameState, Round(float(DeltaScore) * ChosenState.KnowledgeFromOtherChosenPercent), false, true);
			}
		}
	}
}

//---------------------------------------------------------------------------------------
// Called by ability in tactical
function ExtractKnowledge()
{
	local int ScoreToAdd, RemainingScore;
	local XComGameState_HeadquartersXCom XComHQ;

	ScoreToAdd = default.KnowledgePerExtract;
	ScoreToAdd = GetScaledKnowledgeDelta(ScoreToAdd);

	XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	ScoreToAdd = Round(float(ScoreToAdd) * XComHQ.ChosenKnowledgeGainScalar);

	RemainingScore = GetMaxScoreAtKnowledgeLevel(CurrentKnowledgeLevel + 1) - (GetKnowledgeScore(true));
	ScoreToAdd = Clamp(ScoreToAdd, 0, RemainingScore);
	
	bExtractedKnowledge = true;
	MissionKnowledgeExtracted = ScoreToAdd;
	NumExtracts++;
}

//---------------------------------------------------------------------------------------
// Defaults to lowest value at Knowledge Level
function SetKnowledgeLevel(XComGameState NewGameState, EChosenKnowledge KnowledgeLevel, optional bool bForceHigh = false, optional bool bForceMid = false)
{
	local int PriorIndex;
	local EChosenKnowledge OldLevel;

	if(bForceHigh)
	{
		// Set to Highest value at Knowledge Level
		KnowledgeScore = GetMaxScoreAtKnowledgeLevel(KnowledgeLevel);

	}
	else if(bForceMid)
	{
		PriorIndex = int(KnowledgeLevel) - 1;

		if(PriorIndex >= 0)
		{
			KnowledgeScore = GetMaxScoreAtKnowledgeLevel(PriorIndex) + 1;
			KnowledgeScore += ((GetMaxScoreAtKnowledgeLevel(KnowledgeLevel) - GetMaxScoreAtKnowledgeLevel(PriorIndex)) / 2);
		}
		else
		{
			KnowledgeScore = (GetMaxScoreAtKnowledgeLevel(KnowledgeLevel)) / 2;
		}
	}
	else
	{
		PriorIndex = int(KnowledgeLevel) - 1;

		if(PriorIndex >= 0)
		{
			KnowledgeScore = (GetMaxScoreAtKnowledgeLevel(PriorIndex)) + 1;
		}
		else
		{
			KnowledgeScore = 0;
		}
	}

	OldLevel = CurrentKnowledgeLevel;
	CurrentKnowledgeLevel = KnowledgeLevel;
	HandleKnowledgeLevelChange(NewGameState, OldLevel, CurrentKnowledgeLevel);
}

//---------------------------------------------------------------------------------------
function EChosenKnowledge CalculateKnowledgeLevel()
{
	local int idx;

	for(idx = 0; idx < eChosenKnowledge_MAX; idx++)
	{
		if((GetKnowledgeScore(true)) <= GetMaxScoreAtKnowledgeLevel(idx))
		{
			return EChosenKnowledge(idx);
		}
	}

	return eChosenKnowledge_Raider;
}

//---------------------------------------------------------------------------------------
function HandleKnowledgeLevelChange(XComGameState NewGameState, EChosenKnowledge OldLevel, EChosenKnowledge NewLevel)
{
	local XComGameState_HeadquartersAlien AlienHQ;
	local XComGameState_ResistanceFaction FactionState;
	local XComGameState_CovertAction ActionState;
	local StateObjectReference ActionRef;
	local int idx;

	AlienHQ = GetAndAddAlienHQ(NewGameState);
	if (NewLevel > AlienHQ.HighestChosenKnowledgeLevel)
	{
		AlienHQ.HighestChosenKnowledgeLevel = NewLevel;
	}

	if (ShouldIncreaseCovertActionRisks() && OldLevel < eChosenKnowledge_Sentinel)
	{
		// First check if the Faction is already in the NewGameState, otherwise grab it from the History
		FactionState = XComGameState_ResistanceFaction(NewGameState.GetGameStateForObjectID(RivalFaction.ObjectID));
		if (FactionState == none)
		{
			FactionState = GetRivalFaction();
		}
		
		foreach FactionState.GoldenPathActions(ActionRef)
		{
			ActionState = XComGameState_CovertAction(NewGameState.ModifyStateObject(class'XComGameState_CovertAction', ActionRef.ObjectID));
			if (ActionState != none && !ActionState.bStarted)
			{
				for (idx = 0; idx < ActionState.Risks.Length; idx++)
				{
					// Increase the chance of every risk happening for this Chosen's rival covert actions
					// Any Covert Actions which are created after this point will have the risk increase applied with their initialization
					ActionState.Risks[idx].ChanceToOccur = min(ActionState.Risks[idx].ChanceToOccur + default.CovertActionRiskIncrease, 100);
				}
			}
		}

		foreach FactionState.CovertActions(ActionRef)
		{
			ActionState = XComGameState_CovertAction(NewGameState.ModifyStateObject(class'XComGameState_CovertAction', ActionRef.ObjectID));
			if (ActionState != none && !ActionState.bStarted)
			{
				for (idx = 0; idx < ActionState.Risks.Length; idx++)
				{
					// Increase the chance of every risk happening for this Chosen's rival covert actions
					// Any Covert Actions which are created after this point will have the risk increase applied with their initialization
					ActionState.Risks[idx].ChanceToOccur = min(ActionState.Risks[idx].ChanceToOccur + default.CovertActionRiskIncrease, 100);
				}
			}
		}
	}

	if(NewLevel >= eChosenKnowledge_Collector)
	{
		CaptureChanceScalar = 2.0f;
	}
	else if(NewLevel < eChosenKnowledge_Collector)
	{
		CaptureChanceScalar = 1.0f;
	}

	if(NewLevel < eChosenKnowledge_Raider)
	{
		MonthsAsRaider = 0;
	}
}

//#############################################################################################
//----------------   VISIBILITY   -------------------------------------------------------------
//#############################################################################################

//#############################################################################################
//----------------   HELPERS   ----------------------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
function XComGameState_HeadquartersAlien GetAndAddAlienHQ(XComGameState NewGameState)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersAlien AlienHQ;

	foreach NewGameState.IterateByClassType(class'XComGameState_HeadquartersAlien', AlienHQ)
	{
		break;
	}

	if(AlienHQ == none)
	{
		History = `XCOMHISTORY;
		AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));
		AlienHQ = XComGameState_HeadquartersAlien(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersAlien', AlienHQ.ObjectID));
	}

	return AlienHQ;
}

//---------------------------------------------------------------------------------------
function bool ShouldForceMissionRegion()
{
	return (MissionsSinceLastAppearance >= GetForceMissionRegionCount());
}

//---------------------------------------------------------------------------------------
function int GetForceMissionRegionCount()
{
	return `ScaleStrategyArrayInt(default.ForceMissionRegionCount);
}

//---------------------------------------------------------------------------------------
function int GetChosenAppearChance()
{
	local array<AppearChance> ChosenChances;
	local AppearChance MaxAppearChance;
	local int idx, CampaignDifficulty;

	CampaignDifficulty = `TacticalDifficultySetting;

	for(idx = 0; idx < default.AppearChances.Length; idx++)
	{
		if(AppearChances[idx].Difficulty == CampaignDifficulty)
		{
			ChosenChances.AddItem(default.AppearChances[idx]);

			if(ChosenChances.Length == 1 || default.AppearChances[idx].MissionCount > MaxAppearChance.MissionCount)
			{
				MaxAppearChance = default.AppearChances[idx];
			}
		}
	}

	if(ChosenChances.Length == 0)
	{
		return 100;
	}

	for(idx = 0; idx < ChosenChances.Length; idx++)
	{
		if(MissionsSinceLastAppearance == ChosenChances[idx].MissionCount)
		{
			return ChosenChances[idx].PercentChance;
		}
	}

	return MaxAppearChance.PercentChance;
}

//---------------------------------------------------------------------------------------
function RemoveTacticalTagFromAllMissions(XComGameState NewGameState, name TacticalTag, optional name NewTacticalTag = '')
{
	local XComGameStateHistory History;
	local XComGameState_MissionSite MissionState;

	History = `XCOMHISTORY;

	foreach History.IterateByClassType(class'XComGameState_MissionSite', MissionState)
	{
		if(MissionState.TacticalGameplayTags.Find(TacticalTag) != INDEX_NONE)
		{
			MissionState = XComGameState_MissionSite(NewGameState.ModifyStateObject(class'XComGameState_MissionSite', MissionState.ObjectID));
			MissionState.TacticalGameplayTags.RemoveItem(TacticalTag);

			// Clear out any spawn data
			MissionState.SelectedMissionData.SelectedMissionScheduleName = '';

			// Replace with new tag (possibly)
			if(NewTacticalTag != '' && MissionState.TacticalGameplayTags.Find(NewTacticalTag) == INDEX_NONE)
			{
				MissionState.TacticalGameplayTags.AddItem(NewTacticalTag);
			}
		}
	}
}

//---------------------------------------------------------------------------------------
// Safety call on missions (for when this Chosen is defeated)
function PurgeMissionOfTags(out XComGameState_MissionSite MissionState)
{
	local array<name> SpawningTags;
	local name SpawnTag;
	local int idx;

	SpawningTags = GetMyTemplate().ChosenProgressionData.SpawningTags;

	foreach SpawningTags(SpawnTag)
	{
		for(idx = 0; idx < MissionState.TacticalGameplayTags.Length; idx++)
		{
			if(MissionState.TacticalGameplayTags[idx] == SpawnTag)
			{
				MissionState.TacticalGameplayTags.Remove(idx, 1);
				idx--;
			}
		}
	}
}


//#############################################################################################
//----------------   END OF MONTH   -----------------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
function OnEndMonth(XComGameState NewGameState)
{
	if(!bDefeated)
	{
		CleanUpMonthlyActions(NewGameState);
		EndOfMonthUpdateKnowledgeLevel(NewGameState);
	}
}

//---------------------------------------------------------------------------------------
function CleanUpMonthlyActions(XComGameState NewGameState)
{
	local XComGameStateHistory History;
	local XComGameState_ChosenAction ActionState;
	local StateObjectReference EmptyRef;

	History = `XCOMHISTORY;
	ActionState = XComGameState_ChosenAction(History.GetGameStateForObjectID(CurrentMonthAction.ObjectID));

	if(ActionState != none)
	{
		// Some Actions need to be activated here
		if(ActionState.GetMyTemplate().bPerformAtMonthEnd)
		{
			ActionState = XComGameState_ChosenAction(NewGameState.ModifyStateObject(class'XComGameState_ChosenAction', ActionState.ObjectID));
			ActionState.ActivateAction(NewGameState);
			bPerformedMonthlyAction = true;
		}

		// All actions grab their activity string (for the Chosen Events screen) here if they completed the action
		if (!bActionCountered && bPerformedMonthlyAction)
		{
			//MonthActivities.AddItem(ActionState.GetDisplayName());
		}

		// Now place the action in the list of previous actions
		PreviousMonthActions.AddItem(CurrentMonthAction);
	}

	// Clear current action
	CurrentMonthAction = EmptyRef;
	bActionUsesTimer = false;
	bActionCountered = false;
	bPerformedMonthlyAction = false;
}

//---------------------------------------------------------------------------------------
function EndOfMonthUpdateKnowledgeLevel(XComGameState NewGameState)
{
	local EChosenKnowledge OldLevel, NewLevel;

	OldLevel = GetKnowledgeLevel();

	// Guaranteed knowledge gain per month (if met XCom)
	if(bMetXCom && !bDefeated)
	{
		MonthKnowledgeDelta = Clamp((MonthKnowledgeDelta + GetScaledKnowledgeDelta(default.GuaranteedKnowledgeGainPerMonth)), MonthKnowledgeDelta, GetMaxScoreAtKnowledgeLevel(OldLevel + 1));
	}

	NewLevel = CalculateKnowledgeLevel();

	if(OldLevel != NewLevel)
	{
		CurrentKnowledgeLevel = NewLevel;
		HandleKnowledgeLevelChange(NewGameState, OldLevel, NewLevel);

		if(NewLevel > OldLevel)
		{
			bJustIncreasedKnowledgeLevel = true;
		}
	}

	if(NewLevel == eChosenKnowledge_Raider)
	{
		MonthsAsRaider++;
	}
}

//---------------------------------------------------------------------------------------
function string GetMonthActivitiesList()
{
	local string AllActivities;
	local int idx;

	AllActivities = "";

	for(idx = 0; idx < MonthActivities.Length; idx++)
	{
		if(idx == 0)
		{
			AllActivities $= class'UIResistanceReport_ChosenEvents'.default.PrevMonthActivitiesHeader;
		}
		AllActivities $= "-" $ MonthActivities[idx];

		if(idx < (MonthActivities.Length - 1))
		{
			AllActivities $= "\n";
		}
	}

	return AllActivities;
}

//---------------------------------------------------------------------------------------
function ClearMonthActivities()
{
	bJustIncreasedKnowledgeLevel = false;
	bJustLeveledUp = false;
	MonthActivities.Length = 0;
	KnowledgeScore += MonthKnowledgeDelta;
	MonthKnowledgeDelta = 0;
}

//#############################################################################################
//----------------   GEOSCAPE ENTITY IMPLEMENTATION   -----------------------------------------
//#############################################################################################

function bool HasTooltipBounds()
{
	return true; // Placed at the start of the game, so need to always have bounds active
}

//---------------------------------------------------------------------------------------
function bool ShouldBeVisible()
{
	return bMetXCom && !bDefeated; // Chosen icon appears on Geoscape when they meet XCom until they are defeated
}

//---------------------------------------------------------------------------------------
function class<UIStrategyMapItem> GetUIClass()
{
	return class'UIStrategyMapItem_AdventChosen';
}

//---------------------------------------------------------------------------------------
function StaticMesh GetStaticMesh()
{
	local Object MeshObject;

	MeshObject = `CONTENT.RequestGameArchetype(GetMyTemplate().OverworldMeshPath);
	if (MeshObject != none && MeshObject.IsA('StaticMesh'))
	{
		return StaticMesh(MeshObject);
	}
}

//#############################################################################################
//----------------   TACTICAL INFORMATION -----------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
function X2AbilityTemplate GetReinforcementStrength()
{
	local array<X2AbilityTemplate> AllTraits;
	local X2AbilityTemplate StrengthTemplate;

	AllTraits = GetChosenStrengths();

	foreach AllTraits(StrengthTemplate)
	{
		if( StrengthTemplate.ChosenReinforcementGroupName.Length > Level )
		{
			return StrengthTemplate;
		}
	}

	return none;
}

function Name GetReinforcementGroupName()
{
	local array<X2AbilityTemplate> AllTraits;
	local X2AbilityTemplate StrengthTemplate;

	AllTraits = GetChosenStrengths();

	foreach AllTraits(StrengthTemplate)
	{
		if( StrengthTemplate.ChosenReinforcementGroupName.Length > Level )
		{
			return StrengthTemplate.ChosenReinforcementGroupName[Level];
		}
	}

	return GetMyTemplate().GetReinforcementGroupName(Level);
}

//#############################################################################################
//----------------   FAVORED   ----------------------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
function BecomeFavored()
{
	//bFavored = true;
	//KnowledgeGainScalar = default.FavoredKnowledgeGainScalar;
	//GainNewStrengths(default.NumStrengthsWhenFavored);
	//LoseWeaknesses(default.NumWeaknessesWhenFavored);
}

//---------------------------------------------------------------------------------------
function bool IsFavored()
{
	return (bFavored && !bDefeated);
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
		if (bMetXCom && !bSeenLocationReveal)
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
		if (bMetXCom && !bSeenLocationReveal)
		{
			bNeedsLocationReveal = true;
			bModified = true;
		}
	}

	return bModified;
}

//---------------------------------------------------------------------------------------
function UpdateGameBoard()
{
	local XComGameState NewGameState;
	local XComGameState_AdventChosen NewChosenState;
	local UIStrategyMap StrategyMap;
	local bool bUpdated;

	if (ShouldUpdate())
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Update Chosen");

		NewChosenState = XComGameState_AdventChosen(NewGameState.ModifyStateObject(class'XComGameState_AdventChosen', ObjectID));

		bUpdated = NewChosenState.Update(NewGameState);
		`assert(bUpdated); // why did Update & ShouldUpdate return different bools?

		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
		`HQPRES.StrategyMap2D.UpdateMissions();
	}

	StrategyMap = `HQPRES.StrategyMap2D;
	if (StrategyMap != none && StrategyMap.m_eUIState != eSMS_Flight)
	{
		if (bNeedsLocationReveal)
		{
			`HQPRES.BeginChosenRevealSequence(self);
		}
	}
}

//---------------------------------------------------------------------------------------
DefaultProperties
{
	ChosenActivatedStateUnitValue = "ChosenActivatedStateUnitValue"
}
