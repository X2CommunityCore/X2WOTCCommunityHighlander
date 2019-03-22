//---------------------------------------------------------------------------------------
//  FILE:    XComGameState_AlienRulerManager.uc
//  AUTHOR:  Mark Nauta  --  01/28/2016
//  PURPOSE: This object represents the instance of the Alien Ruler manager
//			 in the XCOM 2 strategy game
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComGameState_AlienRulerManager extends XComGameState_BaseObject config(GameData);

// Ruler Tracking
var StateObjectReference								RulerOnCurrentMission;
var array<StateObjectReference>							AllAlienRulers;
var array<StateObjectReference>							ActiveAlienRulers;
var array<StateObjectReference>							DefeatedAlienRulers;
var array<StateObjectReference>							EscapedAlienRulers;
var int													MissionsSinceLastRuler;
var int													RulerAppearRoll; // Need to store for Shadow Chamber to show ruler spawning correctly for concurrent missions
var bool												bRulerEscaped; // Did a Ruler escape on the last mission?
var bool												bHeardRulerEscapedVO; // Did the Ruler Escaped VO play already
var bool												bRulerDefeated; // Was a Ruler defeated on the last mission?
var array<AlienRulerLocation>							AlienRulerLocations; // Used by XPack Integrated DLC to store the mission location of each ruler

// DLC Installation Tracking
var bool												bContentCheckCompleted; // Has the popup asking the player whether or not to enable DLC content been shown
var bool												bContentActivated; // Is the DLC content enabled

// Force Ruler to Appear
var StateObjectReference								ForcedRulerOnNextMission;

// Config vars
var const config array<AlienRulerData>					AlienRulerTemplates;
var const config array<int>								RulerMaxNumEncounters;
var const config array<RulerEscapeHealthThreshold>		RulerEscapeHealthThresholds;
var const config array<RulerReappearChance>				RulerReappearChances;
var const config int									RulerLocationSpawnMaxHours;

// Central's config data
var const config name									NestCentralTemplate;
var const config array<name>							NestCentralWeaponUpgrades;

// Localized strings
var localized string									NestCentralFirstName;
var localized string									NestCentralLastName;
var localized string									NestCentralNickName;

//---------------------------------------------------------------------------------------
static function SetUpRulers(XComGameState StartState)
{
	local XComGameState_AlienRulerManager RulerMgr;

	foreach StartState.IterateByClassType(class'XComGameState_AlienRulerManager', RulerMgr)
	{
		break;
	}

	if (RulerMgr == none)
	{
		RulerMgr = XComGameState_AlienRulerManager(StartState.CreateNewStateObject(class'XComGameState_AlienRulerManager'));
	}
	
	RulerMgr.CreateAlienRulers(StartState);
	RulerMgr.CreateNestCentral(StartState);
}

//---------------------------------------------------------------------------------------
function CreateAlienRulers(XComGameState NewGameState)
{
	local XComGameState_Unit UnitState;
	local X2CharacterTemplateManager CharMgr;
	local X2CharacterTemplate CharTemplate;
	local int idx;

	CharMgr = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager();

	for(idx = 0; idx < default.AlienRulerTemplates.Length; idx++)
	{
		CharTemplate = CharMgr.FindCharacterTemplate(default.AlienRulerTemplates[idx].AlienRulerTemplateName);
		UnitState = CharTemplate.CreateInstanceFromTemplate(NewGameState);
		UnitState.SetUnitFloatValue('NumEscapes', 0.0f, eCleanup_Never);
		UnitState.SetUnitFloatValue('NumAppearances', 0.0f, eCleanup_Never);
		UnitState.bIsSpecial = true;
		UnitState.RemoveStateFromPlay(); // Do not process the ruler states in tactical
		UnitState.ApplyFirstTimeStatModifiers(); // Update the Ruler HP values to work with Beta Strike
		AllAlienRulers.AddItem(UnitState.GetReference());
		class'X2Helpers_DLC_Day60'.static.UpdateRulerEscapeHealth(UnitState);
	}
}

