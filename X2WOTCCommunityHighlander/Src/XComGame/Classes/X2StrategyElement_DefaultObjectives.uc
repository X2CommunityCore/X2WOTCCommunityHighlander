//---------------------------------------------------------------------------------------
//  FILE:    X2StrategyElement_DefaultObjectives.uc
//  AUTHOR:  Mark Nauta
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2StrategyElement_DefaultObjectives extends X2StrategyElement
	dependson(XComGameState_ObjectivesList) config(GameData);

var const config array<int> KillCodexMinDoom;
var const config array<int> KillCodexMaxDoom;
var const config array<int> KillAvatarMinDoom;
var const config array<int> KillAvatarMaxDoom;

var const config array<int> BlacksiteSupplyAmount;
var const config array<int> PsiGateForgeSupplyAmount; // base supply amount
var const config array<int> PsiGateForgeSupplyAdd; // add this amount to the one that appears second

var const config Vector2D FortressLocation;

var localized string KilledCodexLabel;
var localized string KilledAvatarLabel;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Objectives;

	// naming convention:
	// T = mission track (1 = stasis lance + hacking enemies; 2 = Blacksite, etc.; 3 = everything else)
	// M = mission number within the track
	// S = sub-objective number within the mission
	// N = Pure narrative Objective
	// L = objective to cause looking at something specific on geoscape (GP missions)

	/////////////// NARRATIVE //////////////////
	Objectives.AddItem(CreateN_GameStartTemplate());
	Objectives.AddItem(CreateN_AlwaysPlayVOTemplate());
	Objectives.AddItem(CreateN_BeginnerVOTemplate());
	Objectives.AddItem(CreateN_BeginnerVONonTutorialTemplate());
	Objectives.AddItem(CreateN_GPCinematicsTemplate());
	Objectives.AddItem(CreateN_AvatarTemplate());
	Objectives.AddItem(CreateN_FacilityWalkthroughsTemplate());
	Objectives.AddItem(CreateN_AvengerFlightTemplate());
	Objectives.AddItem(CreateN_AutopsyCompleteTemplate());
	Objectives.AddItem(CreateN_TyganGreetingsTemplate());
	Objectives.AddItem(CreateN_ChooseFirstResearchTemplate());
	Objectives.AddItem(CreateN_ChooseResearchTemplate());
	Objectives.AddItem(CreateN_SwitchFirstResearchTemplate());
	Objectives.AddItem(CreateN_SwitchResearchTemplate());
	Objectives.AddItem(CreateN_FirstResearchInProgressTemplate());
	Objectives.AddItem(CreateN_ResearchInProgressTemplate());
	Objectives.AddItem(CreateN_ShenGreetingsTemplate());
	Objectives.AddItem(CreateN_ChooseFirstProvingGroundProjectTemplate());
	Objectives.AddItem(CreateN_ChooseProvingGroundProjectTemplate());
	Objectives.AddItem(CreateN_FirstAlienFacilityTemplate());
	Objectives.AddItem(CreateN_AlienFacilityConstructedTemplate());
	Objectives.AddItem(CreateN_MakingContactAvailable());
	Objectives.AddItem(CreateN_RadioRelaysAvailable());
	Objectives.AddItem(CreateN_AfterActionCommentTemplate());
	Objectives.AddItem(CreateN_AfterActionCommentCouncilTemplate());
	Objectives.AddItem(CreateN_MonthlyReportCommentTemplate());
	Objectives.AddItem(CreateN_UFOAppearedTemplate());
	Objectives.AddItem(CreateN_ContactOrOutpostTemplate());
	Objectives.AddItem(CreateN_FacilityThanksTemplate());
	Objectives.AddItem(CreateN_ToDoWarningsTemplate());
	Objectives.AddItem(CreateN_EquipSkulljackTemplate());
	Objectives.AddItem(CreateN_InDropPositionTemplate());
	Objectives.AddItem(CreateN_DoomReducedTemplate());
	Objectives.AddItem(CreateN_CentralObjectiveAddedTemplate());

	////////////// TUTORIAL ////////////////////
	// T0

	Objectives.AddItem(CreateT0_M0_TutorialFirstMissionTemplate());
	Objectives.AddItem(CreateT0_M1_WelcomeToLabsTemplate());
	Objectives.AddItem(CreateT0_M2_WelcomeToArmoryTemplate());
	Objectives.AddItem(CreateT0_M3_WelcomeToHQTemplate());
	Objectives.AddItem(CreateT0_M4_ReturnToAvengerTemplate());
	Objectives.AddItem(CreateT0_M5_WelcomeToEngineeringTemplate());
	Objectives.AddItem(CreateT0_M5_EquipMedikitTemplate());
	Objectives.AddItem(CreateT0_M6_WelcomeToLabsPt2Template());
	Objectives.AddItem(CreateT0_M7_WelcomeToGeoscapeTemplate());
	Objectives.AddItem(CreateT0_M8_ReturnToAvengerPt2Template());
	Objectives.AddItem(CreateT0_M9_ExcavateRoomTemplate());
	Objectives.AddItem(CreateT0_M10_IntroToBlacksiteTemplate());
	Objectives.AddItem(CreateT0_M10_S1_WaitForResCommsTemplate());
	Objectives.AddItem(CreateT0_M10_L0_FirstTimeScanTemplate());
	Objectives.AddItem(CreateT0_M11_IntroToResCommsTemplate());
	Objectives.AddItem(CreateT0_M11_S1_WaitForRadioRelaysTemplate());
	Objectives.AddItem(CreateT0_M12_IntroToRadioRelaysTemplate());

	////////////// GAME START //////////////////
	// T1

	Objectives.AddItem(CreateT1_M0_FirstMissionTemplate());

	Objectives.AddItem(CreateT1_M1_AlienBiotechTemplate());
	Objectives.AddItem(CreateT1_M1_AutopsyACaptainTemplate());
	Objectives.AddItem(CreateT1_M1_AlienBiotechTutorialTemplate());
	Objectives.AddItem(CreateT1_M1_AutopsyACaptainTutorialTemplate());

	Objectives.AddItem(CreateT1_M2_HackACaptainTemplate());
	Objectives.AddItem(CreateT1_M2_S1_BuildProvingGroundsTemplate());
	Objectives.AddItem(CreateT1_M2_S2_BuildSKULLJACKTemplate());
	Objectives.AddItem(CreateT1_M2_S3_SKULLJACKCaptainTemplate());

	Objectives.AddItem(CreateT1_M3_KillCodexTemplate());
	Objectives.AddItem(CreateT1_M3_S0_RecoverCodexBrainTemplate());

	/////////////// OR /////////////////
	// T2

	Objectives.AddItem(CreateT2_M0_CompleteGuerillaOpsTemplate());
	Objectives.AddItem(CreateT2_M0_L0_BlacksiteRevealTemplate());

	Objectives.AddItem(CreateT2_M1_ContactBlacksiteRegionTemplate());
	Objectives.AddItem(CreateT2_M1_L0_LookAtBlacksiteTemplate());
	Objectives.AddItem(CreateT2_M1_L1_RevealBlacksiteObjectiveTemplate());
	Objectives.AddItem(CreateT2_M1_L2_WaitForBlacksiteContactTemplate());
	Objectives.AddItem(CreateT2_M1_S1_ResearchResistanceCommsTemplate());
	Objectives.AddItem(CreateT2_M1_S2_MakeContactWithBlacksiteRegionTemplate());

	Objectives.AddItem(CreateT2_M1_CompleteBlacksiteMissionTemplate());

	/////////////// THEN /////////////////
	// T3

	Objectives.AddItem(CreateT3_M1_ResearchAlienEncryptionTemplate());

	Objectives.AddItem(CreateT3_M2_BuildShadowChamberTemplate());

	/////////////// CONTINUE /////////////////
	// T1 Continued

	Objectives.AddItem(CreateT1_M4_StudyCodexBrainTemplate());
	Objectives.AddItem(CreateT1_M4_S1_StudyCodexBrainPt1Template());
	Objectives.AddItem(CreateT1_M4_S2_StudyCodexBrainPt2Template());

	Objectives.AddItem(CreateT1_M5_SKULLJACKCodexTemplate());

	Objectives.AddItem(CreateT1_M6_KillAvatarTemplate());
	Objectives.AddItem(CreateT1_M6_S0_RecoverAvatarCorpseTemplate());

	/////////////// AND /////////////////
	// T2 Continued

	Objectives.AddItem(CreateT2_M2_StudyBlacksiteDataTemplate());

	Objectives.AddItem(CreateT2_M3_CompleteForgeMissionTemplate());
	Objectives.AddItem(CreateT2_M3_L0_LookAtForgeTemplate());
	Objectives.AddItem(CreateT2_M3_L1_MakeContactWithForgeRegionTemplate());
	Objectives.AddItem(CreateT2_M3_L2_WaitForForgeContactTemplate());

	Objectives.AddItem(CreateT2_M4_BuildStasisSuitTemplate());

	/////////////// AND /////////////////
	// T4

	Objectives.AddItem(CreateT4_M1_CompleteStargateMissionTemplate());
	Objectives.AddItem(CreateT4_M1_L0_LookAtStargateTemplate());
	Objectives.AddItem(CreateT4_M1_L1_MakeContactWithStargateRegionTemplate());
	Objectives.AddItem(CreateT4_M1_L2_WaitForStargateContactTemplate());

	Objectives.AddItem(CreateT4_M2_ConstructPsiGateTemplate());
	Objectives.AddItem(CreateT4_M2_S2_ResearchPsiGateTemplate());
	Objectives.AddItem(CreateT4_M2_S1_UpgradeShadowChamber());

	////////////// FINAL MISSION //////////////////
	// T5

	Objectives.AddItem(CreateT5_M1_AutopsyTheAvatarTemplate());

	Objectives.AddItem(CreateT5_M2_CompleteBroadcastTheTruthMissionTemplate());
	Objectives.AddItem(CreateT5_M2_L0_LookAtBroadcastTemplate());

	Objectives.AddItem(CreateT5_M3_CompleteFinalMissionTemplate());

	////////////// SPECIAL OBJECTIVES //////////////////

	Objectives.AddItem(CreateS0_RevealAvatarProjectTemplate());
	Objectives.AddItem(CreateS1_ShortenFirstPOITemplate());

	/////////////////////////////////////////////////

	return Objectives;
}


// #######################################################################################
// -------------------- NARRATIVE OBJECTIVES ---------------------------------------------
// #######################################################################################

static function X2DataTemplate CreateN_GameStartTemplate()
{
	local X2ObjectiveTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ObjectiveTemplate', Template, 'N_GameStart');
	Template.bMainObjective = true;
	Template.bNeverShowObjective = true;
	
	// Additional narrative objectives that should begin every time the game starts
	Template.NextObjectives.AddItem('N_AlwaysPlayVO');
	Template.NextObjectives.AddItem('N_GPCinematics');
	Template.NextObjectives.AddItem('N_Avatar');
	Template.NextObjectives.AddItem('N_FacilityWalkthroughs');
	Template.NextObjectives.AddItem('N_AvengerFlight');
	Template.NextObjectives.AddItem('N_AutopsyComplete');
	Template.NextObjectives.AddItem('N_TyganGreetings');
	Template.NextObjectives.AddItem('N_SwitchFirstResearch');
	Template.NextObjectives.AddItem('N_SwitchResearch');
	Template.NextObjectives.AddItem('N_FirstResearchInProgress');
	Template.NextObjectives.AddItem('N_ShenGreetings');
	Template.NextObjectives.AddItem('N_ChooseFirstProvingGroundProject');
	Template.NextObjectives.AddItem('N_FirstAlienFacility');
	Template.NextObjectives.AddItem('N_MonthlyReportComment');
	Template.NextObjectives.AddItem('N_UFOAppeared');
	Template.NextObjectives.AddItem('N_ContactOrOutpostContacted');
	Template.NextObjectives.AddItem('N_FacilityThanks');
	Template.NextObjectives.AddItem('N_ToDoWarnings');
	Template.NextObjectives.AddItem('N_EquipSkulljack');
	Template.NextObjectives.AddItem('N_DoomReduced');

	Template.CompletionEvent = 'PreMissionDone';

	return Template;
}

static function X2DataTemplate CreateN_AlwaysPlayVOTemplate()
{
	local X2ObjectiveTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ObjectiveTemplate', Template, 'N_AlwaysPlayVO');
	Template.bMainObjective = true;
	Template.bNeverShowObjective = true;

	///////////////////////////////////////////////////////////////////////////////////////////////
	// VO which will play in every game, even in tutorial or when beginner VO is turned off		 //
	///////////////////////////////////////////////////////////////////////////////////////////////

	// Play Once
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Central_Support_Established_Contact_Mission_Forge", NAW_OnAssignment, 'PlayForgeAlreadyContacted', '', ELD_OnStateSubmitted, NPC_Once, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Central_Support_Established_Contact_Mission_PsiGate", NAW_OnAssignment, 'PlayPsiGateAlreadyContacted', '', ELD_OnStateSubmitted, NPC_Once, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.S_Support_Final_Avatar_Countdown_Central", NAW_OnAssignment, 'OnFinalCountdown', '', ELD_OnStateSubmitted, NPC_Once, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Shens_Support_VO_Shadow_Chamber_UI_First", NAW_OnAssignment, 'OnShadowChamberMissionUI', '', ELD_OnStateSubmitted, NPC_Once, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Central_Support_Advent_Progress_Warning", NAW_OnAssignment, 'OnAlienFacilityPopupBad', '', ELD_OnStateSubmitted, NPC_Once, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Central_Support_Reminder_Alien_Facilities_Constructed", NAW_OnAssignment, 'OnAlienFacilityPopupReallyBad', '', ELD_OnStateSubmitted, NPC_Once, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Central_Support_Reminder_Need_More_Intel", NAW_OnAssignment, 'MakingContactNoIntel', '', ELD_OnStateSubmitted, NPC_Once, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Central_PreFinalMission_MissionUI_Geoscape", NAW_OnAssignment, 'OnViewFinalMission', '', ELD_OnStateSubmitted, NPC_Once, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.S_GP_Avatar_Reveal_Comm_Feeder_Central", NAW_OnAssignment, 'OnFortressRevealAlert', '', ELD_OnStateSubmitted, NPC_Once, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Shen_Support_Urge_Facility", NAW_OnAssignment, 'OnFacilityNag', '', ELD_OnStateSubmitted, NPC_Once, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.S_GP_Alien_Facility_Selected_Council", NAW_OnAssignment, 'OnViewAvatarProject', '', ELD_OnStateSubmitted, NPC_Once, '');

	// Doom Added Lines
	Template.AddNarrativeTrigger("X2NarrativeMoments.S_Setup_Phase_Facility_Adds_Doom_Central", NAW_OnAssignment, 'OnFacilityAddsDoom', '', ELD_OnStateSubmitted, NPC_Multiple, 'FacilityAddsDoomLines');
	Template.AddNarrativeTrigger("X2NarrativeMoments.S_GP_Doom_Rising_Central", NAW_OnAssignment, 'OnFacilityAddsDoom', '', ELD_OnStateSubmitted, NPC_Multiple, 'FacilityAddsDoomLines');
	Template.AddNarrativeTrigger("X2NarrativeMoments.S_The_Aliens_Continue_Council", NAW_OnAssignment, 'OnFortressAddsDoom', '', ELD_OnStateSubmitted, NPC_Multiple, 'FortressAddsDoomLines');
	Template.AddNarrativeTrigger("X2NarrativeMoments.S_Setup_Phase_Fortress_Adds_Doom_Central", NAW_OnAssignment, 'OnFortressAddsDoom', '', ELD_OnStateSubmitted, NPC_Multiple, 'FortressAddsDoomLines');
	Template.AddNarrativeTrigger("X2NarrativeMoments.S_Setup_Phase_Fortress_Adds_Doom_Central", NAW_OnAssignment, 'OnFortressAddsDoomEndgame', '', ELD_OnStateSubmitted, NPC_Multiple, '');

	// Repeat Plays
	//Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Avenger_Objective_Added", NAW_OnAssignment, 'NarrativeUIOpened', '', ELD_OnStateSubmitted, NPC_Multiple, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.AvengerAI_Support_Establishing_Contact", NAW_OnAssignment, 'StartScanForContact', '', ELD_OnStateSubmitted, NPC_Multiple, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Resistance_Resistance_Outpost_Black_Market", NAW_OnAssignment, 'OnBlackMarketOpen', '', ELD_OnStateSubmitted, NPC_Multiple, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Resistance_Resistance_Outpost_Resistance_Market", NAW_OnAssignment, 'OnResHQGoodsOpen', '', ELD_OnStateSubmitted, NPC_Multiple, '');

	// Monthly Report Alert Lines
	Template.AddNarrativeTrigger("X2NarrativeMoments.Central_Wild_Central_01", NAW_OnAssignment, 'OnMonthlyReportAlert', '', ELD_OnStateSubmitted, NPC_Multiple, 'MonthlyReportAlertLines');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Central_Wild_Central_02", NAW_OnAssignment, 'OnMonthlyReportAlert', '', ELD_OnStateSubmitted, NPC_Multiple, 'MonthlyReportAlertLines');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Central_Wild_Central_03", NAW_OnAssignment, 'OnMonthlyReportAlert', '', ELD_OnStateSubmitted, NPC_Multiple, 'MonthlyReportAlertLines');

	// UFO Lines
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Central_Support_UFO_Inbound_Evasive_Maneuvers", NAW_OnAssignment, 'OnUFOEvasive', '', ELD_OnStateSubmitted, NPC_Once, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Central_Support_UFO_Inbound_UFO_Evaded", NAW_OnAssignment, 'OnUFOEvaded', '', ELD_OnStateSubmitted, NPC_Once, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Central_Support_UFO_Inbound_Shot_Down", NAW_OnAssignment, 'OnUFOAttack', '', ELD_OnStateSubmitted, NPC_Once, '');

	// Wounded Soldiers Allowed Lines
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.S_Support_Squad_Select_Wounded_Soldiers_Central", NAW_OnAssignment, 'OnWoundedSoldiersAllowed', '', ELD_OnStateSubmitted, NPC_Multiple, 'WoundedSoldiersAllowedLines');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Central_Wounded_Soldiers_Can_Go", NAW_OnAssignment, 'OnWoundedSoldiersAllowed', '', ELD_OnStateSubmitted, NPC_Multiple, 'WoundedSoldiersAllowedLines');

	return Template;
}

static function X2DataTemplate CreateN_BeginnerVOTemplate()
{
	local X2ObjectiveTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ObjectiveTemplate', Template, 'N_BeginnerVO');
	Template.bMainObjective = true;
	Template.bNeverShowObjective = true;
	
	///////////////////////////////////////////////////////////////////////////////////////////////
	// This objective should hold ALL Beginner VO EXCEPT things that would play in the tutorial  //
	// They will play in both Tutorial and Non-Tutorial modes        							 //
	// BUT THESE WILL NOT PLAY IF BEGINNER VO IS TURNED OFF									     //
	///////////////////////////////////////////////////////////////////////////////////////////////

	// First Facility Entry
	Template.AddNarrativeTrigger("X2NarrativeMoments.Central_Setup_Phase_First_Memorial", NAW_OnAssignment, 'OnEnteredFacility_BarMemorial', '', ELD_OnStateSubmitted, NPC_Once, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Central_Setup_Phase_First_Living_Quarters", NAW_OnAssignment, 'OnEnteredFacility_LivingQuarters', '', ELD_OnStateSubmitted, NPC_Once, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Shens_Support_VO_Proving_Ground_Visit", NAW_OnAssignment, 'OnEnteredFacility_ProvingGround', '', ELD_OnStateSubmitted, NPC_Once, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Shen_Support_Thanks_Workshop", NAW_OnAssignment, 'OnEnteredFacility_Workshop', '', ELD_OnStateSubmitted, NPC_Once, '');
	
	// Game Firsts
	Template.AddNarrativeTrigger("X2NarrativeMoments.Central_Setup_Phase_Geoscape_First_Make_Contact", NAW_OnAssignment, 'MakingContact', '', ELD_OnStateSubmitted, NPC_Once, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Central_Setup_Phase_Geoscape_Player_Leaves_Without_Scanning", NAW_OnAssignment, 'LeaveContactWithoutScan', '', ELD_OnStateSubmitted, NPC_Once, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Central_Setup_Phase_Geoscape_Scan_Attempt_With_Timed_Mission", NAW_OnAssignment, 'TimeSensitiveMission', '', ELD_OnStateSubmitted, NPC_Once, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Exposed_Power_Coil_First", NAW_OnAssignment, 'OnEnteredRoom_SpecialRoomFeature_PowerCoil', '', ELD_OnStateSubmitted, NPC_Once, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Shen_Support_First_Time_Construction", NAW_OnAssignment, 'OnEnteredBuildFacilities', '', ELD_OnStateSubmitted, NPC_Once, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Shen_Support_First_Facility_Contruction", NAW_OnAssignment, 'ConstructionStarted', '', ELD_OnStateSubmitted, NPC_Once, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Tygan_Support_First_PCS_Interface", NAW_OnAssignment, 'OnViewPCS', '', ELD_OnStateSubmitted, NPC_Once, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Central_Support_First_Doom", NAW_OnAssignment, 'OnDoomPopup', '', ELD_OnStateSubmitted, NPC_Once, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Central_Support_First_Dark_Events", NAW_OnAssignment, 'OnViewDarkEvents', '', ELD_OnStateSubmitted, NPC_Once, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Council_Support_First_Resistance_Goods", NAW_OnAssignment, 'OnHelpResHQ', '', ELD_OnStateSubmitted, NPC_Once, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Central_Support_Avenger_Lands_First_Contact", NAW_OnAssignment, 'AvengerLandedScanRegion', '', ELD_OnStateSubmitted, NPC_Once, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Central_Support_Multiple_Mission_Sites_Available", NAW_OnAssignment, 'OnMultiMissionGOps', '', ELD_OnStateSubmitted, NPC_Once, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Tygan_First_Scientist_Received", NAW_OnAssignment, 'StaffAdded', 'Scientist', ELD_OnStateSubmitted, NPC_Once, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Central_Missing_Supply_Cache", NAW_OnAssignment, 'SupplyDropAppeared', '', ELD_OnStateSubmitted, NPC_Once, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Shen_Support_Excavate_Room_No_Engineer", NAW_OnAssignment, 'NoExcavateEngineers', '', ELD_OnStateSubmitted, NPC_Once, '');
	
	// Skipped or Failed Mission
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Central_Skipped_or_Failed_Mission", NAW_OnAssignment, 'SkippedMissionLostContact', '', ELD_OnStateSubmitted, NPC_Multiple, 'SkippedMissionNarrative');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Council_Skipped_or_Failed_Mission", NAW_OnAssignment, 'SkippedMissionLostContact', '', ELD_OnStateSubmitted, NPC_Multiple, 'SkippedMissionNarrative');

	// Mission Alerts
	Template.AddNarrativeTrigger("X2NarrativeMoments.Central_First_Supply_Raid_Geoscape", NAW_OnAssignment, 'OnSupplyRaidPopup', '', ELD_OnStateSubmitted, NPC_Once, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Central_First_Retaliation_Geoscape", NAW_OnAssignment, 'OnRetaliationPopup', '', ELD_OnStateSubmitted, NPC_Once, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Council_First_Council_Mission_Geoscape", NAW_OnAssignment, 'OnCouncilPopup', '', ELD_OnStateSubmitted, NPC_Once, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Central_First_LandedUFO_Geoscape", NAW_OnAssignment, 'OnLandedUFOPopup', '', ELD_OnStateSubmitted, NPC_Once, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Central_First_Sabotage_Geoscape", NAW_OnAssignment, 'OnViewUnlockedAlienFacility', '', ELD_OnStateSubmitted, NPC_Once, '');
	
	return Template;
}

static function X2DataTemplate CreateN_BeginnerVONonTutorialTemplate()
{
	local X2ObjectiveTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ObjectiveTemplate', Template, 'N_BeginnerVONonTutorial');
	Template.bMainObjective = true;
	Template.bNeverShowObjective = true;

	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// This objective should hold all Beginner VO for things that have unique NMs for the tutorial and need their own versions for the setup phase //
	// These are the setup phase version. Tutorial versions are handled in their objective path.												   //
	//																																			   //
	// THESE WILL NOT PLAY IF BEGINNER VO IS TURNED OFF																							   //
	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	Template.AddNarrativeTrigger("X2NarrativeMoments.Central_Setup_Phase_First_Rumor", NAW_OnAssignment, 'RumorAppeared', '', ELD_OnStateSubmitted, NPC_Once, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Shen_Support_First_Engineer_Received", NAW_OnAssignment, 'StaffAdded', 'Engineer', ELD_OnStateSubmitted, NPC_Once, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Shen_Support_First_Excavating_Room", NAW_OnAssignment, 'ExcavationPossible', '', ELD_OnStateSubmitted, NPC_Once, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Central_Support_First_Guerilla_Operation", NAW_OnAssignment, 'OnGOpsPopup', '', ELD_OnStateSubmitted, NPC_Once, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Central_Support_Begin_Scanning_Activity", NAW_OnAssignment, 'AvengerLandedScanPOI', '', ELD_OnStateSubmitted, NPC_Once, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Shen_Setup_Phase_First_Build_Item_Screen", NAW_OnAssignment, 'OpenBuildItems', '', ELD_OnStateSubmitted, NPC_Once, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Shen_Setup_Phase_Excavation_Underway", NAW_OnAssignment, 'ExcavationStarted', '', ELD_OnStateSubmitted, NPC_Once, '');

	return Template;
}

static function X2DataTemplate CreateN_GPCinematicsTemplate()
{
	local X2ObjectiveTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ObjectiveTemplate', Template, 'N_GPCinematics');
	Template.bMainObjective = true;
	Template.bNeverShowObjective = true;

	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.GP_Retaliation", NAW_OnAssignment, 'RetaliationMissionSpawned', '', ELD_OnStateSubmitted, NPC_Once, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.GP_BuildOutpost", NAW_OnAssignment, 'RegionBuiltOutpost', '', ELD_OnStateSubmitted, NPC_Once, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.GP_AvengerAttacked", NAW_OnAssignment, 'AvengerAttacked', '', ELD_OnStateSubmitted, NPC_Once, '');
	// Victory cinematic triggered by mission now
	//Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.GP_Victory", NAW_OnAssignment, 'XComVictory', '', ELD_OnStateSubmitted, NPC_Once, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.GP_Loss", NAW_OnAssignment, 'XComLoss', '', ELD_OnStateSubmitted, NPC_Once, '', UILose);

	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.GP_FirstContact_Arid_Day", NAW_OnAssignment, 'RegionContacted_Arid_Day', '', ELD_OnStateSubmitted, NPC_Multiple, '', CinematicComplete);
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.GP_FirstContact_Arid_Night", NAW_OnAssignment, 'RegionContacted_Arid_Night', '', ELD_OnStateSubmitted, NPC_Multiple, '', CinematicComplete);
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.GP_FirstContact_Arid_Sunset", NAW_OnAssignment, 'RegionContacted_Arid_Sunset', '', ELD_OnStateSubmitted, NPC_Multiple, '', CinematicComplete);
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.GP_FirstContact_Tundra_Day", NAW_OnAssignment, 'RegionContacted_Tundra_Day', '', ELD_OnStateSubmitted, NPC_Multiple, '', CinematicComplete);
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.GP_FirstContact_Tundra_Night", NAW_OnAssignment, 'RegionContacted_Tundra_Night', '', ELD_OnStateSubmitted, NPC_Multiple, '', CinematicComplete);
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.GP_FirstContact_Tundra_Sunset", NAW_OnAssignment, 'RegionContacted_Tundra_Sunset', '', ELD_OnStateSubmitted, NPC_Multiple, '', CinematicComplete);
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.GP_FirstContact_Wild_Day", NAW_OnAssignment, 'RegionContacted_Temperate_Day', '', ELD_OnStateSubmitted, NPC_Multiple, '', CinematicComplete);
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.GP_FirstContact_Wild_Night", NAW_OnAssignment, 'RegionContacted_Temperate_Night', '', ELD_OnStateSubmitted, NPC_Multiple, '', CinematicComplete);
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.GP_FirstContact_Wild_Sunset", NAW_OnAssignment, 'RegionContacted_Temperate_Sunset', '', ELD_OnStateSubmitted, NPC_Multiple, '', CinematicComplete);
	
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.WeaponIntro_Magnetic", NAW_OnAssignment, 'OnResearchReport', 'MagnetizedWeapons', ELD_OnStateSubmitted, NPC_Once, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.WeaponIntro_Beam", NAW_OnAssignment, 'OnResearchReport', 'PlasmaRifle', ELD_OnStateSubmitted, NPC_Once, '');

	return Template;
}

