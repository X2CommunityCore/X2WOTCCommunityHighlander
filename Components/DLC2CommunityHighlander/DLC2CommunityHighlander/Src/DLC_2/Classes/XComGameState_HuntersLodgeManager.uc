//---------------------------------------------------------------------------------------
//  FILE:    XComGameState_HuntersLodgeManager.uc
//  AUTHOR:  Mike Donovan -- 02/18/2016
//  PURPOSE: This object represents the instance of the Hunter's Lodge manager
//			 in the XCOM 2 strategy game
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class XComGameState_HuntersLodgeManager extends XComGameState_BaseObject config(GameData);

var float TrooperKills, CaptainKills, StunLancerKills, ShieldBearerKills;
var float PsiWitchKills, AdventMEC1Kills, AdventMEC2Kills, AdventTurretKills, SectopodKills;
var float SectoidKills, ArchonKills, ViperKills, MutonKills, BerserkerKills;
var float CyberusKills, GatekeeperKills, ChryssalidKills, AndromedonKills, FacelessKills;

// Alien Hunter weapons and Alien Ruler armors
var bool bShowBoltcasterA, bShowBoltcasterB, bShowBoltcasterC;
var bool bShowPistolA, bShowPistolB, bShowPistolC;
var bool bShowAxeA, bShowAxeB, bShowAxeC;
var bool bShowBerserkerArmor, bShowViperArmor, bShowArchonArmor;

// XPack 
var float PriestKills, PurifierKills, SpectreKills, LostKills;
var bool bShowChosenAssassin, bShowChosenHunter, bShowChosenWarlock;

var bool bDebugVis;