//---------------------------------------------------------------------------------------
function CreateNestCentral(XComGameState NewGameState)
{
	local XComGameState_Unit UnitState;
	local X2ItemTemplateManager ItemTemplateMgr;
	local X2CharacterTemplateManager CharMgr;
	local X2CharacterTemplate CharTemplate;
	local XComGameState_Item CentralRifle;
	local X2WeaponUpgradeTemplate UpgradeTemplate;
	local name WeaponUpgradeName;

	CharMgr = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager();
	CharTemplate = CharMgr.FindCharacterTemplate(default.NestCentralTemplate);
	UnitState = CharTemplate.CreateInstanceFromTemplate(NewGameState);

	UnitState.SetCharacterName(default.NestCentralFirstName, default.NestCentralLastName, default.NestCentralNickName);
	UnitState.SetCountry(CharTemplate.DefaultAppearance.nmFlag);
	UnitState.RankUpSoldier(NewGameState, 'CentralOfficer');
	UnitState.ApplyInventoryLoadout(NewGameState, CharTemplate.DefaultLoadout);
	UnitState.StartingRank = 1;
	UnitState.SetXPForRank(1);

	ItemTemplateMgr = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	CentralRifle = UnitState.GetPrimaryWeapon();
	foreach default.NestCentralWeaponUpgrades(WeaponUpgradeName)
	{
		UpgradeTemplate = X2WeaponUpgradeTemplate(ItemTemplateMgr.FindItemTemplate(WeaponUpgradeName));
		if (UpgradeTemplate != none)
		{
			CentralRifle.ApplyWeaponUpgradeTemplate(UpgradeTemplate);
		}
	}
}

//---------------------------------------------------------------------------------------
static function PreMissionUpdate(XComGameState NewGameState, XComGameState_MissionSite MissionState)
{
	local XComGameStateHistory History;
	local XComGameState_AlienRulerManager RulerMgr;
	local XComGameState_Unit UnitState;

	History = `XCOMHISTORY;
	RulerMgr = XComGameState_AlienRulerManager(History.GetSingleGameStateObjectForClass(class'XComGameState_AlienRulerManager'));
	RulerMgr = XComGameState_AlienRulerManager(NewGameState.ModifyStateObject(class'XComGameState_AlienRulerManager', RulerMgr.ObjectID));

	// Do a hard check for the Nest mission here, in case the Shadow Chamber is up we still need the Ruler Update before that mission
	if (MissionState.SelectedMissionData.SelectedMissionScheduleName == '' || MissionState.Source == 'MissionSource_AlienNest')
	{
		RulerMgr.UpdateRulerSpawningData(NewGameState, MissionState);
	}

	// Only update NumAppearances of the Ruler here when actually going into the mission
	if(RulerMgr.RulerOnCurrentMission.ObjectID != 0)
	{
		UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', RulerMgr.RulerOnCurrentMission.ObjectID));
		class'X2Helpers_DLC_Day60'.static.IncrementRulerNumAppearances(UnitState);
	}
}

//---------------------------------------------------------------------------------------
private function AddRulerAdditionalTacticalTags(XComGameState_HeadquartersXCom XComHQ, int NumAppearances, AlienRulerData RulerData)
{
	local int idx, MaxNumAppearances, MaxAppearanceIndex;

	if(RulerData.AdditionalTags.Length == 0)
	{
		return;
	}

	MaxNumAppearances = 0;
	MaxAppearanceIndex = 0;

	for(idx = 0; idx < RulerData.AdditionalTags.Length; idx++)
	{
		if(NumAppearances == RulerData.AdditionalTags[idx].NumTimesAppeared)
		{
			XComHQ.TacticalGameplayTags.AddItem(RulerData.AdditionalTags[idx].TacticalTag);
			return;
		}

		if(RulerData.AdditionalTags[idx].NumTimesAppeared > MaxNumAppearances)
		{
			MaxNumAppearances = RulerData.AdditionalTags[idx].NumTimesAppeared;
			MaxAppearanceIndex = idx;
		}
	}

	if(NumAppearances >= MaxNumAppearances)
	{
		XComHQ.TacticalGameplayTags.AddItem(RulerData.AdditionalTags[MaxAppearanceIndex].TacticalTag);
	}
}

//---------------------------------------------------------------------------------------
private function int GetRulerAppearChance(XComGameState_Unit UnitState)
{
	local array<RulerReappearChance> AppearChances;
	local RulerReappearChance MaxAppearChance;
	local int idx, CampaignDifficulty, NumAppearances;
	
	CampaignDifficulty = `TacticalDifficultySetting;
	NumAppearances = class'X2Helpers_DLC_Day60'.static.GetRulerNumAppearances(UnitState);
	
	if(NumAppearances == 0)
	{
		return 100;
	}

	for(idx = 0; idx < default.RulerReappearChances.Length; idx++)
	{
		if(default.RulerReappearChances[idx].Difficulty == CampaignDifficulty)
		{
			AppearChances.AddItem(default.RulerReappearChances[idx]);

			if(AppearChances.Length == 1 || default.RulerReappearChances[idx].MissionCount > MaxAppearChance.MissionCount)
			{
				MaxAppearChance = default.RulerReappearChances[idx];
			}
		}
	}

	if(AppearChances.Length == 0)
	{
		return 100;
	}

	for(idx = 0; idx < AppearChances.Length; idx++)
	{
		if(MissionsSinceLastRuler == AppearChances[idx].MissionCount)
		{
			return AppearChances[idx].PercentChance;
		}
	}

	return MaxAppearChance.PercentChance;
}