function UILose()
{
	`HQPRES.UIYouLose();
}

static function X2DataTemplate CreateN_AvatarTemplate()
{
	local X2ObjectiveTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ObjectiveTemplate', Template, 'N_Avatar');
	Template.bMainObjective = true;
	Template.bNeverShowObjective = true;

	Template.CompletionEvent = 'FinalMissionSquadSelected';

	Template.AddNarrativeTrigger("X2NarrativeMoments.T_Avatar_First_Action_Tygan", NAW_OnReveal, 'AvatarFirstAction', '', ELD_OnStateSubmitted, NPC_Once, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.T_Avatar_Teleport_Central", NAW_OnReveal, 'AbilityActivated', 'TriggerDamagedTeleport', ELD_OnStateSubmitted, NPC_Once, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.T_Avatar_Regenerates_Tygan", NAW_OnReveal, 'AvatarInitializationHeal', '', ELD_OnStateSubmitted, NPC_Once, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.T_Avatar_Mind_Control_Central", NAW_OnReveal, 'AbilityActivated', class'X2Ability_PsiWitch'.Default.MindControlAbilityName, ELD_OnStateSubmitted, NPC_Once, '');

	return Template;
}

static function X2DataTemplate CreateN_FacilityWalkthroughsTemplate()
{
	local X2ObjectiveTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ObjectiveTemplate', Template, 'N_FacilityWalkthroughs');
	Template.bMainObjective = true;
	Template.bNeverShowObjective = true;

	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.AdvancedWarfareCenterBuilt", NAW_OnAssignment, 'OnEnteredFacility_AdvancedWarfareCenter', '', ELD_OnStateSubmitted, NPC_Once, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.DefenseFacilityBuilt", NAW_OnAssignment, 'OnEnteredFacility_UFODefense', '', ELD_OnStateSubmitted, NPC_Once, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.GuerrillaTacticsSchoolBuilt", NAW_OnAssignment, 'OnEnteredFacility_OfficerTrainingSchool', '', ELD_OnStateSubmitted, NPC_Once, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.LaboratoryBuilt", NAW_OnAssignment, 'OnEnteredFacility_Laboratory', '', ELD_OnStateSubmitted, NPC_Once, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.PowerRelayBuilt", NAW_OnAssignment, 'OnEnteredFacility_PowerRelay', '', ELD_OnStateSubmitted, NPC_Once, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.ProvingGroundsBuilt", NAW_OnAssignment, 'OnEnteredFacility_ProvingGround', '', ELD_OnStateSubmitted, NPC_Once, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.PsiChamberBuilt", NAW_OnAssignment, 'OnEnteredFacility_PsiChamber', '', ELD_OnStateSubmitted, NPC_Once, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.ResistanceCommsBuilt", NAW_OnAssignment, 'OnEnteredFacility_ResistanceComms', '', ELD_OnStateSubmitted, NPC_Once, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.WorkshopBuilt", NAW_OnAssignment, 'OnEnteredFacility_Workshop', '', ELD_OnStateSubmitted, NPC_Once, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.GP_ShadowChamberBuilt", NAW_OnAssignment, 'OnEnteredFacility_ShadowChamber', '', ELD_OnStateSubmitted, NPC_Once, '', CinematicComplete);

	return Template;
}

static function X2DataTemplate CreateN_AvengerFlightTemplate()
{
	local X2ObjectiveTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ObjectiveTemplate', Template, 'N_AvengerFlight');
	Template.bMainObjective = true;
	Template.bNeverShowObjective = true;

	// Arctic (North Asia)
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.ShipAI_Setting_Course_Region_01", NAW_OnAssignment, 'OnAvengerTakeOff', 'WorldRegion_NorthAS', ELD_OnStateSubmitted, NPC_Multiple, 'AvengerTakeOff_NorthAS');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.ShipAI_Setting_Course_Sectors_01", NAW_OnAssignment, 'OnAvengerTakeOff', 'WorldRegion_NorthAS', ELD_OnStateSubmitted, NPC_Multiple, 'AvengerTakeOff_NorthAS');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.ShipAI_Setting_Course_Experimental_01", NAW_OnAssignment, 'OnAvengerTakeOff', 'WorldRegion_NorthAS', ELD_OnStateSubmitted, NPC_Multiple, 'AvengerTakeOff_NorthAS');

	// Australia
	//Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.ShipAI_Setting_Course_Region_02", NAW_OnAssignment, 'OnAvengerTakeOff', 'WorldRegion_SouthOC', ELD_OnStateSubmitted, NPC_Multiple, 'AvengerTakeOff_SouthOC');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.ShipAI_Setting_Course_Sectors_02", NAW_OnAssignment, 'OnAvengerTakeOff', 'WorldRegion_SouthOC', ELD_OnStateSubmitted, NPC_Multiple, 'AvengerTakeOff_SouthOC');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.ShipAI_Setting_Course_Experimental_02", NAW_OnAssignment, 'OnAvengerTakeOff', 'WorldRegion_SouthOC', ELD_OnStateSubmitted, NPC_Multiple, 'AvengerTakeOff_SouthOC');

	// Brazil
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.ShipAI_Setting_Course_Region_03", NAW_OnAssignment, 'OnAvengerTakeOff', 'WorldRegion_NorthSA', ELD_OnStateSubmitted, NPC_Multiple, 'AvengerTakeOff_NorthSA');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.ShipAI_Setting_Course_Sectors_03", NAW_OnAssignment, 'OnAvengerTakeOff', 'WorldRegion_NorthSA', ELD_OnStateSubmitted, NPC_Multiple, 'AvengerTakeOff_NorthSA');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.ShipAI_Setting_Course_Experimental_03", NAW_OnAssignment, 'OnAvengerTakeOff', 'WorldRegion_NorthSA', ELD_OnStateSubmitted, NPC_Multiple, 'AvengerTakeOff_NorthSA');

	// Chile
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.ShipAI_Setting_Course_Region_04", NAW_OnAssignment, 'OnAvengerTakeOff', 'WorldRegion_SouthSA', ELD_OnStateSubmitted, NPC_Multiple, 'AvengerTakeOff_SouthSA');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.ShipAI_Setting_Course_Sectors_04", NAW_OnAssignment, 'OnAvengerTakeOff', 'WorldRegion_SouthSA', ELD_OnStateSubmitted, NPC_Multiple, 'AvengerTakeOff_SouthSA');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.ShipAI_Setting_Course_Experimental_04", NAW_OnAssignment, 'OnAvengerTakeOff', 'WorldRegion_SouthSA', ELD_OnStateSubmitted, NPC_Multiple, 'AvengerTakeOff_SouthSA');

	// India (South Asia)
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.ShipAI_Setting_Course_Region_05", NAW_OnAssignment, 'OnAvengerTakeOff', 'WorldRegion_SouthAS', ELD_OnStateSubmitted, NPC_Multiple, 'AvengerTakeOff_SouthAS');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.ShipAI_Setting_Course_Sectors_05", NAW_OnAssignment, 'OnAvengerTakeOff', 'WorldRegion_SouthAS', ELD_OnStateSubmitted, NPC_Multiple, 'AvengerTakeOff_SouthAS');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.ShipAI_Setting_Course_Experimental_05", NAW_OnAssignment, 'OnAvengerTakeOff', 'WorldRegion_SouthAS', ELD_OnStateSubmitted, NPC_Multiple, 'AvengerTakeOff_SouthAS');

	// Eastern Europe
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.ShipAI_Setting_Course_Region_06", NAW_OnAssignment, 'OnAvengerTakeOff', 'WorldRegion_EastEU', ELD_OnStateSubmitted, NPC_Multiple, 'AvengerTakeOff_EastEU');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.ShipAI_Setting_Course_Sectors_06", NAW_OnAssignment, 'OnAvengerTakeOff', 'WorldRegion_EastEU', ELD_OnStateSubmitted, NPC_Multiple, 'AvengerTakeOff_EastEU');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.ShipAI_Setting_Course_Experimental_06", NAW_OnAssignment, 'OnAvengerTakeOff', 'WorldRegion_EastEU', ELD_OnStateSubmitted, NPC_Multiple, 'AvengerTakeOff_EastEU');

	// Western Europe
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.ShipAI_Setting_Course_Region_07", NAW_OnAssignment, 'OnAvengerTakeOff', 'WorldRegion_WestEU', ELD_OnStateSubmitted, NPC_Multiple, 'AvengerTakeOff_WestEU');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.ShipAI_Setting_Course_Sectors_07", NAW_OnAssignment, 'OnAvengerTakeOff', 'WorldRegion_WestEU', ELD_OnStateSubmitted, NPC_Multiple, 'AvengerTakeOff_WestEU');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.ShipAI_Setting_Course_Experimental_07", NAW_OnAssignment, 'OnAvengerTakeOff', 'WorldRegion_WestEU', ELD_OnStateSubmitted, NPC_Multiple, 'AvengerTakeOff_WestEU');

	// Mexico
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.ShipAI_Setting_Course_Region_08", NAW_OnAssignment, 'OnAvengerTakeOff', 'WorldRegion_SouthNA', ELD_OnStateSubmitted, NPC_Multiple, 'AvengerTakeOff_SouthNA');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.ShipAI_Setting_Course_Sectors_08", NAW_OnAssignment, 'OnAvengerTakeOff', 'WorldRegion_SouthNA', ELD_OnStateSubmitted, NPC_Multiple, 'AvengerTakeOff_SouthNA');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.ShipAI_Setting_Course_Experimental_08", NAW_OnAssignment, 'OnAvengerTakeOff', 'WorldRegion_SouthNA', ELD_OnStateSubmitted, NPC_Multiple, 'AvengerTakeOff_SouthNA');

	// Western US
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.ShipAI_Setting_Course_Region_09", NAW_OnAssignment, 'OnAvengerTakeOff', 'WorldRegion_WestNA', ELD_OnStateSubmitted, NPC_Multiple, 'AvengerTakeOff_WestNA');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.ShipAI_Setting_Course_Sectors_09", NAW_OnAssignment, 'OnAvengerTakeOff', 'WorldRegion_WestNA', ELD_OnStateSubmitted, NPC_Multiple, 'AvengerTakeOff_WestNA');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.ShipAI_Setting_Course_Experimental_09", NAW_OnAssignment, 'OnAvengerTakeOff', 'WorldRegion_WestNA', ELD_OnStateSubmitted, NPC_Multiple, 'AvengerTakeOff_WestNA');

	// Eastern US
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.ShipAI_Setting_Course_Region_10", NAW_OnAssignment, 'OnAvengerTakeOff', 'WorldRegion_EastNA', ELD_OnStateSubmitted, NPC_Multiple, 'AvengerTakeOff_EastNA');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.ShipAI_Setting_Course_Sectors_10", NAW_OnAssignment, 'OnAvengerTakeOff', 'WorldRegion_EastNA', ELD_OnStateSubmitted, NPC_Multiple, 'AvengerTakeOff_EastNA');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.ShipAI_Setting_Course_Experimental_10", NAW_OnAssignment, 'OnAvengerTakeOff', 'WorldRegion_EastNA', ELD_OnStateSubmitted, NPC_Multiple, 'AvengerTakeOff_EastNA');

	// North Africa
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.ShipAI_Setting_Course_Region_11", NAW_OnAssignment, 'OnAvengerTakeOff', 'WorldRegion_NorthAF', ELD_OnStateSubmitted, NPC_Multiple, 'AvengerTakeOff_NorthAF');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.ShipAI_Setting_Course_Sectors_11", NAW_OnAssignment, 'OnAvengerTakeOff', 'WorldRegion_NorthAF', ELD_OnStateSubmitted, NPC_Multiple, 'AvengerTakeOff_NorthAF');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.ShipAI_Setting_Course_Experimental_11", NAW_OnAssignment, 'OnAvengerTakeOff', 'WorldRegion_NorthAF', ELD_OnStateSubmitted, NPC_Multiple, 'AvengerTakeOff_NorthAF');

	// East Africa
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.ShipAI_Setting_Course_Region_12", NAW_OnAssignment, 'OnAvengerTakeOff', 'WorldRegion_EastAF', ELD_OnStateSubmitted, NPC_Multiple, 'AvengerTakeOff_EastAF');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.ShipAI_Setting_Course_Sectors_12", NAW_OnAssignment, 'OnAvengerTakeOff', 'WorldRegion_EastAF', ELD_OnStateSubmitted, NPC_Multiple, 'AvengerTakeOff_EastAF');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.ShipAI_Setting_Course_Experimental_12", NAW_OnAssignment, 'OnAvengerTakeOff', 'WorldRegion_EastAF', ELD_OnStateSubmitted, NPC_Multiple, 'AvengerTakeOff_EastAF');

	// South Africa
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.ShipAI_Setting_Course_Region_13", NAW_OnAssignment, 'OnAvengerTakeOff', 'WorldRegion_SouthAF', ELD_OnStateSubmitted, NPC_Multiple, 'AvengerTakeOff_SouthAF');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.ShipAI_Setting_Course_Sectors_13", NAW_OnAssignment, 'OnAvengerTakeOff', 'WorldRegion_SouthAF', ELD_OnStateSubmitted, NPC_Multiple, 'AvengerTakeOff_SouthAF');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.ShipAI_Setting_Course_Experimental_13", NAW_OnAssignment, 'OnAvengerTakeOff', 'WorldRegion_SouthAF', ELD_OnStateSubmitted, NPC_Multiple, 'AvengerTakeOff_SouthAF');
	
	// East Asia
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.ShipAI_Setting_Course_Region_14", NAW_OnAssignment, 'OnAvengerTakeOff', 'WorldRegion_EastAS', ELD_OnStateSubmitted, NPC_Multiple, 'AvengerTakeOff_EastAS');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.ShipAI_Setting_Course_Sectors_14", NAW_OnAssignment, 'OnAvengerTakeOff', 'WorldRegion_EastAS', ELD_OnStateSubmitted, NPC_Multiple, 'AvengerTakeOff_EastAS');
	//Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.ShipAI_Setting_Course_Experimental_14", NAW_OnAssignment, 'OnAvengerTakeOff', 'WorldRegion_EastAS', ELD_OnStateSubmitted, NPC_Multiple, 'AvengerTakeOff_EastAS');

	// West Asia
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.ShipAI_Setting_Course_Region_15", NAW_OnAssignment, 'OnAvengerTakeOff', 'WorldRegion_WestAS', ELD_OnStateSubmitted, NPC_Multiple, 'AvengerTakeOff_WestAS');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.ShipAI_Setting_Course_Sectors_15", NAW_OnAssignment, 'OnAvengerTakeOff', 'WorldRegion_WestAS', ELD_OnStateSubmitted, NPC_Multiple, 'AvengerTakeOff_WestAS');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.ShipAI_Setting_Course_Experimental_14", NAW_OnAssignment, 'OnAvengerTakeOff', 'WorldRegion_WestAS', ELD_OnStateSubmitted, NPC_Multiple, 'AvengerTakeOff_WestAS');

	// Indonesia
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.ShipAI_Setting_Course_Region_16", NAW_OnAssignment, 'OnAvengerTakeOff', 'WorldRegion_NorthOC', ELD_OnStateSubmitted, NPC_Multiple, 'AvengerTakeOff_NorthOC');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.ShipAI_Setting_Course_Sectors_16", NAW_OnAssignment, 'OnAvengerTakeOff', 'WorldRegion_NorthOC', ELD_OnStateSubmitted, NPC_Multiple, 'AvengerTakeOff_NorthOC');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.ShipAI_Setting_Course_Experimental_16", NAW_OnAssignment, 'OnAvengerTakeOff', 'WorldRegion_NorthOC', ELD_OnStateSubmitted, NPC_Multiple, 'AvengerTakeOff_NorthOC');

	// Generic
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Avenger_New_Course", NAW_OnAssignment, 'OnAvengerTakeOffGeneric', '', ELD_OnStateSubmitted, NPC_Multiple, '');

	return Template;
}

static function X2DataTemplate CreateN_AutopsyCompleteTemplate()
{
	local X2ObjectiveTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ObjectiveTemplate', Template, 'N_AutopsyComplete');
	Template.bMainObjective = true;
	Template.bNeverShowObjective = true;

	Template.AddNarrativeTrigger("X2NarrativeMoments.Tygan_Autopsy_Trooper_Blurb", NAW_OnAssignment, 'OnResearchReport', 'AutopsyAdventTrooper', ELD_OnStateSubmitted, NPC_Once, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Tygan_Autopsy_Captain_Blurb", NAW_OnAssignment, 'OnResearchReport', 'AutopsyAdventOfficer', ELD_OnStateSubmitted, NPC_Once, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Tygan_Autopsy_Shieldbearer_Blurb", NAW_OnAssignment, 'OnResearchReport', 'AutopsyAdventShieldbearer', ELD_OnStateSubmitted, NPC_Once, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Tygan_Autopsy_Stunlancer_Blurb", NAW_OnAssignment, 'OnResearchReport', 'AutopsyAdventStunLancer', ELD_OnStateSubmitted, NPC_Once, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Shen_Autopsy_MEC_Blurb", NAW_OnAssignment, 'OnResearchReport', 'AutopsyAdventMEC', ELD_OnStateSubmitted, NPC_Once, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Shen_Autopsy_Turret_Blurb", NAW_OnAssignment, 'OnResearchReport', 'AutopsyAdventTurret', ELD_OnStateSubmitted, NPC_Once, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Shen_Autopsy_Sectopod_Blurb", NAW_OnAssignment, 'OnResearchReport', 'AutopsySectopod', ELD_OnStateSubmitted, NPC_Once, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Tygan_Autopsy_Sectoid_Blurb", NAW_OnAssignment, 'OnResearchReport', 'AutopsySectoid', ELD_OnStateSubmitted, NPC_Once, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Tygan_Autopsy_Muton_Blurb", NAW_OnAssignment, 'OnResearchReport', 'AutopsyMuton', ELD_OnStateSubmitted, NPC_Once, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Tygan_Autopsy_Berserker_Blurb", NAW_OnAssignment, 'OnResearchReport', 'AutopsyBerserker', ELD_OnStateSubmitted, NPC_Once, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Tygan_Autopsy_Chryssalid_Blurb", NAW_OnAssignment, 'OnResearchReport', 'AutopsyChryssalid', ELD_OnStateSubmitted, NPC_Once, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Tygan_Autopsy_Viper_Blurb", NAW_OnAssignment, 'OnResearchReport', 'AutopsyViper', ELD_OnStateSubmitted, NPC_Once, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Tygan_Autopsy_Faceless_Blurb", NAW_OnAssignment, 'OnResearchReport', 'AutopsyFaceless', ELD_OnStateSubmitted, NPC_Once, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Tygan_Autopsy_Archon_Blurb", NAW_OnAssignment, 'OnResearchReport', 'AutopsyArchon', ELD_OnStateSubmitted, NPC_Once, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Tygan_Autopsy_Andromedon_Blurb", NAW_OnAssignment, 'OnResearchReport', 'AutopsyAndromedon', ELD_OnStateSubmitted, NPC_Once, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Tygan_Autopsy_Gatekeeper_Blurb", NAW_OnAssignment, 'OnResearchReport', 'AutopsyGatekeeper', ELD_OnStateSubmitted, NPC_Once, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Tygan_Autopsy_Avatar_Blurb", NAW_OnAssignment, 'OnResearchReport', 'AutopsyAdventPsiWitch', ELD_OnStateSubmitted, NPC_Once, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Tygan_Autopsy_Codex", NAW_OnAssignment, 'OnResearchReport', 'CodexBrainPt1', ELD_OnStateSubmitted, NPC_Once, '');

	return Template;
}

static function X2DataTemplate CreateN_TyganGreetingsTemplate()
{
	local X2ObjectiveTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ObjectiveTemplate', Template, 'N_TyganGreetings');
	Template.bMainObjective = true;
	Template.bNeverShowObjective = true;

	Template.CompletionEvent = '';
	
	Template.AddNarrativeTrigger("X2NarrativeMoments.S_Tygan_Greeting_A", NAW_OnAssignment, 'TyganGreeting', '', ELD_OnStateSubmitted, NPC_Multiple, 'TyganGreetings');
	Template.AddNarrativeTrigger("X2NarrativeMoments.S_Tygan_Greeting_B", NAW_OnAssignment, 'TyganGreeting', '', ELD_OnStateSubmitted, NPC_Multiple, 'TyganGreetings');
	Template.AddNarrativeTrigger("X2NarrativeMoments.S_Tygan_Greeting_C", NAW_OnAssignment, 'TyganGreeting', '', ELD_OnStateSubmitted, NPC_Multiple, 'TyganGreetings');
	Template.AddNarrativeTrigger("X2NarrativeMoments.S_Tygan_Greeting_D", NAW_OnAssignment, 'TyganGreeting', '', ELD_OnStateSubmitted, NPC_Multiple, 'TyganGreetings');
	Template.AddNarrativeTrigger("X2NarrativeMoments.S_Tygan_Greeting_E", NAW_OnAssignment, 'TyganGreeting', '', ELD_OnStateSubmitted, NPC_Multiple, 'TyganGreetings');
	Template.AddNarrativeTrigger("X2NarrativeMoments.S_Tygan_Greeting_F", NAW_OnAssignment, 'TyganGreeting', '', ELD_OnStateSubmitted, NPC_Multiple, 'TyganGreetings');

	Template.AddNarrativeTrigger("X2NarrativeMoments.S_Tygan_Generic_ResearchComplete_A", NAW_OnAssignment, 'ResearchCompletePopup', '', ELD_OnStateSubmitted, NPC_Multiple, 'TyganResearchCompletePopup');
	Template.AddNarrativeTrigger("X2NarrativeMoments.S_Tygan_Generic_ResearchComplete_B", NAW_OnAssignment, 'ResearchCompletePopup', '', ELD_OnStateSubmitted, NPC_Multiple, 'TyganResearchCompletePopup');
	Template.AddNarrativeTrigger("X2NarrativeMoments.S_Tygan_Generic_ResearchComplete_C", NAW_OnAssignment, 'ResearchCompletePopup', '', ELD_OnStateSubmitted, NPC_Multiple, 'TyganResearchCompletePopup');
	Template.AddNarrativeTrigger("X2NarrativeMoments.S_Tygan_Generic_ResearchComplete_D", NAW_OnAssignment, 'ResearchCompletePopup', '', ELD_OnStateSubmitted, NPC_Multiple, 'TyganResearchCompletePopup');
	Template.AddNarrativeTrigger("X2NarrativeMoments.S_Tygan_Generic_ResearchComplete_E", NAW_OnAssignment, 'ResearchCompletePopup', '', ELD_OnStateSubmitted, NPC_Multiple, 'TyganResearchCompletePopup');

	// XPACK Additions
	Template.AddNarrativeTrigger("XPACK_NarrativeMoments.X2_XP_S_TYG_Research_Complete_A", NAW_OnAssignment, 'ResearchCompletePopup', '', ELD_OnStateSubmitted, NPC_Multiple, 'TyganResearchCompletePopup');
	Template.AddNarrativeTrigger("XPACK_NarrativeMoments.X2_XP_S_TYG_Research_Complete_B", NAW_OnAssignment, 'ResearchCompletePopup', '', ELD_OnStateSubmitted, NPC_Multiple, 'TyganResearchCompletePopup');
	Template.AddNarrativeTrigger("XPACK_NarrativeMoments.X2_XP_S_TYG_Research_Complete_C", NAW_OnAssignment, 'ResearchCompletePopup', '', ELD_OnStateSubmitted, NPC_Multiple, 'TyganResearchCompletePopup');
	Template.AddNarrativeTrigger("XPACK_NarrativeMoments.X2_XP_S_TYG_Research_Complete_D", NAW_OnAssignment, 'ResearchCompletePopup', '', ELD_OnStateSubmitted, NPC_Multiple, 'TyganResearchCompletePopup');
	Template.AddNarrativeTrigger("XPACK_NarrativeMoments.X2_XP_S_TYG_Research_Complete_E", NAW_OnAssignment, 'ResearchCompletePopup', '', ELD_OnStateSubmitted, NPC_Multiple, 'TyganResearchCompletePopup');

	return Template;
}

static function X2DataTemplate CreateN_ChooseFirstResearchTemplate()
{
	local X2ObjectiveTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ObjectiveTemplate', Template, 'N_ChooseFirstResearch');
	Template.bMainObjective = true;
	Template.bNeverShowObjective = true;

	Template.NextObjectives.AddItem('N_ChooseResearch');
	Template.CompletionEvent = 'ChooseResearch';

	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Tygan_Support_First_Tech_Selected", NAW_OnCompletion, '', '', ELD_OnStateSubmitted, NPC_Once, '');
	
	return Template;
}

static function X2DataTemplate CreateN_ChooseResearchTemplate()
{
	local X2ObjectiveTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ObjectiveTemplate', Template, 'N_ChooseResearch');
	Template.bMainObjective = true;
	Template.bNeverShowObjective = true;

	Template.CompletionEvent = '';

	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Tygan_Support_Tech_Selected_01", NAW_OnAssignment, 'ChooseResearch', '', ELD_OnStateSubmitted, NPC_Multiple, 'ChooseResearchNarrative');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Tygan_Support_Tech_Selected_02", NAW_OnAssignment, 'ChooseResearch', '', ELD_OnStateSubmitted, NPC_Multiple, 'ChooseResearchNarrative');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Tygan_Support_Tech_Selected_03", NAW_OnAssignment, 'ChooseResearch', '', ELD_OnStateSubmitted, NPC_Multiple, 'ChooseResearchNarrative');

	// XPACK Additions
	Template.AddNarrativeTrigger("XPACK_NarrativeMoments.X2_XP_S_TYG_Research_Confirmation_A", NAW_OnAssignment, 'ChooseResearch', '', ELD_OnStateSubmitted, NPC_Multiple, 'ChooseResearchNarrative');
	Template.AddNarrativeTrigger("XPACK_NarrativeMoments.X2_XP_S_TYG_Research_Confirmation_B", NAW_OnAssignment, 'ChooseResearch', '', ELD_OnStateSubmitted, NPC_Multiple, 'ChooseResearchNarrative');
	Template.AddNarrativeTrigger("XPACK_NarrativeMoments.X2_XP_S_TYG_Research_Confirmation_C", NAW_OnAssignment, 'ChooseResearch', '', ELD_OnStateSubmitted, NPC_Multiple, 'ChooseResearchNarrative');
	Template.AddNarrativeTrigger("XPACK_NarrativeMoments.X2_XP_S_TYG_Research_Confirmation_D", NAW_OnAssignment, 'ChooseResearch', '', ELD_OnStateSubmitted, NPC_Multiple, 'ChooseResearchNarrative');
	Template.AddNarrativeTrigger("XPACK_NarrativeMoments.X2_XP_S_TYG_Research_Confirmation_E", NAW_OnAssignment, 'ChooseResearch', '', ELD_OnStateSubmitted, NPC_Multiple, 'ChooseResearchNarrative');

	return Template;
}

static function X2DataTemplate CreateN_SwitchFirstResearchTemplate()
{
	local X2ObjectiveTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ObjectiveTemplate', Template, 'N_SwitchFirstResearch');
	Template.bMainObjective = true;
	Template.bNeverShowObjective = true;

	Template.CompletionEvent = 'SwitchFirstResearch';

	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Tygan_Support_First_Tech_Changed", NAW_OnCompletion, '', '', ELD_OnStateSubmitted, NPC_Once, '');

	return Template;
}

static function X2DataTemplate CreateN_SwitchResearchTemplate()
{
	local X2ObjectiveTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ObjectiveTemplate', Template, 'N_SwitchResearch');
	Template.bMainObjective = true;
	Template.bNeverShowObjective = true;

	Template.CompletionEvent = '';

	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Tygan_Support_Tech_Changed_01", NAW_OnAssignment, 'SwitchResearch', '', ELD_OnStateSubmitted, NPC_Multiple, 'SwitchResearchNarrative');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Tygan_Support_Tech_Changed_02", NAW_OnAssignment, 'SwitchResearch', '', ELD_OnStateSubmitted, NPC_Multiple, 'SwitchResearchNarrative');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Tygan_Support_Tech_Changed_03", NAW_OnAssignment, 'SwitchResearch', '', ELD_OnStateSubmitted, NPC_Multiple, 'SwitchResearchNarrative');

	return Template;
}

static function X2DataTemplate CreateN_FirstResearchInProgressTemplate()
{
	local X2ObjectiveTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ObjectiveTemplate', Template, 'N_FirstResearchInProgress');
	Template.bMainObjective = true;
	Template.bNeverShowObjective = true;

	Template.NextObjectives.AddItem('N_ResearchInProgress');
	Template.CompletionEvent = 'ResearchInProgress';

	Template.AddNarrativeTrigger("X2NarrativeMoments.Tygan_Setup_Phase_Research_In_Progress", NAW_OnCompletion, '', '', ELD_OnStateSubmitted, NPC_Once, '');

	return Template;
}

static function X2DataTemplate CreateN_ResearchInProgressTemplate()
{
	local X2ObjectiveTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ObjectiveTemplate', Template, 'N_ResearchInProgress');
	Template.bMainObjective = true;
	Template.bNeverShowObjective = true;

	Template.CompletionEvent = '';

	Template.AddNarrativeTrigger("X2NarrativeMoments.S_Tygan_Research_InProgress_A", NAW_OnAssignment, 'ResearchInProgress', '', ELD_OnStateSubmitted, NPC_Multiple, 'TyganGreetingInProgress');
	Template.AddNarrativeTrigger("X2NarrativeMoments.S_Tygan_Research_InProgress_B", NAW_OnAssignment, 'ResearchInProgress', '', ELD_OnStateSubmitted, NPC_Multiple, 'TyganGreetingInProgress');
	Template.AddNarrativeTrigger("X2NarrativeMoments.S_Tygan_Research_InProgress_C", NAW_OnAssignment, 'ResearchInProgress', '', ELD_OnStateSubmitted, NPC_Multiple, 'TyganGreetingInProgress');
	Template.AddNarrativeTrigger("X2NarrativeMoments.S_Tygan_Research_InProgress_D", NAW_OnAssignment, 'ResearchInProgress', '', ELD_OnStateSubmitted, NPC_Multiple, 'TyganGreetingInProgress');
	Template.AddNarrativeTrigger("X2NarrativeMoments.S_Tygan_Research_InProgress_E", NAW_OnAssignment, 'ResearchInProgress', '', ELD_OnStateSubmitted, NPC_Multiple, 'TyganGreetingInProgress');

	return Template;
}

static function X2DataTemplate CreateN_ShenGreetingsTemplate()
{
	local X2ObjectiveTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ObjectiveTemplate', Template, 'N_ShenGreetings');
	Template.bMainObjective = true;
	Template.bNeverShowObjective = true;

	Template.CompletionEvent = '';

	Template.AddNarrativeTrigger("X2NarrativeMoments.S_Shen_Greeting_A", NAW_OnAssignment, 'ShenGreeting', '', ELD_OnStateSubmitted, NPC_Multiple, 'ShenGreetings');
	Template.AddNarrativeTrigger("X2NarrativeMoments.S_Shen_Greeting_B", NAW_OnAssignment, 'ShenGreeting', '', ELD_OnStateSubmitted, NPC_Multiple, 'ShenGreetings');
	Template.AddNarrativeTrigger("X2NarrativeMoments.S_Shen_Greeting_C", NAW_OnAssignment, 'ShenGreeting', '', ELD_OnStateSubmitted, NPC_Multiple, 'ShenGreetings');
	Template.AddNarrativeTrigger("X2NarrativeMoments.S_Shen_Greeting_D", NAW_OnAssignment, 'ShenGreeting', '', ELD_OnStateSubmitted, NPC_Multiple, 'ShenGreetings');
	Template.AddNarrativeTrigger("X2NarrativeMoments.S_Shen_Greeting_E", NAW_OnAssignment, 'ShenGreeting', '', ELD_OnStateSubmitted, NPC_Multiple, 'ShenGreetings');
	Template.AddNarrativeTrigger("X2NarrativeMoments.S_Shen_Greeting_F", NAW_OnAssignment, 'ShenGreeting', '', ELD_OnStateSubmitted, NPC_Multiple, 'ShenGreetings');

	return Template;
}

static function X2DataTemplate CreateN_ChooseFirstProvingGroundProjectTemplate()
{
	local X2ObjectiveTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ObjectiveTemplate', Template, 'N_ChooseFirstProvingGroundProject');
	Template.bMainObjective = true;
	Template.bNeverShowObjective = true;

	Template.NextObjectives.AddItem('N_ChooseProvingGroundProject');
	Template.CompletionEvent = 'ChooseProvingGroundProject';

	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Shens_Support_VO_Proving_Ground_Project_First", NAW_OnCompletion, '', '', ELD_OnStateSubmitted, NPC_Once, '');

	return Template;
}

static function X2DataTemplate CreateN_ChooseProvingGroundProjectTemplate()
{
	local X2ObjectiveTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ObjectiveTemplate', Template, 'N_ChooseProvingGroundProject');
	Template.bMainObjective = true;
	Template.bNeverShowObjective = true;

	Template.CompletionEvent = '';

	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Shens_Support_VO_Proving_Ground_Project_Selected_01", NAW_OnAssignment, 'ChooseProvingGroundProject', '', ELD_OnStateSubmitted, NPC_Multiple, 'ChooseProvingGroundProjectNarrative');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Shens_Support_VO_Proving_Ground_Project_Selected_02", NAW_OnAssignment, 'ChooseProvingGroundProject', '', ELD_OnStateSubmitted, NPC_Multiple, 'ChooseProvingGroundProjectNarrative');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Shens_Support_VO_Proving_Ground_Project_Selected_03", NAW_OnAssignment, 'ChooseProvingGroundProject', '', ELD_OnStateSubmitted, NPC_Multiple, 'ChooseProvingGroundProjectNarrative');

	return Template;
}

static function X2DataTemplate CreateN_FirstAlienFacilityTemplate()
{
	local X2ObjectiveTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ObjectiveTemplate', Template, 'N_FirstAlienFacility');
	Template.bMainObjective = true;
	Template.bNeverShowObjective = true;

	Template.NextObjectives.AddItem('N_AlienFacilityConstructed');
	Template.CompletionEvent = 'CameraAtAlienFacility';

	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Central_Support_First_Alien_Facility_Constructed", NAW_OnAssignment, 'CameraAtAlienFacility', '', ELD_OnStateSubmitted, NPC_Once, 'FirstAlienFacilityLines');
	Template.AddNarrativeTrigger("X2NarrativeMoments.S_GP_First_Alien_Facility_Buit_Central", NAW_OnAssignment, 'CameraAtAlienFacility', '', ELD_OnStateSubmitted, NPC_Once, 'FirstAlienFacilityLines');

	return Template;
}

static function X2DataTemplate CreateN_AlienFacilityConstructedTemplate()
{
	local X2ObjectiveTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ObjectiveTemplate', Template, 'N_AlienFacilityConstructed');
	Template.bMainObjective = true;
	Template.bNeverShowObjective = true;

	Template.CompletionEvent = '';

	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.First_Avatar_RepeatA", NAW_OnAssignment, 'OnAlienFacilityPopup', '', ELD_OnStateSubmitted, NPC_Multiple, 'ViewAlienFacility');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.First_Avatar_RepeatB", NAW_OnAssignment, 'OnAlienFacilityPopup', '', ELD_OnStateSubmitted, NPC_Multiple, 'ViewAlienFacility');

	return Template;
}

static function X2DataTemplate CreateN_MakingContactAvailable()
{
	local X2ObjectiveTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ObjectiveTemplate', Template, 'N_MakingContactAvailable');
	Template.bMainObjective = true;
	Template.bNeverShowObjective = true;

	Template.CompletionEvent = 'ResearchCompleted';
	Template.CompletionRequirements.RequiredTechs.AddItem('ResistanceCommunications');

	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Central_Support_First_Regions_Available", NAW_OnCompletion, 'OnGeoscapeEntry', '', ELD_OnStateSubmitted, NPC_Once, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Central_Support_First_Regions_Available", NAW_OnCompletion, 'OnResearchCompletePopupClosed', '', ELD_OnStateSubmitted, NPC_Once, '');

	return Template;
}

static function X2DataTemplate CreateN_RadioRelaysAvailable()
{
	local X2ObjectiveTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ObjectiveTemplate', Template, 'N_RadioRelaysAvailable');
	Template.bMainObjective = true;
	Template.bNeverShowObjective = true;

	Template.CompletionEvent = 'ResearchCompleted';
	Template.CompletionRequirements.RequiredTechs.AddItem('ResistanceRadio');

	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Central_Support_First_Radio_Relays", NAW_OnCompletion, 'OnGeoscapeEntry', '', ELD_OnStateSubmitted, NPC_Once, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Central_Support_First_Radio_Relays", NAW_OnCompletion, 'OnResearchCompletePopupClosed', '', ELD_OnStateSubmitted, NPC_Once, '');

	return Template;
}

static function X2DataTemplate CreateN_AfterActionCommentTemplate()
{
	local X2ObjectiveTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ObjectiveTemplate', Template, 'N_AfterActionComment');
	Template.bMainObjective = true;
	Template.bNeverShowObjective = true;

	Template.CompletionEvent = '';

	// Great Mission
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Shen_Support_Great_Mission_01", NAW_OnAssignment, 'AfterAction_GreatMission', '', ELD_OnStateSubmitted, NPC_Multiple, 'AfterActionGreatMission');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Shen_Support_Great_Mission_02", NAW_OnAssignment, 'AfterAction_GreatMission', '', ELD_OnStateSubmitted, NPC_Multiple, 'AfterActionGreatMission');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Shen_Support_Great_Mission_03", NAW_OnAssignment, 'AfterAction_GreatMission', '', ELD_OnStateSubmitted, NPC_Multiple, 'AfterActionGreatMission');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Shen_Support_Great_Mission_04", NAW_OnAssignment, 'AfterAction_GreatMission', '', ELD_OnStateSubmitted, NPC_Multiple, 'AfterActionGreatMission');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Shen_Support_Great_Mission_05", NAW_OnAssignment, 'AfterAction_GreatMission', '', ELD_OnStateSubmitted, NPC_Multiple, 'AfterActionGreatMission');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Shen_Support_Great_Mission_06", NAW_OnAssignment, 'AfterAction_GreatMission', '', ELD_OnStateSubmitted, NPC_Multiple, 'AfterActionGreatMission');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Shen_Support_Great_Mission_07", NAW_OnAssignment, 'AfterAction_GreatMission', '', ELD_OnStateSubmitted, NPC_Multiple, 'AfterActionGreatMission');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Shen_Support_Great_Mission_08", NAW_OnAssignment, 'AfterAction_GreatMission', '', ELD_OnStateSubmitted, NPC_Multiple, 'AfterActionGreatMission');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Shen_Support_Great_Mission_09", NAW_OnAssignment, 'AfterAction_GreatMission', '', ELD_OnStateSubmitted, NPC_Multiple, 'AfterActionGreatMission');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Shen_Support_Great_Mission_10", NAW_OnAssignment, 'AfterAction_GreatMission', '', ELD_OnStateSubmitted, NPC_Multiple, 'AfterActionGreatMission');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Tygan_Support_Great_Mission_01", NAW_OnAssignment, 'AfterAction_GreatMission', '', ELD_OnStateSubmitted, NPC_Multiple, 'AfterActionGreatMission');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Tygan_Support_Great_Mission_02", NAW_OnAssignment, 'AfterAction_GreatMission', '', ELD_OnStateSubmitted, NPC_Multiple, 'AfterActionGreatMission');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Tygan_Support_Great_Mission_03", NAW_OnAssignment, 'AfterAction_GreatMission', '', ELD_OnStateSubmitted, NPC_Multiple, 'AfterActionGreatMission');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Tygan_Support_Great_Mission_04", NAW_OnAssignment, 'AfterAction_GreatMission', '', ELD_OnStateSubmitted, NPC_Multiple, 'AfterActionGreatMission');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Tygan_Support_Great_Mission_05", NAW_OnAssignment, 'AfterAction_GreatMission', '', ELD_OnStateSubmitted, NPC_Multiple, 'AfterActionGreatMission');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Tygan_Support_Great_Mission_06", NAW_OnAssignment, 'AfterAction_GreatMission', '', ELD_OnStateSubmitted, NPC_Multiple, 'AfterActionGreatMission');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Tygan_Support_Great_Mission_07", NAW_OnAssignment, 'AfterAction_GreatMission', '', ELD_OnStateSubmitted, NPC_Multiple, 'AfterActionGreatMission');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Tygan_Support_Great_Mission_08", NAW_OnAssignment, 'AfterAction_GreatMission', '', ELD_OnStateSubmitted, NPC_Multiple, 'AfterActionGreatMission');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Tygan_Support_Great_Mission_09", NAW_OnAssignment, 'AfterAction_GreatMission', '', ELD_OnStateSubmitted, NPC_Multiple, 'AfterActionGreatMission');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Tygan_Support_Great_Mission_10", NAW_OnAssignment, 'AfterAction_GreatMission', '', ELD_OnStateSubmitted, NPC_Multiple, 'AfterActionGreatMission');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Tygan_Support_Great_Mission_11", NAW_OnAssignment, 'AfterAction_GreatMission', '', ELD_OnStateSubmitted, NPC_Multiple, 'AfterActionGreatMission');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Central_Support_Great_Mission_01", NAW_OnAssignment, 'AfterAction_GreatMission', '', ELD_OnStateSubmitted, NPC_Multiple, 'AfterActionGreatMission');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Central_Support_Great_Mission_02", NAW_OnAssignment, 'AfterAction_GreatMission', '', ELD_OnStateSubmitted, NPC_Multiple, 'AfterActionGreatMission');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Central_Support_Great_Mission_03", NAW_OnAssignment, 'AfterAction_GreatMission', '', ELD_OnStateSubmitted, NPC_Multiple, 'AfterActionGreatMission');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Central_Support_Great_Mission_04", NAW_OnAssignment, 'AfterAction_GreatMission', '', ELD_OnStateSubmitted, NPC_Multiple, 'AfterActionGreatMission');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Central_Support_Great_Mission_05", NAW_OnAssignment, 'AfterAction_GreatMission', '', ELD_OnStateSubmitted, NPC_Multiple, 'AfterActionGreatMission');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Central_Support_Great_Mission_06", NAW_OnAssignment, 'AfterAction_GreatMission', '', ELD_OnStateSubmitted, NPC_Multiple, 'AfterActionGreatMission');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Central_Support_Great_Mission_07", NAW_OnAssignment, 'AfterAction_GreatMission', '', ELD_OnStateSubmitted, NPC_Multiple, 'AfterActionGreatMission');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Central_Support_Great_Mission_08", NAW_OnAssignment, 'AfterAction_GreatMission', '', ELD_OnStateSubmitted, NPC_Multiple, 'AfterActionGreatMission');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Central_Support_Great_Mission_09", NAW_OnAssignment, 'AfterAction_GreatMission', '', ELD_OnStateSubmitted, NPC_Multiple, 'AfterActionGreatMission');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Central_Support_Great_Mission_10", NAW_OnAssignment, 'AfterAction_GreatMission', '', ELD_OnStateSubmitted, NPC_Multiple, 'AfterActionGreatMission');

	
	// Tough Mission
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Shen_Support_Tough_Mission_01", NAW_OnAssignment, 'AfterAction_ToughMission', '', ELD_OnStateSubmitted, NPC_Multiple, 'AfterActionToughMission');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Shen_Support_Tough_Mission_02", NAW_OnAssignment, 'AfterAction_ToughMission', '', ELD_OnStateSubmitted, NPC_Multiple, 'AfterActionToughMission');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Shen_Support_Tough_Mission_03", NAW_OnAssignment, 'AfterAction_ToughMission', '', ELD_OnStateSubmitted, NPC_Multiple, 'AfterActionToughMission');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Shen_Support_Tough_Mission_04", NAW_OnAssignment, 'AfterAction_ToughMission', '', ELD_OnStateSubmitted, NPC_Multiple, 'AfterActionToughMission');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Shen_Support_Tough_Mission_05", NAW_OnAssignment, 'AfterAction_ToughMission', '', ELD_OnStateSubmitted, NPC_Multiple, 'AfterActionToughMission');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Tygan_Support_Tough_Mission_01", NAW_OnAssignment, 'AfterAction_ToughMission', '', ELD_OnStateSubmitted, NPC_Multiple, 'AfterActionToughMission');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Tygan_Support_Tough_Mission_02", NAW_OnAssignment, 'AfterAction_ToughMission', '', ELD_OnStateSubmitted, NPC_Multiple, 'AfterActionToughMission');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Tygan_Support_Tough_Mission_03", NAW_OnAssignment, 'AfterAction_ToughMission', '', ELD_OnStateSubmitted, NPC_Multiple, 'AfterActionToughMission');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Tygan_Support_Tough_Mission_04", NAW_OnAssignment, 'AfterAction_ToughMission', '', ELD_OnStateSubmitted, NPC_Multiple, 'AfterActionToughMission');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Tygan_Support_Tough_Mission_05", NAW_OnAssignment, 'AfterAction_ToughMission', '', ELD_OnStateSubmitted, NPC_Multiple, 'AfterActionToughMission');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Central_Support_Tough_Mission_01", NAW_OnAssignment, 'AfterAction_ToughMission', '', ELD_OnStateSubmitted, NPC_Multiple, 'AfterActionToughMission');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Central_Support_Tough_Mission_02", NAW_OnAssignment, 'AfterAction_ToughMission', '', ELD_OnStateSubmitted, NPC_Multiple, 'AfterActionToughMission');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Central_Support_Tough_Mission_03", NAW_OnAssignment, 'AfterAction_ToughMission', '', ELD_OnStateSubmitted, NPC_Multiple, 'AfterActionToughMission');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Central_Support_Tough_Mission_04", NAW_OnAssignment, 'AfterAction_ToughMission', '', ELD_OnStateSubmitted, NPC_Multiple, 'AfterActionToughMission');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Central_Support_Tough_Mission_05", NAW_OnAssignment, 'AfterAction_ToughMission', '', ELD_OnStateSubmitted, NPC_Multiple, 'AfterActionToughMission');

	return Template;
}

static function X2DataTemplate CreateN_AfterActionCommentCouncilTemplate()
{
	local X2ObjectiveTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ObjectiveTemplate', Template, 'N_AfterActionCommentCouncil');
	Template.bMainObjective = true;
	Template.bNeverShowObjective = true;

	Template.CompletionEvent = '';

	// Great Mission
	Template.AddNarrativeTrigger("X2NarrativeMoments.Council_Support_VO_Great_Mission_01", NAW_OnAssignment, 'AfterActionCouncil_GreatMission', '', ELD_OnStateSubmitted, NPC_Multiple, 'AfterActionCouncilGreatMission');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Council_Support_VO_Great_Mission_02", NAW_OnAssignment, 'AfterActionCouncil_GreatMission', '', ELD_OnStateSubmitted, NPC_Multiple, 'AfterActionCouncilGreatMission');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Council_Support_VO_Great_Mission_03", NAW_OnAssignment, 'AfterActionCouncil_GreatMission', '', ELD_OnStateSubmitted, NPC_Multiple, 'AfterActionCouncilGreatMission');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Council_Support_VO_Great_Mission_04", NAW_OnAssignment, 'AfterActionCouncil_GreatMission', '', ELD_OnStateSubmitted, NPC_Multiple, 'AfterActionCouncilGreatMission');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Council_Support_VO_Great_Mission_05", NAW_OnAssignment, 'AfterActionCouncil_GreatMission', '', ELD_OnStateSubmitted, NPC_Multiple, 'AfterActionCouncilGreatMission');

	// Tough Mission
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Council_Support_VO_Tough_Mission_01", NAW_OnAssignment, 'AfterActionCouncil_ToughMission', '', ELD_OnStateSubmitted, NPC_Multiple, 'AfterActionCouncilToughMission');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Council_Support_VO_Tough_Mission_02", NAW_OnAssignment, 'AfterActionCouncil_ToughMission', '', ELD_OnStateSubmitted, NPC_Multiple, 'AfterActionCouncilToughMission');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Council_Support_VO_Tough_Mission_03", NAW_OnAssignment, 'AfterActionCouncil_ToughMission', '', ELD_OnStateSubmitted, NPC_Multiple, 'AfterActionCouncilToughMission');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Council_Support_VO_Tough_Mission_04", NAW_OnAssignment, 'AfterActionCouncil_ToughMission', '', ELD_OnStateSubmitted, NPC_Multiple, 'AfterActionCouncilToughMission');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Council_Support_VO_Tough_Mission_05", NAW_OnAssignment, 'AfterActionCouncil_ToughMission', '', ELD_OnStateSubmitted, NPC_Multiple, 'AfterActionCouncilToughMission');

	// Facility Success
	Template.AddNarrativeTrigger("X2NarrativeMoments.Council_Support_Facility_Success_01", NAW_OnAssignment, 'AfterActionCouncil_FacilitySuccess', '', ELD_OnStateSubmitted, NPC_Multiple, 'AfterActionCouncilFacilitySuccess');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Council_Support_Facility_Success_02", NAW_OnAssignment, 'AfterActionCouncil_FacilitySuccess', '', ELD_OnStateSubmitted, NPC_Multiple, 'AfterActionCouncilFacilitySuccess');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Council_Support_Facility_Success_03", NAW_OnAssignment, 'AfterActionCouncil_FacilitySuccess', '', ELD_OnStateSubmitted, NPC_Multiple, 'AfterActionCouncilFacilitySuccess');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Council_Support_Facility_Success_04", NAW_OnAssignment, 'AfterActionCouncil_FacilitySuccess', '', ELD_OnStateSubmitted, NPC_Multiple, 'AfterActionCouncilFacilitySuccess');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Council_Support_Facility_Success_05", NAW_OnAssignment, 'AfterActionCouncil_FacilitySuccess', '', ELD_OnStateSubmitted, NPC_Multiple, 'AfterActionCouncilFacilitySuccess');

	// Facility Failed
	Template.AddNarrativeTrigger("X2NarrativeMoments.Council_Support_Facility_Failed_01", NAW_OnAssignment, 'AfterActionCouncil_FacilityFailed', '', ELD_OnStateSubmitted, NPC_Multiple, 'AfterActionCouncilFacilityFailed');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Council_Support_Facility_Failed_02", NAW_OnAssignment, 'AfterActionCouncil_FacilityFailed', '', ELD_OnStateSubmitted, NPC_Multiple, 'AfterActionCouncilFacilityFailed');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Council_Support_Facility_Failed_03", NAW_OnAssignment, 'AfterActionCouncil_FacilityFailed', '', ELD_OnStateSubmitted, NPC_Multiple, 'AfterActionCouncilFacilityFailed');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Council_Support_Facility_Failed_04", NAW_OnAssignment, 'AfterActionCouncil_FacilityFailed', '', ELD_OnStateSubmitted, NPC_Multiple, 'AfterActionCouncilFacilityFailed');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Council_Support_Facility_Failed_05", NAW_OnAssignment, 'AfterActionCouncil_FacilityFailed', '', ELD_OnStateSubmitted, NPC_Multiple, 'AfterActionCouncilFacilityFailed');

	// Golden Path Remarks
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Blacksite_Spokesman_Remarks", NAW_OnAssignment, 'AfterActionCouncil_Blacksite', '', ELD_OnStateSubmitted, NPC_Once, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Psi_Gate_Spokesman_Remarks", NAW_OnAssignment, 'AfterActionCouncil_PsiGate', '', ELD_OnStateSubmitted, NPC_Once, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Forge_Spokesman_Remarks", NAW_OnAssignment, 'AfterActionCouncil_Forge', '', ELD_OnStateSubmitted, NPC_Once, '');

	return Template;
}

static function X2DataTemplate CreateN_MonthlyReportCommentTemplate()
{
	local X2ObjectiveTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ObjectiveTemplate', Template, 'N_MonthlyReportComment');
	Template.bMainObjective = true;
	Template.bNeverShowObjective = true;

	Template.CompletionEvent = '';

	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Council_Support_Status_Report_Grade_A", NAW_OnAssignment, 'MonthlyReport_Good', '', ELD_OnStateSubmitted, NPC_Multiple, 'MonthlyReportGood');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Council_Support_Status_Report_Grade_B", NAW_OnAssignment, 'MonthlyReport_Good', '', ELD_OnStateSubmitted, NPC_Multiple, 'MonthlyReportGood');

	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Council_Support_Status_Report_Grade_C", NAW_OnAssignment, 'MonthlyReport_Moderate', '', ELD_OnStateSubmitted, NPC_Multiple, 'MonthlyReportModerate');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Council_Support_Status_Report_Grade_D", NAW_OnAssignment, 'MonthlyReport_Moderate', '', ELD_OnStateSubmitted, NPC_Multiple, 'MonthlyReportModerate');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Council_ALT_Mediocre", NAW_OnAssignment, 'MonthlyReport_Moderate', '', ELD_OnStateSubmitted, NPC_Multiple, 'MonthlyReportModerate');

	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Council_Support_Status_Report_Grade_F", NAW_OnAssignment, 'MonthlyReport_Bad', '', ELD_OnStateSubmitted, NPC_Multiple, 'MonthlyReportBad');

	return Template;
}

static function X2DataTemplate CreateN_UFOAppearedTemplate()
{
	local X2ObjectiveTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ObjectiveTemplate', Template, 'N_UFOAppeared');
	Template.bMainObjective = true;
	Template.bNeverShowObjective = true;

	Template.CompletionEvent = 'UFOSpawned';

	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Central_Support_UFO_Inbound_Now_Hunting", NAW_OnCompletion, 'OnGeoscapeEntry', '', ELD_OnStateSubmitted, NPC_Once, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Central_Support_UFO_Inbound_Now_Hunting", NAW_OnCompletion, 'OnDarkEventPopupClosed', '', ELD_OnStateSubmitted, NPC_Once, '');

	return Template;
}

static function X2DataTemplate CreateN_ContactOrOutpostTemplate()
{
	local X2ObjectiveTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ObjectiveTemplate', Template, 'N_ContactOrOutpostContacted');
	Template.bMainObjective = true;
	Template.bNeverShowObjective = true;

	Template.CompletionEvent = '';

	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Resistance_Resistance_Outpost_Contact_Established_01", NAW_OnAssignment, 'OnContactOrOutpost', '', ELD_OnStateSubmitted, NPC_Multiple, 'ContactOrOutpostNarrative');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Resistance_Resistance_Outpost_Contact_Established_02", NAW_OnAssignment, 'OnContactOrOutpost', '', ELD_OnStateSubmitted, NPC_Multiple, 'ContactOrOutpostNarrative');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Resistance_Resistance_Outpost_Contact_Established_03", NAW_OnAssignment, 'OnContactOrOutpost', '', ELD_OnStateSubmitted, NPC_Multiple, 'ContactOrOutpostNarrative');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Resistance_Resistance_Outpost_Contact_Established_04", NAW_OnAssignment, 'OnContactOrOutpost', '', ELD_OnStateSubmitted, NPC_Multiple, 'ContactOrOutpostNarrative');

	return Template;
}

static function X2DataTemplate CreateN_FacilityThanksTemplate()
{
	local X2ObjectiveTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ObjectiveTemplate', Template, 'N_FacilityThanks');
	Template.bMainObjective = true;
	Template.bNeverShowObjective = true;

	Template.CompletionEvent = '';

	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Thanks_NewLab", NAW_OnAssignment, 'FacilityCompletePopup', 'Laboratory', ELD_OnStateSubmitted, NPC_Once, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Thanks_NewWorkshop", NAW_OnAssignment, 'FacilityCompletePopup', 'Workshop', ELD_OnStateSubmitted, NPC_Once, '');
	
	// This one seems to be misnamed, but talks about proving ground being built
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.GP_FirstStasisLanceBolted_Shen", NAW_OnAssignment, 'FacilityCompletePopup', 'ProvingGround', ELD_OnStateSubmitted, NPC_Once, '');

	return Template;
}

static function X2DataTemplate CreateN_ToDoWarningsTemplate()
{
	local X2ObjectiveTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ObjectiveTemplate', Template, 'N_ToDoWarnings');
	Template.bMainObjective = true;
	Template.bNeverShowObjective = true;

	Template.CompletionEvent = '';

	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Tygan_Support_Red_UI_Player_Not_Researching", NAW_OnAssignment, 'WarningNoResearch', '', ELD_OnStateSubmitted, NPC_Multiple, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Tygan_Support_Unstaffed_Scientist", NAW_OnAssignment, 'WarningUnstaffedScientist', '', ELD_OnStateSubmitted, NPC_Multiple, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Shen_Support_Unstaffed_Engineer", NAW_OnAssignment, 'WarningUnstaffedEngineer', '', ELD_OnStateSubmitted, NPC_Multiple, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Shen_Support_Not_Enough_Comms", NAW_OnAssignment, 'WarningNoComms', '', ELD_OnStateSubmitted, NPC_Multiple, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Shen_Support_Not_Enough_Power", NAW_OnAssignment, 'WarningNoPower', '', ELD_OnStateSubmitted, NPC_Multiple, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Power_Red", NAW_OnAssignment, 'WarningNoPowerAI', '', ELD_OnStateSubmitted, NPC_Multiple, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Central_Support_No_Supply_Income", NAW_OnAssignment, 'WarningNoIncome', '', ELD_OnStateSubmitted, NPC_Multiple, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.No_Soldiers", NAW_OnAssignment, 'WarningNoSoldiers', '', ELD_OnStateSubmitted, NPC_Multiple, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Not_Enough_Soldiers", NAW_OnAssignment, 'WarningNotEnoughSoldiers', '', ELD_OnStateSubmitted, NPC_Multiple, '');

	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Not_Enough_Engineers", NAW_OnAssignment, 'WarningNeedMoreEngineers', '', ELD_OnStateSubmitted, NPC_Once, 'NeedMoreEngineersLines');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Shen_Support_More_Engineers", NAW_OnAssignment, 'WarningNeedMoreEngineers', '', ELD_OnStateSubmitted, NPC_Once, 'NeedMoreEngineersLines');

	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Not_Enough_Scientists", NAW_OnAssignment, 'WarningNeedMoreScientists', '', ELD_OnStateSubmitted, NPC_Once, 'NeedMoreScientistsLines');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Tygan_Support_More_Scientists", NAW_OnAssignment, 'WarningNeedMoreScientists', '', ELD_OnStateSubmitted, NPC_Once, 'NeedMoreScientistsLines');
	
	return Template;
}

static function X2DataTemplate CreateN_EquipSkulljackTemplate()
{
	local X2ObjectiveTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ObjectiveTemplate', Template, 'N_EquipSkulljack');
	Template.bMainObjective = true;
	Template.bNeverShowObjective = true;

	Template.CompletionEvent = '';

	Template.AddNarrativeTrigger("X2NarrativeMoments.Central_Skulljack_Objective_Active_Not_Equipped", NAW_OnAssignment, 'NeedToEquipSkulljack', '', ELD_OnStateSubmitted, NPC_Multiple, 'SkulljackEquip');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Central_Skulljack_Objective_Active_Not_Equipped_B", NAW_OnAssignment, 'NeedToEquipSkulljack', '', ELD_OnStateSubmitted, NPC_Multiple, 'SkulljackEquip');

	return Template;
}

static function X2DataTemplate CreateN_InDropPositionTemplate()
{
	local X2ObjectiveTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ObjectiveTemplate', Template, 'N_InDropPosition');
	Template.bMainObjective = true;
	Template.bNeverShowObjective = true;

	Template.CompletionEvent = '';

	Template.AddNarrativeTrigger("X2NarrativeMoments.T_In_Drop_Position_Firebrande_OO", NAW_OnAssignment, 'OnSkyrangerArrives', '', ELD_OnStateSubmitted, NPC_Multiple, 'InDropPosition');
	Template.AddNarrativeTrigger("X2NarrativeMoments.T_In_Drop_Position_Firebrande_O1", NAW_OnAssignment, 'OnSkyrangerArrives', '', ELD_OnStateSubmitted, NPC_Multiple, 'InDropPosition');
	Template.AddNarrativeTrigger("X2NarrativeMoments.T_In_Drop_Position_Firebrande_O2", NAW_OnAssignment, 'OnSkyrangerArrives', '', ELD_OnStateSubmitted, NPC_Multiple, 'InDropPosition');
	Template.AddNarrativeTrigger("X2NarrativeMoments.T_In_Drop_Position_Firebrande_O3", NAW_OnAssignment, 'OnSkyrangerArrives', '', ELD_OnStateSubmitted, NPC_Multiple, 'InDropPosition');
	Template.AddNarrativeTrigger("X2NarrativeMoments.T_In_Drop_Position_Firebrande_O4", NAW_OnAssignment, 'OnSkyrangerArrives', '', ELD_OnStateSubmitted, NPC_Multiple, 'InDropPosition');
	

	return Template;
}

static function X2DataTemplate CreateN_DoomReducedTemplate()
{
	local X2ObjectiveTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ObjectiveTemplate', Template, 'N_DoomReduced');
	Template.bMainObjective = true;
	Template.bNeverShowObjective = true;

	Template.CompletionEvent = '';

	// Blacksite
	Template.AddNarrativeTrigger("X2NarrativeMoments.S_GP_Doom_Lowered_Council_Blacksite_A", NAW_OnAssignment, 'BlacksiteDoomEvent', '', ELD_OnStateSubmitted, NPC_Multiple, 'BlacksiteDoom');
	Template.AddNarrativeTrigger("X2NarrativeMoments.S_GP_Doom_Lowered_Council_Blacksite_B", NAW_OnAssignment, 'BlacksiteDoomEvent', '', ELD_OnStateSubmitted, NPC_Multiple, 'BlacksiteDoom');
	Template.AddNarrativeTrigger("X2NarrativeMoments.S_GP_Doom_Lowered_Council_Blacksite_C", NAW_OnAssignment, 'BlacksiteDoomEvent', '', ELD_OnStateSubmitted, NPC_Multiple, 'BlacksiteDoom');
	Template.AddNarrativeTrigger("X2NarrativeMoments.S_GP_Doom_Lowered_Council_Blacksite_D", NAW_OnAssignment, 'BlacksiteDoomEvent', '', ELD_OnStateSubmitted, NPC_Multiple, 'BlacksiteDoom');
	Template.AddNarrativeTrigger("X2NarrativeMoments.S_GP_Doom_Lowered_Council_Blacksite_E", NAW_OnAssignment, 'BlacksiteDoomEvent', '', ELD_OnStateSubmitted, NPC_Multiple, 'BlacksiteDoom');
	
	// Forge
	Template.AddNarrativeTrigger("X2NarrativeMoments.S_GP_Doom_Lowered_Council_Forge_A", NAW_OnAssignment, 'ForgeDoomEvent', '', ELD_OnStateSubmitted, NPC_Multiple, 'ForgeDoom');
	Template.AddNarrativeTrigger("X2NarrativeMoments.S_GP_Doom_Lowered_Council_Forge_B", NAW_OnAssignment, 'ForgeDoomEvent', '', ELD_OnStateSubmitted, NPC_Multiple, 'ForgeDoom');
	Template.AddNarrativeTrigger("X2NarrativeMoments.S_GP_Doom_Lowered_Council_Forge_C", NAW_OnAssignment, 'ForgeDoomEvent', '', ELD_OnStateSubmitted, NPC_Multiple, 'ForgeDoom');
	Template.AddNarrativeTrigger("X2NarrativeMoments.S_GP_Doom_Lowered_Council_Forge_D", NAW_OnAssignment, 'ForgeDoomEvent', '', ELD_OnStateSubmitted, NPC_Multiple, 'ForgeDoom');
	Template.AddNarrativeTrigger("X2NarrativeMoments.S_GP_Doom_Lowered_Council_Forge_E", NAW_OnAssignment, 'ForgeDoomEvent', '', ELD_OnStateSubmitted, NPC_Multiple, 'ForgeDoom');
	
	// Psi Gate
	Template.AddNarrativeTrigger("X2NarrativeMoments.S_GP_Doom_Lowered_Council_PsiGate_A", NAW_OnAssignment, 'PsiGateDoomEvent', '', ELD_OnStateSubmitted, NPC_Multiple, 'PsiGateDoom');
	Template.AddNarrativeTrigger("X2NarrativeMoments.S_GP_Doom_Lowered_Council_PsiGate_B", NAW_OnAssignment, 'PsiGateDoomEvent', '', ELD_OnStateSubmitted, NPC_Multiple, 'PsiGateDoom');
	Template.AddNarrativeTrigger("X2NarrativeMoments.S_GP_Doom_Lowered_Council_PsiGate_C", NAW_OnAssignment, 'PsiGateDoomEvent', '', ELD_OnStateSubmitted, NPC_Multiple, 'PsiGateDoom');
	Template.AddNarrativeTrigger("X2NarrativeMoments.S_GP_Doom_Lowered_Council_PsiGate_D", NAW_OnAssignment, 'PsiGateDoomEvent', '', ELD_OnStateSubmitted, NPC_Multiple, 'PsiGateDoom');
	Template.AddNarrativeTrigger("X2NarrativeMoments.S_GP_Doom_Lowered_Council_PsiGate_E", NAW_OnAssignment, 'PsiGateDoomEvent', '', ELD_OnStateSubmitted, NPC_Multiple, 'PsiGateDoom');
	
	// Codex
	Template.AddNarrativeTrigger("X2NarrativeMoments.S_GP_Doom_Lowered_Council_KillCodex_A", NAW_OnAssignment, 'CodexDoomEvent', '', ELD_OnStateSubmitted, NPC_Multiple, 'CodexDoom');
	Template.AddNarrativeTrigger("X2NarrativeMoments.S_GP_Doom_Lowered_Council_KillCodex_B", NAW_OnAssignment, 'CodexDoomEvent', '', ELD_OnStateSubmitted, NPC_Multiple, 'CodexDoom');
	Template.AddNarrativeTrigger("X2NarrativeMoments.S_GP_Doom_Lowered_Council_KillCodex_C", NAW_OnAssignment, 'CodexDoomEvent', '', ELD_OnStateSubmitted, NPC_Multiple, 'CodexDoom');
	Template.AddNarrativeTrigger("X2NarrativeMoments.S_GP_Doom_Lowered_Council_KillCodex_D", NAW_OnAssignment, 'CodexDoomEvent', '', ELD_OnStateSubmitted, NPC_Multiple, 'CodexDoom');
	Template.AddNarrativeTrigger("X2NarrativeMoments.S_GP_Doom_Lowered_Council_KillCodex_E", NAW_OnAssignment, 'CodexDoomEvent', '', ELD_OnStateSubmitted, NPC_Multiple, 'CodexDoom');
	
	// Avatar
	Template.AddNarrativeTrigger("X2NarrativeMoments.S_GP_Doom_Lowered_Council_KillAvatar_A", NAW_OnAssignment, 'AvatarDoomEvent', '', ELD_OnStateSubmitted, NPC_Multiple, 'AvatarDoom');
	Template.AddNarrativeTrigger("X2NarrativeMoments.S_GP_Doom_Lowered_Council_KillAvatar_B", NAW_OnAssignment, 'AvatarDoomEvent', '', ELD_OnStateSubmitted, NPC_Multiple, 'AvatarDoom');
	Template.AddNarrativeTrigger("X2NarrativeMoments.S_GP_Doom_Lowered_Council_KillAvatar_C", NAW_OnAssignment, 'AvatarDoomEvent', '', ELD_OnStateSubmitted, NPC_Multiple, 'AvatarDoom');
	Template.AddNarrativeTrigger("X2NarrativeMoments.S_GP_Doom_Lowered_Council_KillAvatar_D", NAW_OnAssignment, 'AvatarDoomEvent', '', ELD_OnStateSubmitted, NPC_Multiple, 'AvatarDoom');
	Template.AddNarrativeTrigger("X2NarrativeMoments.S_GP_Doom_Lowered_Council_KillAvatar_E", NAW_OnAssignment, 'AvatarDoomEvent', '', ELD_OnStateSubmitted, NPC_Multiple, 'AvatarDoom');


	return Template;
}

static function X2DataTemplate CreateN_CentralObjectiveAddedTemplate()
{
	local X2ObjectiveTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ObjectiveTemplate', Template, 'N_CentralObjectiveAdded');
	Template.bMainObjective = true;
	Template.bNeverShowObjective = true;

	Template.CompletionEvent = '';

	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy_New_Objective_Generic_Central_A", NAW_OnAssignment, 'NarrativeUICompleted', '', ELD_OnStateSubmitted, NPC_Multiple, 'CentralNewObjectiveLines');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy_New_Objective_Generic_Central_B", NAW_OnAssignment, 'NarrativeUICompleted', '', ELD_OnStateSubmitted, NPC_Multiple, 'CentralNewObjectiveLines');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy_New_Objective_Generic_Central_C", NAW_OnAssignment, 'NarrativeUICompleted', '', ELD_OnStateSubmitted, NPC_Multiple, 'CentralNewObjectiveLines');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy_New_Objective_Generic_Central_D", NAW_OnAssignment, 'NarrativeUICompleted', '', ELD_OnStateSubmitted, NPC_Multiple, 'CentralNewObjectiveLines');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy_New_Objective_Generic_Central_E", NAW_OnAssignment, 'NarrativeUICompleted', '', ELD_OnStateSubmitted, NPC_Multiple, 'CentralNewObjectiveLines');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy_New_Objective_Generic_Central_F", NAW_OnAssignment, 'NarrativeUICompleted', '', ELD_OnStateSubmitted, NPC_Multiple, 'CentralNewObjectiveLines');

	return Template;
}

// #######################################################################################
// -------------------- T0 OBJECTIVES ----------------------------------------------------
// #######################################################################################

// #######################################################################################
// -------------------- T0 M0 --------------------------------------------------

static function X2DataTemplate CreateT0_M0_TutorialFirstMissionTemplate()
{
	local X2ObjectiveTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ObjectiveTemplate', Template, 'T0_M0_TutorialFirstMission');
	Template.bMainObjective = true;
	Template.bNeverShowObjective = true;
	Template.bTutorialOnly = true;

	Template.NextObjectives.AddItem('T0_M1_WelcomeToLabs');
	Template.NextObjectives.AddItem('T1_M1_AlienBiotechTutorial');

	Template.AssignObjectiveFn = TutorialInitialization;
	Template.CompletionEvent = 'OnEnteredFacility_PowerCore';
	
	Template.AddNarrativeTrigger("", NAW_OnAssignment, 'PreMissionDone', '', ELD_OnStateSubmitted, NPC_Once, '', TutorialSetupInCommandersQuarters);

	return Template;
}

static function TutorialInitialization(XComGameState NewGameState, XComGameState_Objective ObjectiveState)
{
	// create golden path missions
	CreatePreplacedGoldenPathMissions(NewGameState, ObjectiveState);

	// cheat some tech values
	TutorialRushAlienBiotech(NewGameState);
	
}

static function TutorialRushAlienBiotech(XComGameState NewGameState)
{
	local XComGameStateHistory History;
	local XComGameState_Tech TechState;

	foreach NewGameState.IterateByClassType(class'XComGameState_Tech', TechState)
	{
		if(TechState.GetMyTemplateName() == 'AlienBiotech')
		{
			TechState.TimeReductionScalar = 0.8f;
			return;
		}
	}

	History = `XCOMHISTORY;

	foreach History.IterateByClassType(class'XComGameState_Tech', TechState)
	{
		if(TechState.GetMyTemplateName() == 'AlienBiotech')
		{
			TechState = XComGameState_Tech(NewGameState.ModifyStateObject(class'XComGameState_Tech', TechState.ObjectID));
			TechState.TimeReductionScalar = 0.8f;
			return;
		}
	}
}