function CalcKillCount(optional XComGameState StartState = none)
{
	local XComGameStateHistory History;
	local XComGameState_Analytics AnalyticsObject;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_CampaignSettings CampaignSettings;
	local XComGameState_AlienRulerManager RulerMgr;
	
	if( bDebugVis )
	{
		DoDebugVis();
		return;
	}

	if( StartState != none )
	{
		foreach StartState.IterateByClassType(class'XComGameState_Analytics', AnalyticsObject)
		{
			break;
		}

		foreach StartState.IterateByClassType(class'XComGameState_HeadquartersXCom', XComHQ)
		{
			break;
		}
	}

	History = `XCOMHISTORY;
	if( AnalyticsObject == none )
	{
		AnalyticsObject = XComGameState_Analytics(History.GetSingleGameStateObjectForClass(class'XComGameState_Analytics', true));
	}

	// Gather kill stats
	TrooperKills = AnalyticsObject.GetFloatValue("ADVENT_TROOPER_MK1_KILLED");
	TrooperKills += AnalyticsObject.GetFloatValue("ADVENT_TROOPER_MK2_KILLED");
	TrooperKills += AnalyticsObject.GetFloatValue("ADVENT_TROOPER_MK3_KILLED");

	CaptainKills = AnalyticsObject.GetFloatValue("ADVENT_CAPTAIN_MK1_KILLED");
	CaptainKills += AnalyticsObject.GetFloatValue("ADVENT_CAPTAIN_MK2_KILLED");
	CaptainKills += AnalyticsObject.GetFloatValue("ADVENT_CAPTAIN_MK3_KILLED");

	StunLancerKills = AnalyticsObject.GetFloatValue("ADVENT_STUN_LANCER_MK1_KILLED");
	StunLancerKills += AnalyticsObject.GetFloatValue("ADVENT_STUN_LANCER_MK2_KILLED");
	StunLancerKills += AnalyticsObject.GetFloatValue("ADVENT_STUN_LANCER_MK3_KILLED");

	ShieldBearerKills = AnalyticsObject.GetFloatValue("ADVENT_SHIELDBEARER_MK1_KILLED");
	ShieldBearerKills += AnalyticsObject.GetFloatValue("ADVENT_SHIELDBEARER_MK2_KILLED");
	ShieldBearerKills += AnalyticsObject.GetFloatValue("ADVENT_SHIELDBEARER_MK3_KILLED");

	PsiWitchKills = AnalyticsObject.GetFloatValue("ADVENT_PSI_WITCH_MK3_KILLED");

	AdventMEC1Kills = AnalyticsObject.GetFloatValue("ADVENT_MEC_MK1_KILLED");
	AdventMEC2Kills = AnalyticsObject.GetFloatValue("ADVENT_MEC_MK2_KILLED");

	AdventTurretKills = AnalyticsObject.GetFloatValue("ADVENT_TURRETS_KILLED");

	SectopodKills = AnalyticsObject.GetFloatValue("SECTOPODS_KILLED");

	SectoidKills = AnalyticsObject.GetFloatValue("SECTOIDS_KILLED");

	ArchonKills = AnalyticsObject.GetFloatValue("ARCHONS_KILLED");

	ViperKills = AnalyticsObject.GetFloatValue("VIPERS_KILLED");

	MutonKills = AnalyticsObject.GetFloatValue("MUTONS_KILLED");

	BerserkerKills = AnalyticsObject.GetFloatValue("MUTON_BERSERKERS_KILLED");

	CyberusKills = AnalyticsObject.GetFloatValue("CYBERUS_KILLED");

	GatekeeperKills = AnalyticsObject.GetFloatValue("GATEKEEPERS_KILLED");

	ChryssalidKills = AnalyticsObject.GetFloatValue("CHRYSSALIDS_KILLED");

	AndromedonKills = AnalyticsObject.GetFloatValue("ANDROMEDON_ROBOT_KILLED");

	FacelessKills = AnalyticsObject.GetFloatValue("FACELESS_KILLED");

	PriestKills = AnalyticsObject.GetFloatValue("ADVENT_PRIEST_MK1_KILLED");
	PriestKills += AnalyticsObject.GetFloatValue("ADVENT_PRIEST_MK2_KILLED");
	PriestKills += AnalyticsObject.GetFloatValue("ADVENT_PRIEST_MK3_KILLED");

	PurifierKills = AnalyticsObject.GetFloatValue("ADVENT_PURIFIER_MK1_KILLED");
	PurifierKills += AnalyticsObject.GetFloatValue("ADVENT_PURIFIER_MK2_KILLED");
	PurifierKills += AnalyticsObject.GetFloatValue("ADVENT_PURIFIER_MK3_KILLED");

	SpectreKills = AnalyticsObject.GetFloatValue("SPECTRE_MK1_KILLED");
	SpectreKills += AnalyticsObject.GetFloatValue("SPECTRE_MK2_KILLED");

	LostKills = AnalyticsObject.GetFloatValue("LOST_EASY_KILLED");
	LostKills += AnalyticsObject.GetFloatValue("LOST_MEDIUM_KILLED");
	LostKills += AnalyticsObject.GetFloatValue("LOST_HARD_KILLED");
	LostKills += AnalyticsObject.GetFloatValue("LOST_DASHER_EASY_KILLED");
	LostKills += AnalyticsObject.GetFloatValue("LOST_DASHER_MEDIUM_KILLED");
	LostKills += AnalyticsObject.GetFloatValue("LOST_DASHER_HARD_KILLED");
	LostKills += AnalyticsObject.GetFloatValue("LOST_HOWLER_EASY_KILLED");
	LostKills += AnalyticsObject.GetFloatValue("LOST_HOWLER_MEDIUM_KILLED");
	LostKills += AnalyticsObject.GetFloatValue("LOST_HOWLER_HARD_KILLED");
	
	if (XComHQ == none)
	{
		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom', true));
	}

	if (XComHQ != none)
	{
		RulerMgr = XComGameState_AlienRulerManager(History.GetSingleGameStateObjectForClass(class'XComGameState_AlienRulerManager'));

		if (RulerMgr.bContentActivated)
		{
			CampaignSettings = XComGameState_CampaignSettings(History.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings'));

			if (CampaignSettings.HasOptionalNarrativeDLCEnabled(name(class'X2DownloadableContentInfo_DLC_Day60'.default.DLCIdentifier)) && 
			class'XComGameState_HeadquartersXCom'.static.IsObjectiveCompleted('DLC_HunterWeapons'))
			{
				bShowBoltcasterA = true;
				bShowPistolA = true;
				bShowAxeA = true;
			}
			else
			{
				bShowBoltcasterA = XComHQ.HasItemByName('HunterRifle_CV_Schematic');
				bShowPistolA = XComHQ.HasItemByName('HunterPistol_CV_Schematic');
				bShowAxeA = XComHQ.HasItemByName('HunterAxe_CV_Schematic');
			}

			bShowBoltcasterB = XComHQ.HasItemByName('HunterRifle_MG_Schematic');
			bShowPistolB = XComHQ.HasItemByName('HunterPistol_MG_Schematic');
			bShowAxeB = XComHQ.HasItemByName('HunterAxe_MG_Schematic');

			bShowBoltcasterC = XComHQ.HasItemByName('HunterRifle_BM_Schematic');
			bShowPistolC = XComHQ.HasItemByName('HunterPistol_BM_Schematic');
			bShowAxeC = XComHQ.HasItemByName('HunterAxe_BM_Schematic');

			bShowBerserkerArmor = XComHQ.IsTechResearched('RAGESuit');
			bShowViperArmor = XComHQ.IsTechResearched('SerpentSuit');
			bShowArchonArmor = XComHQ.IsTechResearched('IcarusArmor');

			bShowChosenAssassin = (XComHQ.HasItemByName('ChosenAssassinShotgun') || XComHQ.HasItemByName('ChosenShotgun_Schematic'));
			bShowChosenHunter = (XComHQ.HasItemByName('ChosenHunterSniperRifle') || XComHQ.HasItemByName('ChosenSniperRifle_Schematic'));
			bShowChosenWarlock = (XComHQ.HasItemByName('ChosenWarlockRifle') || XComHQ.HasItemByName('ChosenRifle_Schematic'));
		}
	}
}

function DoDebugVis()
{
	TrooperKills = 30 + Rand(10);
	CaptainKills = 10 + Rand(20);
	StunLancerKills = 10 + Rand(20);
	ShieldBearerKills = 10 + Rand(10);
	PsiWitchKills = 2;
	AdventMEC1Kills = 15 + Rand(10);
	AdventMEC2Kills = 10 + Rand(10);
	AdventTurretKills = 5 + Rand(10);
	SectopodKills = 1 + Rand(5);
	SectoidKills = 15 + Rand(15);
	ArchonKills = 10 + Rand(10);
	ViperKills = 10 + Rand(20);
	MutonKills = 5 + Rand(15);
	BerserkerKills = 5 + Rand(10);
	CyberusKills = 10 + Rand(20);
	GatekeeperKills = 1 + Rand(5);
	ChryssalidKills = 5 + Rand(10);
	AndromedonKills = 10 + Rand(10);
	FacelessKills = 5 + Rand(15);

	bShowBoltcasterA = true;
	bShowPistolA = true;
	bShowAxeA = true;

	bShowBoltcasterB = true;
	bShowPistolB = true;
	bShowAxeB = true;

	bShowBoltcasterC = true;
	bShowPistolC = true;
	bShowAxeC = true;

	bShowBerserkerArmor = true;
	bShowViperArmor = true;
	bShowArchonArmor = true;

	PriestKills = 10 + Rand(10);
	PurifierKills = 10 + Rand(10);
	SpectreKills = 5 + Rand(10);
	LostKills = 50 + Rand(100);

	bShowChosenAssassin = true;
	bShowChosenHunter = true;
	bShowChosenWarlock = true;
}