//---------------------------------------------------------------------------------------
function OnEndTacticalPlay(XComGameState NewGameState)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Unit RulerState, UnitState;
	local StateObjectReference EmptyRef;
	local XComGameState_AIPlayerData AIPlayerData;
	local XComGameState_AIGroup AIGroup;
	local int GroupIndex, UnitIndex, RulerIndex, LocationIndex;

	super.OnEndTacticalPlay(NewGameState);

	History = `XCOMHISTORY;

	bRulerDefeated = false;
	bRulerEscaped = false;

	// Update Active and Defeated Rulers
	if (RulerOnCurrentMission.ObjectID != 0)
	{
		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
		XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));

		RulerState = XComGameState_Unit(NewGameState.GetGameStateForObjectID(RulerOnCurrentMission.ObjectID));
		if (RulerState == none)
		{
			RulerState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', RulerOnCurrentMission.ObjectID));
		}

		// Grab the ruler unit actually used in this tactical mission and check if they died
		AIPlayerData = XComGameState_AIPlayerData(History.GetSingleGameStateObjectForClass(class'XComGameState_AIPlayerData'));

		for (GroupIndex = 0; GroupIndex < AIPlayerData.GroupList.Length; GroupIndex++)
		{
			if (bRulerDefeated)
			{
				break;
			}

			AIGroup = XComGameState_AIGroup(History.GetGameStateForObjectID(AIPlayerData.GroupList[GroupIndex].ObjectID));
			if (AIGroup != none)
			{
				for (UnitIndex = 0; UnitIndex < AIGroup.m_arrMembers.Length; UnitIndex++)
				{
					UnitState = XComGameState_Unit(History.GetGameStateForObjectID(AIGroup.m_arrMembers[UnitIndex].ObjectID));

					if (UnitState != none && UnitState.GetMyTemplateName() == RulerState.GetMyTemplateName())
					{
						RulerState.SetCurrentStat(eStat_HP, UnitState.GetCurrentStat(eStat_HP));
						RulerState.SetCurrentStat(eStat_ArmorMitigation, max(UnitState.GetCurrentStat(eStat_ArmorMitigation) - UnitState.Shredded, 0));

						if (UnitState.IsDead())
						{
							DefeatedAlienRulers.AddItem(RulerOnCurrentMission);
							ActiveAlienRulers.RemoveItem(RulerOnCurrentMission);
							EscapedAlienRulers.RemoveItem(RulerOnCurrentMission); // Safety check
							RulerIndex = default.AlienRulerTemplates.Find('AlienRulerTemplateName', RulerState.GetMyTemplateName());
							XComHQ.TacticalGameplayTags.AddItem(default.AlienRulerTemplates[RulerIndex].DeadTacticalTag);
							bRulerDefeated = true;
							break;
						}
						else if (class'X2Helpers_DLC_Day60'.static.GetRulerNumAppearances(UnitState) >= `ScaleStrategyArrayInt(default.RulerMaxNumEncounters))
						{
							EscapedAlienRulers.AddItem(RulerOnCurrentMission);
							ActiveAlienRulers.RemoveItem(RulerOnCurrentMission);
							break;
						}
						else
						{
							// If the ruler escaped for the first time, check to see if it was on a specific location
							LocationIndex = AlienRulerLocations.Find('RulerRef', RulerOnCurrentMission);
							if (LocationIndex != INDEX_NONE)
							{
								// Remove the specific location for the ruler so it can start spawning on any mission
								AlienRulerLocations.Remove(LocationIndex, 1);
							}
						}
					}
				}
			}
		}

		if (!bRulerDefeated)
		{
			// If not defeated, then they escaped
			class'X2Helpers_DLC_Day60'.static.IncrementRulerNumEscapes(RulerState);
			class'X2Helpers_DLC_Day60'.static.UpdateRulerEscapeHealth(RulerState);
			bRulerEscaped = true;
		}

		// Reset current mission ruler and mission counter
		ClearActiveRulerTags(XComHQ);
		RulerOnCurrentMission = EmptyRef;
		ForcedRulerOnNextMission = EmptyRef;
		MissionsSinceLastRuler = 0;
	}

	// Increment mission counter here and store appearance roll
	MissionsSinceLastRuler++;
	RulerAppearRoll = `SYNC_RAND_STATIC(100);
}

//---------------------------------------------------------------------------------------
static function PostMissionUpdate(XComGameState NewGameState)
{
	local XComGameStateHistory History;
	local XComGameState_AlienRulerManager RulerMgr;
	local XComGameState_BattleData BattleData;

	History = `XCOMHISTORY;
	RulerMgr = XComGameState_AlienRulerManager(History.GetSingleGameStateObjectForClass(class'XComGameState_AlienRulerManager'));

	BattleData = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
	BattleData = XComGameState_BattleData(NewGameState.ModifyStateObject(class'XComGameState_BattleData', BattleData.ObjectID));
	BattleData.bRulerEscaped = false;
	if (RulerMgr.bRulerEscaped)
	{
		RulerMgr.bRulerEscaped = false; // Reset the flag in the manager
		if (!RulerMgr.bHeardRulerEscapedVO)
		{
			BattleData.bRulerEscaped = true; // Set in Battle Data to trigger VO on after action walkup
			RulerMgr.bHeardRulerEscapedVO = true; // and set the VO as heard
		}
	}

	if (RulerMgr.bRulerDefeated)
	{
		RulerMgr = XComGameState_AlienRulerManager(NewGameState.ModifyStateObject(class'XComGameState_AlienRulerManager', RulerMgr.ObjectID));
		RulerMgr.bRulerDefeated = false;

		class'XComGameState_HeadquartersResistance'.static.RecordResistanceActivity(NewGameState, 'ResAct_AlienRulersKilled');
	}	
}