function TutorialSetupInCommandersQuarters()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState NewGameState;
	local XComGameState_FacilityXCom FacilityState;
	local XGGeoscape Geoscape;

	History = `XCOMHISTORY;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Setup Tutorial Start");

	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	FacilityState = XComHQ.GetFacilityByName('CommandersQuarters');
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
	XComHQ.bJustWentOnFirstMission = false;

	// we direct the player to the labs, engineering during the tutorial, so we don't need the automatic direction to these facilities
	XComHQ.bHasVisitedLabs = true;
	XComHQ.bHasVisitedEngineering = true;
	//XComHQ.bHasVisitedGeoscape = true;

	// since we're skipping the post-mission flow, have to clear the post mission visible levels
	Geoscape = `GAME.GetGeoscape();
	Geoscape.m_kBase.SetAvengerCapVisibility(false);
	Geoscape.m_kBase.SetPostMissionSequenceVisibility(false);

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	// trigger the "needs attention" on the Power Core
	RequireAttentionToRoom('PowerCore', false, true);

	// We want to be in the Commander's Quarters
	FacilityState.GetMyTemplate().SelectFacilityFn(FacilityState.GetReference(), true);

	// Need to manually start needs attention VO for tutorial
	Geoscape.m_kBase.m_kAmbientVOMgr.EnableNeedsAttentionVO();

	// Autosave for start of tutorial
	`AUTOSAVEMGR.DoAutosave();

	//// TODO: force a refresh of the facility grid
	//`HQPRES.m_kFacilityGrid.OnLoseFocus();
	//`HQPRES.m_kFacilityGrid.OnReceiveFocus();
}

// #######################################################################################
// -------------------- T0 M1 --------------------------------------------------

static function X2DataTemplate CreateT0_M1_WelcomeToLabsTemplate()
{
	local X2ObjectiveTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ObjectiveTemplate', Template, 'T0_M1_WelcomeToLabs');
	Template.bMainObjective = true;
	Template.bNeverShowObjective = true;
	Template.bTutorialOnly = true;

	Template.NextObjectives.AddItem('T0_M2_WelcomeToArmory');

	Template.CompletionEvent = 'OnEnteredFacility_Hangar';
	

	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.GP_WelcomeToTheLabs", NAW_OnAssignment, '', '', ELD_OnStateSubmitted, NPC_Once, '', TutorialOpenChooseResearch);
	Template.AddNarrativeTrigger("X2NarrativeMoments.Tygan_Setup_Phase_Study_The_Chip", NAW_OnAssignment, 'OpenChooseResearch', '', ELD_OnStateSubmitted, NPC_Once, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Tygan_Support_Tech_Selected_03", NAW_OnAssignment, 'ChooseResearch', '', ELD_OnStateSubmitted, NPC_Once, '', TutorialLeaveLabs);
	Template.AddNarrativeTrigger("X2NarrativeMoments.Central_Setup_Phase_Welcome_to_Avenger_Post_Research_Central", NAW_OnAssignment, 'TutorialPostKickToBaseView', '', ELD_OnStateSubmitted, NPC_Once, '', TutorialKickToArmory);

	return Template;
}

function TutorialOpenChooseResearch()
{
	local XComHQPresentationLayer HQPres;

	HQPres = `HQPRES;

	HQPres.UIChooseResearch();
}

function TutorialLeaveLabs()
{
	local XComGameState NewGameState;
	local XComHQPresentationLayer HQPres;
	local UIFacility_PowerCore kScreen;

	HQPres = `HQPRES;

	RequireAttentionToRoom('', false, true);
	kScreen = UIFacility_PowerCore(HQPres.ScreenStack.GetScreen(class'UIFacility_PowerCore'));
	kScreen.LeaveLabs();

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Tutorial Post Kick to Base View");
	`XEVENTMGR.TriggerEvent('TutorialPostKickToBaseView', , , NewGameState);
	`GAMERULES.SubmitGameState(NewGameState);
}

function TutorialKickToArmory()
{
	// trigger the "needs attention" on the armory
	RequireAttentionToRoom('Hangar', false, true);
}

// #######################################################################################
// -------------------- T0 M2 --------------------------------------------------

static function X2DataTemplate CreateT0_M2_WelcomeToArmoryTemplate()
{
	local X2ObjectiveTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ObjectiveTemplate', Template, 'T0_M2_WelcomeToArmory');
	Template.bMainObjective = true;
	Template.bNeverShowObjective = true;
	Template.bTutorialOnly = true;

	Template.NextObjectives.AddItem('T0_M3_WelcomeToHQ');

	Template.CompletionEvent = 'WelcomeToArmoryComplete';
	
	Template.AddNarrativeTrigger("X2NarrativeMoments.Central_Setup_Phase_Armory_Promote_Jane", NAW_OnAssignment, '', '', ELD_OnStateSubmitted, NPC_Once, '');
	Template.AddNarrativeTrigger("", NAW_OnAssignment, '', '', ELD_OnStateSubmitted, NPC_Once, '', TutorialOpenViewSoldier);
	Template.AddNarrativeTrigger("X2NarrativeMoments.Central_Setup_Phase_New_Ability_Confirmed", NAW_OnAssignment, 'UnitPromoted', '', ELD_OnStateSubmitted, NPC_Once, '', DelayedKickToBridge);

	return Template;
}

function TutorialOpenViewSoldier()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComHQPresentationLayer HQPres;
	local UIFacility_Armory CurrentScreen;

	HQPres = `HQPRES;
	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
		
	CurrentScreen = UIFacility_Armory(HQPres.ScreenStack.GetCurrentScreen());
	if( CurrentScreen != none )
	{
		CurrentScreen.OnPersonnelSelected(XComHQ.TutorialSoldier);
	}
}

function DelayedKickToBridge()
{
	`HQPRES.SetTimer(1.0f, false, nameof(TutorialKickToBridge), self);
}

function TutorialKickToBridge()
{
	local XComHQPresentationLayer HQPres;
	local UIFacility_Armory CurrentScreen;
	local XComGameState NewGameState;

	HQPres = `HQPRES;
	HQPres.ScreenStack.PopUntilFirstInstanceOfClass(class'UIFacility_Armory');
	CurrentScreen = UIFacility_Armory(HQPres.ScreenStack.GetCurrentScreen());
	CurrentScreen.LeaveArmory();

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Welcome to Armory Completion Event");
	`XEVENTMGR.TriggerEvent('WelcomeToArmoryComplete', , , NewGameState);
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	// trigger the "needs attention" on the Bridge
	RequireAttentionToRoom('CIC', false, true);
}

// #######################################################################################
// -------------------- T0 M3 --------------------------------------------------

static function X2DataTemplate CreateT0_M3_WelcomeToHQTemplate()
{
	local X2ObjectiveTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ObjectiveTemplate', Template, 'T0_M3_WelcomeToHQ');
	Template.bMainObjective = true;
	Template.bNeverShowObjective = true;
	Template.bTutorialOnly = true;

	Template.NextObjectives.AddItem('T0_M4_ReturnToAvenger');

	Template.CompletionEvent = 'LaunchMissionSelected';
	Template.CompleteObjectiveFn = FlightDeviceFastForward;


	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.GP_WelcomeToHQ", NAW_OnAssignment, 'OnEnteredFacility_CIC', '', ELD_OnStateSubmitted, NPC_Once, '', TutorialKickToSquadSelect);

	return Template;
}

static function FlightDeviceFastForward(XComGameState NewGameState, XComGameState_Objective ObjectiveState)
{
	local XComGameStateHistory History;
	local XComGameState_GameTime TimeState;
	local XComGameState_MissionCalendar CalendarState;
	local TDateTime NewDate, GOpsDate;

	History = `XCOMHISTORY;
	

	CalendarState = XComGameState_MissionCalendar(History.GetSingleGameStateObjectForClass(class'XComGameState_MissionCalendar'));

	CalendarState.GetNextDateForMissionSource('MissionSource_GuerillaOp', GOpsDate);
	NewDate = GOpsDate;

	// Add buffer for LessThan Check to be true
	class'X2StrategyGameRulesetDataStructures'.static.AddTime(NewDate, 1.0f);

	`GAME.GetGeoscape().m_kDateTime = NewDate;
	`STRATEGYRULES.GameTime = NewDate;
	TimeState = XComGameState_GameTime(History.GetSingleGameStateObjectForClass(class'XComGameState_GameTime'));
	TimeState = XComGameState_GameTime(NewGameState.ModifyStateObject(class'XComGameState_GameTime', TimeState.ObjectID));
	TimeState.CurrentTime = NewDate;
}

function TutorialKickToSquadSelect()
{
	local XComGameState NewGameState;
	local array<XComGameState_Reward> Rewards;
	local XComGameState_MissionSite MissionSite;
	local XGStrategy StrategyGame;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Kick to Squad Select");

	// create the Recover Flight Device mission
	MissionSite = CreateMission(NewGameState, Rewards, 'MissionSource_RecoverFlightDevice', 0, true, true, , , , , , 'WorldRegion_SouthAS');

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	StrategyGame = `GAME;
	StrategyGame.PrepareTacticalBattle(MissionSite.ObjectID);

	// kick the user to squad select for the first recover item mission; disallow backing out
	`HQPRES.UISquadSelect(true);

	// TODO: play the VO for "The Opportunity We Need"
}



// #######################################################################################
// -------------------- T0 M4 --------------------------------------------------

static function X2DataTemplate CreateT0_M4_ReturnToAvengerTemplate()
{
	local X2ObjectiveTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ObjectiveTemplate', Template, 'T0_M4_ReturnToAvenger');
	Template.bMainObjective = true;
	Template.bNeverShowObjective = true;
	Template.bTutorialOnly = true;

	Template.NextObjectives.AddItem('T0_M5_WelcomeToEngineering');
	Template.NextObjectives.AddItem('N_AfterActionComment');
	Template.NextObjectives.AddItem('N_AfterActionCommentCouncil');

	Template.CompletionEvent = 'OnEnteredFacility_Storage';
	
	Template.AddNarrativeTrigger("X2NarrativeMoments.Central_Setup_Phase_Soldier_Walkup_Promote", NAW_OnAssignment, 'AfterActionWalkUp', '', ELD_OnStateSubmitted, NPC_Once, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Tygan_Setup_Phase_First_Loot_Screen", NAW_OnAssignment, 'PostAfterAction', '', ELD_OnStateSubmitted, NPC_Once, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.GP_ShenObtainsFlightDevice", NAW_OnAssignment, 'PostMissionDone', '', ELD_OnStateSubmitted, NPC_Once, '', TutorialKickToEngineering);

	return Template;
}

function TutorialKickToEngineering()
{
	// trigger the "needs attention" on the armory
	RequireAttentionToRoom('Storage', false, true);
}

// #######################################################################################
// -------------------- T0 M5 --------------------------------------------------

static function X2DataTemplate CreateT0_M5_WelcomeToEngineeringTemplate()
{
	local X2ObjectiveTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ObjectiveTemplate', Template, 'T0_M5_WelcomeToEngineering');
	Template.bMainObjective = true;
	Template.bNeverShowObjective = true;
	Template.bTutorialOnly = true;

	Template.NextObjectives.AddItem('T0_M5_EquipMedikit');
	Template.NextObjectives.AddItem('T0_M6_WelcomeToLabsPt2');

	Template.CompleteObjectiveFn = TutorialFinishAlienBiotech;
	Template.CompletionEvent = 'TutorialPostKickToBaseView';

	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.GP_WelcomeToStorageEngineering", NAW_OnAssignment, '', '', ELD_OnStateSubmitted, NPC_Once, '', TutorialOpenBuildItems);
	Template.AddNarrativeTrigger("X2NarrativeMoments.Shen_Build_This_Item_Engineering_Tutorial", NAW_OnAssignment, 'OpenBuildItems', '', ELD_OnStateSubmitted, NPC_Once, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Shen_Item_Selected_Engineering_Tutorial", NAW_OnAssignment, 'ItemConstructionCompleted', '', ELD_OnStateSubmitted, NPC_Once, '', TutorialLeaveEngineering);
	Template.AddNarrativeTrigger("X2NarrativeMoments.S_Setup_Phase_Lab_Transition_Central", NAW_OnCompletion, '', '', ELD_OnStateSubmitted, NPC_Once, '');

	return Template;
}

static function TutorialFinishAlienBiotech(XComGameState NewGameState, XComGameState_Objective ObjectiveState)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_HeadquartersProjectResearch ResearchProject;
	local XComGameState_Tech TechState;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));

	foreach History.IterateByClassType(class'XComGameState_HeadquartersProjectResearch', ResearchProject)
	{
		break;
	}

	TechState = XComGameState_Tech(NewGameState.ModifyStateObject(class'XComGameState_Tech', ResearchProject.ProjectFocus.ObjectID));

	XComHQ.TechsResearched.AddItem(TechState.GetReference());
	XComHQ.Projects.RemoveItem(ResearchProject.GetReference());
	NewGameState.RemoveStateObject(ResearchProject.ObjectID);

	TechState.TimesResearched++;
	TechState.TimeReductionScalar = 0;
	TechState.CompletionTime = `STRATEGYRULES.GameTime;
	TechState.OnResearchCompleted(NewGameState);
	`XEVENTMGR.TriggerEvent('ResearchCompleted', TechState, TechState, NewGameState);
}

function TutorialOpenBuildItems()
{
	local XComHQPresentationLayer HQPres;
	local UIFacility_Storage CurrentScreen;

	HQPres = `HQPRES;

	CurrentScreen = UIFacility_Storage(HQPres.ScreenStack.GetCurrentScreen());
	if( CurrentScreen != none )
	{
		HQPres.UIBuildItem();
	}
}