//---------------------------------------------------------------------------------------
function StateObjectReference GetAlienRulerReference(name TemplateName)
{
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState;
	local StateObjectReference EmptyRef;
	local int idx;

	History = `XCOMHISTORY;
	
	for(idx = 0; idx < AllAlienRulers.Length; idx++)
	{
		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(AllAlienRulers[idx].ObjectID));

		if(UnitState != none && UnitState.GetMyTemplateName() == TemplateName)
		{
			return UnitState.GetReference();
		}
	}

	return EmptyRef;
}

//---------------------------------------------------------------------------------------
function ClearActiveRulerTags(XComGameState_HeadquartersXCom XComHQ)
{
	local int idx, i;

	for(idx = 0; idx < default.AlienRulerTemplates.Length; idx++)
	{
		// Remove the active tag
		XComHQ.TacticalGameplayTags.RemoveItem(default.AlienRulerTemplates[idx].ActiveTacticalTag);

		// Remove any additional tags
		for(i = 0; i < default.AlienRulerTemplates[idx].AdditionalTags.Length; i++)
		{
			XComHQ.TacticalGameplayTags.RemoveItem(default.AlienRulerTemplates[idx].AdditionalTags[i].TacticalTag);
		}
	}
}

//---------------------------------------------------------------------------------------
function UpdateRulerSpawningData(XComGameState NewGameState, XComGameState_MissionSite MissionState)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Unit UnitState;
	local StateObjectReference EmptyRef, ViperKingRef, RulerRef;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));

	// Clear out active ruler tags
	ClearActiveRulerTags(XComHQ);

	// Handle case where this is the nest mission
	if(MissionState.Source == 'MissionSource_AlienNest')
	{
		ViperKingRef = GetAlienRulerReference('ViperKing');
		if (ActiveAlienRulers.Find('ObjectID', ViperKingRef.ObjectID) == INDEX_NONE)
		{
			// Only add the Viper King to the active rulers list if it isn't already included
			ActiveAlienRulers.AddItem(ViperKingRef);
		}
		RulerOnCurrentMission = ViperKingRef;
		return;
	}
	
	// Handle Integrated DLC and Cheat Case where ruler is forced
	ForcedRulerOnNextMission = GetRulerLocatedAtMission(MissionState);
	if(ForcedRulerOnNextMission.ObjectID != 0)
	{
		if(ActiveAlienRulers.Find('ObjectID', ForcedRulerOnNextMission.ObjectID) == INDEX_NONE)
		{
			ActiveAlienRulers.AddItem(ForcedRulerOnNextMission);
		}

		if(ChosenOnMission(MissionState))
		{
			RemoveChosenFromMission(NewGameState, MissionState, XComHQ);
		}

		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(ForcedRulerOnNextMission.ObjectID));
		SetRulerOnCurrentMission(NewGameState, UnitState, XComHQ);
		return;
	}

	// Only add Rulers to missions if the Nest is complete (or optional narrative content is disabled)
	if (AreAlienRulersAllowedToSpawn())
	{
		// Update Active Rulers based on force level
		UpdateActiveAlienRulers();

		// Determine if a Ruler is on the current mission
		if (ActiveAlienRulers.Length != 0 && CanRulerAppearOnMission(MissionState))
		{
			foreach ActiveAlienRulers(RulerRef)
			{
				// Make sure that the ruler is not waiting at a specific location
				if (AlienRulerLocations.Find('RulerRef', RulerRef) == INDEX_NONE)
				{
					// If the ruler is active and not at a specific location, it can appear on normal missions
					UnitState = XComGameState_Unit(History.GetGameStateForObjectID(RulerRef.ObjectID));					
					if (RulerAppearRoll < GetRulerAppearChance(UnitState))
					{
						SetRulerOnCurrentMission(NewGameState, UnitState, XComHQ);
						return;
					}
				}				
			}
		}
	}

	RulerOnCurrentMission = EmptyRef;
}

//---------------------------------------------------------------------------------------
// Check to see if the mission has any chosen tags active
private function bool ChosenOnMission(XComGameState_MissionSite MissionState)
{
	local array<name> TacTags;

	TacTags = MissionState.TacticalGameplayTags;

	if(TacTags.Length == 0)
	{
		return false;
	}

	return (TacTags.Find('Chosen_AssassinActive') != INDEX_NONE || TacTags.Find('Chosen_AssassinActiveM2') != INDEX_NONE ||
			TacTags.Find('Chosen_AssassinActiveM3') != INDEX_NONE || TacTags.Find('Chosen_AssassinActiveM4') != INDEX_NONE ||
			TacTags.Find('Chosen_SniperActive') != INDEX_NONE || TacTags.Find('Chosen_SniperActiveM2') != INDEX_NONE ||
			TacTags.Find('Chosen_SniperActiveM3') != INDEX_NONE || TacTags.Find('Chosen_SniperActiveM4') != INDEX_NONE ||
			TacTags.Find('Chosen_WarlockActive') != INDEX_NONE || TacTags.Find('Chosen_WarlockActiveM2') != INDEX_NONE ||
			TacTags.Find('Chosen_WarlockActiveM3') != INDEX_NONE || TacTags.Find('Chosen_WarlockActiveM4') != INDEX_NONE);
}

//---------------------------------------------------------------------------------------
// If the Ruler is forced on the mission, we need to remove the Chosen
private function RemoveChosenFromMission(XComGameState NewGameState, XComGameState_MissionSite MissionState, XComGameState_HeadquartersXCom XComHQ)
{
	MissionState = XComGameState_MissionSite(NewGameState.ModifyStateObject(class'XComGameState_MissionSite', MissionState.ObjectID));

	MissionState.TacticalGameplayTags.RemoveItem('Chosen_AssassinActive');
	MissionState.TacticalGameplayTags.RemoveItem('Chosen_AssassinActiveM2');
	MissionState.TacticalGameplayTags.RemoveItem('Chosen_AssassinActiveM3');
	MissionState.TacticalGameplayTags.RemoveItem('Chosen_AssassinActiveM4');
	MissionState.TacticalGameplayTags.RemoveItem('Chosen_SniperActive');
	MissionState.TacticalGameplayTags.RemoveItem('Chosen_SniperActiveM2');
	MissionState.TacticalGameplayTags.RemoveItem('Chosen_SniperActiveM3');
	MissionState.TacticalGameplayTags.RemoveItem('Chosen_SniperActiveM4');
	MissionState.TacticalGameplayTags.RemoveItem('Chosen_WarlockActive');
	MissionState.TacticalGameplayTags.RemoveItem('Chosen_WarlockActiveM2');
	MissionState.TacticalGameplayTags.RemoveItem('Chosen_WarlockActiveM3');
	MissionState.TacticalGameplayTags.RemoveItem('Chosen_WarlockActiveM4');

	XComHQ.TacticalGameplayTags.RemoveItem('Chosen_AssassinActive');
	XComHQ.TacticalGameplayTags.RemoveItem('Chosen_AssassinActiveM2');
	XComHQ.TacticalGameplayTags.RemoveItem('Chosen_AssassinActiveM3');
	XComHQ.TacticalGameplayTags.RemoveItem('Chosen_AssassinActiveM4');
	XComHQ.TacticalGameplayTags.RemoveItem('Chosen_SniperActive');
	XComHQ.TacticalGameplayTags.RemoveItem('Chosen_SniperActiveM2');
	XComHQ.TacticalGameplayTags.RemoveItem('Chosen_SniperActiveM3');
	XComHQ.TacticalGameplayTags.RemoveItem('Chosen_SniperActiveM4');
	XComHQ.TacticalGameplayTags.RemoveItem('Chosen_WarlockActive');
	XComHQ.TacticalGameplayTags.RemoveItem('Chosen_WarlockActiveM2');
	XComHQ.TacticalGameplayTags.RemoveItem('Chosen_WarlockActiveM3');
	XComHQ.TacticalGameplayTags.RemoveItem('Chosen_WarlockActiveM4');
}

//---------------------------------------------------------------------------------------
private function bool MissionSitrepsBanRulers(XComGameState_MissionSite MissionState)
{
	local X2SitRepTemplateManager SitRepMgr;
	local X2SitRepTemplate SitRepTemplate;
	local name SitRepTemplateName;
	local array<name> TacTags;

	SitRepMgr = class'X2SitRepTemplateManager'.static.GetSitRepTemplateManager();

	foreach MissionState.GeneratedMission.SitReps(SitRepTemplateName)
	{
		SitRepTemplate = SitRepMgr.FindSitRepTemplate(SitRepTemplateName);
		TacTags = SitRepTemplate.ExcludeGameplayTags;

		if(TacTags.Length == 0)
		{
			continue;
		}

		if(TacTags.Find('Ruler_ViperKingActive') != INDEX_NONE || TacTags.Find('Ruler_ViperKing_02') != INDEX_NONE ||
		   TacTags.Find('Ruler_ViperKing_03') != INDEX_NONE || TacTags.Find('Ruler_ViperKing_04') != INDEX_NONE ||
		   TacTags.Find('Ruler_BerserkerQueenActive') != INDEX_NONE || TacTags.Find('Ruler_BerserkerQueen_02') != INDEX_NONE ||
		   TacTags.Find('Ruler_BerserkerQueen_03') != INDEX_NONE || TacTags.Find('Ruler_BerserkerQueen_04') != INDEX_NONE ||
		   TacTags.Find('Ruler_ArchonKingActive') != INDEX_NONE || TacTags.Find('Ruler_ArchonKing_02') != INDEX_NONE ||
		   TacTags.Find('Ruler_ArchonKing_03') != INDEX_NONE || TacTags.Find('Ruler_ArchonKing_04') != INDEX_NONE)
		{
			return true;
		}
	}

	return false;
}

//---------------------------------------------------------------------------------------
private function bool CanRulerAppearOnMission(XComGameState_MissionSite MissionState)
{
	return (!ChosenOnMission(MissionState) && !MissionSitrepsBanRulers(MissionState));
}

//---------------------------------------------------------------------------------------
// Updates which Rulers are currently active
private function UpdateActiveAlienRulers()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersAlien AlienHQ;
	local XComGameState_Unit UnitState;
	local int idx, RulerIndex, ForceLevel;
	local bool bXpackIntegrated;

	History = `XCOMHISTORY;
	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));
	ForceLevel = AlienHQ.GetForceLevel();
	bXpackIntegrated = class'X2Helpers_DLC_Day60'.static.IsXPackIntegrationEnabled();

	for (idx = 0; idx < AllAlienRulers.Length; idx++)
	{
		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(AllAlienRulers[idx].ObjectID));

		if (UnitState != none)
		{
			RulerIndex = default.AlienRulerTemplates.Find('AlienRulerTemplateName', UnitState.GetMyTemplateName());
			
			// Rulers can only appear naturally if DLC is not integrated with the XPack. Otherwise they appear on Alien Facilities.
			if (!bXpackIntegrated && CanRulerBeActivated(RulerIndex, AllAlienRulers[idx], ForceLevel))
			{
				ActiveAlienRulers.AddItem(AllAlienRulers[idx]);
			}
			else if (EscapedAlienRulers.Find('ObjectID', AllAlienRulers[idx].ObjectID) != INDEX_NONE)
			{
				// Only allow escaped rulers to reappear if ALL of the rulers have escaped or been killed
				if ((DefeatedAlienRulers.Length + EscapedAlienRulers.Length) >= AllAlienRulers.Length)
				{
					EscapedAlienRulers.RemoveItem(AllAlienRulers[idx]);
					ActiveAlienRulers.AddItem(AllAlienRulers[idx]);
				}
			}
		}
	}
}