function TutorialLeaveEngineering()
{
	local XComGameState NewGameState;
	local XComHQPresentationLayer HQPres;
	local UIFacility_Storage kScreen;

	HQPres = `HQPRES;

	RequireAttentionToRoom('PowerCore', false, true);
	kScreen = UIFacility_Storage(HQPres.ScreenStack.GetScreen(class'UIFacility_Storage'));
	kScreen.TutorialForceExit();

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Tutorial Post Kick to Base View");
	`XEVENTMGR.TriggerEvent('TutorialPostKickToBaseView', , , NewGameState);
	`GAMERULES.SubmitGameState(NewGameState);
}

static function X2DataTemplate CreateT0_M5_EquipMedikitTemplate()
{
	local X2ObjectiveTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ObjectiveTemplate', Template, 'T0_M5_EquipMedikit');
	Template.bMainObjective = true;
	Template.bNeverShowObjective = true;
	Template.bTutorialOnly = true;

	Template.CompletionEvent = 'TutorialItemEquipped';

	Template.AddNarrativeTrigger("X2NarrativeMoments.Central_Equip_New_Item_SquadSelect_Engineering_Tutorial", NAW_OnReveal, 'EnterSquadSelect', '', ELD_OnStateSubmitted, NPC_Once, '');

	return Template;
}

// #######################################################################################
// -------------------- T0 M6 --------------------------------------------------

static function X2DataTemplate CreateT0_M6_WelcomeToLabsPt2Template()
{
	local X2ObjectiveTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ObjectiveTemplate', Template, 'T0_M6_WelcomeToLabsPt2');
	Template.bMainObjective = true;
	Template.bNeverShowObjective = true;
	Template.bTutorialOnly = true;

	Template.NextObjectives.AddItem('N_ChooseResearch');
	Template.NextObjectives.AddItem('T0_M7_WelcomeToGeoscape');

	Template.CompletionEvent = 'WelcomeLabsPt2Complete';
	
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Tygan_Support_First_Tech_Selected", NAW_OnAssignment, 'ChooseResearch', '', ELD_OnStateSubmitted, NPC_Once, '', TutorialFinishWelcomeLabsPt2);
	Template.AddNarrativeTrigger("X2NarrativeMoments.S_GP_Flight_Device_Bridge_Transition_Central", NAW_OnCompletion, '', '', ELD_OnStateSubmitted, NPC_Once, '');

	return Template;
}

function TutorialFinishWelcomeLabsPt2()
{
	local XComGameState NewGameState;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Tutorial Welcome Labs Pt 2 Complete");
	`XEVENTMGR.TriggerEvent('WelcomeLabsPt2Complete', , , NewGameState);
	`GAMERULES.SubmitGameState(NewGameState);

	// trigger the "needs attention" on the CIC
	RequireAttentionToRoom('CIC', false, false, true);
}

// #######################################################################################
// -------------------- T0 M7 --------------------------------------------------

static function X2DataTemplate CreateT0_M7_WelcomeToGeoscapeTemplate()
{
	local X2ObjectiveTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ObjectiveTemplate', Template, 'T0_M7_WelcomeToGeoscape');
	Template.bMainObjective = true;
	Template.bNeverShowObjective = true;
	Template.bTutorialOnly = true;

	Template.NextObjectives.AddItem('T0_M8_ReturnToAvengerPt2');
	Template.NextObjectives.AddItem('N_InDropPosition');

	Template.CompletionEvent = 'LaunchMissionSelected';
	
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.GP_FirstFlight", NAW_OnAssignment, 'OnEnteredFacility_CIC', '', ELD_OnStateSubmitted, NPC_Once, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Central_Setup_Phase_Geoscape_First_GOP", NAW_OnAssignment, 'OnGOpsPopup', '', ELD_OnStateSubmitted, NPC_Once, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Central_Setup_Phase_First_Geoscape_Ready_Deploy", NAW_OnAssignment, 'OnSkyrangerArrives', '', ELD_OnStateSubmitted, NPC_Once, '');

	return Template;
}

// #######################################################################################
// -------------------- T0 M8 --------------------------------------------------

static function X2DataTemplate CreateT0_M8_ReturnToAvengerPt2Template()
{
	local X2ObjectiveTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ObjectiveTemplate', Template, 'T0_M8_ReturnToAvengerPt2');
	Template.bMainObjective = true;
	Template.bNeverShowObjective = true;
	Template.bTutorialOnly = true;

	Template.NextObjectives.AddItem('T0_M9_ExcavateRoom');
	Template.CompleteObjectiveFn = TutorialActivateResistance;
	Template.CompletionEvent = 'PostMissionDone';

	Template.AddNarrativeTrigger("", NAW_OnCompletion, '', '', ELD_OnStateSubmitted, NPC_Once, '', TutorialExcavateHighlight);

	return Template;
}

static function TutorialActivateResistance(XComGameState NewGameState, XComGameState_Objective ObjectiveState)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersResistance ResistanceHQ;

	History = `XCOMHISTORY;
	ResistanceHQ = XComGameState_HeadquartersResistance(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersResistance'));
	ResistanceHQ = XComGameState_HeadquartersResistance(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersResistance', ResistanceHQ.ObjectID));

	ResistanceHQ.bInactive = false;
}

function TutorialExcavateHighlight()
{
	RequireAttentionToRoom('', false, true, false, class'XComGameState_HeadquartersXCom'.default.TutorialExcavateIndex);
}

// #######################################################################################
// -------------------- T0 M9 --------------------------------------------------

static function X2DataTemplate CreateT0_M9_ExcavateRoomTemplate()
{
	local X2ObjectiveTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ObjectiveTemplate', Template, 'T0_M9_ExcavateRoom');
	Template.bMainObjective = true;
	Template.bNeverShowObjective = true;
	Template.bTutorialOnly = true;

	Template.NextObjectives.AddItem('T0_M10_IntroToBlacksite');
	Template.NextObjectives.AddItem('T0_M10_L0_FirstTimeScan');
	Template.CompletionEvent = 'WelcomeToResistanceComplete';

	Template.AddNarrativeTrigger("X2NarrativeMoments.Shen_Setup_Phase_Start_Excavation", NAW_OnAssignment, 'StaffAdded', 'Engineer', ELD_OnStateSubmitted, NPC_Once, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Shen_Setup_Phase_How_To_Excavate", NAW_OnAssignment, 'OnEnteredRoom_SpecialRoomFeature_AlienDebris', '', ELD_OnStateSubmitted, NPC_Once, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Shen_Setup_Phase_Excavation_Staff_Confirmed", NAW_OnAssignment, 'OnStaffSelected', '', ELD_OnStateSubmitted, NPC_Once, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Shen_Setup_Phase_Excavation_Underway", NAW_OnAssignment, 'ExcavationStarted', '', ELD_OnStateSubmitted, NPC_Once, '', TriggerCentralWelcomeRes);
	Template.AddNarrativeTrigger("X2NarrativeMoments.Central_Welcome_Resistance_Incoming_Trans", NAW_OnAssignment, 'TutorialCentralWelcomeRes', '', ELD_OnStateSubmitted, NPC_Once, '', TutorialKickToCommandersQuarters);
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.GP_WelcomeToTheResistance", NAW_OnAssignment, 'OnEnteredFacility_CommandersQuarters', '', ELD_OnStateSubmitted, NPC_Once, '', WelcomeToTheResistanceCompleteTutorial);
	Template.AddNarrativeTrigger("X2NarrativeMoments.Central_Wild_Central_04", NAW_OnCompletion, '', '', ELD_OnStateSubmitted, NPC_Once, '');

	return Template;
}

function TriggerCentralWelcomeRes()
{
	local XComGameState NewGameState;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Tutorial Central Welcome to Resistance");
	`XEVENTMGR.TriggerEvent('TutorialCentralWelcomeRes', , , NewGameState);
	`GAMERULES.SubmitGameState(NewGameState);
}

function TutorialKickToCommandersQuarters()
{
	RequireAttentionToRoom('CommandersQuarters', true, true);
}

function WelcomeToTheResistanceCompleteTutorial()
{
	local XComGameState NewGameState;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Tutorial Welcome to Resistance Complete");
	`XEVENTMGR.TriggerEvent('WelcomeToResistanceComplete', , , NewGameState);
	`GAMERULES.SubmitGameState(NewGameState);

	RequireAttentionToRoom('CIC', true, true);
}

// #######################################################################################
// -------------------- T0 M10 --------------------------------------------------

static function X2DataTemplate CreateT0_M10_IntroToBlacksiteTemplate()
{
	local X2ObjectiveTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ObjectiveTemplate', Template, 'T0_M10_IntroToBlacksite');
	Template.bMainObjective = true;
	Template.bNeverShowObjective = true;
	Template.bTutorialOnly = true;

	Template.NextObjectives.AddItem('T0_M10_S1_WaitForResComms');
	Template.NextObjectives.AddItem('N_CentralObjectiveAdded');
	Template.CompletionEvent = 'AvengerLandedScanPOI';
	Template.CompleteObjectiveFn = FlagTutorialCompleted;

	Template.AddNarrativeTrigger("", NAW_OnAssignment, 'OnEnteredFacility_CIC', '', ELD_OnStateSubmitted, NPC_Once, '', EnableFlightMode);
	Template.AddNarrativeTrigger("XPACK_NarrativeMoments.X2_XP_CEN_S_Reapers_Contact_Soon", NAW_OnAssignment, 'OnGeoscapeEntry', '', ELD_OnStateSubmitted, NPC_Once, '', CameraLookAtBlacksite);
	Template.AddNarrativeTrigger("X2NarrativeMoments.Central_Setup_Phase_Geoscape_Blacksite_Focus", NAW_OnAssignment, 'CameraAtBlacksite', '', ELD_OnStateSubmitted, NPC_Once, '', CameraLookAtAvenger);
	Template.AddNarrativeTrigger("X2NarrativeMoments.Central_Setup_Phase_Geoscape_Avenger_Focus", NAW_OnAssignment, 'CameraAtAvenger', '', ELD_OnStateSubmitted, NPC_Once, '', ShowBlacksiteScreen);
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.GP_ContactBlacksiteRegionScreen", NAW_OnAssignment, 'ShowBlacksiteScreen', '', ELD_OnStateSubmitted, NPC_Once, '');
	Template.AddNarrativeTrigger("", NAW_OnAssignment, 'NarrativeUICompleted', '', ELD_OnStateSubmitted, NPC_Once, '', RevealObjectives);
	Template.AddNarrativeTrigger("X2NarrativeMoments.Central_Setup_Phase_Geoscape_Objectives_Appear", NAW_OnAssignment, 'ObjectivesRevealed', '', ELD_OnStateSubmitted, NPC_Once, '', RevealPOI);
	Template.AddNarrativeTrigger("X2NarrativeMoments.Central_Setup_Phase_Pass_Time_Geoscape_Specific_Alt", NAW_OnAssignment, 'AvengerLandedScanPOI', '', ELD_OnStateSubmitted, NPC_Once, '', TutorialUnlockAllRooms);
	
	return Template;
}

static function X2DataTemplate CreateT0_M10_S1_WaitForResCommsTemplate()
{
	local X2ObjectiveTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ObjectiveTemplate', Template, 'T0_M10_S1_WaitForResComms');
	Template.bMainObjective = true;
	Template.bNeverShowObjective = true;
	Template.bTutorialOnly = true;

	Template.NextObjectives.AddItem('T0_M11_IntroToResComms');
	Template.NextObjectives.AddItem('T0_M11_S1_WaitForRadioRelays');

	Template.CompletionRequirements.RequiredTechs.AddItem('ResistanceCommunications');
	Template.CompletionEvent = 'ResearchCompleted';

	return Template;
}

static function X2DataTemplate CreateT0_M10_L0_FirstTimeScanTemplate()
{
	local X2ObjectiveTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ObjectiveTemplate', Template, 'T0_M10_L0_FirstTimeScan');
	Template.bMainObjective = true;
	Template.bNeverShowObjective = true;
	Template.bTutorialOnly = true;

	Template.CompletionEvent = 'ScanStarted';

	return Template;
}

function CameraLookAtAvenger()
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	
	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	`HQPRES.CAMLookAtEarth(XComHQ.Get2DLocation(), 0.5f);

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Tutorial Cam Look at Avenger");
	`XEVENTMGR.TriggerEvent('CameraAtAvenger', , , NewGameState);
	`GAMERULES.SubmitGameState(NewGameState);
}

function CameraLookAtBlacksite()
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_MissionSite MissionState;

	History = `XCOMHISTORY;
	foreach History.IterateByClassType(class'XComGameState_MissionSite', MissionState)
	{
		if (MissionState.GetMissionSource().DataName == 'MissionSource_Blacksite')
		{
			break;
		}
	}

	`HQPRES.CAMLookAtEarth(MissionState.Get2DLocation(), 0.5f);

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Tutorial Cam Look at Blacksite");
	`XEVENTMGR.TriggerEvent('CameraAtBlacksite', , , NewGameState);
	`GAMERULES.SubmitGameState(NewGameState);
}

function ShowBlacksiteScreen()
{
	local XComGameState NewGameState;
	
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Tutorial Show Blacksite Screen");
	`XEVENTMGR.TriggerEvent('ShowBlacksiteScreen', , , NewGameState);
	`GAMERULES.SubmitGameState(NewGameState);
}

function RevealObjectives()
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;

	XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	// Enable objective display
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Tutorial Reveal Objectives");	
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
	XComHQ.bBlockObjectiveDisplay = false;
	`XEVENTMGR.TriggerEvent('ObjectivesRevealed', , , NewGameState);
	`GAMERULES.SubmitGameState(NewGameState);

	class'X2StrategyGameRulesetDataStructures'.static.ForceUpdateObjectivesUI();	
}

function RevealPOI()
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_PointOfInterest POIState;

	History = `XCOMHISTORY;
	foreach History.IterateByClassType(class'XComGameState_PointOfInterest', POIState)
	{
		if (POIState.bTriggerAppearedPopup)
		{
			break;
		}
	}

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Tutorial Reveal POI");
	POIState = XComGameState_PointOfInterest(NewGameState.ModifyStateObject(class'XComGameState_PointOfInterest', POIState.ObjectID));
	POIState.bAvailable = true;
	POIState.bTriggerAppearedPopup = false;
	POIState.bNeedsAppearedPopup = false;
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	`HQPRES.UIPointOfInterestAlert(POIState.GetReference());
}

function TutorialUnlockAllRooms()
{
	DisableFlightMode();

	// Unlock all rooms, player has access to full game now
	RequireAttentionToRoom('', false, false, false);
}

function EnableFlightMode()
{
	`HQPRES.m_bEnableFlightModeAfterStrategyMapEnter = true; // Set Flight Mode to switch on as soon as transition into Geoscape is complete
}

function SetFlightModeTutorial()
{
	local XComGameState NewGameState;
	
	`HQPRES.StrategyMap2D.SetUIState(eSMS_Flight); // Turn on flight mode immediately. Will not work if not in the Geoscape.

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Tutorial On Flight Mode Activated");
	`XEVENTMGR.TriggerEvent('OnFlightModeActivatedTutorial', , , NewGameState);
	`GAMERULES.SubmitGameState(NewGameState);
}

function DisableFlightMode()
{
	`HQPRES.StrategyMap2D.SetUIState(eSMS_Default);
}

static function FlagTutorialCompleted(XComGameState NewGameState, XComGameState_Objective ObjectiveState)
{
	if (`XPROFILESETTINGS.Data.m_bPlayerHasUncheckedBoxTutorialSetting == false)
	{
		`XPROFILESETTINGS.Data.m_bPlayerHasUncheckedBoxTutorialSetting = true; //Only allow this to be activate for this profile, never toggled back. 
		`ONLINEEVENTMGR.SaveProfileSettings(true);
	}
}

// #######################################################################################
// -------------------- T0 M11 --------------------------------------------------

static function X2DataTemplate CreateT0_M11_IntroToResCommsTemplate()
{
	local X2ObjectiveTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ObjectiveTemplate', Template, 'T0_M11_IntroToResComms');
	Template.bMainObjective = true;
	Template.bNeverShowObjective = true;
	Template.bTutorialOnly = true;

	Template.CompletionEvent = 'CameraAtBlacksite';

	Template.AddNarrativeTrigger("", NAW_OnAssignment, 'OnEnteredFacility_CIC', '', ELD_OnStateSubmitted, NPC_Once, '', EnableFlightMode);
	Template.AddNarrativeTrigger("X2NarrativeMoments.Central_Setup_Phase_Resistance_Comms_Bridge_Matinee", NAW_OnAssignment, 'OnGeoscapeEntry', '', ELD_OnStateSubmitted, NPC_Once, '', UnlockNormalRegion);
	Template.AddNarrativeTrigger("", NAW_OnAssignment, 'RegionUnlocked', '', ELD_OnStateSubmitted, NPC_Once, '', UnlockBlacksiteRegion);
	Template.AddNarrativeTrigger("", NAW_OnAssignment, 'BlacksiteRegionUnlocked', '', ELD_OnStateSubmitted, NPC_Once, '', CameraLookAtBlacksite);
	Template.AddNarrativeTrigger("X2NarrativeMoments.Central_Setup_Phase_Geoscape_Blacksite_Region_Focus", NAW_OnAssignment, 'CameraAtBlacksite', '', ELD_OnStateSubmitted, NPC_Once, '', DisableFlightMode);

	// Backup triggers in case the player cancels the Research Complete popup
	Template.AddNarrativeTrigger("", NAW_OnAssignment, 'OnResearchCompletePopupClosed', '', ELD_OnStateSubmitted, NPC_Once, '', SetFlightModeTutorial);
	Template.AddNarrativeTrigger("X2NarrativeMoments.Central_Setup_Phase_Resistance_Comms_Bridge_Matinee", NAW_OnAssignment, 'OnFlightModeActivatedTutorial', '', ELD_OnStateSubmitted, NPC_Once, '', UnlockNormalRegion);
	
	return Template;
}

static function X2DataTemplate CreateT0_M11_S1_WaitForRadioRelaysTemplate()
{
	local X2ObjectiveTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ObjectiveTemplate', Template, 'T0_M11_S1_WaitForRadioRelays');
	Template.bMainObjective = true;
	Template.bNeverShowObjective = true;
	Template.bTutorialOnly = true;

	Template.NextObjectives.AddItem('T0_M12_IntroToRadioRelays');
	Template.CompletionRequirements.RequiredTechs.AddItem('ResistanceRadio');
	Template.CompletionEvent = 'ResearchCompleted';

	return Template;
}

function UnlockNormalRegion()
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_WorldRegion RegionState;
	local XComGameState_MissionSite MissionState;
	local bool bRegionFound;

	History = `XCOMHISTORY;
	
	foreach History.IterateByClassType(class'XComGameState_MissionSite', MissionState)
	{
		if (MissionState.GetMissionSource().DataName == 'MissionSource_Blacksite')
		{
			foreach History.IterateByClassType(class'XComGameState_WorldRegion', RegionState)
			{
				if (RegionState.bUnlockedPopup && RegionState.GetReference() != MissionState.Region)
				{
					bRegionFound = true;
					break;
				}
			}
		}
	}

	// If a non-Blacksite region is not found to unlock, trigger the unlock event so the tutorial sequence can continue
	if (!bRegionFound)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Region Unlocked");
		`XEVENTMGR.TriggerEvent('RegionUnlocked', , , NewGameState);
		`GAMERULES.SubmitGameState(NewGameState);
	}
	else
	{
		RegionState.UnlockPopup();
	}
}

function UnlockBlacksiteRegion()
{
	local XComGameStateHistory History;
	local XComGameState_MissionSite MissionState;

	History = `XCOMHISTORY;
	
	foreach History.IterateByClassType(class'XComGameState_MissionSite', MissionState)
	{
		if (MissionState.GetMissionSource().DataName == 'MissionSource_Blacksite' &&
			MissionState.GetWorldRegion().bUnlockedPopup)
		{
			break;
		}
	}

	MissionState.GetWorldRegion().UnlockPopup();
}

// #######################################################################################
// -------------------- T0 M12 --------------------------------------------------

static function X2DataTemplate CreateT0_M12_IntroToRadioRelaysTemplate()
{
	local X2ObjectiveTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ObjectiveTemplate', Template, 'T0_M12_IntroToRadioRelays');
	Template.bMainObjective = true;
	Template.bNeverShowObjective = true;
	Template.bTutorialOnly = true;
	
	Template.CompletionEvent = 'OnIntroToRadioRelaysComplete';

	Template.AddNarrativeTrigger("", NAW_OnAssignment, 'OnEnteredFacility_CIC', '', ELD_OnStateSubmitted, NPC_Once, '', EnableFlightMode);
	Template.AddNarrativeTrigger("X2NarrativeMoments.Tygan_Setup_Phase_Geoscape_Build_Radio_Relays_To_Reduce_Costs", NAW_OnAssignment, 'OnGeoscapeEntry', '', ELD_OnStateSubmitted, NPC_Once, '', CompleteIntroToRadioRelaysTutorial);

	// Backup triggers in case the player cancels the Research Complete popup
	Template.AddNarrativeTrigger("", NAW_OnAssignment, 'OnResearchCompletePopupClosed', '', ELD_OnStateSubmitted, NPC_Once, '', SetFlightModeTutorial);
	Template.AddNarrativeTrigger("X2NarrativeMoments.Tygan_Setup_Phase_Geoscape_Build_Radio_Relays_To_Reduce_Costs", NAW_OnAssignment, 'OnFlightModeActivatedTutorial', '', ELD_OnStateSubmitted, NPC_Once, '', CompleteIntroToRadioRelaysTutorial);
	
	return Template;
}

function CompleteIntroToRadioRelaysTutorial()
{
	local XComGameState NewGameState;

	DisableFlightMode();

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Trigger Event: Completed Intro to Radio Relays Tutorial");
	`XEVENTMGR.TriggerEvent('OnIntroToRadioRelaysComplete', , , NewGameState);
	`GAMERULES.SubmitGameState(NewGameState);
}

// #######################################################################################
// -------------------- T1 OBJECTIVES --------------------------------------------------
// #######################################################################################

// #######################################################################################
// -------------------- T1 M0 --------------------------------------------------

static function X2DataTemplate CreateT1_M0_FirstMissionTemplate()
{
	local X2ObjectiveTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ObjectiveTemplate', Template, 'T1_M0_FirstMission');
	Template.bMainObjective = true;

	Template.NextObjectives.AddItem('N_ChooseFirstResearch');
	Template.NextObjectives.AddItem('N_MakingContactAvailable');
	Template.NextObjectives.AddItem('N_RadioRelaysAvailable');
	Template.NextObjectives.AddItem('N_AfterActionComment');
	Template.NextObjectives.AddItem('N_AfterActionCommentCouncil');
	Template.NextObjectives.AddItem('T2_M0_L0_BlacksiteReveal');
	Template.NextObjectives.AddItem('N_InDropPosition');
	Template.NextObjectives.AddItem('S1_ShortenFirstPOI');
	Template.NextObjectives.AddItem('N_CentralObjectiveAdded');
	Template.NextObjectives.AddItem('T1_M1_AlienBiotech');

	Template.AssignObjectiveFn = CreatePreplacedGoldenPathMissions;
	Template.CompleteObjectiveFn = FirstMissionComplete;
	Template.CompletionEvent = 'PreMissionDone';
	
	Template.bNeverShowObjective = true;
	
	// Narrative Moments for welcome to Avenger, Labs, Engineering, Resistance, etc.
	// Don't play the game intro as this is taken care of by the loading movie	
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.GP_WelcomeToTheLabsShort", NAW_OnCompletion, 'OnEnteredFacility_PowerCore', '', ELD_OnStateSubmitted, NPC_Once, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.GP_WelcomeToStorageEngineering", NAW_OnCompletion, 'OnEnteredFacility_Storage', '', ELD_OnStateSubmitted, NPC_Once, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.GP_WelcomeToHQ_NS", NAW_OnCompletion, 'OnEnteredFacility_CIC', '', ELD_OnStateSubmitted, NPC_Once, '');

	return Template;
}

static function CreatePreplacedGoldenPathMissions(XComGameState NewGameState, XComGameState_Objective ObjectiveState)
{
	CreateBlacksiteMission(NewGameState);
	CreateForgeAndPsiGateMissions(NewGameState);
	CreateFortressMission(NewGameState);

	// With missions now placed home regions for Chosen and Factions can be assigned
	AssignFactionAndChosenHomeRegions(NewGameState);
}

static function AssignFactionAndChosenHomeRegions(XComGameState NewGameState)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersResistance ResHQ;
	local XComGameState_HeadquartersAlien AlienHQ;

	History = `XCOMHISTORY;

	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));
	AlienHQ = XComGameState_HeadquartersAlien(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersAlien', AlienHQ.ObjectID));
	AlienHQ.SetChosenHomeAndTerritoryRegions(NewGameState);

	ResHQ = XComGameState_HeadquartersResistance(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersResistance'));
	ResHQ = XComGameState_HeadquartersResistance(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersResistance', ResHQ.ObjectID));
	ResHQ.SetFactionHomeRegions(NewGameState);
}

static function CreateForgeAndPsiGateMissions(XComGameState NewGameState)
{
	local XComGameState_MissionSite MissionState;
	local XComGameState_WorldRegion RegionState;
	local array<XComGameState_Reward> Rewards;
	local X2StrategyElementTemplateManager StratMgr;
	local X2RewardTemplate RewardTemplate;
	local XComGameState_Reward RewardState;
	local XComGameState_Continent ContinentState;

	StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
	RewardTemplate = X2RewardTemplate(StratMgr.FindStrategyElementTemplate('Reward_Supplies'));
	RewardState = RewardTemplate.CreateInstanceFromTemplate(NewGameState);
	RewardState.SetReward(, GetPsiGateForgeSupplyAmount());
	Rewards.AddItem(RewardState);

	MissionState = CreateMission(NewGameState, Rewards, 'MissionSource_Forge', 3, false, false, false);
	RegionState = XComGameState_WorldRegion(NewGameState.GetGameStateForObjectID(MissionState.Region.ObjectID));

	if(RegionState == none)
	{
		RegionState = MissionState.GetWorldRegion();
	}

	ContinentState = XComGameState_Continent(NewGameState.GetGameStateForObjectID(RegionState.Continent.ObjectID));

	if(ContinentState == none)
	{
		ContinentState = RegionState.GetContinent();
	}

	Rewards.Length = 0;
	RewardState = RewardTemplate.CreateInstanceFromTemplate(NewGameState);
	RewardState.SetReward(, GetPsiGateForgeSupplyAmount());
	Rewards.AddItem(RewardState);

	CreateMission(NewGameState, Rewards, 'MissionSource_PsiGate', 4, false, false, false, RegionState, 4, , , , ContinentState);
}

static function CreateFortressMission(XComGameState NewGameState)
{
	local array<XComGameState_Reward> Rewards;

	CreateMission(NewGameState, Rewards, 'MissionSource_Final', 0, false, true, false, , , true, default.FortressLocation);
}

static function FirstMissionComplete(XComGameState NewGameState, XComGameState_Objective ObjectiveState)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_FacilityXCom PowerCore;
	local int idx;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
	XComHQ.bJustWentOnFirstMission = false;

	for( idx = 0; idx < XComHQ.Facilities.Length; idx++ )
	{
		PowerCore = XComGameState_FacilityXCom(History.GetGameStateForObjectID(XComHQ.Facilities[idx].ObjectID));

		if( PowerCore.GetMyTemplateName() == 'PowerCore' )
		{
			PowerCore = XComGameState_FacilityXCom(NewGameState.ModifyStateObject(class'XComGameState_FacilityXCom', PowerCore.ObjectID));
			PowerCore.TriggerNeedsAttention();
		}
	}
	`HQPRES.m_kFacilityGrid.UpdateData();
}

// #######################################################################################
// -------------------- T1 M1 --------------------------------------------------

static function X2DataTemplate CreateT1_M1_AlienBiotechTemplate()
{
	local X2ObjectiveTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ObjectiveTemplate', Template, 'T1_M1_AlienBiotech');
	Template.bMainObjective = true;
	Template.bNeverShowObjective = true;

	Template.NextObjectives.AddItem('T1_M1_AutopsyACaptain');

	Template.CompletionRequirements.RequiredTechs.AddItem('AlienBiotech');
	Template.CompletionEvent = 'ResearchCompleted';

	Template.NagDelayHours = 336;
		
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Tygan_Support_Reminder_Alien_Biotech", NAW_OnNag, 'OnEnteredFacility_PowerCore', '', ELD_OnStateSubmitted, NPC_Multiple, '');

	return Template;
}

static function X2DataTemplate CreateT1_M1_AutopsyACaptainTemplate()
{
	local X2ObjectiveTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ObjectiveTemplate', Template, 'T1_M1_AutopsyACaptain');
	Template.bMainObjective = true;
	Template.ImagePath = "img:///UILibrary_StrategyImages.ResearchTech.GOLDTECH_Advent_Officer";

	Template.NextObjectives.AddItem('T1_M2_HackACaptain');

	Template.CompletionRequirements.RequiredTechs.AddItem('AutopsyAdventOfficer');
	Template.CompletionEvent = 'ResearchCompleted';
	Template.RevealEvent = '';

	Template.NagDelayHours = 336;

	Template.InProgressFn = CaptainAutopsyInProgress;

	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.GP_WelcomeToTheLabsPt2", NAW_OnReveal, '', '', ELD_OnStateSubmitted, NPC_Once, '', JumpToPowerCore);
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.GP_CaptainAutopsyScreen", NAW_OnReveal, 'OnEnteredFacility_PowerCore', '', ELD_OnStateSubmitted, NPC_Once, '', ShowResearchReport);
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.GP_CaptainAutopsy_Tygan", NAW_OnReveal, 'UniqueNarrativeUICompleted', '', ELD_OnStateSubmitted, NPC_Once, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.GP_CaptainAutopsyReminder_Tygan", NAW_OnNag, 'OnEnteredFacility_PowerCore', '', ELD_OnStateSubmitted, NPC_Multiple, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.GP_PsiNetwork", NAW_OnCompletion, '', '', ELD_OnStateSubmitted, NPC_Once, '', JumpToPowerCore);

	return Template;
}

function JumpToPowerCore()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_FacilityXCom FacilityState;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	FacilityState = XComHQ.GetFacilityByName('PowerCore');
	FacilityState.GetMyTemplate().SelectFacilityFn(FacilityState.GetReference());
}

static function X2DataTemplate CreateT1_M1_AlienBiotechTutorialTemplate()
{
	local X2ObjectiveTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ObjectiveTemplate', Template, 'T1_M1_AlienBiotechTutorial');
	Template.bMainObjective = true;
	Template.bNeverShowObjective = true;
	Template.bTutorialOnly = true;

	Template.NextObjectives.AddItem('T1_M1_AutopsyACaptainTutorial');

	Template.CompletionRequirements.RequiredTechs.AddItem('AlienBiotech');
	Template.CompletionEvent = 'ResearchCompleted';

	Template.NagDelayHours = 336;

	return Template;
}

static function X2DataTemplate CreateT1_M1_AutopsyACaptainTutorialTemplate()
{
	local X2ObjectiveTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ObjectiveTemplate', Template, 'T1_M1_AutopsyACaptainTutorial');
	Template.bMainObjective = true;
	Template.bTutorialOnly = true;
	Template.ImagePath = "img:///UILibrary_StrategyImages.ResearchTech.GOLDTECH_Advent_Officer";

	Template.NextObjectives.AddItem('T1_M2_HackACaptain');

	Template.CompletionRequirements.RequiredTechs.AddItem('AutopsyAdventOfficer');
	Template.CompletionEvent = 'ResearchCompleted';
	Template.RevealEvent = 'OnEnteredFacility_PowerCore';

	Template.NagDelayHours = 336;

	Template.InProgressFn = CaptainAutopsyInProgress;

	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.GP_WelcomeToTheLabsPt2", NAW_OnReveal, '', '', ELD_OnStateSubmitted, NPC_Once, '', CinematicComplete);
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.GP_CaptainAutopsyScreen", NAW_OnReveal, 'CinematicComplete', '', ELD_OnStateSubmitted, NPC_Once, '', ShowResearchReport);
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.GP_CaptainAutopsy_Tygan", NAW_OnReveal, 'UniqueNarrativeUICompleted', '', ELD_OnStateSubmitted, NPC_Once, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.GP_CaptainAutopsyReminder_Tygan", NAW_OnNag, 'OnEnteredFacility_PowerCore', '', ELD_OnStateSubmitted, NPC_Multiple, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.GP_PsiNetwork", NAW_OnCompletion, '', '', ELD_OnStateSubmitted, NPC_Once, '', JumpToPowerCore);

	return Template;
}

function CinematicComplete()
{
	local XComGameState NewGameState;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Trigger Cinematic Complete Event");
	`XEVENTMGR.TriggerEvent('CinematicComplete', , , NewGameState);
	`GAMERULES.SubmitGameState(NewGameState);
}

static function bool CaptainAutopsyInProgress()
{
	return ResearchInProgress('AutopsyAdventOfficer');
}

function ShowResearchReport()
{
	local UIFacility_Powercore kScreen;

	kScreen = UIFacility_PowerCore(`HQPRES.ScreenStack.GetScreen(class'UIFacility_PowerCore'));
	kScreen.TriggerResearchReport();
}

// #######################################################################################
// -------------------- T1 M2 --------------------------------------------------

static function X2DataTemplate CreateT1_M2_HackACaptainTemplate()
{
	local X2ObjectiveTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ObjectiveTemplate', Template, 'T1_M2_HackACaptain');
	Template.bMainObjective = true;
	Template.ImagePath = "img:///UILibrary_StrategyImages.X2StrategyMap.Alert_SkullJack_AdventOfficer";

	Template.Steps.AddItem('T1_M2_S1_BuildProvingGrounds');
	Template.Steps.AddItem('T1_M2_S2_BuildSKULLJACK');
	Template.Steps.AddItem('T1_M2_S3_SKULLJACKCaptain');

	Template.NextObjectives.AddItem('T1_M3_KillCodex');

	Template.CompletionEvent = ''; // completed via children objectives
	

	 // no nag, this objective functions as a container for its subobjectives

	// no narrative triggers

	return Template;
}

// -------------------- T1 M2 S1 --------------------------------------------------

static function X2DataTemplate CreateT1_M2_S1_BuildProvingGroundsTemplate()
{
	local X2ObjectiveTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ObjectiveTemplate', Template, 'T1_M2_S1_BuildProvingGrounds');
	Template.bMainObjective = false;
	Template.ImagePath = "img:///UILibrary_StrategyImages.FacilityIcons.ChooseFacility_ProvingGround";

	Template.NextObjectives.AddItem('T1_M2_S2_BuildSKULLJACK');

	Template.CompletionRequirements.RequiredFacilities.AddItem('ProvingGround');
	Template.CompletionEvent = 'FacilityConstructionCompleted';
	Template.RevealEvent = 'OnEnteredFacility_PowerCore';

	Template.NagDelayHours = 336;
	Template.InProgressFn = ProvingGroundsInProgress;

	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.GP_HackACaptainScreen", NAW_OnReveal, '', '', ELD_OnStateSubmitted, NPC_Once, '', ShowResearchReport);
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Shen_Support_Build_Proving_Grounds", NAW_OnAssignment, 'FacilityAvailablePopup', 'ProvingGround', ELD_OnStateSubmitted, NPC_Once, '');

	return Template;
}

static function bool ProvingGroundsInProgress()
{
	return BuildFacilityInProgress('ProvingGround');
}

// -------------------- T1 M2 S2 --------------------------------------------------

static function X2DataTemplate CreateT1_M2_S2_BuildSKULLJACKTemplate()
{
	local X2ObjectiveTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ObjectiveTemplate', Template, 'T1_M2_S2_BuildSKULLJACK');
	Template.bMainObjective = false;

	Template.NextObjectives.AddItem('T1_M2_S3_SKULLJACKCaptain');

	Template.CompletionRequirements.RequiredItems.AddItem('SKULLJACK');
	Template.CompletionEvent = 'ItemConstructionCompleted';
	

	Template.NagDelayHours = 336;

	Template.InProgressFn = BuildSKULLJACKInProgress;
	
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.GP_FirstStasisLanceAvailable_Shen", NAW_OnNag, 'OnEnteredFacility_ProvingGround', '', ELD_OnStateSubmitted, NPC_Multiple, 'SkulljackNag');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.GP_StasisLanceReminder_Shen", NAW_OnNag, 'OnEnteredFacility_ProvingGround', '', ELD_OnStateSubmitted, NPC_Multiple, 'SkulljackNag');
	//Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.GP_FirstStasisLanceBolted_Shen", NAW_OnCompletion, 'OnSKULLJACKEquip', '', ELD_OnStateSubmitted, true, '');

	return Template;
}