//---------------------------------------------------------------------------------------
private function bool CanRulerBeActivated(int RulerIndex, StateObjectReference RulerRef, int ForceLevel)
{
	// Only allow new rulers to spawn if they:
	// 1) Are at the appropriate force level
	// 2) Are not already marked as active, escaped, or defeated
	// 3) Does not have a specific location where it is waiting to spawn
	if (RulerIndex != INDEX_NONE && 
		ForceLevel >= default.AlienRulerTemplates[RulerIndex].ForceLevel &&
		ActiveAlienRulers.Find('ObjectID', RulerRef.ObjectID) == INDEX_NONE &&
		EscapedAlienRulers.Find('ObjectID', RulerRef.ObjectID) == INDEX_NONE &&
		DefeatedAlienRulers.Find('ObjectID', RulerRef.ObjectID) == INDEX_NONE &&
		AlienRulerLocations.Find('RulerRef', RulerRef) == INDEX_NONE)
	{
		return true;
	}

	return false;
}

//---------------------------------------------------------------------------------------
private function SetRulerOnCurrentMission(XComGameState NewGameState, XComGameState_Unit UnitState, XComGameState_HeadquartersXCom XComHQ)
{
	local int RulerIndex;
		
	RulerOnCurrentMission = UnitState.GetReference();
	RulerIndex = default.AlienRulerTemplates.Find('AlienRulerTemplateName', UnitState.GetMyTemplateName());
	XComHQ.TacticalGameplayTags.AddItem(default.AlienRulerTemplates[RulerIndex].ActiveTacticalTag);
	AddRulerAdditionalTacticalTags(XComHQ, (class'X2Helpers_DLC_Day60'.static.GetRulerNumAppearances(UnitState) + 1), default.AlienRulerTemplates[RulerIndex]);
}