static function bool BuildSKULLJACKInProgress()
{
	return ResearchInProgress('Skulljack');
}

// -------------------- T1 M2 S3 --------------------------------------------------

static function X2DataTemplate CreateT1_M2_S3_SKULLJACKCaptainTemplate()
{
	local X2ObjectiveTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ObjectiveTemplate', Template, 'T1_M2_S3_SKULLJACKCaptain');
	Template.bMainObjective = false;

	Template.CompletionEvent = 'HackedACaptain';
	Template.TacticalCompletion = true;
	Template.AssignObjectiveFn = SKULLJACKCaptainAssigned;

	Template.NagDelayHours = 336;

	Template.AddNarrativeTrigger("X2NarrativeMoments.TACTICAL.goldenpath.GP_ADVENTcaptainSightedOne_Tygan", NAW_OnReveal, 'AdventCaptainSighted', '', ELD_OnStateSubmitted, NPC_OncePerTacticalMission, 'GP_ADVENTcaptainSighted', , , SkullJackOnHand);
	Template.AddNarrativeTrigger("X2NarrativeMoments.TACTICAL.goldenpath.GP_ADVENTcaptainSightedTwo_Tygan", NAW_OnReveal, 'AdventCaptainSighted', '', ELD_OnStateSubmitted, NPC_OncePerTacticalMission, 'GP_ADVENTcaptainSighted', , , SkullJackOnHand);
	Template.AddNarrativeTrigger("X2NarrativeMoments.TACTICAL.goldenpath.GP_ADVENTcaptainSightedSightedThree_Tygan", NAW_OnReveal, 'AdventCaptainSighted', '', ELD_OnStateSubmitted, NPC_OncePerTacticalMission, 'GP_ADVENTcaptainSighted', , , SkullJackOnHand);
	
	// Stunned and Hacked should be played back to back upon completion
// 	Template.AddNarrativeTrigger("X2NarrativeMoments.TACTICAL.goldenpath.GP_FirstSuccessfulStun_Tygan", NAW_OnCompletion, '', '', ELD_OnStateSubmitted, true, '');
// 	Template.AddNarrativeTrigger("X2NarrativeMoments.TACTICAL.goldenpath.GP_FirstSuccessfulOfficerHack_Tygan", NAW_OnCompletion, '', '', ELD_OnStateSubmitted, true, '');

	return Template;
}

// #######################################################################################
// -------------------- T1 M3 --------------------------------------------------

static function X2DataTemplate CreateT1_M3_KillCodexTemplate()
{
	local X2ObjectiveTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ObjectiveTemplate', Template, 'T1_M3_KillCodex');
	Template.bMainObjective = true;
	Template.ImagePath = "img:///UILibrary_StrategyImages.X2StrategyMap.Alert_Kill_Codex";

	Template.NextObjectives.AddItem('T1_M3_S0_RecoverCodexBrain');

	Template.CompleteObjectiveFn = KillCodexComplete;
	Template.CompletionEvent = 'KilledACodex';
	Template.TacticalCompletion = true;

	Template.SimCombatItemReward = 'CorpseCyberus';
	
	Template.NagDelayHours = 336;

	Template.AddNarrativeTrigger("X2NarrativeMoments.TACTICAL.goldenpath.GP_CodexFirstAction_Tygan", NAW_OnReveal, 'AbilityActivated', 'Teleport', ELD_OnStateSubmitted, NPC_Once, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.TACTICAL.goldenpath.GP_CodexFirstCleave_Tygan", NAW_OnReveal, 'AbilityActivated', 'TriggerSuperposition', ELD_OnStateSubmitted, NPC_Once, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.TACTICAL.goldenpath.GP_CodexDeath_Tygan", NAW_OnCompletion, '', '', ELD_OnStateSubmitted, NPC_Once, '');

	return Template;
}

static function SKULLJACKCaptainAssigned(XComGameState NewGameState, XComGameState_Objective ObjectiveState)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;

	History = `XCOMHISTORY;

		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));

	XComHQ.RequiredSpawnGroups.AddItem('AdventCaptain');
}

static function KillCodexComplete(XComGameState NewGameState, XComGameState_Objective ObjectiveState)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersAlien AlienHQ;
	local PendingDoom DoomPending;
	local XGParamTag ParamTag;
	local string DoomString;
	local XComGameState_HeadquartersXCom XComHQ;

	History = `XCOMHISTORY;
	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));
	AlienHQ = XComGameState_HeadquartersAlien(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersAlien', AlienHQ.ObjectID));
	DoomPending.Doom = -(GetKillCodexMinDoom() + `SYNC_RAND_STATIC(GetKillCodexMaxDoom() - GetKillCodexMinDoom() + 1));
	DoomString = default.KilledCodexLabel;
	ParamTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	ParamTag.StrValue0 = string(-DoomPending.Doom);

	if(DoomPending.Doom == -1)
	{
		DoomString @= `XEXPAND.ExpandString(class'UIRewardsRecap'.default.m_strAvatarProgressReducedSingular);
	}
	else
	{
		DoomString @= `XEXPAND.ExpandString(class'UIRewardsRecap'.default.m_strAvatarProgressReducedPlural);
	}

	DoomPending.DoomMessage = DoomString;
	AlienHQ.PendingDoomData.AddItem(DoomPending);
	AlienHQ.PendingDoomEvent = 'CodexDoomEvent';

	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));

	XComHQ.RequiredSpawnGroups.RemoveItem('AdventCaptain');
}

static function X2DataTemplate CreateT1_M3_S0_RecoverCodexBrainTemplate()
{
	local X2ObjectiveTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ObjectiveTemplate', Template, 'T1_M3_S0_RecoverCodexBrain');
	Template.bMainObjective = true;
	Template.bNeverShowObjective = true;

	Template.NextObjectives.AddItem('T3_M1_ResearchAlienEncryption');
	Template.NextObjectives.AddItem('T1_M4_StudyCodexBrain');

	Template.CompletionRequirements.RequiredItems.AddItem('CorpseCyberus');
	Template.CompletionEvent = 'PostMissionLoot';
	
	return Template;
}

// #######################################################################################
// -------------------- T1 M4 --------------------------------------------------

static function X2DataTemplate CreateT1_M4_StudyCodexBrainTemplate()
{
	local X2ObjectiveTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ObjectiveTemplate', Template, 'T1_M4_StudyCodexBrain');
	Template.bMainObjective = true;
	Template.ImagePath = "img:///UILibrary_StrategyImages.ResearchTech.GOLDTECH_Codex_Brain_Pt1";

	Template.NextObjectives.AddItem('T1_M5_SKULLJACKCodex');

	Template.Steps.AddItem('T1_M4_S1_StudyCodexBrainPt1');
	Template.Steps.AddItem('T1_M4_S1_StudyCodexBrainPt2');

	Template.AssignmentRequirements.RequiredObjectives.AddItem('T1_M3_S0_RecoverCodexBrain');
	Template.AssignmentRequirements.RequiredObjectives.AddItem('T3_M2_BuildShadowChamber');
	Template.CompletionEvent = '';

	Template.NagDelayHours = 336;

	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.GP_StudyCodexBrainScreen", NAW_OnReveal, 'CinematicComplete', '', ELD_OnStateSubmitted, NPC_Once, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.GP_StudyCodexBrainScreen", NAW_OnReveal, 'PostMissionDone', '', ELD_OnStateSubmitted, NPC_Once, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.S_Tygan_New_Objective_CodexBrain", NAW_OnReveal, 'UniqueNarrativeUICompleted', '', ELD_OnStateSubmitted, NPC_Once, '');

	return Template;
}

// -------------------- T1 M4 S1 --------------------------------------------------

static function X2DataTemplate CreateT1_M4_S1_StudyCodexBrainPt1Template()
{
	local X2ObjectiveTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ObjectiveTemplate', Template, 'T1_M4_S1_StudyCodexBrainPt1');
	Template.bMainObjective = false;

	Template.NextObjectives.AddItem('T1_M4_S1_StudyCodexBrainPt2');
	Template.NextObjectives.AddItem('T4_M1_CompleteStargateMission');
	Template.NextObjectives.AddItem('T4_M1_L0_LookAtStargate');
	Template.NextObjectives.AddItem('T4_M1_L1_MakeContactWithStargateRegion');

	Template.CompletionRequirements.RequiredTechs.AddItem('CodexBrainPt1');
	Template.CompletionEvent = 'ResearchCompleted';
	Template.CompleteObjectiveFn = BreakShadowChamber;

	Template.NagDelayHours = 336;
	Template.InProgressFn = StudyCodexBrainPt1InProgress;

	Template.AddNarrativeTrigger("X2NarrativeMoments.S_Support_Shadow_Chamber_Constructed_Shen", NAW_OnNag, 'OnEnteredFacility_ShadowChamber', '', ELD_OnStateSubmitted, NPC_Once, 'ShadowChamberBuiltNags');
	Template.AddNarrativeTrigger("X2NarrativeMoments.S_Support_Shadow_Chamber_Nag_Shen", NAW_OnNag, 'OnEnteredFacility_ShadowChamber', '', ELD_OnStateSubmitted, NPC_Once, 'ShadowChamberBuiltNags');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.GP_OldGodsPt1", NAW_OnCompletion, '', '', ELD_OnStateSubmitted, NPC_Once, '', JumpToShadowChamber);

	return Template;
}

static function bool StudyCodexBrainPt1InProgress()
{
	return (ResearchInProgress('CodexBrainPt1'));
}

static function BreakShadowChamber(XComGameState NewGameState, XComGameState_Objective ObjectiveState)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_FacilityXCom FacilityState;

	XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	FacilityState = XComHQ.GetFacilityByName('ShadowChamber');
	FacilityState = XComGameState_FacilityXCom(NewGameState.ModifyStateObject(class'XComGameState_FacilityXCom', FacilityState.ObjectID));
	FacilityState.ActivateUpgrade(NewGameState, 'ShadowChamber_Destroyed');
}

// -------------------- T1 M4 S2 --------------------------------------------------

static function X2DataTemplate CreateT1_M4_S2_StudyCodexBrainPt2Template()
{
	local X2ObjectiveTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ObjectiveTemplate', Template, 'T1_M4_S1_StudyCodexBrainPt2');
	Template.bMainObjective = false;

	Template.CompletionRequirements.RequiredTechs.AddItem('CodexBrainPt2');
	Template.CompletionEvent = 'ResearchCompleted';
	

	Template.NagDelayHours = 336;
	Template.InProgressFn = StudyCodexBrainPt2InProgress;

	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.GP_StudyCodexBrainPt2Screen", NAW_OnReveal, '', '', ELD_OnStateSubmitted, NPC_Once, '', ShowShadowProjectResearchReport);
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.GP_OldGodsPt2", NAW_OnCompletion, '', '', ELD_OnStateSubmitted, NPC_Once, '', JumpToShadowChamber);

	return Template;
}

static function bool StudyCodexBrainPt2InProgress()
{
	return (ResearchInProgress('CodexBrainPt2'));
}

// #######################################################################################
// -------------------- T1 M5 --------------------------------------------------

static function X2DataTemplate CreateT1_M5_SKULLJACKCodexTemplate()
{
	local X2ObjectiveTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ObjectiveTemplate', Template, 'T1_M5_SKULLJACKCodex');
	Template.bMainObjective = true;
	Template.ImagePath = "img:///UILibrary_StrategyImages.X2StrategyMap.Alert_SkullJack_Codex";

	Template.NextObjectives.AddItem('T1_M6_KillAvatar');

	Template.CompletionEvent = 'HackedACodex';
	Template.TacticalCompletion = true;
	Template.AssignObjectiveFn = SKULLJACKCodexAssigned;


	Template.NagDelayHours = 336;

	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.GP_HackACodexScreen", NAW_OnReveal, '', '', ELD_OnStateSubmitted, NPC_Once, '', ShowShadowProjectResearchReport);
	Template.AddNarrativeTrigger("X2NarrativeMoments.T_Live_Codex_Sighted_Hack_It_Tygan", NAW_OnReveal, 'CyberusSighted', '', ELD_OnStateSubmitted, NPC_OncePerTacticalMission , '', , , SkullJackOnHand);


	return Template;
}

// #######################################################################################
// -------------------- T1 M6 --------------------------------------------------

static function X2DataTemplate CreateT1_M6_KillAvatarTemplate()
{
	local X2ObjectiveTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ObjectiveTemplate', Template, 'T1_M6_KillAvatar');
	Template.bMainObjective = true;
	Template.ImagePath = "img:///UILibrary_StrategyImages.X2StrategyMap.Alert_Kill_Avatar";

	Template.NextObjectives.AddItem('T1_M6_S0_RecoverAvatarCorpse');

	Template.CompleteObjectiveFn = KillAvatarComplete;
	Template.CompletionEvent = 'KilledAnAvatar';
	Template.TacticalCompletion = true;
	
	Template.SimCombatItemReward = 'CorpseAdventPsiWitch';

	Template.NagDelayHours = 336;

	//Template.AddNarrativeTrigger("", NAW_OnReveal, '', '', ELD_OnStateSubmitted, true, '');
	//Template.AddNarrativeTrigger("", NAW_OnNag, '', '', ELD_OnStateSubmitted, false, '');
	//Template.AddNarrativeTrigger("", NAW_OnCompletion, '', '', ELD_OnStateSubmitted, true, '');

	return Template;
}

static function SKULLJACKCodexAssigned(XComGameState NewGameState, XComGameState_Objective ObjectiveState)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;

	History = `XCOMHISTORY;

	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));

	XComHQ.RequiredSpawnGroups.AddItem('Cyberus');
}

static function KillAvatarComplete(XComGameState NewGameState, XComGameState_Objective ObjectiveState)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersAlien AlienHQ;
	local PendingDoom DoomPending;
	local XGParamTag ParamTag;
	local string DoomString;
    local XComGameState_HeadquartersXCom XComHQ;
	
	History = `XCOMHISTORY;
	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));
	AlienHQ = XComGameState_HeadquartersAlien(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersAlien', AlienHQ.ObjectID));

	//Grant Act/Chapter 3 amounts of clerks
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
	XComHQ.UpdateClerkCount(3, NewGameState);

	XComHQ.RequiredSpawnGroups.RemoveItem('Cyberus');

	DoomPending.Doom = -(GetKillAvatarMinDoom() + `SYNC_RAND_STATIC(GetKillAvatarMaxDoom() - GetKillAvatarMinDoom() + 1));
	DoomString = default.KilledAvatarLabel;
	ParamTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	ParamTag.StrValue0 = string(-DoomPending.Doom);

	if(DoomPending.Doom == -1)
	{
		DoomString @= `XEXPAND.ExpandString(class'UIRewardsRecap'.default.m_strAvatarProgressReducedSingular);
	}
	else
	{
		DoomString @= `XEXPAND.ExpandString(class'UIRewardsRecap'.default.m_strAvatarProgressReducedPlural);
	}

	DoomPending.DoomMessage = DoomString;
	AlienHQ.PendingDoomData.AddItem(DoomPending);
	AlienHQ.PendingDoomEvent = 'AvatarDoomEvent';
}

static function X2DataTemplate CreateT1_M6_S0_RecoverAvatarCorpseTemplate()
{
	local X2ObjectiveTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ObjectiveTemplate', Template, 'T1_M6_S0_RecoverAvatarCorpse');
	Template.bMainObjective = true;
	Template.bNeverShowObjective = true;

	Template.NextObjectives.AddItem('T5_M1_AutopsyTheAvatar');

	Template.CompletionRequirements.RequiredItems.AddItem('CorpseAdventPsiWitch');
	Template.CompletionEvent = 'PostMissionLoot';

	return Template;
}

// #######################################################################################
// -------------------- T2 OBJECTIVES --------------------------------------------------
// #######################################################################################

// #######################################################################################
// -------------------- T2 M0 --------------------------------------------------

static function X2DataTemplate CreateT2_M0_CompleteGuerillaOpsTemplate()
{
	local X2ObjectiveTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ObjectiveTemplate', Template, 'T2_M0_CompleteGuerillaOps');
	Template.bMainObjective = true;
	Template.bNeverShowObjective = true;

	Template.NextObjectives.AddItem('T2_M1_ContactBlacksiteRegion');

	Template.CompletionEvent = 'GuerillaOpComplete';

	return Template;
}

static function X2DataTemplate CreateT2_M0_L0_BlacksiteRevealTemplate()
{
	local X2ObjectiveTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ObjectiveTemplate', Template, 'T2_M0_L0_BlacksiteReveal');
	Template.bMainObjective = true;
	Template.bNeverShowObjective = true;

	Template.NextObjectives.AddItem('T2_M1_L0_LookAtBlacksite');
	Template.NextObjectives.AddItem('T2_M1_L1_RevealBlacksiteObjective');

	Template.CompletionEvent = 'GuerillaOpComplete';

	return Template;
}


// #######################################################################################
// -------------------- T2 M1 --------------------------------------------------

static function X2DataTemplate CreateT2_M1_ContactBlacksiteRegionTemplate()
{
	local X2ObjectiveTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ObjectiveTemplate', Template, 'T2_M1_ContactBlacksiteRegion');
	Template.bMainObjective = true;
	Template.ImagePath = "img:///UILibrary_StrategyImages.X2StrategyMap.Alert_Contact_Resistance";

	Template.NextObjectives.AddItem('T2_M1_InvestigateBlacksite');
	Template.Steps.AddItem('T2_M1_S1_ResearchResistanceComms');
	Template.Steps.AddItem('T2_M1_S2_MakeContactWithBlacksiteRegion');

	Template.AssignObjectiveFn = MakeBlacksiteMissionAvailable;
	Template.CompletionEvent = '';	

	Template.NagDelayHours = 336;

	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.GP_BlacksiteRegionContactReminder_Council", NAW_OnNag, 'OnGeoscapeEntry', '', ELD_OnStateSubmitted, NPC_Multiple, 'MakeContactNag');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Central_Support_Reminder_Make_Contact", NAW_OnNag, 'OnGeoscapeEntry', '', ELD_OnStateSubmitted, NPC_Multiple, 'MakeContactNag');
	
	return Template;
}

static function X2DataTemplate CreateT2_M1_L0_LookAtBlacksiteTemplate()
{
	local X2ObjectiveTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ObjectiveTemplate', Template, 'T2_M1_L0_LookAtBlacksite');
	Template.bMainObjective = true;
	Template.bNeverShowObjective = true;

	Template.CompletionEvent = 'CameraAtBlacksite';
	
	Template.AddNarrativeTrigger("", NAW_OnAssignment, 'OnEnteredFacility_CIC', '', ELD_OnStateSubmitted, NPC_Once, '', EnableFlightMode);
	Template.AddNarrativeTrigger("", NAW_OnAssignment, 'OnGeoscapeEntry', '', ELD_OnStateSubmitted, NPC_Once, '', CameraLookAtBlacksiteOpenUI);
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.GP_BlacksiteMissionSpawn_Council", NAW_OnAssignment, 'CameraAtBlacksite', '', ELD_OnStateSubmitted, NPC_Multiple, 'BlacksiteLockedLines');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Central_Support_Blacksite_Mission_Locked", NAW_OnAssignment, 'CameraAtBlacksite', '', ELD_OnStateSubmitted, NPC_Multiple, 'BlacksiteLockedLines');

	return Template;
}

static function X2DataTemplate CreateT2_M1_L1_RevealBlacksiteObjectiveTemplate()
{
	local X2ObjectiveTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ObjectiveTemplate', Template, 'T2_M1_L1_RevealBlacksiteObjective');
	Template.bMainObjective = true;
	Template.bNeverShowObjective = true;

	Template.CompletionEvent = 'NarrativeUICompleted';

	// After completing first mission
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.GP_WelcomeToTheResistance", NAW_OnReveal, 'MissionRewardRecap', '', ELD_OnStateSubmitted, NPC_Once, '', BlacksiteJumpToCommandersQuarters);
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.GP_ContactBlacksiteRegionScreen", NAW_OnReveal, 'CinematicComplete', '', ELD_OnStateSubmitted, NPC_Once, '', OpenRewardsRecap);
	
	// If first mission is skipped
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.GP_WelcomeToTheResistance", NAW_OnReveal, 'MissionExpired', '', ELD_OnStateSubmitted, NPC_Once, '', WelcomeToTheResistanceComplete);
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.GP_ContactBlacksiteRegionScreen", NAW_OnReveal, 'WelcomeToResistanceComplete', '', ELD_OnStateSubmitted, NPC_Once, '');

	return Template;
}

function BlacksiteJumpToCommandersQuarters()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_FacilityXCom FacilityState;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	FacilityState = XComHQ.GetFacilityByName('CommandersQuarters');
	FacilityState.GetMyTemplate().SelectFacilityFn(FacilityState.GetReference());
	`HQPRES.CAMLookAtNamedLocation("UIDisplayCam_ResistanceScreen", 0);

	CinematicComplete();
}

function OpenRewardsRecap()
{
	`HQPRES.UIRewardsRecap(true);
}

static function X2DataTemplate CreateT2_M1_S1_ResearchResistanceCommsTemplate()
{
	local X2ObjectiveTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ObjectiveTemplate', Template, 'T2_M1_S1_ResearchResistanceComms');
	Template.bMainObjective = false;

	Template.NextObjectives.AddItem('T2_M1_S2_MakeContactWithBlacksiteRegion');

	Template.CompletionRequirements.RequiredTechs.AddItem('ResistanceCommunications');
	Template.CompletionEvent = 'ResearchCompleted';

	Template.InProgressFn = ResistanceCommsInProgress;

	return Template;
}

static function bool ResistanceCommsInProgress()
{
	return ResearchInProgress('ResistanceCommunications');
}

static function X2DataTemplate CreateT2_M1_S2_MakeContactWithBlacksiteRegionTemplate()
{
	local X2ObjectiveTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ObjectiveTemplate', Template, 'T2_M1_S2_MakeContactWithBlacksiteRegion');
	Template.bMainObjective = false;
	
	Template.NextObjectives.AddItem('T2_M1_L2_WaitForBlacksiteContact');

	Template.CompletionEvent = 'OnBlacksiteContacted';
	Template.InProgressFn = BlacksiteContactInProgress;
	Template.GetDisplayStringFn = GetBlacksiteContactDisplayString;

	return Template;
}