//---------------------------------------------------------------------------------------
private function bool AreAlienRulersAllowedToSpawn()
{
	local XComGameStateHistory History;
	local XComGameState_CampaignSettings CampaignSettings;

	History = `XCOMHISTORY;
	CampaignSettings = XComGameState_CampaignSettings(History.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings'));

	if (CampaignSettings.HasIntegratedDLCEnabled())
	{
		return true; // Rulers are always available if Integrated XPack DLC is enabled
	}
	else if (!CampaignSettings.HasOptionalNarrativeDLCEnabled(name(class'X2DownloadableContentInfo_DLC_Day60'.default.DLCIdentifier)))
	{
		return true;
	}

	return class'XComGameState_HeadquartersXCom'.static.IsObjectiveCompleted('DLC_AlienNestMissionComplete');
}

//---------------------------------------------------------------------------------------
function UpdateRulerStatsForDifficulty(XComGameState NewGameState)
{
	local X2CharacterTemplateManager CharMgr;
	local X2CharacterTemplate CharTemplate;
	local XComGameState_Unit UnitState;
	local int idx;

	CharMgr = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager();

	for (idx = 0; idx < AllAlienRulers.Length; idx++)
	{
		UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(AllAlienRulers[idx].ObjectID));

		// If the ruler has not yet been encountered by the player, reset their stats using the template from the new difficulty
		if (class'X2Helpers_DLC_Day60'.static.GetRulerNumAppearances(UnitState) == 0)
		{
			UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', UnitState.ObjectID));
			CharTemplate = CharMgr.FindCharacterTemplate(UnitState.GetMyTemplateName());
			UnitState.OnCreation(CharTemplate); // Reset their stat values to match the new difficulty template
		}

		// Update all of the rulers escape health to reflect any health changes
		// Also accounts for Nest edge case where Viper King is listed as having 1 appearance, even though it may not have been encountered yet
		class'X2Helpers_DLC_Day60'.static.UpdateRulerEscapeHealth(UnitState);
	}
}

// #######################################################################################
// ---------------------- XPACK INTEGRATION ----------------------------------------------
// #######################################################################################

//---------------------------------------------------------------------------------------
private function StateObjectReference GetRulerLocatedAtMission(XComGameState_MissionSite MissionState)
{
	local AlienRulerLocation RulerLocation;

	// If DLC is integrated with the XPack, rulers only appear for the first time on specific missions
	if (class'X2Helpers_DLC_Day60'.static.IsXPackIntegrationEnabled())
	{
		// Check to see if the ruler is located at this mission site
		foreach AlienRulerLocations(RulerLocation)
		{
			if (RulerLocation.MissionRef.ObjectID == MissionState.ObjectID)
			{
				return RulerLocation.RulerRef;
			}
		}
	}
}

//---------------------------------------------------------------------------------------
// Activates new rulers which will spawn at specific location. 
// Only called when integrated DLC is on.
function bool ActivateRulerLocations()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersAlien AlienHQ;
	local XComGameState_Unit UnitState;
	local AlienRulerLocation RulerLocation;
	local TDateTime ActivationTime;
	local int idx, RulerIndex, ForceLevel;
	local bool bUpdated;

	History = `XCOMHISTORY;
	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));
	ForceLevel = AlienHQ.GetForceLevel();

	for (idx = 0; idx < AllAlienRulers.Length; idx++)
	{
		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(AllAlienRulers[idx].ObjectID));

		if (UnitState != none)
		{
			RulerIndex = default.AlienRulerTemplates.Find('AlienRulerTemplateName', UnitState.GetMyTemplateName());

			// If a ruler can activate, calculate and set their activation timer
			if (CanRulerBeActivated(RulerIndex, AllAlienRulers[idx], ForceLevel))
			{
				ActivationTime = `STRATEGYRULES.GameTime;
				class'X2StrategyGameRulesetDataStructures'.static.AddHours(ActivationTime, `SYNC_RAND(default.RulerLocationSpawnMaxHours + 1));

				RulerLocation.RulerRef = AllAlienRulers[idx];
				RulerLocation.MissionRef.ObjectID = 0;
				RulerLocation.ActivationTime = ActivationTime;
				RulerLocation.bActivated = false;
				RulerLocation.bNeedsPopup = false;
				AlienRulerLocations.AddItem(RulerLocation);
				bUpdated = true;
			}
		}
	}

	return bUpdated;
}

//---------------------------------------------------------------------------------------
// Check activated ruler timers, and spawn them on alien facilities if they are completed.
// Only called when integrated DLC is on.
function bool UpdateRulerLocations()
{
	local XComGameStateHistory History;
	local XComGameState_MissionSite MissionState;
	local AlienRulerLocation RulerLocation;
	local StateObjectReference BestMissionRef;
	local int idx, MinLinksToResNetwork, NewLinkCount;

	if (AlienRulerLocations.Length > 0)
	{
		History = `XCOMHISTORY;

		foreach AlienRulerLocations(RulerLocation, idx)
		{
			if (!RulerLocation.bActivated && class'X2StrategyGameRulesetDataStructures'.static.LessThan(RulerLocation.ActivationTime, `STRATEGYRULES.GameTime))
			{
				AlienRulerLocations[idx].bActivated = true; // The ruler is now activated, whether or not we find a mission to place it on

				foreach History.IterateByClassType(class'XComGameState_MissionSite', MissionState)
				{
					// Find the Alien Facility mission closest to the player Res Network which does not already have a Ruler
					if (MissionState.Source == 'MissionSource_AlienNetwork' && MissionState.Available && AlienRulerLocations.Find('MissionRef', MissionState.GetReference()) == INDEX_NONE)
					{
						NewLinkCount = MissionState.GetWorldRegion().GetLinkCountToMinResistanceLevel(eResLevel_Contact);
						if (NewLinkCount < MinLinksToResNetwork || BestMissionRef.ObjectID == 0)
						{
							BestMissionRef = MissionState.GetReference(); // Save the mission ref
							MinLinksToResNetwork = NewLinkCount; // and update the link counter to the new min
						}
					}
				}

				if (BestMissionRef.ObjectID != 0)
				{
					AlienRulerLocations[idx].MissionRef = BestMissionRef; // Save the mission ref
					AlienRulerLocations[idx].bNeedsPopup = true; // Activate the popup since we found a mission
				}

				// Don't need to iterate again for other rulers, because if we didn't find an Alien Facility the first time we won't on further iterations
				// Always return true if a ruler activated, even if a mission location was not found, to save state change
				return true;
			}
		}
	}

	return false;
}