static function X2DataTemplate CreateT2_M1_L2_WaitForBlacksiteContactTemplate()
{
	local X2ObjectiveTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ObjectiveTemplate', Template, 'T2_M1_L2_WaitForBlacksiteContact');
	Template.bMainObjective = true;
	Template.bNeverShowObjective = true;

	Template.CompletionEvent = 'CinematicComplete';

	// These NMs work fine, but they don't reference Blacksite being a difficult mission
	//Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.GP_BlacksiteRegionContactMade_Council", NAW_OnAssignment, 'CinematicComplete', '', ELD_OnStateSubmitted, NPC_Multiple, 'BlacksiteContactedLines');
	//Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Central_Support_Established_Contact_Mission_Blacksite", NAW_OnAssignment, 'CinematicComplete', '', ELD_OnStateSubmitted, NPC_Multiple, 'BlacksiteContactedLines');
	
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Central_Support_Contact_Blacksite_Region", NAW_OnAssignment, 'CinematicComplete', '', ELD_OnStateSubmitted, NPC_Multiple, 'BlacksiteContactedLines');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Central_Setup_Phase_Geoscape_Blacksite_Region_Contact_Made", NAW_OnAssignment, 'CinematicComplete', '', ELD_OnStateSubmitted, NPC_Multiple, 'BlacksiteContactedLines');

	return Template;
}

static function bool BlacksiteContactInProgress()
{
	local XComGameStateHistory History;
	local XComGameState_MissionSite MissionState;

	History = `XCOMHISTORY;

	foreach History.IterateByClassType(class'XComGameState_MissionSite', MissionState)
	{
		if(MissionState.Source == 'MissionSource_Blacksite')
		{
			return MakingContactInProgress(MissionState.Region);
		}
	}

	return false;
}

static function string GetBlacksiteContactDisplayString(XComGameState NewGameState, XComGameState_Objective ObjectiveState)
{
	local XComGameStateHistory History;
	local XComGameState_MissionSite MissionState;
	local XGParamTag ParamTag;

	History = `XCOMHISTORY;

	if(NewGameState != none)
	{
		foreach NewGameState.IterateByClassType(class'XComGameState_MissionSite', MissionState)
		{
			if(MissionState.GetMissionSource().DataName == 'MissionSource_Blacksite')
			{
				break;
			}
		}
	}

	if(MissionState == none)
	{
		foreach History.IterateByClassType(class'XComGameState_MissionSite', MissionState)
		{
			if(MissionState.GetMissionSource().DataName == 'MissionSource_Blacksite')
			{
				break;
			}
		}
	}

	ParamTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	if( MissionState == none )
	{
		// will hit this case after the objective has been completed and the mission site cleaned up
		ParamTag.StrValue0 = class'XLocalizedData'.default.Redacted;
	}
	else
	{
		ParamTag.StrValue0 = MissionState.GetWorldRegion().GetMyTemplate().DisplayName;
	}
	return `XEXPAND.ExpandString(ObjectiveState.GetMyTemplate().Title);
}

static function X2DataTemplate CreateT2_M1_CompleteBlacksiteMissionTemplate()
{
	local X2ObjectiveTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ObjectiveTemplate', Template, 'T2_M1_InvestigateBlacksite');
	Template.bMainObjective = true;
	Template.ImagePath = "img:///UILibrary_StrategyImages.X2StrategyMap.Alert_Blacksite";

	Template.NextObjectives.AddItem('T3_M1_ResearchAlienEncryption');
	Template.NextObjectives.AddItem('T2_M2_StudyBlacksiteData');

	Template.CompletionRequirements.RequiredItems.AddItem('BlacksiteDataCube');
	Template.CompletionEvent = 'PostMissionLoot';
	

	Template.NagDelayHours = 336;

	
	//Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.GP_BlacksiteTransmission_Central", NAW_OnReveal, '', '', ELD_OnStateSubmitted, NPC_Once, '');
	//Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.GP_BlacksiteCommunique_Council", NAW_OnReveal, '', '', ELD_OnStateSubmitted, NPC_Once, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.GP_InvestigateBlacksiteScreen", NAW_OnReveal, '', '', ELD_OnStateSubmitted, NPC_Once, '');

	return Template;
}

static function CreateBlacksiteMission(XComGameState NewGameState)
{
	local array<XComGameState_Reward> Rewards;
	local X2StrategyElementTemplateManager StratMgr;
	local X2RewardTemplate RewardTemplate;
	local XComGameState_Reward RewardState;
	local XComGameState_MissionSite MissionState;
	local XComGameState_WorldRegion RegionState;

	StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
	RewardTemplate = X2RewardTemplate(StratMgr.FindStrategyElementTemplate('Reward_Supplies'));
	RewardState = RewardTemplate.CreateInstanceFromTemplate(NewGameState);
	RewardState.SetReward(, GetBlacksiteSupplyAmount());
	Rewards.AddItem(RewardState);
	MissionState = CreateMission(NewGameState, Rewards, 'MissionSource_BlackSite', 1, false, false, false);
	
	RegionState = MissionState.GetWorldRegion();
	RegionState = XComGameState_WorldRegion(NewGameState.ModifyStateObject(class'XComGameState_WorldRegion', RegionState.ObjectID));
	RegionState.SetShortestPathToContactRegion(NewGameState); // Flag the region to update its shortest path to a player-contacted region, used for region link display states
}

static function MakeBlacksiteMissionAvailable(XComGameState NewGameState, XComGameState_Objective ObjectiveState)
{
	local XComGameState_MissionSite MissionState;
	local XComGameStateHistory History;
	local XComGameState_WorldRegion RegionState;
	local bool bFound;

	bFound = false;
	History = `XCOMHISTORY;

	foreach NewGameState.IterateByClassType(class'XComGameState_MissionSite', MissionState)
	{
		if(MissionState.Source == 'MissionSource_Blacksite')
		{
			MissionState.Available = true;
			bFound = true;
			break;
		}
	}

	if(!bFound)
	{
		foreach History.IterateByClassType(class'XComGameState_MissionSite', MissionState)
		{
			if(MissionState.Source == 'MissionSource_Blacksite')
			{
				MissionState = XComGameState_MissionSite(NewGameState.ModifyStateObject(class'XComGameState_MissionSite', MissionState.ObjectID));
				MissionState.Available = true;
				bFound = true;
				break;
			}
		}
	}

	RegionState = MissionState.GetWorldRegion();
	RegionState = XComGameState_WorldRegion(NewGameState.ModifyStateObject(class'XComGameState_WorldRegion', RegionState.ObjectID));
	RegionState.SetShortestPathToContactRegion(NewGameState); // Flag the region to update its shortest path to a player-contacted region, used for region link display states
}

function CameraLookAtBlacksiteOpenUI()
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_MissionSite MissionState;

	History = `XCOMHISTORY;
		foreach History.IterateByClassType(class'XComGameState_MissionSite', MissionState)
	{
			if (MissionState.GetMissionSource().DataName == 'MissionSource_Blacksite')
			{
				break;
			}
		}

	`HQPRES.CAMLookAtEarth(MissionState.Get2DLocation(), 0.5f);

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Cam Look at Blacksite");
	`XEVENTMGR.TriggerEvent('CameraAtBlacksite', , , NewGameState);
	`GAMERULES.SubmitGameState(NewGameState);

	`HQPRES.OnMissionSelected(MissionState, false);

	DisableFlightMode();
}

function WelcomeToTheResistanceComplete()
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_FacilityXCom FacilityState;

	History = `XCOMHISTORY;
		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	if(`GAME.GetGeoscape().IsScanning())
		`HQPRES.StrategyMap2D.ToggleScan();


	FacilityState = XComHQ.GetFacilityByName('CommandersQuarters');
	FacilityState.GetMyTemplate().SelectFacilityFn(FacilityState.GetReference());

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Welcome to Resistance Complete Event");
	`XEVENTMGR.TriggerEvent('WelcomeToResistanceComplete', , , NewGameState);
	`GAMERULES.SubmitGameState(NewGameState);
}

// #######################################################################################
// -------------------- T2 M2 --------------------------------------------------

static function X2DataTemplate CreateT2_M2_StudyBlacksiteDataTemplate()
{
	local X2ObjectiveTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ObjectiveTemplate', Template, 'T2_M2_StudyBlacksiteData');
	Template.bMainObjective = true;
	Template.ImagePath = "img:///UILibrary_StrategyImages.ResearchTech.GOLDTECH_Blacksite_Vial";

	Template.NextObjectives.AddItem('T2_M3_CompleteForgeMission');
	Template.NextObjectives.AddItem('T2_M3_L0_LookAtForge');
	Template.NextObjectives.AddItem('T2_M3_L1_MakeContactWithForgeRegion');

	Template.AssignmentRequirements.RequiredObjectives.AddItem('T2_M1_InvestigateBlacksite');
	Template.AssignmentRequirements.RequiredObjectives.AddItem('T3_M2_BuildShadowChamber');
	Template.CompletionRequirements.RequiredTechs.AddItem('BlacksiteData');
	Template.CompletionEvent = 'ResearchCompleted';

	Template.InProgressFn = StudyBlacksiteDataInProgress;

	Template.NagDelayHours = 336;

	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.GP_StudyBlacksiteDataScreen", NAW_OnReveal, 'CinematicComplete', '', ELD_OnStateSubmitted, NPC_Once, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.GP_StudyBlacksiteDataScreen", NAW_OnReveal, 'PostMissionDone', '', ELD_OnStateSubmitted, NPC_Once, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.S_Tygan_New_Objective_BlacksiteVial", NAW_OnReveal, 'UniqueNarrativeUICompleted', '', ELD_OnStateSubmitted, NPC_Once, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.S_Support_Shadow_Chamber_Constructed_Shen", NAW_OnNag, 'OnEnteredFacility_ShadowChamber', '', ELD_OnStateSubmitted, NPC_Once, 'ShadowChamberBuiltNags');
	Template.AddNarrativeTrigger("X2NarrativeMoments.S_Support_Shadow_Chamber_Nag_Shen", NAW_OnNag, 'OnEnteredFacility_ShadowChamber', '', ELD_OnStateSubmitted, NPC_Once, 'ShadowChamberBuiltNags');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.GP_HumanHolocost", NAW_OnCompletion, '', '', ELD_OnStateSubmitted, NPC_Once, '', JumpToShadowChamber);

	return Template;
}

static function bool StudyBlacksiteDataInProgress()
{
	return ResearchInProgress('BlacksiteData');
}

function JumpToShadowChamber()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_FacilityXCom FacilityState;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	FacilityState = XComHQ.GetFacilityByName('ShadowChamber');
	FacilityState.GetMyTemplate().SelectFacilityFn(FacilityState.GetReference());
}

function ShowShadowProjectResearchReport()
{
	local UIFacility_ShadowChamber kScreen;

	kScreen = UIFacility_ShadowChamber(`HQPRES.ScreenStack.GetScreen(class'UIFacility_ShadowChamber'));
	kScreen.TriggerResearchReport();
}

// #######################################################################################
// -------------------- T2 M3 --------------------------------------------------

static function X2DataTemplate CreateT2_M3_CompleteForgeMissionTemplate()
{
	local X2ObjectiveTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ObjectiveTemplate', Template, 'T2_M3_CompleteForgeMission');
	Template.bMainObjective = true;
	Template.ImagePath = "img:///UILibrary_StrategyImages.X2StrategyMap.Alert_Forged";

	Template.NextObjectives.AddItem('T2_M4_BuildStasisSuit');

	Template.AssignObjectiveFn = CreateForgeMission;
	Template.CompletionRequirements.RequiredItems.AddItem('StasisSuitComponent');
	Template.CompletionEvent = 'PostMissionDone';
	

	Template.NagDelayHours = 336;

	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.GP_ForgeMissionScreen", NAW_OnReveal, '', '', ELD_OnStateSubmitted, NPC_Once, '', ShowShadowProjectResearchReport);

	return Template;
}

static function X2DataTemplate CreateT2_M3_L0_LookAtForgeTemplate()
{
	local X2ObjectiveTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ObjectiveTemplate', Template, 'T2_M3_L0_LookAtForge');
	Template.bMainObjective = true;
	Template.bNeverShowObjective = true;
	
	Template.CompletionEvent = 'GPMissionBladesClosed';

	Template.AddNarrativeTrigger("", NAW_OnAssignment, 'OnEnteredFacility_CIC', '', ELD_OnStateSubmitted, NPC_Once, '', EnableFlightMode);
	Template.AddNarrativeTrigger("", NAW_OnAssignment, 'OnGeoscapeEntry', '', ELD_OnStateSubmitted, NPC_Once, '', CameraLookAtForgeOpenUI);
	Template.AddNarrativeTrigger("X2NarrativeMoments.Central_Setup_Phase_Forge_Coordinates_But_No_Contact", NAW_OnAssignment, 'PlayForgeMakeContact', '', ELD_OnStateSubmitted, NPC_Multiple, 'ForgeMakeContactLines');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Central_Forge_Marked_On_Geoscape", NAW_OnAssignment, 'PlayForgeMakeContact', '', ELD_OnStateSubmitted, NPC_Multiple, 'ForgeMakeContactLines');

	return Template;
}

static function X2DataTemplate CreateT2_M3_L1_MakeContactWithForgeRegionTemplate()
{
	local X2ObjectiveTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ObjectiveTemplate', Template, 'T2_M3_L1_MakeContactWithForgeRegion');
	Template.bMainObjective = true;
	Template.bNeverShowObjective = true;

	Template.NextObjectives.AddItem('T2_M3_L2_WaitForForgeContact');

	Template.CompletionEvent = 'OnForgeContacted';
	
	return Template;
}

static function X2DataTemplate CreateT2_M3_L2_WaitForForgeContactTemplate()
{
	local X2ObjectiveTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ObjectiveTemplate', Template, 'T2_M3_L2_WaitForForgeContact');
	Template.bMainObjective = true;
	Template.bNeverShowObjective = true;

	Template.CompletionEvent = 'CinematicComplete';

	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.Central_Support_Established_Contact_Mission_Forge", NAW_OnAssignment, 'CinematicComplete', '', ELD_OnStateSubmitted, NPC_Once, '');

	return Template;
}

static function CreateForgeMission(XComGameState NewGameState, XComGameState_Objective ObjectiveState)
{
	local XComGameState_MissionSite MissionState;
	local XComGameState_WorldRegion RegionState;
	local XComGameStateHistory History;
	local array<XComGameState_Reward> Rewards;
	local X2StrategyElementTemplateManager StratMgr;
	local X2RewardTemplate RewardTemplate;
	local XComGameState_Reward RewardState;
	local XComGameState_HeadquartersXCom XComHQ;
	local int SuppliesToAdd;
	local bool bFound;

	bFound = false;
	SuppliesToAdd = 0;
	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	if(XComHQ.IsObjectiveCompleted('T1_M4_S1_StudyCodexBrainPt1'))
	{
		SuppliesToAdd = GetPsiGateForgeSupplyAdd();
	}

	foreach NewGameState.IterateByClassType(class'XComGameState_MissionSite', MissionState)
	{
		if(MissionState.Source == 'MissionSource_Forge')
		{
			MissionState.Available = true;
			bFound = true;
			break;
		}
	}

	if(!bFound)
	{
		foreach History.IterateByClassType(class'XComGameState_MissionSite', MissionState)
		{
			if(MissionState.Source == 'MissionSource_Forge')
			{
				MissionState = XComGameState_MissionSite(NewGameState.ModifyStateObject(class'XComGameState_MissionSite', MissionState.ObjectID));
				MissionState.Available = true;
				bFound = true;
				break;
			}
		}
	}

	if(bFound)
	{
		// Flag the region to update its shortest path to a player-contacted region, used for region link display states
		RegionState = XComGameState_WorldRegion(NewGameState.GetGameStateForObjectID(MissionState.Region.ObjectID));

		if(RegionState == none)
		{
			RegionState = XComGameState_WorldRegion(NewGameState.ModifyStateObject(class'XComGameState_WorldRegion', MissionState.Region.ObjectID));
		}
		
		RegionState.SetShortestPathToContactRegion(NewGameState);

		if(SuppliesToAdd != 0)
		{
			RewardState = XComGameState_Reward(NewGameState.GetGameStateForObjectID(MissionState.Rewards[0].ObjectID));

			if(RewardState == none)
			{
				RewardState = XComGameState_Reward(NewGameState.ModifyStateObject(class'XComGameState_Reward', MissionState.Rewards[0].ObjectID));
			}

			RewardState.SetReward(, (GetPsiGateForgeSupplyAmount() + SuppliesToAdd));
		}
	}
	else
	{
		// Should only reach this point on very old saves
		StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
		RewardTemplate = X2RewardTemplate(StratMgr.FindStrategyElementTemplate('Reward_Supplies'));
		RewardState = RewardTemplate.CreateInstanceFromTemplate(NewGameState);
		RewardState.SetReward(, (GetPsiGateForgeSupplyAmount() + SuppliesToAdd));
		Rewards.AddItem(RewardState);

		CreateMission(NewGameState, Rewards, 'MissionSource_Forge', 2);
	}
}

function CameraLookAtForgeOpenUI()
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_MissionSite MissionState;

	History = `XCOMHISTORY;
	foreach History.IterateByClassType(class'XComGameState_MissionSite', MissionState)
	{
		if (MissionState.GetMissionSource().DataName == 'MissionSource_Forge')
		{
			break;
		}
	}

	`HQPRES.CAMLookAtEarth(MissionState.Get2DLocation(), 0.5f);

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Trigger Event: Cam Look at Forge");
	if (!MissionState.GetWorldRegion().HaveMadeContact())
	{
		`XEVENTMGR.TriggerEvent('PlayForgeMakeContact', , , NewGameState);
	}
	else
	{
		`XEVENTMGR.TriggerEvent('PlayForgeAlreadyContacted', , , NewGameState);
	}
	`XEVENTMGR.TriggerEvent('CameraAtForge', , , NewGameState);
	`GAMERULES.SubmitGameState(NewGameState);

	`HQPRES.OnMissionSelected(MissionState, false);

	DisableFlightMode();
}


// #######################################################################################
// -------------------- T2 M4 --------------------------------------------------

static function X2DataTemplate CreateT2_M4_BuildStasisSuitTemplate()
{
	local X2ObjectiveTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ObjectiveTemplate', Template, 'T2_M4_BuildStasisSuit');
	Template.bMainObjective = true;
	Template.ImagePath = "img:///UILibrary_StrategyImages.ResearchTech.GOLDTECH_Advent_Stasis_Suit";

	Template.NextObjectives.AddItem('T5_M1_AutopsyTheAvatar');

	Template.CompletionRequirements.RequiredTechs.AddItem('ForgeStasisSuit');
	Template.CompletionEvent = 'ResearchCompleted';

	Template.InProgressFn = StasisSuitInProgress;

	Template.NagDelayHours = 336;

	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.GP_BuildStasisSuitScreen", NAW_OnReveal, '', '', ELD_OnStateSubmitted, NPC_Once, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.GP_HumansAreObsolete", NAW_OnCompletion, '', '', ELD_OnStateSubmitted, NPC_Once, '', JumpToShadowChamber);

	return Template;
}

static function bool StasisSuitInProgress()
{
	return ResearchInProgress('ForgeStasisSuit');
}


// #######################################################################################
// -------------------- T3 OBJECTIVES --------------------------------------------------
// #######################################################################################

// #######################################################################################
// -------------------- T3 M1 --------------------------------------------------

static function X2DataTemplate CreateT3_M1_ResearchAlienEncryptionTemplate()
{
	local X2ObjectiveTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ObjectiveTemplate', Template, 'T3_M1_ResearchAlienEncryption');
	Template.bMainObjective = true;
	Template.ImagePath = "img:///UILibrary_StrategyImages.X2StrategyMap.Alert_Alien_Encryption";

	Template.NextObjectives.AddItem('T3_M2_BuildShadowChamber');

	Template.CompletionRequirements.RequiredTechs.AddItem('AlienEncryption');
	Template.CompletionEvent = 'ResearchCompleted';
	Template.RevealEvent = 'PostMissionDone';

	Template.NagDelayHours = 336;

	Template.InProgressFn = AlienEncryptionInProgress;

	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.GP_ResearchAlienEncryptionScreen", NAW_OnReveal, '', '', ELD_OnStateSubmitted, NPC_Once, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.MISC_VO_Alien_Encryp_Tygan", NAW_OnReveal, 'UniqueNarrativeUICompleted', '', ELD_OnStateSubmitted, NPC_Once, '');

	return Template;
}

static function bool AlienEncryptionInProgress()
{
	return ResearchInProgress('AlienEncryption');
}

// #######################################################################################
// -------------------- T3 M2 --------------------------------------------------

static function X2DataTemplate CreateT3_M2_BuildShadowChamberTemplate()
{
	local X2ObjectiveTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ObjectiveTemplate', Template, 'T3_M2_BuildShadowChamber');
	Template.bMainObjective = true;
	Template.ImagePath = "img:///UILibrary_StrategyImages.X2StrategyMap.Alert_Build_ShadowChamber";

	Template.NextObjectives.AddItem('T1_M4_StudyCodexBrain');
	Template.NextObjectives.AddItem('T2_M2_StudyBlacksiteData');

	Template.CompletionRequirements.RequiredFacilities.AddItem('ShadowChamber');
	Template.CompletionEvent = 'FacilityConstructionCompleted';
	Template.RevealEvent = 'OnLabsExit';

	Template.NagDelayHours = 336;

	Template.InProgressFn = ShadowChamberInProgress;
	Template.CompleteObjectiveFn = ShadowChamberBuilt;

	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.GP_BuildShadowChamberScreen", NAW_OnReveal, '', '', ELD_OnStateSubmitted, NPC_Once, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.S_Tygan_New_Objective_BuildShadowChamber", NAW_OnReveal, 'UniqueNarrativeUICompleted', '', ELD_OnStateSubmitted, NPC_Once, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.S_Shadow_Chamber_Build_Nag_Shen", NAW_OnNag, 'OnEnteredBuildFacilities', '', ELD_OnStateSubmitted, NPC_Multiple, 'BuildShadowChamberNags');
	Template.AddNarrativeTrigger("X2NarrativeMoments.S_We_Can_Start_Shen", NAW_OnNag, 'OnEnteredBuildFacilities', '', ELD_OnStateSubmitted, NPC_Multiple, 'BuildShadowChamberNags');

	return Template;
}

static function bool ShadowChamberInProgress()
{
	return BuildFacilityInProgress('ShadowChamber');
}

static function ShadowChamberBuilt(XComGameState NewGameState, XComGameState_Objective ObjectiveState)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;

	History = `XCOMHISTORY;
	
	//Grant Act/Chapter 2 amounts of clerks
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
	XComHQ.UpdateClerkCount(2, NewGameState);
}


// #######################################################################################
// -------------------- T4 OBJECTIVES --------------------------------------------------
// #######################################################################################

// #######################################################################################
// -------------------- T4 M1 --------------------------------------------------

static function X2DataTemplate CreateT4_M1_CompleteStargateMissionTemplate()
{
	local X2ObjectiveTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ObjectiveTemplate', Template, 'T4_M1_CompleteStargateMission');
	Template.bMainObjective = true;
	Template.ImagePath = "img:///UILibrary_StrategyImages.X2StrategyMap.Alert_PsiGate";

	Template.NextObjectives.AddItem('T4_M2_ConstructPsiGate');

	Template.AssignObjectiveFn = CreateStargateMission;
	Template.CompletionRequirements.RequiredItems.AddItem('PsiGateArtifact');
	Template.CompletionEvent = 'PostMissionDone';
	
	Template.NagDelayHours = 336;

	Template.AddNarrativeTrigger("X2NarrativeMoments.TACTICAL.goldenpath.GP_FirstPsiGateAppears_Tygan", NAW_OnReveal, 'PsiGateSeen', '', ELD_OnStateSubmitted, NPC_Once, '');

	return Template;
}

static function X2DataTemplate CreateT4_M1_L0_LookAtStargateTemplate()
{
	local X2ObjectiveTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ObjectiveTemplate', Template, 'T4_M1_L0_LookAtStargate');
	Template.bMainObjective = true;
	Template.bNeverShowObjective = true;
	
	Template.RevealEvent = 'OnGeoscapeEntry';
	Template.CompletionEvent = 'GPMissionBladesClosed';

	Template.AddNarrativeTrigger("", NAW_OnAssignment, 'OnEnteredFacility_CIC', '', ELD_OnStateSubmitted, NPC_Once, '', EnableFlightMode);
	Template.AddNarrativeTrigger("", NAW_OnAssignment, 'OnGeoscapeEntry', '', ELD_OnStateSubmitted, NPC_Once, '', CameraLookAtPsiGate);
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.GP_PsiGateMissionScreen", NAW_OnAssignment, 'CameraAtPsiGate', '', ELD_OnStateSubmitted, NPC_Once, '');
	Template.AddNarrativeTrigger("", NAW_OnReveal, 'NarrativeUICompleted', '', ELD_OnStateSubmitted, NPC_Once, '', PsiGateOpenUI);
	Template.AddNarrativeTrigger("X2NarrativeMoments.Central_Setup_Phase_Psi_Gate_Coordinates_But_No_Contact", NAW_OnAssignment, 'PlayPsiGateMakeContact', '', ELD_OnStateSubmitted, NPC_Multiple, 'PsiGateMakeContactLines');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Central_Psi_Gate_Marked_On_Geoscape", NAW_OnAssignment, 'PlayPsiGateMakeContact', '', ELD_OnStateSubmitted, NPC_Multiple, 'PsiGateMakeContactLines');

	return Template;
}

static function X2DataTemplate CreateT4_M1_L1_MakeContactWithStargateRegionTemplate()
{
	local X2ObjectiveTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ObjectiveTemplate', Template, 'T4_M1_L1_MakeContactWithStargateRegion');
	Template.bMainObjective = true;
	Template.bNeverShowObjective = true;

	Template.NextObjectives.AddItem('T4_M1_L2_WaitForStargateContact');

	Template.CompletionEvent = 'OnPsiGateContacted';

	return Template;
}

static function X2DataTemplate CreateT4_M1_L2_WaitForStargateContactTemplate()
{
	local X2ObjectiveTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ObjectiveTemplate', Template, 'T4_M1_L2_WaitForStargateContact');
	Template.bMainObjective = true;
	Template.bNeverShowObjective = true;

	Template.CompletionEvent = 'CinematicComplete';

	Template.AddNarrativeTrigger("X2NarrativeMoments.Central_Support_Established_Contact_Mission_PsiGate", NAW_OnAssignment, 'CinematicComplete', '', ELD_OnStateSubmitted, NPC_Once, '');

	return Template;
}

static function CreateStargateMission(XComGameState NewGameState, XComGameState_Objective ObjectiveState)
{
	local XComGameState_MissionSite MissionState;
	local XComGameState_WorldRegion RegionState;
	local XComGameStateHistory History;
	local array<XComGameState_Reward> Rewards;
	local X2StrategyElementTemplateManager StratMgr;
	local X2RewardTemplate RewardTemplate;
	local XComGameState_Reward RewardState;
	local XComGameState_HeadquartersXCom XComHQ;
	local int SuppliesToAdd;
	local bool bFound;

	bFound = false;
	SuppliesToAdd = 0;
	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	if(XComHQ.IsObjectiveCompleted('T2_M2_StudyBlacksiteData'))
	{
		SuppliesToAdd = GetPsiGateForgeSupplyAdd();
	}

	foreach NewGameState.IterateByClassType(class'XComGameState_MissionSite', MissionState)
	{
		if(MissionState.Source == 'MissionSource_PsiGate')
		{
			MissionState.Available = true;
			bFound = true;
			break;
		}
	}

	if(!bFound)
	{
		foreach History.IterateByClassType(class'XComGameState_MissionSite', MissionState)
		{
			if(MissionState.Source == 'MissionSource_PsiGate')
			{
				MissionState = XComGameState_MissionSite(NewGameState.ModifyStateObject(class'XComGameState_MissionSite', MissionState.ObjectID));
				MissionState.Available = true;
				bFound = true;
				break;
			}
		}
	}

	if(bFound)
	{
		// Flag the region to update its shortest path to a player-contacted region, used for region link display states
		RegionState = XComGameState_WorldRegion(NewGameState.GetGameStateForObjectID(MissionState.Region.ObjectID));

		if(RegionState == none)
		{
			RegionState = XComGameState_WorldRegion(NewGameState.ModifyStateObject(class'XComGameState_WorldRegion', MissionState.Region.ObjectID));
		}

		RegionState.SetShortestPathToContactRegion(NewGameState);

		if(SuppliesToAdd != 0)
		{
			RewardState = XComGameState_Reward(NewGameState.GetGameStateForObjectID(MissionState.Rewards[0].ObjectID));

			if(RewardState == none)
			{
				RewardState = XComGameState_Reward(NewGameState.ModifyStateObject(class'XComGameState_Reward', MissionState.Rewards[0].ObjectID));
			}

			RewardState.SetReward(, (GetPsiGateForgeSupplyAmount() + SuppliesToAdd));
		}
	}
	else
	{
		// Should only reach this point on very old saves
		StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
		RewardTemplate = X2RewardTemplate(StratMgr.FindStrategyElementTemplate('Reward_Supplies'));
		RewardState = RewardTemplate.CreateInstanceFromTemplate(NewGameState);
		RewardState.SetReward(, (GetPsiGateForgeSupplyAmount() + SuppliesToAdd));
		Rewards.AddItem(RewardState);

		CreateMission(NewGameState, Rewards, 'MissionSource_PsiGate', 2);
	}
}

function CameraLookAtPsiGate()
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_MissionSite MissionState;

	History = `XCOMHISTORY;
	foreach History.IterateByClassType(class'XComGameState_MissionSite', MissionState)
	{
		if (MissionState.GetMissionSource().DataName == 'MissionSource_PsiGate')
		{
			break;
		}
	}

	`HQPRES.CAMLookAtEarth(MissionState.Get2DLocation(), 0.5f);

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Trigger Event: Cam Look at Psi Gate");
	`XEVENTMGR.TriggerEvent('CameraAtPsiGate', , , NewGameState);
	`GAMERULES.SubmitGameState(NewGameState);
}

function PsiGateOpenUI()
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_MissionSite MissionState;

	History = `XCOMHISTORY;
	foreach History.IterateByClassType(class'XComGameState_MissionSite', MissionState)
	{
		if (MissionState.GetMissionSource().DataName == 'MissionSource_PsiGate')
		{
			break;
		}
	}

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Trigger Event: Open Psi Gate UI");
	if (!MissionState.GetWorldRegion().HaveMadeContact())
	{
		`XEVENTMGR.TriggerEvent('PlayPsiGateMakeContact', , , NewGameState);
	}
	else
	{
		`XEVENTMGR.TriggerEvent('PlayPsiGateAlreadyContacted', , , NewGameState);
	}
	`GAMERULES.SubmitGameState(NewGameState);

	`HQPRES.OnMissionSelected(MissionState, false);

	DisableFlightMode();
}