//---------------------------------------------------------------------------------------
// Attempt to spawn an activated ruler at a specific mission location
// Only called when integrated DLC is on.
function bool PlaceRulerAtLocation(StateObjectReference MissionRef)
{
	local AlienRulerLocation RulerLocation;
	local int idx;

	if (AlienRulerLocations.Length > 0)
	{
		foreach AlienRulerLocations(RulerLocation, idx)
		{
			if (RulerLocation.bActivated && RulerLocation.MissionRef.ObjectID == 0)
			{
				// There was an activated ruler with no location, so set it at the new one and flag it to trigger a popup
				AlienRulerLocations[idx].MissionRef = MissionRef;
				AlienRulerLocations[idx].bNeedsPopup = true;
				return true;
			}
		}
	}

	return false;
}

//---------------------------------------------------------------------------------------
// Trigger any ruler alerts which have been queued
// Only called when integrated DLC is on.
function DisplayRulerPopup()
{
	local XComGameState NewGameState;
	local XComGameState_AlienRulerManager RulerMgr;
	local AlienRulerLocation RulerLocation;
	local int idx;

	RulerMgr = XComGameState_AlienRulerManager(`XCOMHISTORY.GetGameStateForObjectID(ObjectID));

	if (RulerMgr.AlienRulerLocations.Length > 0)
	{
		foreach RulerMgr.AlienRulerLocations(RulerLocation, idx)
		{
			if (RulerLocation.bNeedsPopup)
			{
				NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Display Ruler Popup");
				RulerMgr = XComGameState_AlienRulerManager(NewGameState.ModifyStateObject(class'XComGameState_AlienRulerManager', ObjectID));
				RulerMgr.AlienRulerLocations[idx].bNeedsPopup = false;
				`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

				class'X2Helpers_DLC_Day60'.static.ShowRulerGuardingFacilityPopup(RulerLocation.MissionRef);
				break; // Only display one popup at a time
			}
		}
	}
	
}

//---------------------------------------------------------------------------------------
DefaultProperties
{
}