// #######################################################################################
// -------------------- T4 M2 --------------------------------------------------

static function X2DataTemplate CreateT4_M2_ConstructPsiGateTemplate()
{
	local X2ObjectiveTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ObjectiveTemplate', Template, 'T4_M2_ConstructPsiGate');
	Template.bMainObjective = true;
	Template.ImagePath = "img:///UILibrary_StrategyImages.ResearchTech.GOLDTECH_Psi_Gate_Project";

	Template.Steps.AddItem('T4_M2_S1_UpgradeShadowChamber');
	Template.Steps.AddItem('T4_M2_S2_ResearchPsiGate');

	Template.NextObjectives.AddItem('T5_M1_AutopsyTheAvatar');

	Template.CompletionEvent = ''; // completed via children objectives
	
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.GP_ConstructPsiGateScreen", NAW_OnReveal, '', '', ELD_OnStateSubmitted, NPC_Once, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.S_Tygan_New_Objective_UpgradeShadowChamber", NAW_OnReveal, 'UniqueNarrativeUICompleted', '', ELD_OnStateSubmitted, NPC_Once, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.GP_AlienFortressRevealed", NAW_OnCompletion, '', '', ELD_OnStateSubmitted, NPC_Once, '', JumpToShadowChamber);

	return Template;
}

// #######################################################################################
// -------------------- T4 M2 S2 --------------------------------------------------

static function X2DataTemplate CreateT4_M2_S1_UpgradeShadowChamber()
{
	local X2ObjectiveTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ObjectiveTemplate', Template, 'T4_M2_S1_UpgradeShadowChamber');
	Template.bMainObjective = false;
	
	Template.NextObjectives.AddItem('T4_M2_S2_ResearchPsiGate');

	Template.CompletionRequirements.RequiredUpgrades.AddItem('ShadowChamber_CelestialGate');
	Template.CompletionEvent = 'UpgradeCompleted';

	return Template;
}

// #######################################################################################
// -------------------- T4 M2 S2 --------------------------------------------------

static function X2DataTemplate CreateT4_M2_S2_ResearchPsiGateTemplate()
{
	local X2ObjectiveTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ObjectiveTemplate', Template, 'T4_M2_S2_ResearchPsiGate');
	Template.bMainObjective = false;
	
	Template.CompletionRequirements.RequiredTechs.AddItem('PsiGate');
	Template.CompletionEvent = 'ResearchCompleted';

	Template.NagDelayHours = 336;

	Template.InProgressFn = PsiGateInProgress;

	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.S_Support_Psi_Gate_Recovered_Shen", NAW_OnNag, 'OnEnteredFacility_ShadowChamber', '', ELD_OnStateSubmitted, NPC_Multiple, '');

	return Template;
}

static function bool PsiGateInProgress()
{
	return ResearchInProgress('PsiGate');
}

// #######################################################################################
// -------------------- T5 OBJECTIVES --------------------------------------------------
// #######################################################################################

// #######################################################################################
// -------------------- T5 M1 --------------------------------------------------

static function X2DataTemplate CreateT5_M1_AutopsyTheAvatarTemplate()
{
	local X2ObjectiveTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ObjectiveTemplate', Template, 'T5_M1_AutopsyTheAvatar');
	Template.bMainObjective = true;
	Template.ImagePath = "img:///UILibrary_StrategyImages.ResearchTech.GOLDTECH_Avatar";

	Template.NextObjectives.AddItem('T5_M2_CompleteBroadcastTheTruthMission');
	Template.NextObjectives.AddItem('T5_M2_L0_LookAtBroadcast');

	Template.AssignmentRequirements.RequiredObjectives.AddItem('T1_M6_S0_RecoverAvatarCorpse');

	Template.CompletionRequirements.RequiredTechs.AddItem('AutopsyAdventPsiWitch');
	Template.CompletionEvent = 'ResearchCompleted';	

	Template.NagDelayHours = 336;

	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.GP_AvatarAutopsyScreen", NAW_OnReveal, '', '', ELD_OnStateSubmitted, NPC_Once, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.S_Tygan_New_Objective_AvatarAutopsy", NAW_OnReveal, 'AvatarAutopsyReady', '', ELD_OnStateSubmitted, NPC_Once, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.GP_DarkVolunteer", NAW_OnCompletion, '', '', ELD_OnStateSubmitted, NPC_Once, '', JumpToShadowChamber);

	Template.InProgressFn = AvatarAutopsyInProgress;

	return Template;
}

static function bool AvatarAutopsyInProgress()
{
	return ResearchInProgress('AutopsyAdventPsiWitch');
}


// #######################################################################################
// -------------------- T5 M2 --------------------------------------------------

static function X2DataTemplate CreateT5_M2_CompleteBroadcastTheTruthMissionTemplate()
{
	local X2ObjectiveTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ObjectiveTemplate', Template, 'T5_M2_CompleteBroadcastTheTruthMission');
	Template.bMainObjective = true;
	Template.ImagePath = "img:///UILibrary_StrategyImages.X2StrategyMap.Alert_Sky_Tower";

	Template.NextObjectives.AddItem('T5_M3_CompleteFinalMission');

	Template.AssignObjectiveFn = CreateBroadcastTheTruthMission;
	Template.CompletionRequirements.RequiredItems.AddItem('TheTruth');
	Template.CompletionEvent = 'PostMissionDone';
	Template.RevealEvent = 'OnEnteredFacility_CIC';
	
	Template.NagDelayHours = 336;

	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.GP_PreBroadcastMissionPrep", NAW_OnReveal, '', '', ELD_OnStateSubmitted, NPC_Once, '', CinematicComplete);
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.GP_BroadcastTheTruthScreen", NAW_OnReveal, 'CinematicComplete', '', ELD_OnStateSubmitted, NPC_Once, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.S_Broadcast_Mission_No_Turning_Back_Central", NAW_OnReveal, 'OnLaunchBroadcastMission', '', ELD_OnStateSubmitted, NPC_Once, '');
	Template.AddNarrativeTrigger("X2NarrativeMoments.Central_Broadcast_Marked_On_Geoscape", NAW_OnReveal, 'EnterSquadSelectBroadcast', '', ELD_OnStateSubmitted, NPC_Once, '');

	return Template;
}

static function X2DataTemplate CreateT5_M2_L0_LookAtBroadcastTemplate()
{
	local X2ObjectiveTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ObjectiveTemplate', Template, 'T5_M2_L0_LookAtBroadcast');
	Template.bMainObjective = true;
	Template.bNeverShowObjective = true;

	Template.CompletionEvent = 'CameraAtBroadcast';

	Template.AddNarrativeTrigger("", NAW_OnAssignment, 'OnEnteredFacility_CIC', '', ELD_OnStateSubmitted, NPC_Once, '', EnableFlightMode);
	Template.AddNarrativeTrigger("", NAW_OnAssignment, 'OnGeoscapeEntry', '', ELD_OnStateSubmitted, NPC_Once, '', CameraLookAtBroadcastOpenUI);
	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.S_Broadcast_Mission_Appears_Central", NAW_OnCompletion, '', '', ELD_OnStateSubmitted, NPC_Once, '');

	return Template;
}

static function CreateBroadcastTheTruthMission(XComGameState NewGameState, XComGameState_Objective ObjectiveState)
{
	local XComGameStateHistory History;
	local XComGameState_MissionCalendar CalendarState;
	local array<XComGameState_Reward> Rewards;
	
	CreateMission(NewGameState, Rewards, 'MissionSource_Broadcast', 2, true);
	
	// Update the calendar to use the end game mission decks
	foreach NewGameState.IterateByClassType(class'XComGameState_MissionCalendar', CalendarState)
	{
		break;
	}

	if (CalendarState == none)
	{
		History = `XCOMHISTORY;
		CalendarState = XComGameState_MissionCalendar(History.GetSingleGameStateObjectForClass(class'XComGameState_MissionCalendar'));
		CalendarState = XComGameState_MissionCalendar(NewGameState.ModifyStateObject(class'XComGameState_MissionCalendar', CalendarState.ObjectID));
	}

	CalendarState.SwitchToEndGameMissions(NewGameState);
}

function CameraLookAtBroadcastOpenUI()
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_MissionSite MissionState;

	History = `XCOMHISTORY;
	foreach History.IterateByClassType(class'XComGameState_MissionSite', MissionState)
	{
		if (MissionState.GetMissionSource().DataName == 'MissionSource_Broadcast')
		{
			break;
		}
	}

	`HQPRES.CAMLookAtEarth(MissionState.Get2DLocation(), 0.5f);

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Cam Look at Broadcast");
	`XEVENTMGR.TriggerEvent('CameraAtBroadcast', , , NewGameState);
	`GAMERULES.SubmitGameState(NewGameState);

	`HQPRES.OnMissionSelected(MissionState, false);

	DisableFlightMode();
}


// #######################################################################################
// -------------------- T5 M3 --------------------------------------------------

static function X2DataTemplate CreateT5_M3_CompleteFinalMissionTemplate()
{
	local X2ObjectiveTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ObjectiveTemplate', Template, 'T5_M3_CompleteFinalMission');
	Template.bMainObjective = true;
	Template.ImagePath = "img:///UILibrary_StrategyImages.X2StrategyMap.Alert_Alien_Fortress";

	Template.AssignObjectiveFn = CreateFinalMission;
	Template.CompletionEvent = '';	

	Template.NagDelayHours = 336;

	Template.AddNarrativeTrigger("X2NarrativeMoments.Strategy.GP_FinalMissionScreen", NAW_OnReveal, 'PostMissionDone', '', ELD_OnStateSubmitted, NPC_Once, '');

	return Template;
}

static function CreateFinalMission(XComGameState NewGameState, XComGameState_Objective ObjectiveState)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local array<XComGameState_Reward> Rewards;
	local XComGameState_MissionSite MissionState;

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

	XComHQ.bNeedsToSeeFinalMission = true;

	foreach NewGameState.IterateByClassType(class'XComGameState_MissionSite', MissionState)
	{
		if(MissionState.Source == 'MissionSource_Final')
		{
			MissionState.bNotAtThreshold = false;
			return;
		}
	}

	foreach History.IterateByClassType(class'XComGameState_MissionSite', MissionState)
	{
		if(MissionState.Source == 'MissionSource_Final')
		{
			MissionState = XComGameState_MissionSite(NewGameState.ModifyStateObject(class'XComGameState_MissionSite', MissionState.ObjectID));
			MissionState.bNotAtThreshold = false;
			return;
		}
	}

	CreateMission(NewGameState, Rewards, 'MissionSource_Final', 0, true, true, false, , , true, default.FortressLocation);
}

// #######################################################################################
// -------------------- SPECIAL OBJECTIVES --------------------------------------------------

static function X2DataTemplate CreateS0_RevealAvatarProjectTemplate()
{
	local X2ObjectiveTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ObjectiveTemplate', Template, 'S0_RevealAvatarProject');
	Template.bMainObjective = true;
	Template.bNeverShowObjective = true;
		
	Template.RevealEvent = 'AvatarProjectRevealed';
	Template.CompletionEvent = 'AvatarProjectRevealComplete';

	Template.AddNarrativeTrigger("X2NarrativeMoments.CIN_Avatar_Project", NAW_OnReveal, '', '', ELD_OnStateSubmitted, NPC_Once, '', AvatarProjectCinematicComplete);
	Template.AddNarrativeTrigger("X2NarrativeMoments.S_GP_Avatar_Bar_Geoscape_Central", NAW_OnAssignment, 'CameraAtFortress', '', ELD_OnStateSubmitted, NPC_Once, '', AvatarProjectRevealComplete);

	return Template;
}

function AvatarProjectCinematicComplete()
{
	if (`GAME.GetGeoscape().IsScanning())
		`HQPRES.StrategyMap2D.ToggleScan();

	CameraLookAtFortressOpenUI();
}

function CameraLookAtFortressOpenUI()
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_MissionSite MissionState;
	local XComGameState_HeadquartersAlien AlienHQ;

	History = `XCOMHISTORY;
	foreach History.IterateByClassType(class'XComGameState_MissionSite', MissionState)
	{
		if (MissionState.GetMissionSource().DataName == 'MissionSource_Final')
		{
			break;
		}
	}

	`HQPRES.CAMLookAtEarth(MissionState.Get2DLocation(), 0.5f);

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Cam Look at Fortress");
	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));
	AlienHQ = XComGameState_HeadquartersAlien(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersAlien', AlienHQ.ObjectID));
	AlienHQ.MakeFortressAvailable(NewGameState);
	`HQPRES.StrategyMap2D.StrategyMapHUD.SetDoomMessage(MissionState.GetMissionSource().DoomLabel, false, false);
	`XEVENTMGR.TriggerEvent('CameraAtFortress', , , NewGameState);
	`GAMERULES.SubmitGameState(NewGameState);

	`HQPRES.OnMissionSelected(MissionState, false);
}

function AvatarProjectRevealComplete()
{
	local XComGameState NewGameState;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Trigger Event: Avatar Project Reveal Complete");
	`XEVENTMGR.TriggerEvent('AvatarProjectRevealComplete', , , NewGameState);
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

static function X2DataTemplate CreateS1_ShortenFirstPOITemplate()
{
	local X2ObjectiveTemplate Template;

	`CREATE_X2TEMPLATE(class'X2ObjectiveTemplate', Template, 'S1_ShortenFirstPOI');
	Template.bMainObjective = true;
	Template.bNeverShowObjective = true;

	Template.CompletionEvent = 'RumorAppeared';

	// No triggers, only used to shorten the length of the first POI

	return Template;
}


// #######################################################################################
// #######################################################################################
// #######################################################################################
// #######################################################################################
// #######################################################################################
// #######################################################################################
// -------------------- Helpers --------------------------------------------------
// #######################################################################################
// #######################################################################################
// #######################################################################################
// #######################################################################################
// #######################################################################################
// #######################################################################################

function XComGameState_Reward BuildMissionItemReward(XComGameState NewGameState, Name TemplateName)
{
	local X2RewardTemplate RewardTemplate;
	local XComGameState_Reward RewardState;
	local X2StrategyElementTemplateManager StratMgr;
	local X2ItemTemplateManager ItemMgr;
	local X2ItemTemplate ItemTemplate;
	local XComGameState_Item ItemState;

	// create the item reward
	StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();

	RewardTemplate = X2RewardTemplate(StratMgr.FindStrategyElementTemplate('Reward_Item'));
	RewardState = RewardTemplate.CreateInstanceFromTemplate(NewGameState);

	ItemMgr = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	ItemTemplate = ItemMgr.FindItemTemplate(TemplateName);
	ItemState = ItemTemplate.CreateInstanceFromTemplate(NewGameState);
	RewardState.RewardObjectReference = ItemState.GetReference();

	return RewardState;
}

static function XComGameState_MissionSite CreateMission(XComGameState NewGameState, out array<XComGameState_Reward> MissionRewards, Name MissionSourceTemplateName,
												 int IdealDistanceFromResistanceNetwork, optional bool bForceAtThreshold = false, 
												 optional bool bSetMissionData = false, optional bool bAvailable = true, 
												 optional XComGameState_WorldRegion AvoidRegion = none, optional int IdealDistanceFromRegion = -1, 
												 optional bool bNoRegion, optional Vector2D ForceLocation, optional name ForceRegionName = '', optional XComGameState_Continent ExcludeContinent = none)
{
	local XComGameState_MissionSite MissionState;
	local X2RewardTemplate RewardTemplate;
	local XComGameState_Reward RewardState;
	local XComGameState_WorldRegion RegionState;
	local X2StrategyElementTemplateManager StratMgr;
	local X2MissionSourceTemplate MissionSource;
	local StateObjectReference RegionRef;
	local Vector2D v2Loc;

	StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();

	// Create the mission site
	MissionState = XComGameState_MissionSite(NewGameState.CreateNewStateObject(class'XComGameState_MissionSite'));

	if(MissionRewards.Length == 0)
	{
		RewardTemplate = X2RewardTemplate(StratMgr.FindStrategyElementTemplate('Reward_None'));
		RewardState = RewardTemplate.CreateInstanceFromTemplate(NewGameState);
		MissionRewards.AddItem(RewardState);
	}

	// select the mission source
	MissionSource = X2MissionSourceTemplate(StratMgr.FindStrategyElementTemplate(MissionSourceTemplateName));

	// select the region for the mission
	if(!bNoRegion)
	{
		RegionState = SelectRegionForMission(NewGameState, IdealDistanceFromResistanceNetwork, AvoidRegion, IdealDistanceFromRegion, ForceRegionName, ExcludeContinent);
		RegionRef = RegionState.GetReference();

		// have to set the initial "threshold" for mission visibility
		MissionState.bNotAtThreshold = (!RegionState.HaveMadeContact());
	}
	else
	{
		MissionState.bNotAtThreshold = true;
	}

	// build the mission, location needs to be updated when map generates if not forced
	if(ForceLocation != v2Loc)
	{
		v2Loc = ForceLocation;
	}
	else
	{
		MissionState.bNeedsLocationUpdate = true;
	}

	MissionState.BuildMission(MissionSource, v2Loc, RegionRef, MissionRewards, bAvailable, false, , , , , bSetMissionData);
	
	if(bForceAtThreshold)
	{
		MissionState.bNotAtThreshold = false;
	}

	return MissionState;
}

static function XComGameState_WorldRegion SelectRegionForMission(XComGameState NewGameState, int IdealDistanceFromResistanceNetwork, optional XComGameState_WorldRegion AvoidRegion = none,
														  optional int IdealDistanceFromRegion = -1, optional name ForceRegionName = '', optional XComGameState_Continent ExcludeContinent = none)
{
	local XComGameStateHistory History;
	local XComGameState_WorldRegion RegionState, TempRegion;
	local array<XComGameState_WorldRegion> AllRegions, PreferredRegions, BestRegions, AvoidRegions;
	local int BestLinkDiff, CurrentLinkDiff;

	History = `XCOMHISTORY;

	//Gather a list of all regions
	if( NewGameState.GetContext().IsStartState() )
	{
		foreach NewGameState.IterateByClassType(class'XComGameState_WorldRegion', RegionState)
		{
			if(RegionState.GetMyTemplateName() == ForceRegionName)
			{
				return RegionState;
			}
			AllRegions.AddItem(RegionState);
		}
	}
	else
	{
		foreach History.IterateByClassType(class'XComGameState_WorldRegion', RegionState)
		{
			if(RegionState.GetMyTemplateName() == ForceRegionName)
			{
				return RegionState;
			}
			AllRegions.AddItem(RegionState);
		}
	}

	BestLinkDiff = -1;

	//Make a list of valid regions based on ideal link distance
	foreach AllRegions(RegionState)
	{
		// TODO: track which regions have been selected for GP missions and exclude those from this list (maybe?)

		if(ExcludeContinent == none || ExcludeContinent.Regions.Find('ObjectID', RegionState.ObjectID) == INDEX_NONE)
		{
			CurrentLinkDiff = Abs(IdealDistanceFromResistanceNetwork - RegionState.GetLinkCountToMinResistanceLevel(eResLevel_Contact));

			if(BestLinkDiff == -1 || CurrentLinkDiff < BestLinkDiff)
			{
				BestLinkDiff = CurrentLinkDiff;
				PreferredRegions.Length = 0;
				PreferredRegions.AddItem(RegionState);
			}
			else if(CurrentLinkDiff == BestLinkDiff)
			{
				PreferredRegions.AddItem(RegionState);
			}
		}	
	}

	if(PreferredRegions.Length == 0)
	{
		PreferredRegions = AllRegions;
	}

	if(AvoidRegion != none && IdealDistanceFromRegion > 0)
	{
		BestLinkDiff = -1;
		AvoidRegions.AddItem(AvoidRegion);
		
		foreach PreferredRegions(RegionState)
		{
			CurrentLinkDiff = Abs(IdealDistanceFromRegion - RegionState.FindClosestRegion(AvoidRegions, TempRegion));

			if(BestLinkDiff == -1 || CurrentLinkDiff < BestLinkDiff)
			{
				BestLinkDiff = CurrentLinkDiff;
				BestRegions.Length = 0;
				BestRegions.AddItem(RegionState);
			}
			else if(CurrentLinkDiff == BestLinkDiff)
			{
				BestRegions.AddItem(RegionState);
			}
		}
	}
	
	if(BestRegions.Length > 0)
	{
		return BestRegions[`SYNC_RAND_STATIC(BestRegions.Length)];
	}

	return PreferredRegions[`SYNC_RAND_STATIC(PreferredRegions.Length)];
}

static function bool ResearchInProgress(name TechTemplateName)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Tech TechState;
	local X2TechTemplate TechTemplate;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	TechState = XComHQ.GetCurrentResearchTech();
	if (TechState != none) 
	{
		TechTemplate = TechState.GetMyTemplate();
		if (TechTemplate != none && TechTemplate.DataName == TechTemplateName)
		{
			return true;
		}
	}

	TechState = XComHQ.GetCurrentShadowTech();
	if (TechState != none)
	{
		TechTemplate = TechState.GetMyTemplate();
		if (TechTemplate != none && TechTemplate.DataName == TechTemplateName)
		{
			return true;
		}
	}

	TechState = XComHQ.GetCurrentProvingGroundTech();
	if (TechState != none)
	{
		TechTemplate = TechState.GetMyTemplate();
		if (TechTemplate != none && TechTemplate.DataName == TechTemplateName)
		{
			return true;
		}
	}

	return false;
}

static function bool MakingContactInProgress(StateObjectReference RegionRef)
{
	local XComGameStateHistory History;
	local XComGameState_WorldRegion RegionState;

	History = `XCOMHISTORY;
	RegionState = XComGameState_WorldRegion(History.GetGameStateForObjectID(RegionRef.ObjectID));

	if(RegionState != none && RegionState.bCanScanForContact)
	{
		return true;
	}

	return false;
}

static function bool BuildItemInProgress(name ItemTemplateName)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_HeadquartersProjectBuildItem ItemProject;
	local XComGameState_Item ItemState;
	local int idx;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	for(idx = 0; idx < XComHQ.Projects.Length; idx++)
	{
		ItemProject = XComGameState_HeadquartersProjectBuildItem(History.GetGameStateForObjectID(XComHQ.Projects[idx].ObjectID));
		
		if(ItemProject != none)
		{
			ItemState = XComGameState_Item(History.GetGameStateForObjectID(ItemProject.ProjectFocus.ObjectID));

			if(ItemState != none && ItemState.GetMyTemplateName() == ItemTemplateName)
			{
				return true;
			}
		}
	}

	return false;
}

static function bool BuildFacilityInProgress(name FacilityTemplateName)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_HeadquartersProjectBuildFacility FacilityProject;
	local XComGameState_FacilityXCom FacilityState;
	local int idx;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	for(idx = 0; idx < XComHQ.Projects.Length; idx++)
	{
		FacilityProject = XComGameState_HeadquartersProjectBuildFacility(History.GetGameStateForObjectID(XComHQ.Projects[idx].ObjectID));

		if(FacilityProject != none)
		{
			FacilityState = XComGameState_FacilityXCom(History.GetGameStateForObjectID(FacilityProject.ProjectFocus.ObjectID));

			if(FacilityState != none && FacilityState.GetMyTemplateName() == FacilityTemplateName)
			{
				return true;
			}
		}
	}

	return false;
}

static function RequireAttentionToRoom(Name RoomName, bool ForceClearToHUD, bool LockOtherRooms, optional bool bLockOnlyGrid = false, optional int RoomIndex = -1)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_FacilityXCom Facility;
	local XComGameState_HeadquartersRoom Room;
	local int idx;
	local XComGameState NewGameState;
	local XComHQPresentationLayer HQPres;

	// kick the user back to the side view
	HQPres = `HQPRES;

	if( ForceClearToHUD )
	{
		HQPres.ClearUIToHUD();
	}

	History = `XCOMHISTORY;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Kick to " $ RoomName);
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	// trigger the "needs attention" on the facility
	for( idx = 0; idx < XComHQ.Facilities.Length; idx++ )
	{
		Facility = XComGameState_FacilityXCom(History.GetGameStateForObjectID(XComHQ.Facilities[idx].ObjectID));
		Facility = XComGameState_FacilityXCom(NewGameState.ModifyStateObject(class'XComGameState_FacilityXCom', Facility.ObjectID));

		if( Facility.GetMyTemplateName() == RoomName )
		{
			Facility.TriggerNeedsAttention();

			Facility.bTutorialLocked = false;
		}
		else
		{
			Facility.bTutorialLocked = LockOtherRooms;
		}
	}

	for( idx = 0; idx < XComHQ.Rooms.Length; idx++ )
	{
		Room = XComGameState_HeadquartersRoom(History.GetGameStateForObjectID(XComHQ.Rooms[idx].ObjectID));
		Room = XComGameState_HeadquartersRoom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersRoom', Room.ObjectID));

		Room.bTutorialLocked = LockOtherRooms;

		if(bLockOnlyGrid && !Room.HasFacility())
		{
			Room.bTutorialLocked = true;
		}

		if(Room.MapIndex == RoomIndex)
		{
			Room.bTutorialLocked = false;
		}
	}

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	HQPres.m_kFacilityGrid.UpdateData();
	HQPres.m_kAvengerHUD.Shortcuts.UpdateCategories();
	HQPres.m_kAvengerHUD.NavHelp.AddGeoscapeButton();
}

function bool SkullJackOnHand()
{
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState;

	History = `XCOMHISTORY;
	
	foreach History.IterateByClassType(class'XComGameState_Unit', UnitState, eReturnType_Reference)
	{
		if (UnitState.GetTeam() == eTeam_XCom)
		{
			if (UnitState.HasItemOfTemplateType('SKULLJACK'))
			{
				return true;
			}
		}
	}

	return false;
}

static function bool DontCompleteWithSimCombat()
{
	return false;
}

// #######################################################################################
// -------------------- DIFFICULTY HELPERS -----------------------------------------------
// #######################################################################################

static function int GetKillCodexMinDoom()
{
	return `ScaleStrategyArrayInt(default.KillCodexMinDoom);
}

static function int GetKillCodexMaxDoom()
{
	return `ScaleStrategyArrayInt(default.KillCodexMaxDoom);
}

static function float GetAverageKillCodexDoom()
{
	return ((float(GetKillCodexMinDoom()) + float(GetKillCodexMaxDoom())) / 2.0f);
}

static function int GetKillAvatarMinDoom()
{
	return `ScaleStrategyArrayInt(default.KillAvatarMinDoom);
}

static function int GetKillAvatarMaxDoom()
{
	return `ScaleStrategyArrayInt(default.KillAvatarMaxDoom);
}

static function float GetAverageKillAvatarDoom()
{
	return ((float(GetKillAvatarMinDoom()) + float(GetKillAvatarMaxDoom())) / 2.0f);
}

static function int GetBlacksiteSupplyAmount()
{
	return `ScaleStrategyArrayInt(default.BlacksiteSupplyAmount);
}

static function int GetPsiGateForgeSupplyAmount()
{
	return `ScaleStrategyArrayInt(default.PsiGateForgeSupplyAmount);
}

static function int GetPsiGateForgeSupplyAdd()
{
	return `ScaleStrategyArrayInt(default.PsiGateForgeSupplyAdd);
}