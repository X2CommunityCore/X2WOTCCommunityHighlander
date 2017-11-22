class UIAlert extends UIX2SimpleScreen
	dependson(XComPhotographer_Strategy);


struct TAlertCompletedInfo
{
	var String strName;
	var String strHeaderLabel;
	var String strBody;
	var String strHelp;
	var String strHeadImage1;
	var String strHeadImage2;
	var String strImage;
	var String strConfirm;
	var String strCarryOn;
	var EUIState eColor;
	var LinearColor clrAlert;
	var int Staff1ID;
	var int Staff2ID;
	var string strStaff1Title;
	var string strStaff2Title; 
	var string strHeaderIcon;
};

struct TAlertAvailableInfo
{
	var String strTitle;
	var String strName;
	var String strBody;
	var String strHelp;
	var String strImage;
	var String strConfirm;
	var EUIState eColor;
	var LinearColor clrAlert;
	var String strHeadImage1;
	var int Staff1ID;
	var string strStaff1Title;
	var string strHeaderIcon;
};

struct TAlertPOIAvailableInfo
{
	var Vector2D zoomLocation;
	var String strTitle;
	var String strLabel;
	var String strBody;
	var String strImage;
	var String strReport;
	var String strReward;
	var String strRewardIcon;
	var String strDurationLabel;
	var String strDuration;
	var String strInvestigate;
	var String strIgnore;
	var String strFlare;
	var String strUIIcon;
	var EUIState eColor;
	var LinearColor clrAlert;
};

struct TAlertHelpInfo
{
	var String strHeader;
	var String strTitle;
	var String strDescription;
	var String strImage;
	var String strConfirm;
	var String strCarryOn;
};

var public localized String m_strCouncilCommTitle;
var public localized String m_strCouncilCommConfirm;

var public localized String m_strCouncilMissionTitle;
var public localized String m_strCouncilMissionLabel;
var public localized String m_strCouncilMissionBody;
var public localized String m_strCouncilMissionFlare;
var public localized String m_strCouncilMissionConfirm;
var public localized String m_strCouncilMissionImage;

var public localized String m_strGOpsTitle;
var public localized String m_strGOpsTitle_Sing;
var public localized String m_strGOpsSubtitle;
var public localized String m_strGOpsBody;
var public localized String m_strGOpsBody_Sing;
var public localized String m_strGOpsFlare;
var public localized String m_strGOpsConfirm;
var public localized String m_strGOpsConfirm_Sing;
var public localized String m_strGOpsImage;

var public localized String m_strRetaliationTitle;
var public localized String m_strRetaliationLabel;
var public localized String m_strRetaliationBody;
var public localized String m_strRetaliationFlare;
var public localized String m_strRetaliationConfirm;
var public localized String m_strRetaliationImage;

var public localized String m_strSupplyRaidTitle;
var public localized String m_strSupplyRaidLabel;
var public localized String m_strSupplyRaidBody;
var public localized String m_strSupplyRaidFlare;
var public localized String m_strSupplyRaidConfirm;
var public localized String m_strSupplyRaidImage;
var public localized String m_strSupplyRaidHeader;

var public localized String m_strLandedUFOTitle;
var public localized String m_strLandedUFOLabel;
var public localized String m_strLandedUFOBody;
var public localized String m_strLandedUFOFlare;
var public localized String m_strLandedUFOConfirm;
var public localized String m_strLandedUFOImage;

var public localized String m_strFacilityTitle;
var public localized String m_strFacilityLabel;
var public localized String m_strFacilityBody;
var public localized String m_strFacilityConfirm;
var public localized String m_strFacilityImage;

var public localized String m_strControlLabel;
var public localized String m_strControlBody;
var public localized String m_strControlFlare;
var public localized String m_strControlConfirm;
var public localized String m_strControlImage;

var public localized String m_strDoomTitle;
var public localized String m_strDoomLabel;
var public localized String m_strDoomBody;
var public localized String m_strDoomConfirm;
var public localized String m_strDoomImage;
var public localized String m_strHiddenDoomLabel;
var public localized String m_strHiddenDoomBody;

var public localized String m_strUFOInboundTitle;
var public localized String m_strUFOInboundLabel;
var public localized String m_strUFOInboundBody;
var public localized String m_strUFOInboundConfirm;
var public localized String m_strUFOInboundImage;
var public localized String m_strUFOInboundDistanceLabel;
var public localized String m_strUFOInboundDistanceUnits;
var public localized String m_strUFOInboundSpeedLabel;
var public localized String m_strUFOInboundSpeedUnits;
var public localized String m_strUFOInboundTimeLabel;

var public localized String m_strUFOEvadedTitle;
var public localized String m_strUFOEvadedLabel;
var public localized String m_strUFOEvadedBody;
var public localized String m_strUFOEvadedConfirm;
var public localized String m_strUFOEvadedImage;

var public localized String m_strObjectiveTitle;
var public localized String m_strObjectiveFlare;
var public localized String m_strObjectiveTellMeMore;

var public localized String m_strContactTitle;
var public localized String m_strContactCostLabel;
var public localized String m_strContactCostHelp;
var public localized String m_strContactTimeLabel;
var public localized String m_strContactBody;
var public localized String m_strContactNeedResComms;
var public localized String m_strContactConfirm;
var public localized String m_strContactHelp;

var public localized String m_strOutpostTitle;
var public localized String m_strOutpostCostLabel;
var public localized String m_strOutpostTimeLabel;
var public localized String m_strOutpostBody;
var public localized String m_strOutpostConfirm;
var public localized String m_strOutpostReward;
var public localized String m_strOutpostHelp;

var public localized String m_strContactMadeTitle;
var public localized String m_strContactMadeIncome;
var public localized String m_strContactMadeBody;

var public localized String m_strOutpostBuiltTitle;
var public localized String m_strOutpostBuiltIncome;
var public localized String m_strOutpostBuiltBody;

var public localized String m_strContinentTitle;
var public localized String m_strContinentFlare;
var public localized String m_strContinentBonusLabel;

var public localized String m_strUnlockedLabel;
var public localized String m_strUnlockedBody;
var public localized String m_strFirstUnlockedBody;
var public localized String m_strUnlockedHelp;
var public localized String m_strUnlockedFlare;
var public localized String m_strUnlockedConfirm;
var public localized String m_strUnlockedImage;

var public localized String m_strPOITitle;
var public localized String m_strPOILabel;
var public localized String m_strPOIBody;
var public localized String m_strPOIReport;
var public localized String m_strPOIReward;
var public localized String m_strPOIDuration;
var public localized String m_strPOIFlare;
var public localized String m_strPOIInvestigate;
var public localized String m_strPOIImage;

var public localized String m_strPOICompleteLabel;
var public localized String m_strPOICompleteFlare;
var public localized String m_strPOIReturnToHQ;

var public localized String m_strResourceCacheAvailableTitle;
var public localized String m_strResourceCacheAvailableBody;

var public localized String m_strResourceCacheCompleteTitle;
var public localized String m_strResourceCacheCompleteLabel;
var public localized String m_strResourceCacheCompleteBody;
var public localized String m_strResourceCacheCompleteFlare;
var public localized String m_strResourceCacheCompleteImage;

var public localized String m_strInstantResourceCacheTitle;
var public localized String m_strInstantResourceCacheBody;

var public localized String m_strBlackMarketAvailableBody;
var public localized String m_strBlackMarketAvailableAgainBody;
var public localized String m_strBlackMarketDuration;
var public localized String m_strBlackMarketTitle;
var public localized String m_strBlackMarketLabel;
var public localized String m_strBlackMarketBody;
var public localized String m_strBlackMarketConfirm;
var public localized String m_strBlackMarketImage;
var public localized String m_strBlackMarketFooterLeft;
var public localized String m_strBlackMarketFooterRight;
var public localized String m_strBlackMarketLogoString;

// The Text that will fill out the header of the UIScreen when eAlert == eAlert_Objective.
var string				ObjectiveUIHeaderText;

// The Text that will fill out the body of the UIScreen when eAlert == eAlert_Objective.
var string				ObjectiveUIBodyText;

// The path to the image that will fill out the UIScreen when eAlert == eAlert_Objective.
var string				ObjectiveUIImagePath;

// The Text that will fill out the array of additional strings of the UIScreen when eAlert == eAlert_Objective.
var array<string>		ObjectiveUIArrayText;

var public localized String m_strResearchCompleteLabel;
var public localized String m_strResearchProjectComplete;
var public localized String m_strAssignNewResearch;
var public localized String m_strCarryOn;
var public localized String m_strResearchIntelReward;

var public localized String m_strShadowProjectCompleteLabel;
var public localized String m_strShadowProjectComplete;
var public localized String m_strViewReport;

var public localized String m_strItemCompleteLabel;
var public localized String m_strManufacturingComplete;
var public localized String m_strAssignNewProjects;

var public localized String m_strProvingGroundProjectCompleteLabel;
var public localized String m_strProvingGroundProjectComplete;

var public localized String m_strFacilityContructedLabel;
var public localized String m_strConstructionComplete;
var public localized String m_strAssignNewConstruction;
var public localized String m_strViewFacility;

var public localized String m_strUpgradeContructedLabel;
var public localized String m_strUpgradeComplete;
var public localized String m_strAssignNewUpgrade;

var public localized String m_strClearRoomCompleteLabel;
var public localized String m_strClearRoomComplete;
var public localized String m_strBuilderAvailable;
var public localized String m_strViewRoom;
var public localized String m_strClearRoomLoot;

var public localized String m_strTrainingCompleteLabel;
var public localized String m_strSoldierPromoted;
var public localized String m_strSoldierPromotedLabel;
var public localized String m_strPsiSoldierPromoted;
var public localized String m_strViewSoldier;
var public localized String m_strNewAbilityLabel;

var public localized String m_strPsiTrainingCompleteLabel;
var public localized String m_strPsiTrainingCompleteRank;
var public localized String m_strPsiTrainingCompleteHelp;
var public localized String m_strPsiTrainingComplete;
var public localized String m_strContinueTraining;

var public localized String m_strIntroToPsiLab;
var public localized String m_strIntroToPsiLabBody;

var public localized String m_strPsiOperativeIntroTitle;
var public localized String m_strPsiOperativeIntro;
var public localized String m_strPsiOperativeIntroHelp;

var public localized String m_strTrainingCenterIntroTitle;
var public localized String m_strTrainingCenterIntroLabel;
var public localized String m_strTrainingCenterIntroBody;

var public localized String m_strInfirmaryIntroTitle;
var public localized String m_strInfirmaryIntroLabel;
var public localized String m_strInfirmaryIntroBody;

var public localized String m_strStaffSlotOpenLabel;
var public localized String m_strBuildStaffSlotOpen;
var public localized String m_strClearRoomStaffSlotOpen;
var public localized String m_strEngStaffSlotOpen;
var public localized String m_strSciStaffSlotOpen;
var public localized String m_strStaffSlotOpenBenefit;
var public localized String m_strDoctorHonorific;

var public localized String m_strStaffSlotFilledTitle;
var public localized String m_strStaffSlotFilledLabel;
var public localized String m_strClearRoomSlotFilledLabel;
var public localized String m_strClearRoomSlotFilled;
var public localized String m_strConstructionSlotFilledLabel;
var public localized String m_strConstructionSlotFilled;

var public localized String m_strAttentionCommander;
var public localized String m_strNewStaffAvailableTitle;
var public localized String m_strNewSoldierAvailableTitle;
var public localized String m_strNewSoldierAvailable;
var public localized String m_strNewSciAvailable;
var public localized String m_strNewEngAvailable;
var public localized String m_strNewStaffAvailableSlots;
var public localized String m_strStaffRecoveredTitle;

var public localized String m_strStaffInfoTitle;
var public localized String m_strStaffInfoBonus;

var public localized String m_strNewResearchAvailable;
var public localized String m_strInstantResearchAvailable;
var public localized String m_strInstantResearchAvailableBody;
var public localized String m_strNewShadowProjectAvailable;
var public localized String m_strNewFacilityAvailable;
var public localized String m_strNewUpgradeAvailable;
var public localized String m_strNewItemAvailable;
var public localized String m_strNewItemReceived;
var public localized String m_strNewItemReceivedProvingGround;
var public localized String m_strItemReceivedInInventory;
var public localized String m_strNewItemUpgraded;
var public localized String m_strNewProvingGroundProjectAvailable;

var public localized String m_strNegativeTraitAcquiredTitle;
var public localized String m_strPositiveTraitAcquiredTitle;

var public localized String m_strSoldierShakenTitle;
var public localized String m_strSoldierShakenHeader;
var public localized String m_strSoldierShaken;
var public localized String m_strSoldierShakenHelp;

var public localized String m_strSoldierShakenRecoveredTitle;
var public localized String m_strSoldierShakenRecovered;
var public localized String m_strSoldierShakenRecoveredHelp;

var public localized String m_strDarkEventLabel;
var public localized String m_strDarkEventBody;

var public localized String m_strMissionExpiredLabel;
var public localized String m_strMissionExpiredFlare;
var public localized String m_strMissionExpiredLostContact;
var public localized String m_strMissionExpiredImage;

var public localized String m_strTimeSensitiveMissionLabel;
var public localized String m_strTimeSensitiveMissionText;
var public localized String m_strTimeSensitiveMissionFlare;
var public localized String m_strTimeSensitiveMissionImage;
var public localized String m_strFlyToMission;
var public localized String m_strSkipTimeSensitiveMission;

var public localized String m_strItemUnlock;
var public localized String m_strFacilityUnlock;
var public localized String m_strUpgradeUnlock;
var public localized String m_strResearchUnlock;
var public localized String m_strProjectUnlock;

var public localized String m_strWeaponUpgradesAvailableTitle;
var public localized String m_strWeaponUpgradesAvailableBody;

var public localized String m_strNewCustomizationsAvailableTitle;
var public localized String m_strNewCustomizationsAvailableBody;

var public localized String m_strForceUnderstrengthTitle;
var public localized String m_strForceUnderstrengthBody;

var public localized String m_strWoundedSoldiersAllowedTitle;
var public localized String m_strWoundedSoldiersAllowedBody;

var public localized String m_strStrongholdMissionWarningTitle;
var public localized String m_strStrongholdMissionWarningBody;

var public localized String m_strAlienVictoryImminentTitle;
var public localized String m_strAlienVictoryImminentBody;
var public localized String m_strAlienVictoryImminentImage;

var public localized String m_strHelpResHQGoodsTitle;
var public localized String m_strHelpResHQGoodsHeader;
var public localized String m_strHelpResHQGoodsDescription;
var public localized String m_strHelpResHQGoodsImage;
var public localized String m_strRecruitNewStaff;

var public localized String m_strBuildRingTitle;
var public localized String m_strBuildRingHeader;
var public localized String m_strBuildRingDescription;
var public localized String m_strBuildRingBody;
var public localized String m_strBuildRingImage;
var public localized array<String> m_strBuildRingList;

var public localized String m_strLowIntelTitle;
var public localized String m_strLowIntelHeader;
var public localized String m_strLowIntelDescription;
var public localized String m_strLowIntelBody;
var public localized String m_strLowIntelImage;
var public localized array<String> m_strLowIntelList;

var public localized String m_strLowSuppliesTitle;
var public localized String m_strLowSuppliesHeader;
var public localized String m_strLowSuppliesDescription;
var public localized String m_strLowSuppliesBody;
var public localized String m_strLowSuppliesImage;
var public localized array<String> m_strLowSuppliesList;

var public localized String m_strLowScientistsTitle;
var public localized String m_strLowScientistsHeader;
var public localized String m_strLowScientistsDescription;
var public localized String m_strLowScientistsBody;
var public localized String m_strLowScientistsImage;
var public localized array<String> m_strLowScientistsList;

var public localized String m_strLowEngineersTitle;
var public localized String m_strLowEngineersHeader;
var public localized String m_strLowEngineersDescription;
var public localized String m_strLowEngineersBody;
var public localized String m_strLowEngineersImage;
var public localized array<String> m_strLowEngineersList;

var public localized String m_strLowScientistsSmallTitle;
var public localized String m_strLowScientistsSmallBody;

var public localized String m_strLowEngineersSmallTitle;
var public localized String m_strLowEngineersSmallBody;

var public localized String m_strSupplyDropReminderTitle;
var public localized String m_strSupplyDropReminderBody;

var public localized String m_strPowerCoilShieldedTitle;
var public localized String m_strPowerCoilShieldedBody;
var public localized array<String> m_strPowerCoilShieldedList;

var public localized String m_strLaunchMissionWarningHeader;
var public localized String m_strLaunchMissionWarningTitle;

var public localized String m_strCovertActionsTitle;
var public localized String m_strCovertActionsLabel;
var public localized String m_strCovertActionsBody;
var public localized String m_strCovertActionsFlare;
var public localized String m_strCovertActionsConfirm;
var public localized String m_strCovertActionsRisksLabel;

var public localized String m_strLostAndAbandonedTitle;
var public localized String m_strLostAndAbandonedLabel;
var public localized String m_strLostAndAbandonedBody;
var public localized String m_strLostAndAbandonedFlare;
var public localized String m_strLostAndAbandonedConfirm;
var public localized String m_strLostAndAbandonedImage;

var public localized String m_strResistanceOpTitle;
var public localized String m_strResistanceOpLabel;
var public localized String m_strResistanceOpBody;
var public localized String m_strResistanceOpFlare;
var public localized String m_strResistanceOpConfirm;
var public localized String m_strResistanceOpImage;

var public localized String m_strChosenAmbushTitle;
var public localized String m_strChosenAmbushLabel;
var public localized String m_strChosenAmbushBody;
var public localized String m_strChosenAmbushFlare;
var public localized String m_strChosenAmbushConfirm;
var public localized String m_strChosenAmbushImage;

var public localized String m_strChosenStrongholdTitle;
var public localized String m_strChosenStrongholdLabel;
var public localized String m_strChosenStrongholdBody;
var public localized String m_strChosenStrongholdConfirm;
var public localized String m_strChosenStrongholdImage;

var public localized String m_strChosenSabotageTitle;
var public localized String m_strChosenSabotageFailedTitle;
var public localized String m_strChosenSabotageFailedBody;

var public localized String m_strChosenFavoredTitle;
var public localized String m_strChosenFavoredBody;

var public localized String m_strRescueSoldierTitle;
var public localized String m_strRescueSoldierLabel;
var public localized String m_strRescueSoldierBody;
var public localized String m_strRescueSoldierFlare;
var public localized String m_strRescueSoldierConfirm;
var public localized String m_strRescueSoldierImage;

var public localized String m_strInspiredResearchAvailable;
var public localized String m_strInspiredResearchAvailableBody;

var public localized String m_strBreakthroughResearchAvailable;
var public localized String m_strBreakthroughResearchAvailableBody;

var public localized String m_strBreakthroughResearchComplete;

var public localized String m_strNewStrategyCardReceivedTitle;
var public localized String m_strNewStrategyCardReceivedBody;

var public localized String m_strComIntIntroTitle;
var public localized String m_strComIntIntro;
var public localized String m_strComIntIntroBody;

var public localized String m_strSitrepIntroHeader;
var public localized String m_strSitrepIntroTitle;
var public localized String m_strSitrepIntroBody;

var public localized String m_strSoldierCompatibilityIntroHeader;
var public localized String m_strSoldierCompatibilityIntroTitle;
var public localized String m_strSoldierCompatibilityIntroBody;

var public localized String m_strSoldierTiredTitle;
var public localized String m_strSoldierTired;
var public localized String m_strSoldierTiredHelp;

var public localized String m_strResistanceOrdersIntroHeader;
var public localized String m_strResistanceOrdersIntroTitle;
var public localized String m_strResistanceOrdersIntroBody;

var public localized String m_strCovertActionIntroHeader;
var public localized String m_strCovertActionIntroTitle;
var public localized String m_strCovertActionIntroBody;

var public localized String m_strCovertActionRiskIntroHeader;
var public localized String m_strCovertActionRiskIntroTitle;
var public localized String m_strCovertActionRiskIntroBody;

var public localized String m_strCantChangeOrdersHeader;
var public localized String m_strCantChangeOrdersTitle;
var public localized String m_strCantChangeOrdersBody;

var public localized String m_strConfirmCovertActionLabel;
var public localized String m_strConfirmCovertActionReward;
var public localized String m_strConfirmCovertActionDuration;
var public localized String m_strConfirmCovertActionBody;
var public localized String m_strConfirmCovertActionOK;

var public localized String m_strNextCovertActionHeader;
var public localized String m_strNextCovertActionTitle;
var public localized String m_strNextCovertActionBody;
var public localized String m_strNextCovertActionConfirm;

var public localized String m_strRetributionAlertTitle;
var public localized String m_strRetributionAlertDescription;
var public localized String m_strRetributionAlertIncomeDecreasedTitle;
var public localized String m_strRetributionAlertIncomeDescription;
var public localized String m_strRetributionAlertKnowledgeTitle;
var public localized String m_strRetributionAlertKnowledgeDescription;

var public localized String m_strReinforcedUnderlayTitle;
var public localized String m_strReinforcedUnderlayBody;

var Name eAlertName;
var DynamicPropertySet DisplayPropertySet;

var bool bAlertTransitionsToMission; // Flag if the alert will transition to mission blades, which will restore the camera when they are closed
var bool bRestoreCameraPosition; // Flag for when an alert should restore the camera to a saved position when it is closed
var bool bRestoreCameraPositionOnReceiveFocus; // Flag for when an alert should restore the camera when it receives focus (only used for TellMeMore)
//var delegate<AlertCallback> fnCallback;
var Texture2D StaffPicture;
//var Name PrimaryTemplateName;
//var Name SecondaryTemplateName;
//
//var string SoundToPlay;
var bool bSoundPlayed;

//var name EventToTrigger;
//var Object EventData;
var bool bEventTriggered;

var bool bInstantInterp;

var UIPanel LibraryPanel, ButtonGroup;
var UIButton Button1, Button2;

var Name XPACK_Package; 

//delegate OnClickedDelegate(UIButton Button);

//----------------------------------------------------------------------------
// MEMBERS

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	//BEFORE THE INIT: must set the alert type 
	SetPackageFromAlertType();

	super.InitScreen(InitController, InitMovie, InitName);
	BuildAlert();
}

simulated function OnInit()
{
	super.OnInit();

	if (Movie.Pres.ScreenStack.IsTopScreen(self))
	{
		PresentUIEffects();
	}
}

simulated function PresentUIEffects()
{
	local XComGameState NewGameState;
	local string SoundToPlay;
	local Name EventToTrigger;
	local Object EventData;
	local Name EventDataTemplateName;
	local int EventDataObjectID;

	if( !bSoundPlayed )
	{
		SoundToPlay = class'X2StrategyGameRulesetDataStructures'.static.GetDynamicStringProperty(DisplayPropertySet, 'SoundToPlay');
		if( SoundToPlay != "" )
		{
		PlaySFX(SoundToPlay);
		bSoundPlayed = true;
		}
	}
		
	if( !bEventTriggered )
	{
		EventToTrigger = class'X2StrategyGameRulesetDataStructures'.static.GetDynamicNameProperty(DisplayPropertySet, 'EventToTrigger');
		if (EventToTrigger != '')
		{
			EventDataTemplateName = class'X2StrategyGameRulesetDataStructures'.static.GetDynamicNameProperty(DisplayPropertySet, 'EventDataTemplate');
			if( EventDataTemplateName != '' )
			{
				EventData = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager().FindStrategyElementTemplate(EventDataTemplateName);
			}
			else
			{
				EventDataObjectID = class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(DisplayPropertySet, 'EventDataRef');

				if( EventDataObjectID > 0 )
				{
					EventData = `XCOMHISTORY.GetGameStateForObjectID(EventDataObjectID);
				}
			}

			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("New Popup Event");
			`XEVENTMGR.TriggerEvent(EventToTrigger, EventData, EventData, NewGameState);
			`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

			bEventTriggered = true;
		}
	}
}

simulated function SetPackageFromAlertType()
{
	switch (eAlertName)
	{
	case 'eAlert_LostAndAbandoned':
	case 'eAlert_ResistanceOp':
	case 'eAlert_RescueSoldier':
	case 'eAlert_NextCovertAction':
	case 'eAlert_XPACK_Retribution':
	case 'eAlert_ConfirmCovertAction':
	case 'eAlert_StrategyCardReceived':
		Package = XPACK_Package;
		break;

	default:
		Package = class'UIAlert'.default.Package;
	}
}

simulated function BuildAlert()
{
	BindLibraryItem();

	switch( eAlertName )
	{
	case 'eAlert_CouncilComm':
		BuildCouncilCommAlert();
		break;
	case 'eAlert_GOps':
		BuildGOpsAlert();
		break;
	case 'eAlert_CouncilMission':
		BuildCouncilMissionAlert();
		break;
	case 'eAlert_Retaliation':
		BuildRetaliationAlert();
		break;
	case 'eAlert_SupplyRaid':
		BuildSupplyRaidAlert();
		break;
	case 'eAlert_LandedUFO':
		BuildLandedUFOAlert();
		break;
	case 'eAlert_AlienFacility':
		BuildFacilityAlert();
		break;
	case 'eAlert_Control':
		BuildControlAlert();
		break;
	case 'eAlert_Doom':
		BuildDoomAlert();
		break;
	case 'eAlert_HiddenDoom':
		BuildHiddenDoomAlert();
		break;
	case 'eAlert_UFOInbound':
		BuildUFOInboundAlert();
		break;
	case 'eAlert_UFOEvaded':
		BuildUFOEvadedAlert();
		break;
	case 'eAlert_Objective':
		BuildObjectiveAlert();
		break;
	case 'eAlert_Contact':
		BuildContactAlert();
		break;
	case 'eAlert_Outpost':
		BuildOutpostAlert();
		break;
	case 'eAlert_ContactMade':
		BuildContactMadeAlert();
		break;
	case 'eAlert_OutpostBuilt':
		BuildOutpostBuiltAlert();
		break;
	case 'eAlert_ContinentBonus':
		BuildContinentAlert();
		break;
	case 'eAlert_RegionUnlocked':
	case 'eAlert_RegionUnlockedMission':
		BuildRegionUnlockedAlert();
		break;
	case 'eAlert_BlackMarketAvailable':
		BuildBlackMarketAvailableAlert();
		break;
	case 'eAlert_BlackMarket':
		BuildBlackMarketAlert();
		break;
	case 'eAlert_ResearchComplete':
		BuildResearchCompleteAlert();
		break;
	case 'eAlert_ItemComplete':
		BuildItemCompleteAlert();
		break;
	case 'eAlert_ProvingGroundProjectComplete':
		BuildProvingGroundProjectCompleteAlert();
		break;
	case 'eAlert_FacilityComplete':
		BuildFacilityCompleteAlert();
		break;
	case 'eAlert_UpgradeComplete':
		BuildUpgradeCompleteAlert();
		break;
	case 'eAlert_ShadowProjectComplete':
		BuildShadowProjectCompleteAlert();
		break;
	case 'eAlert_ClearRoomComplete':
		BuildClearRoomCompleteAlert();
		break;
	case 'eAlert_TrainingComplete':
		BuildTrainingCompleteAlert(m_strTrainingCompleteLabel);
		break;
	case 'eAlert_ClassEarned':
		BuildTrainingCompleteAlert(m_strSoldierPromotedLabel);
		break;
	case 'eAlert_PsiTrainingComplete':
		BuildPsiTrainingCompleteAlert(m_strPsiTrainingCompleteLabel);
		break;
	case 'eAlert_PsiSoldierPromoted':
		BuildPsiTrainingCompleteAlert(m_strPsiSoldierPromoted);
		break;
	case 'eAlert_SoldierPromoted':
		BuildSoldierPromotedAlert();
		break;
	case 'eAlert_PsiLabIntro':
		BuildPsiLabIntroAlert();
		break;
	case 'eAlert_PsiOperativeIntro':
		BuildPsiOperativeIntroAlert();
		break;
	case 'eAlert_TrainingCenterIntro':
		BuildTrainingCenterIntroAlert();
		break;
	case 'eAlert_InfirmaryIntro':
		BuildInfirmaryIntroAlert();
		break;
	case 'eAlert_BuildSlotOpen':
		BuildConstructionSlotOpenAlert();
		break;
	case 'eAlert_ClearRoomSlotOpen':
		BuildClearRoomSlotOpenAlert();
		break;
	case 'eAlert_StaffSlotOpen':
		BuildStaffSlotOpenAlert();
		break;
	case 'eAlert_BuildSlotFilled':
		BuildConstructionSlotFilledAlert();
		break;
	case 'eAlert_ClearRoomSlotFilled':
		BuildClearRoomSlotFilledAlert();
		break;
	case 'eAlert_StaffSlotFilled':
		BuildStaffSlotFilledAlert();
		break;
	case 'eAlert_SuperSoldier':
		BuildSuperSoldierAlert();
		break;
	case 'eAlert_ResearchAvailable':
		BuildResearchAvailableAlert();
		break;
	case 'eAlert_InstantResearchAvailable':
		BuildInstantResearchAvailableAlert();
		break;
	case 'eAlert_ItemAvailable':
		BuildItemAvailableAlert();
		break;
	case 'eAlert_ItemReceived':
		BuildItemReceivedAlert();
		break;
	case 'eAlert_ItemReceivedProvingGround':
		BuildItemReceivedProvingGroundAlert();
		break;
	case 'eAlert_ItemUpgraded':
		BuildItemUpgradedAlert();
		break;
	case 'eAlert_ProvingGroundProjectAvailable':
		BuildProvingGroundProjectAvailableAlert();
		break;
	case 'eAlert_FacilityAvailable':
		BuildFacilityAvailableAlert();
		break;
	case 'eAlert_UpgradeAvailable':
		BuildUpgradeAvailableAlert();
		break;
	case 'eAlert_ShadowProjectAvailable':
		BuildShadowProjectAvailableAlert();
		break;
	case 'eAlert_NewStaffAvailable':
	case 'eAlert_NewStaffAvailableSmall':
		BuildNewStaffAvailableAlert();
		break;
	case 'eAlert_StaffInfo':
		BuildStaffInfoAlert();
		break;

	case 'eAlert_SoldierShaken':
		BuildSoldierShakenAlert();
		break;
	case 'eAlert_SoldierShakenRecovered':
		BuildSoldierShakenRecoveredAlert();
		break;
	case 'eAlert_WeaponUpgradesAvailable':
		BuildWeaponUpgradesAvailableAlert();
		break;
	case 'eAlert_CustomizationsAvailable':
		BuildSoldierCustomizationsAvailableAlert();
		break;
	case 'eAlert_ForceUnderstrength':
		BuildForceUnderstrengthAlert();
		break;
	case 'eAlert_WoundedSoldiersAllowed':
		BuildWoundedSoldiersAllowedAlert();
		break;
	case 'eAlert_StrongholdMissionWarning':
		BuildStrongholdMissionWarningAlert();
		break;

	case 'eAlert_HelpResHQGoods':
		BuildHelpResHQGoodsAlert();
		break;

	case 'eAlert_NewScanningSite':
		BuildPointOfInterestAlert();
		break;
	case 'eAlert_ScanComplete':
		BuildPointOfInterestCompleteAlert();
		break;
	case 'eAlert_ResourceCacheAvailable':
		BuildResourceCacheAvailableAlert();
		break;
	case 'eAlert_ResourceCacheComplete':
		BuildResourceCacheCompleteAlert();
		break;
	case 'eAlert_DarkEvent':
		BuildDarkEventAlert();
		break;
	case 'eAlert_MissionExpired':
		BuildMissionExpiredAlert();
		break;
	case 'eAlert_TimeSensitiveMission':
		BuildTimeSensitiveMissionAlert();
		break;
	case 'eAlert_AlienVictoryImminent':
		BuildAlienVictoryImminentAlert();
		break;

	case 'eAlert_LowIntel':
		BuildLowIntelAlert();
		break;
	case 'eAlert_LowSupplies':
		BuildLowSuppliesAlert();
		break;
	case 'eAlert_LowScientists':
		BuildLowScientistsAlert();
		break;
	case 'eAlert_LowEngineers':
		BuildLowEngineersAlert();
		break;
	case 'eAlert_LowScientistsSmall':
		BuildLowScientistsSmallAlert();
		break;
	case 'eAlert_LowEngineersSmall':
		BuildLowEngineersSmallAlert();
		break;
	case 'eAlert_SupplyDropReminder':
		BuildSupplyDropReminderAlert();
		break;
	case 'eAlert_PowerCoilShielded':
		BuildPowerCoilShieldedAlert();
		break;
	case 'eAlert_LaunchMissionWarning':
		BuildLaunchMissionWarningAlert();

	case 'eAlert_CovertActions':
		BuildCovertActionsAlert();
		break;
	case 'eAlert_LostAndAbandoned':
		BuildLostAndAbandonedAlert();
		break;
	case 'eAlert_ResistanceOp':
		BuildResistanceOpAlert();
		break;
	case 'eAlert_ChosenAmbush':
		BuildChosenAmbushAlert();
		break;
	case 'eAlert_ChosenStronghold':
		BuildChosenStrongholdAlert();
		break;
	case 'eAlert_ChosenSabotage':
		BuildChosenSabotageAlert();
		break;
	case 'eAlert_ChosenFavored':
		BuildChosenFavoredAlert();
		break;
	case 'eAlert_RescueSoldier':
		BuildRescueSoldierAlert();
		break;

	case 'eAlert_NegativeTraitAcquired':
		BuildNegativeTraitAcquiredAlert();
		break;
	case 'eAlert_PositiveTraitAcquired':
		BuildPositiveTraitAcquiredAlert();
		break;

	case 'eAlert_InspiredResearchAvailable':
		BuildInspiredResearchAvailableAlert();
		break;
	case 'eAlert_BreakthroughResearchAvailable':
		BuildBreakthroughResearchAvailableAlert();
		break;
	case 'eAlert_BreakthroughResearchComplete':
		BuildBreakthroughResearchCompleteAlert();
		break;
	case 'eAlert_ReinforcedUnderlayActive':
		BuildReinforcedUnderlayActiveAlert();
		break;

	case 'eAlert_StrategyCardReceived':
		BuildStrategyCardReceivedAlert();
		break;
	case 'eAlert_ComIntIntro':
		BuildComIntIntroAlert();
		break;
	case 'eAlert_SitrepIntro':
		BuildSitrepIntroAlert();
		break;
	case 'eAlert_SoldierCompatibilityIntro':
		BuildSoldierCompatibilityIntroAlert();
		break;
	case 'eAlert_SoldierTired':
		BuildSoldierTiredAlert();
		break;
	case 'eAlert_ResistanceOrdersIntro':
		BuildResistanceOrdersIntroAlert();
		break;
	case 'eAlert_CovertActionIntro':
		BuildCovertActionIntroAlert();
		break;
	case 'eAlert_CovertActionRiskIntro':
		BuildCovertActionRiskIntroAlert();
		break;
	case 'eAlert_CantChangeOrders':
		BuildCantChangeOrdersAlert();
		break;
	case 'eAlert_ConfirmCovertAction':
		BuildConfirmCovertActionAlert();
		break;
	case 'eAlert_NextCovertAction':
		BuildNextCovertActionAlert();
		break;
	case 'eAlert_TempPopup':
		BuildTempPopupAlert();
		break;
	case 'eAlert_XPACK_Retribution':
		BuildRetributionAlert();
		break;
	case 'eAlert_InstantResourceCache':
		BuildInstantResourceCacheAlert();
		break;
	case 'eAlert_BuildTheRing':
		BuildTheRingAlert();
		break;

	default:
		AddBG(MakeRect(0, 0, 1000, 500), eUIState_Normal).SetAlpha(0.75f);
		break;
	}

	// Set  up the navigation *after* the alert is built, so that the button visibility can be used. 
	RefreshNavigation();
	if (!Movie.IsMouseActive())
	{
		Navigator.Clear();
	}
}

simulated function BindLibraryItem()
{
	local Name AlertLibID;

	AlertLibID = GetLibraryID();
	if( AlertLibID != '' )
	{
		LibraryPanel = Spawn(class'UIPanel', self);
		LibraryPanel.bAnimateOnInit = false;
		LibraryPanel.InitPanel('AlertLibraryPanel', AlertLibID);

		if( `ISCONTROLLERACTIVE)
		{
			LibraryPanel.DisableNavigation();
		}
		else
		{
			LibraryPanel.SetSelectedNavigation();
			LibraryPanel.bCascadeSelection = true;
		}

		ButtonGroup = Spawn(class'UIPanel', LibraryPanel);
		ButtonGroup.bAnimateOnInit = false;
		ButtonGroup.bCascadeFocus = false;
		ButtonGroup.InitPanel('ButtonGroup', '');
		if( `ISCONTROLLERACTIVE)
		{
			ButtonGroup.DisableNavigation();
		}
		else
		{
			ButtonGroup.SetSelectedNavigation();
			ButtonGroup.bCascadeSelection = true;
			ButtonGroup.Navigator.LoopSelection = true; 
		}

		Button1 = Spawn(class'UIButton', ButtonGroup);
		if( `ISCONTROLLERACTIVE)
		{
			Button1.InitButton('Button0', "", OnConfirmClicked, eUIButtonStyle_HOTLINK_WHEN_SANS_MOUSE);
		}
		else
		{
			Button1.InitButton('Button0', "", OnConfirmClicked);
			//Button1.SetSelectedNavigation(); //will cause the button to highlight on initial open of the screen. 
		}

		Button1.bAnimateOnInit = false;

		if( `ISCONTROLLERACTIVE)
		{
			Button1.SetGamepadIcon(class'UIUtilities_Input'.static.GetAdvanceButtonIcon());
			Button1.OnSizeRealized = OnButtonSizeRealized;
			Button1.SetX(-150.0 / 2.0);
			Button1.SetY(-Button1.Height / 2.0);
			//Button1.DisableNavigation();
		}
		else
		{
			Button1.SetResizeToText(false);
		}

		Button2 = Spawn(class'UIButton', ButtonGroup);
		if( `ISCONTROLLERACTIVE)
		   Button2.InitButton('Button1', "", OnCancelClicked, eUIButtonStyle_HOTLINK_WHEN_SANS_MOUSE);
		else
			Button2.InitButton('Button1', "", OnCancelClicked, );

		Button2.bAnimateOnInit = false;

		if( `ISCONTROLLERACTIVE)
		{
			Button2.SetGamepadIcon(class'UIUtilities_Input'.static.GetBackButtonIcon());
			Button2.OnSizeRealized = OnButtonSizeRealized;
			Button2.SetX(-150.0 / 2.0);
			Button2.SetY(Button2.Height / 2.0);
			//Button2.DisableNavigation();
		}
		else
		{
			Button2.SetResizeToText(false);
		}
		//TODO: bsteiner: remove this when the strategy map handles it's own visibility
		if( `HQPRES.StrategyMap2D != none )
			`HQPRES.StrategyMap2D.Hide();
	}
}

simulated function OnButtonSizeRealized()
{
	Button1.SetX(-Button1.Width / 2.0);
	Button2.SetX(-Button2.Width / 2.0);
}

simulated function Name GetLibraryID()
{
	//This gets the Flash library name to load in a panel. No name means no library asset yet. 
	switch( eAlertName )
	{
	case 'eAlert_CouncilComm':					return 'Alert_CouncilReport';
	case 'eAlert_GOps':							return 'Alert_GuerrillaOpsSplash';
	case 'eAlert_CouncilMission':					return 'Alert_CouncilMissionSplash';
	case 'eAlert_Retaliation':					return 'Alert_RetaliationSplash'; 
	case 'eAlert_SupplyRaid':						return 'Alert_SupplyRaidSplash';
	case 'eAlert_LandedUFO':						return 'Alert_SupplyRaidSplash';
	case 'eAlert_AlienFacility':					return 'Alert_AlienSplash';
	case 'eAlert_Control':						return ''; //Deprecated?
	case 'eAlert_Doom':							return 'Alert_AlienSplash';
	case 'eAlert_HiddenDoom':						return 'Alert_AlienSplash';
	case 'eAlert_UFOInbound':						return 'Alert_AlienSplash';
	case 'eAlert_UFOEvaded':						return 'Alert_AlienSplash';
	case 'eAlert_Objective':						return 'Alert_NewObjective';
	case 'eAlert_Contact':						return 'Alert_MakeContact';
	case 'eAlert_Outpost':						return 'Alert_MakeContact';
	case 'eAlert_ContactMade':					return 'Alert_ContactMade';
	case 'eAlert_OutpostBuilt':					return 'Alert_ContactMade';
	case 'eAlert_ContinentBonus':					return 'Alert_NewRegion';
	case 'eAlert_RegionUnlocked':					return 'Alert_NewRegion';
	case 'eAlert_RegionUnlockedMission':			return ''; //Deprecated?
	case 'eAlert_BlackMarketAvailable':			return 'Alert_POI';
	case 'eAlert_BlackMarket':					return 'Alert_BlackMarket';

	case 'eAlert_ResearchComplete':				return 'Alert_Complete';
	case 'eAlert_ItemComplete':					return 'Alert_Complete';
	case 'eAlert_ProvingGroundProjectComplete':	return 'Alert_Complete';
	case 'eAlert_FacilityComplete':				return 'Alert_Complete';
	case 'eAlert_UpgradeComplete':				return 'Alert_Complete';
	case 'eAlert_ShadowProjectComplete':			return 'Alert_Complete';
	case 'eAlert_ClearRoomComplete':				return 'Alert_Complete';
	case 'eAlert_ClassEarned':					return 'Alert_TrainingComplete';
	case 'eAlert_TrainingComplete':				return 'Alert_TrainingComplete';
	case 'eAlert_PsiTrainingComplete':			return 'Alert_TrainingComplete';
	case 'eAlert_SoldierPromoted':				return 'Alert_TrainingComplete';
	case 'eAlert_PsiSoldierPromoted':				return 'Alert_TrainingComplete';
	case 'eAlert_PsiLabIntro':					return 'Alert_ItemAvailable';
	case 'eAlert_PsiOperativeIntro':				return 'Alert_AssignStaff';

	case 'eAlert_BuildSlotOpen':					return 'Alert_OpenStaff';
	case 'eAlert_ClearRoomSlotOpen':				return 'Alert_OpenStaff';
	case 'eAlert_StaffSlotOpen':					return 'Alert_OpenStaff';
	case 'eAlert_BuildSlotFilled':				return 'Alert_AssignStaff';
	case 'eAlert_ClearRoomSlotFilled':			return 'Alert_AssignStaff';
	case 'eAlert_StaffSlotFilled':				return 'Alert_AssignStaff';
	case 'eAlert_SuperSoldier':                   return 'Alert_AssignStaff';

	case 'eAlert_ResearchAvailable':				return 'Alert_ItemAvailable';
	case 'eAlert_InstantResearchAvailable':		return 'Alert_ItemAvailable';
	case 'eAlert_ItemAvailable':					return 'Alert_ItemAvailable';

	case 'eAlert_ItemReceived':					return 'Alert_ItemAvailable';
	case 'eAlert_ItemReceivedProvingGround':		return 'Alert_ProvingGroundAvailable';
	case 'eAlert_ItemUpgraded':					return 'Alert_ItemAvailable';

	case 'eAlert_ProvingGroundProjectAvailable':	return 'Alert_ItemAvailable';
	case 'eAlert_FacilityAvailable':				return 'Alert_ItemAvailable';
	case 'eAlert_UpgradeAvailable':				return 'Alert_ItemAvailable';
	case 'eAlert_ShadowProjectAvailable':			return 'Alert_ItemAvailable';//'Alert_ShadowChamberAvailable';
	case 'eAlert_NewStaffAvailable':				return 'Alert_NewStaff';
	case 'eAlert_NewStaffAvailableSmall':			return 'Alert_NewStaffSmall';
	case 'eAlert_StaffInfo':						return 'Alert_NewStaff';

	case 'eAlert_XCOMLives':						return 'Alert_Help';

	case 'eAlert_HelpContact':					return 'Alert_Help';
	case 'eAlert_HelpOutpost':					return 'Alert_Help';
	case 'eAlert_HelpNewRegions':					return 'Alert_Help';
	case 'eAlert_HelpResHQGoods':					return 'Alert_Help';
	case 'eAlert_HelpHavenOps':					return 'Alert_Help';
	case 'eAlert_HelpMissionLocked':				return 'Alert_Help';

	case 'eAlert_SoldierShaken':					return 'Alert_AssignStaff';
	case 'eAlert_SoldierShakenRecovered':			return 'Alert_AssignStaff';
	case 'eAlert_WeaponUpgradesAvailable':		return 'Alert_ItemAvailable';
	case 'eAlert_CustomizationsAvailable':		return 'Alert_XComGeneric';
	case 'eAlert_ForceUnderstrength':				return 'Alert_XComGeneric';
	case 'eAlert_WoundedSoldiersAllowed':			return 'Alert_XComGeneric';
	case 'eAlert_StrongholdMissionWarning':			return 'Alert_XComGeneric';

	case 'eAlert_NewScanningSite':				return 'Alert_POI';
	case 'eAlert_ScanComplete':					return 'Alert_POI';
	case 'eAlert_ResourceCacheAvailable':			return 'Alert_POI';
	case 'eAlert_ResourceCacheComplete':			return 'Alert_POI';
	case 'eAlert_InstantResourceCache':				return 'Alert_POI';
	case 'eAlert_DarkEvent':						return 'Alert_DarkEventActive';
	case 'eAlert_MissionExpired':					return 'Alert_AlienSplash';
	case 'eAlert_TimeSensitiveMission':			return 'Alert_AlienSplash';
	case 'eAlert_AlienVictoryImminent':			return 'Alert_AlienSplash';

	case 'eAlert_LowIntel':						return 'Alert_Warning';
	case 'eAlert_LowSupplies':					return 'Alert_Warning';
	case 'eAlert_LowScientists':					return 'Alert_Warning';
	case 'eAlert_LowEngineers':					return 'Alert_Warning';
	case 'eAlert_LowScientistsSmall':				return 'Alert_XComGeneric';
	case 'eAlert_LowEngineersSmall':				return 'Alert_XComGeneric';
	case 'eAlert_SupplyDropReminder':				return 'Alert_XComGeneric';
	case 'eAlert_PowerCoilShielded':				return 'Alert_XComGeneric';
	case 'eAlert_LaunchMissionWarning':			return 'Alert_XComGeneric';

	case 'eAlert_CovertActions':					return 'Alert_CouncilMissionSplash';
	case 'eAlert_LostAndAbandoned':				return 'XPACK_Alert_MissionSplash';
	case 'eAlert_ResistanceOp':					return 'XPACK_Alert_MissionSplash';
	case 'eAlert_ChosenAmbush':					return 'Alert_ChosenSplash';
	case 'eAlert_ChosenStronghold':				return 'Alert_ChosenSplash';
	case 'eAlert_ChosenSabotage':				return 'Alert_ChosenSplash';
	case 'eAlert_ChosenFavored':				return 'Alert_ChosenSplash';
	case 'eAlert_RescueSoldier':					return 'XPACK_Alert_MissionSplash';

	case 'eAlert_NegativeTraitAcquired':			return 'Alert_NegativeSoldierEvent';
	case 'eAlert_PositiveTraitAcquired':			return 'Alert_AssignStaff';

	case 'eAlert_InspiredResearchAvailable':		return 'Alert_ItemAvailable';
	case 'eAlert_BreakthroughResearchAvailable':	return 'Alert_ItemAvailable';
	case 'eAlert_BreakthroughResearchComplete':		return 'Alert_ItemAvailable';
	case 'eAlert_ReinforcedUnderlayActive':			return 'Alert_ItemAvailable';

	case 'eAlert_StrategyCardReceived':				return 'XPACK_Alert_MissionSplash';
	case 'eAlert_ComIntIntro':						return 'Alert_AssignStaff';
	case 'eAlert_SitrepIntro':						return 'Alert_XComGeneric';
	case 'eAlert_SoldierCompatibilityIntro':		return 'Alert_XComGeneric';
	case 'eAlert_SoldierTired':						return 'Alert_AssignStaff';
	case 'eAlert_ResistanceOrdersIntro':			return 'Alert_XComGeneric';
	case 'eAlert_CovertActionIntro':				return 'Alert_XComGeneric';
	case 'eAlert_CovertActionRiskIntro':			return 'Alert_XComGeneric';
	case 'eAlert_CantChangeOrders':					return 'Alert_XComGeneric';
	case 'eAlert_TrainingCenterIntro':				return 'Alert_ItemAvailable';
	case 'eAlert_InfirmaryIntro':					return 'Alert_ItemAvailable';
	case 'eAlert_TempPopup':						return 'Alert_AssignStaff';
	case 'eAlert_BuildTheRing':						return 'Alert_Warning';

	case 'eAlert_NextCovertAction':					return 'XPACK_Alert_CovertOps';
	case 'eAlert_XPACK_Retribution':				return 'XPACK_Alert_Retribution';
	case 'eAlert_ConfirmCovertAction':				return 'XPACK_Alert_CovertOpConfirm';

	default:
		return ''; 
	}
}
simulated function RefreshNavigation()
{
	if( Button1.IsVisible() )
	{
		//ButtonGroup.Navigator.SetSelected(Button1);
	}
	else
	{
		Button1.DisableNavigation();
		//ButtonGroup.Navigator.SetSelected(Button2);
	}

	if( !Button2.IsVisible() )
	{
		Button2.DisableNavigation();
	}
}

simulated function BuildCouncilCommAlert() 
{
	if( LibraryPanel == none )
	{
		`RedScreen("UI Problem with the alerts! Couldn't find LibraryPanel for current eAlertName: " $ eAlertName);
		return;
	}

	// Save camera
	XComHQPresentationLayer(Movie.Pres).CAMSaveCurrentLocation();

	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateData");
	LibraryPanel.MC.QueueString(m_strCouncilCommTitle);
	LibraryPanel.MC.QueueString(m_strCouncilCommConfirm);
	LibraryPanel.MC.EndOp();

	Button2.DisableNavigation(); 
	Button2.Hide();
}

simulated function BuildGOpsAlert()
{
	local XComGameStateHistory History;
	local XComGameState_MissionSite MissionState;
	local int MissionCount;
	local bool bMultipleMissions;

	if( LibraryPanel == none )
	{
		`RedScreen("UI Problem with the alerts! Couldn't find LibraryPanel for current eAlertName: " $ eAlertName);
		return;
	}

	// Save camera
	XComHQPresentationLayer(Movie.Pres).CAMSaveCurrentLocation();
	bAlertTransitionsToMission = true;

	History = `XCOMHISTORY;
	MissionCount = 0;

	foreach History.IterateByClassType(class'XComGameState_MissionSite', MissionState)
	{
		if(MissionState.Source == 'MissionSource_GuerillaOp' && MissionState.Available)
		{
			MissionCount++;
		}
	}

	bMultipleMissions = (MissionCount > 1);
	
	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateGuerrillaOpsSplash");
	LibraryPanel.MC.QueueString(bMultipleMissions ? m_strGOpsTitle : m_strGOpsTitle_Sing);
	LibraryPanel.MC.QueueString(m_strGOpsSubtitle);
	LibraryPanel.MC.QueueString(bMultipleMissions ? m_strGOpsBody : m_strGOpsBody_Sing);
	LibraryPanel.MC.QueueString(m_strGOpsImage);
	LibraryPanel.MC.QueueString(bMultipleMissions ? m_strGOpsConfirm : m_strGOpsConfirm_Sing);
	LibraryPanel.MC.QueueString(m_strIgnore);
	LibraryPanel.MC.EndOp();

	if(!class'XComGameState_HeadquartersXCom'.static.IsObjectiveCompleted('T0_M7_WelcomeToGeoscape'))
	{
		Button2.Hide();
	}
}

simulated function Hide()
{
	super.Hide();
}

simulated function BuildCouncilMissionAlert()
{
	// Save camera
	XComHQPresentationLayer(Movie.Pres).CAMSaveCurrentLocation();
	bAlertTransitionsToMission = true;

	if( LibraryPanel == none )
	{
		`RedScreen("UI Problem with the alerts! Couldn't find LibraryPanel for current eAlertName: " $ eAlertName);
		return;
	}

	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateCouncilSplashData");
	LibraryPanel.MC.QueueString(m_strCouncilMissionTitle);
	LibraryPanel.MC.QueueString(m_strCouncilMissionLabel);
	LibraryPanel.MC.QueueString(m_strCouncilMissionBody);
	LibraryPanel.MC.QueueString(m_strCouncilMissionFlare);
	LibraryPanel.MC.QueueString(m_strCouncilMissionConfirm);
	LibraryPanel.MC.QueueString(m_strIgnore);
	LibraryPanel.MC.EndOp();

	//bsg-crobinson (5.26.17): Move buttons
	if(`ISCONTROLLERACTIVE)
	{
		Button1.OnSizeRealized = OnCouncilButtonRealized;
		Button2.OnSizeRealized = OnCouncilButtonRealized;
	}
	//bsg-crobinson (5.26.17): end
}

//bsg-crobinson (5.26.17): Realize the buttons need to be in a different place for this alert
simulated function OnCouncilButtonRealized()
{
	Button1.SetX((-Button1.Width / 2.0) + 150);
	Button2.SetX((-Button2.Width / 2.0) + 150);
}
//bsg-crobinson (5.26.17): end

simulated function BuildRetaliationAlert()
{
	// Save camera
	XComHQPresentationLayer(Movie.Pres).CAMSaveCurrentLocation();
	bAlertTransitionsToMission = true;

	if( LibraryPanel == none )
	{
		`RedScreen("UI Problem with the alerts! Couldn't find LibraryPanel for current eAlertName: " $ eAlertName);
		return;
	}

	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateRetaliationSplash");
	LibraryPanel.MC.QueueString(m_strRetaliationTitle);
	LibraryPanel.MC.QueueString(m_strRetaliationLabel);
	LibraryPanel.MC.QueueString(m_strRetaliationBody);
	LibraryPanel.MC.QueueString(m_strRetaliationFlare);
	LibraryPanel.MC.QueueString(m_strRetaliationImage);
	LibraryPanel.MC.QueueString(m_strRetaliationConfirm);
	LibraryPanel.MC.QueueString(m_strIgnore);
	LibraryPanel.MC.EndOp();
}

simulated function BuildSupplyRaidAlert()
{
	// Save camera
	XComHQPresentationLayer(Movie.Pres).CAMSaveCurrentLocation();
	bAlertTransitionsToMission = true;

	if( LibraryPanel == none )
	{
		`RedScreen("UI Problem with the alerts! Couldn't find LibraryPanel for current eAlertName: " $ eAlertName);
		return;
	}

	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateSupplyRaidSplashData");
	LibraryPanel.MC.QueueString(m_strSupplyRaidHeader);
	LibraryPanel.MC.QueueString(m_strSupplyRaidTitle);
	LibraryPanel.MC.QueueString(m_strSupplyRaidBody);
	LibraryPanel.MC.QueueString(m_strSupplyRaidImage);
	LibraryPanel.MC.QueueString(m_strSupplyRaidFlare);
	LibraryPanel.MC.QueueString(m_strSupplyRaidConfirm);
	LibraryPanel.MC.QueueString(m_strIgnore);
	LibraryPanel.MC.EndOp();
}

simulated function BuildLandedUFOAlert()
{
	// Save camera
	XComHQPresentationLayer(Movie.Pres).CAMSaveCurrentLocation();
	bAlertTransitionsToMission = true;

	if( LibraryPanel == none )
	{
		`RedScreen("UI Problem with the alerts! Couldn't find LibraryPanel for current eAlertName: " $ eAlertName);
		return;
	}

	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateSupplyRaidSplashData");
	LibraryPanel.MC.QueueString(m_strLandedUFOLabel);
	LibraryPanel.MC.QueueString(m_strLandedUFOTitle);
	LibraryPanel.MC.QueueString(m_strLandedUFOBody);
	LibraryPanel.MC.QueueString(m_strLandedUFOImage);
	LibraryPanel.MC.QueueString(m_strLandedUFOFlare);
	LibraryPanel.MC.QueueString(m_strLandedUFOConfirm);
	LibraryPanel.MC.QueueString(m_strIgnore);
	LibraryPanel.MC.EndOp();
}

simulated function BuildFacilityAlert()
{
	// Save camera
	XComHQPresentationLayer(Movie.Pres).CAMSaveCurrentLocation();
	bAlertTransitionsToMission = true;

	BuildAlienSplashAlert(m_strFacilityTitle, m_strFacilityLabel, m_strFacilityBody, m_strFacilityImage, m_strFacilityConfirm, m_strOK);
}

// UFO inbound, doom generation, alien facility, UFO active, alien facility constructed, and any other negative generic popup needed 
function BuildAlienSplashAlert(String strHeader, String strTitle, String strDescription, String strImage, String strButton1Label, String strButton2Label)
{
	if( LibraryPanel == none )
	{
		`RedScreen("UI Problem with the alerts! Couldn't find LibraryPanel for current eAlertName: " $ eAlertName);
		return;
	}
	
	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateData");
	LibraryPanel.MC.QueueString(strHeader);
	LibraryPanel.MC.QueueString(strTitle);
	LibraryPanel.MC.QueueString(strDescription);
	LibraryPanel.MC.QueueString(strImage);
	LibraryPanel.MC.QueueString(strButton1Label);
	LibraryPanel.MC.QueueString(strButton2Label);
	LibraryPanel.MC.EndOp();

	if( strButton2Label == "" )
	{
		Button2.DisableNavigation(); 
		Button2.Hide();
	}
}


simulated function XComGameState_WorldRegion GetRegion()
{
	return XComGameState_WorldRegion(`XCOMHISTORY.GetGameStateForObjectID(
		class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(DisplayPropertySet, 'RegionRef')));
}

simulated function BuildControlAlert()
{
	local TRect rAlert, rPos;
	local LinearColor clrControl;
	local String strControl;
	local XGParamTag ParamTag;

	clrControl = MakeLinearColor(0.75, 0.0, 0, 1);

	// Save Camera
	bRestoreCameraPosition = true;
	XComHQPresentationLayer(Movie.Pres).CAMSaveCurrentLocation();

	if(bInstantInterp)
	{
		XComHQPresentationLayer(Movie.Pres).CAMLookAtEarth(GetRegion().Get2DLocation(), 0.75f, 0);
	}
	else
	{
		XComHQPresentationLayer(Movie.Pres).CAMLookAtEarth(GetRegion().Get2DLocation(), 0.75f);
	}

	// BG
	rAlert = AnchorRect(MakeRect(0, 0, 750, 600), eRectAnchor_Center);
	rPos = VSubRect(rAlert, 0, 0.15f);
	AddBG(rPos, eUIState_Warning);

	// Header
	rPos = VSubRect(rAlert, 0, 0.15f);
	AddHeader(rPos, class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS(GetRegion().GetMyTemplate().DisplayName), clrControl, m_strControlLabel);

	// Image
	rPos = VSubRect(rAlert, 0.15f, 0.8f);
	rPos = HSubRect(rPos, 0.0f, 0.6f);
	AddBG(rPos, eUIState_Warning);

	rPos = VSubRect(rAlert, 0.3f, 0.7f);
	rPos = HSubRect(rPos, 0.0f, 0.6f);
	AddImage(rPos, m_strControlImage, eUIState_Bad);

	rPos = VSubRect(rAlert, 0.15f, 0.8f);
	rPos = HSubRect(rPos, 0.6f, 1.0f);
	AddBG(rPos, eUIState_Warning);
	
	// OK Button
	rPos = VSubRect(rAlert, 0.45f, 0.55f);
	rPos = HSubRect(rPos, 0.7f, 0.8f);
	AddButton(rPos, m_strOK, OnCancelClicked);

	// Body
	ParamTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	ParamTag.StrValue0 = GetRegion().GetMyTemplate().DisplayName;
	strControl = `XEXPAND.ExpandString(m_strControlBody);

	rPos = VSubRect(rAlert, 0.7, 1.0f);
	AddBG(rPos, eUIState_Warning);
	AddText(rPos, strControl);

	//Flare Left
	rPos = MakeRect(0, 1080 / 2 - 50 / 2, rAlert.fLeft, 50);
	AddBG(rPos, eUIState_Warning).SetAlpha(0.5f);
	AddHeader(rPos, m_strControlFlare, clrControl);

	//Flare Right
	rPos = MakeRect(rAlert.fRight, 1080 / 2 - 50 / 2, 1920 - rAlert.fRight, 50);
	AddBG(rPos, eUIState_Warning).SetAlpha(0.5f);
	AddHeader(rPos, m_strControlFlare, clrControl);
}
simulated function BuildDoomAlert()
{
	local XGParamTag ParamTag;

	ParamTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	ParamTag.StrValue0 = GetRegion().GetMyTemplate().DisplayName;

	// Save camera
	bAlertTransitionsToMission = true;
	XComHQPresentationLayer(Movie.Pres).CAMSaveCurrentLocation();

	BuildAlienSplashAlert(m_strDoomTitle, `XEXPAND.ExpandString(m_strDoomLabel), `XEXPAND.ExpandString(m_strDoomBody), m_strDoomImage, m_strDoomConfirm, m_strIgnore);
}
simulated function BuildHiddenDoomAlert()
{
	BuildAlienSplashAlert(m_strDoomTitle, m_strHiddenDoomLabel, m_strHiddenDoomBody, m_strDoomImage, m_strAccept, "");
}
simulated function BuildUFOInboundAlert()
{
	local XComGameState_UFO UFOState;
	local String strBody, strStats;

	UFOState = XComGameState_UFO(`XCOMHISTORY.GetGameStateForObjectID(
		class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(DisplayPropertySet, 'UFORef')));
	
	// Save camera
	XComHQPresentationLayer(Movie.Pres).CAMSaveCurrentLocation();

	// Stat Text
	strStats $= m_strUFOInboundDistanceLabel @ UFOState.GetDistanceToAvenger() @ m_strUFOInboundDistanceUnits $ "\n";
	strStats $= m_strUFOInboundSpeedLabel @ UFOState.GetInterceptionSpeed() @ m_strUFOInboundSpeedUnits $ "\n";
	strStats $= m_strUFOInboundTimeLabel @ UFOState.GetTimeToIntercept();
	strBody = m_strUFOInboundBody $ "\n\n" $ strStats;

	BuildAlienSplashAlert(m_strUFOInboundTitle, m_strUFOInboundLabel, strBody, m_strUFOInboundImage, m_strUFOInboundConfirm, "");
}

simulated function BuildUFOEvadedAlert()
{
	// Save camera
	XComHQPresentationLayer(Movie.Pres).CAMSaveCurrentLocation();

	BuildAlienSplashAlert(m_strUFOEvadedTitle, m_strUFOEvadedLabel, m_strUFOEvadedBody, m_strUFOEvadedImage, m_strUFOEvadedConfirm, m_strIgnore);
}

simulated function BuildObjectiveAlert()
{
	local string SubObjectives;
	local int iSubObj;
	local array<DynamicProperty> ArrayProperty;

	//local XComGameState NewGameState;
	
	if( LibraryPanel == none )
	{
		`RedScreen("UI Problem with the alerts! Couldn't find LibraryPanel for current eAlertName: " $ eAlertName);
		return;
	}

	// Can only be used to trigger voice only lines
	XComHQPresentationLayer(Movie.Pres).UINarrative(XComNarrativeMoment'X2NarrativeMoments.Strategy.Avenger_Objective_Added');
	//NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Narrative UI Closed");
	//`XEVENTMGR.TriggerEvent('NarrativeUICompleted', , , NewGameState);
	//`GAMERULES.SubmitGameState(NewGameState);

	class'X2StrategyGameRulesetDataStructures'.static.GetDynamicArrayProperty(DisplayPropertySet, 'UIArrayText', ArrayProperty);

	// Subobjectives
	for( iSubObj = 0; iSubObj < ArrayProperty.Length; iSubObj++ )
	{
		SubObjectives $= "-" @ ArrayProperty[iSubObj].ValueString $ "\n";
	}
	
	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateData");
	LibraryPanel.MC.QueueString(m_strObjectiveFlare);
	LibraryPanel.MC.QueueString(m_strObjectiveTitle);
	LibraryPanel.MC.QueueString(class'X2StrategyGameRulesetDataStructures'.static.GetDynamicStringProperty(DisplayPropertySet, 'UIHeaderText'));
	LibraryPanel.MC.QueueString(class'X2StrategyGameRulesetDataStructures'.static.GetDynamicStringProperty(DisplayPropertySet, 'UIBodyText'));
	LibraryPanel.MC.QueueString(SubObjectives);
	LibraryPanel.MC.QueueString(class'UIUtilities_Image'.const.MissionObjective_GoldenPath);
	LibraryPanel.MC.QueueString(class'X2StrategyGameRulesetDataStructures'.static.GetDynamicStringProperty(DisplayPropertySet, 'UIImagePath'));
	LibraryPanel.MC.QueueString(m_strOK);
	LibraryPanel.MC.QueueString(m_strObjectiveTellMeMore);
	LibraryPanel.MC.EndOp();
	
	Button2.OnClickedDelegate = TellMeMore;
	Button2.SetGamepadIcon(class'UIUtilities_Input'.static.GetGamepadIconPrefix() $ class'UIUtilities_Input'.const.ICON_X_SQUARE);

	// Don't show the Tell Me More button if tutorial is active
	if (class'UIUtilities_Strategy'.static.GetXComHQ().AnyTutorialObjectivesInProgress())
	{
		Button2.DisableNavigation(); 
		Button2.Hide();
	}
}

simulated function String GetDateString()
{
	return class'X2StrategyGameRulesetDataStructures'.static.GetDateString(`GAME.GetGeoscape().m_kDateTime);
}
simulated static function array<String> GetItemUnlockStrings(array<X2ItemTemplate> arrNewItems)
{
	local array<String> arrStrings;
	local int i;
	local XGParamTag ParamTag;

	ParamTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));

	for( i = 0; i < arrNewItems.Length; i++ )
	{
		ParamTag.StrValue0 = arrNewItems[i].GetItemFriendlyName(, false);
		arrStrings.AddItem(`XEXPAND.ExpandString(default.m_strItemUnlock));
	}

	return arrStrings;
}
simulated static function array<String> GetFacilityUnlockStrings(array<X2FacilityTemplate> arrNewFacilities)
{
	local array<String> arrStrings;
	local int i;
	local XGParamTag ParamTag;

	ParamTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));

	for( i = 0; i < arrNewFacilities.Length; i++ )
	{
		ParamTag.StrValue0 = arrNewFacilities[i].DisplayName;
		arrStrings.AddItem(`XEXPAND.ExpandString(default.m_strFacilityUnlock));
	}

	return arrStrings;
}
simulated static function array<String> GetUpgradeUnlockStrings(array<X2FacilityUpgradeTemplate> arrNewUpgrades)
{
	local array<String> arrStrings;
	local int i;
	local XGParamTag ParamTag;

	ParamTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));

	for (i = 0; i < arrNewUpgrades.Length; i++)
	{
		ParamTag.StrValue0 = arrNewUpgrades[i].DisplayName;
		ParamTag.StrValue1 = arrNewUpgrades[i].FacilityName;
		arrStrings.AddItem(`XEXPAND.ExpandString(default.m_strUpgradeUnlock));
	}

	return arrStrings;
}
simulated static function array<String> GetResearchUnlockStrings(array<StateObjectReference> arrNewTechs)
{
	local XComGameStateHistory History;
	local XComGameState_Tech TechState;
	local array<String> arrStrings;
	local int i;
	local XGParamTag ParamTag;

	History = `XCOMHISTORY;
	ParamTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));

	for( i = 0; i < arrNewTechs.Length; i++ )
	{
		TechState = XComGameState_Tech(History.GetGameStateForObjectID(arrNewTechs[i].ObjectID));
		ParamTag.StrValue0 = TechState.GetDisplayName();
		arrStrings.AddItem(`XEXPAND.ExpandString(default.m_strResearchUnlock));
	}

	return arrStrings;
}
simulated static function array<String> GetProjectUnlockStrings(array<StateObjectReference> arrNewProjects)
{
	local XComGameStateHistory History;
	local XComGameState_Tech TechState; 
	local array<String> arrStrings;
	local int i;
	local XGParamTag ParamTag;

	History = `XCOMHISTORY;
	ParamTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));

	for (i = 0; i < arrNewProjects.Length; i++)
	{
		TechState = XComGameState_Tech(History.GetGameStateForObjectID(arrNewProjects[i].ObjectID));
		ParamTag.StrValue0 = TechState.GetDisplayName();
		arrStrings.AddItem(`XEXPAND.ExpandString(default.m_strProjectUnlock));
	}

	return arrStrings;
}
//simulated function String GetObjectiveTitle()
//{
//	return "OBJECTIVE TITLE";
//}
//simulated function String GetObjectiveImage()
//{
//	return "img:///UILibrary_ProtoImages.Proto_AlienBase";
//}
//simulated function String GetObjectiveDesc()
//{
//	return "Objective description, Objective description, Objective description, Objective description, Objective description, Objective description, Objective description, Objective description, Objective description, Objective description, Objective description, Objective description, Objective description.";
//}
//
//simulated function array<String> GetSubObjectives()
//{
//	local array<String> arrSubobjectives;
//
//	arrSubobjectives.AddItem("Subobjective 1");
//	arrSubobjectives.AddItem("Subobjective 2");
//	arrSubobjectives.AddItem("Subobjective 3");
//	arrSubobjectives.AddItem("Subobjective 4");
//	arrSubobjectives.AddItem("Subobjective 5");
//
//	return arrSubobjectives;
//}

simulated function BuildContactAlert()
{
	local bool bCanAfford;
	local string ContactCost;

	if( LibraryPanel == none )
	{
		`RedScreen("UI Problem with the alerts! Couldn't find LibraryPanel for current eAlertName: " $ eAlertName);
		return;
	}

	// Save camera
	bRestoreCameraPosition = true;	
	XComHQPresentationLayer(Movie.Pres).CAMSaveCurrentLocation();

	`HQPRES.StrategyMap2D.HideCursor();
	if(bInstantInterp)
	{
		XComHQPresentationLayer(Movie.Pres).CAMLookAtEarth(GetRegion().Get2DLocation(), 0.5f, 0);
	}
	else
	{
		XComHQPresentationLayer(Movie.Pres).CAMLookAtEarth(GetRegion().Get2DLocation(), 0.5f);
	}
	
	bCanAfford = CanAffordContact();
	ContactCost = GetContactCostString();
	
	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateData");
	LibraryPanel.MC.QueueString(m_strContactTitle);
	LibraryPanel.MC.QueueString(class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS(GetRegion().GetMyTemplate().DisplayName));
	
	LibraryPanel.MC.QueueString(m_strContactCostLabel);
	LibraryPanel.MC.QueueString(class'UIUtilities_Text'.static.GetColoredText(ContactCost, bCanAfford ? eUIState_Normal : eUIState_Bad));
	LibraryPanel.MC.QueueString(GetContactCostHelp());
	
	LibraryPanel.MC.QueueString(GetContactTimeLabel());
	LibraryPanel.MC.QueueString(GetContactTimeString());

	LibraryPanel.MC.QueueString(GetContactBody());
	LibraryPanel.MC.QueueString(m_strContactHelp);
	LibraryPanel.MC.QueueString(m_strContactConfirm);
	LibraryPanel.MC.QueueString(m_strCancel);
	LibraryPanel.MC.EndOp();
	
	if (!bCanAfford || !CanMakeContact())
	{
		Button1.SetDisabled(true);
		if (`ISCONTROLLERACTIVE)
			Button1.SetGamepadIcon(class'UIUtilities_Input'.static.GetAdvanceButtonIcon());
	}
}

simulated function String GetContactCostHelp()
{
	local XGParamTag ParamTag;
	
	ParamTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	ParamTag.IntValue0 = `ScaleStrategyArrayInt(GetRegion().ContactIntelCost);

	return `XEXPAND.ExpandString(m_strContactCostHelp);
}
simulated function String GetContactCostString()
{
	return class'UIUtilities_Strategy'.static.GetStrategyCostString(GetRegion().CalcContactCost(), GetRegion().ContactCostScalars);
}
simulated function bool CanAffordContact()
{
	return XCOMHQ().CanAffordAllStrategyCosts(GetRegion().CalcContactCost(), GetRegion().ContactCostScalars);
}
simulated function bool CanMakeContact()
{
	return (XCOMHQ().GetRemainingContactCapacity() > 0);
}
simulated function String GetContactTimeLabel()
{
	return m_strContactTimeLabel;
}
simulated function String GetContactTimeString()
{
	local XComGameState_HeadquartersXCom XComHQ;
	local int iMinDays, iMaxDays;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	if (XComHQ.bInstantContacts)
	{
		return XComHQ.strETAInstant;
	}

	GetRegion().MakeContactETA(iMinDays, iMaxDays);

	if (iMinDays == iMaxDays)
		return iMinDays@m_strDays;
	else
		return iMinDays@"-"@iMaxDays@m_strDays;
}
simulated function String GetContactBody()
{
	local XGParamTag ParamTag;
	local string ContactBody;

	ParamTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	ParamTag.StrValue0 = GetRegion().GetMyTemplate().DisplayName;
	ParamTag.IntValue0 = GetRegion().GetSupplyDropReward(true);
	ContactBody = `XEXPAND.ExpandString(m_strContactBody);

	if (!CanMakeContact())
		ContactBody $= "\n" $ class'UIUtilities_Text'.static.GetColoredText(m_strContactNeedResComms, eUIState_Bad);

	return ContactBody;
}

simulated function BuildOutpostAlert()
{
	local bool bCanAfford; 
	local string OutpostCost; 

	// Save camera
	bRestoreCameraPosition = true;
	XComHQPresentationLayer(Movie.Pres).CAMSaveCurrentLocation();

	if(bInstantInterp)
	{
		XComHQPresentationLayer(Movie.Pres).CAMLookAtEarth(GetRegion().GetHaven().Get2DLocation(), 0.5f, 0);
	}
	else
	{
		XComHQPresentationLayer(Movie.Pres).CAMLookAtEarth(GetRegion().GetHaven().Get2DLocation(), 0.5f);
	}

	bCanAfford = XCOMHQ().CanAffordAllStrategyCosts(GetRegion().CalcOutpostCost(), GetRegion().OutpostCostScalars);
	OutpostCost = class'UIUtilities_Strategy'.static.GetStrategyCostString(GetRegion().CalcOutpostCost(), GetRegion().OutpostCostScalars);
	
	//--------------------- 

	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateData");
	LibraryPanel.MC.QueueString(m_strOutpostTitle);
	LibraryPanel.MC.QueueString(class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS(GetRegion().GetMyTemplate().DisplayName));
	
	LibraryPanel.MC.QueueString(m_strContactCostLabel); //reusing string here.
	LibraryPanel.MC.QueueString(class'UIUtilities_Text'.static.GetColoredText(OutpostCost, bCanAfford ? eUIState_Normal : eUIState_Bad));
	LibraryPanel.MC.QueueString("");
	
	LibraryPanel.MC.QueueString(m_strOutpostTimeLabel);
	LibraryPanel.MC.QueueString(GetOutpostTimeString());

	LibraryPanel.MC.QueueString(GetOutpostBody());
	LibraryPanel.MC.QueueString(m_strOutpostHelp);
	LibraryPanel.MC.QueueString(m_strOutpostConfirm);
	LibraryPanel.MC.QueueString(m_strIgnore);
	LibraryPanel.MC.EndOp();

	Button1.SetDisabled(!bCanAfford);

	//--------------------- 

	//LibraryPanel.MC.BeginFunctionOp("UpdateReward");
	//LibraryPanel.MC.QueueString(m_strReward);
	//LibraryPanel.MC.EndOp();
}

simulated function bool CanAffordOutpost()
{
	return XCOMHQ().CanAffordAllStrategyCosts(GetRegion().CalcOutpostCost(), GetRegion().OutpostCostScalars);
}
simulated function String GetOutpostTimeString()
{
	local int iMinDays, iMaxDays;

	GetRegion().BuildHavenETA(iMinDays, iMaxDays);

	if (iMinDays == iMaxDays)
		return iMinDays@m_strDays;
	else
		return iMinDays@"-"@iMaxDays@m_strDays;
}
simulated function String GetOutpostBody()
{
	local XGParamTag ParamTag;

	ParamTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	ParamTag.StrValue0 = GetRegion().GetMyTemplate().DisplayName;
	ParamTag.IntValue0 = GetRegion().GetSupplyDropReward(,true);
	return `XEXPAND.ExpandString(m_strOutpostBody);
}

simulated function BuildContactMadeAlert()
{
	local String strContact;
	local XGParamTag ParamTag;
	
	if( LibraryPanel == none )
	{
		`RedScreen("UI Problem with the alerts! Couldn't find LibraryPanel for current eAlertName: " $ eAlertName);
		return;
	}

	// Save camera
	bRestoreCameraPosition = true;
	XComHQPresentationLayer(Movie.Pres).CAMSaveCurrentLocation();

	if( bInstantInterp )
	{
		XComHQPresentationLayer(Movie.Pres).CAMLookAtEarth(GetRegion().Get2DLocation(), 0.5f, 0);
	}
	else
	{
		XComHQPresentationLayer(Movie.Pres).CAMLookAtEarth(GetRegion().Get2DLocation(), 0.5f);
	}

	ParamTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	ParamTag.StrValue0 = GetRegion().GetMyTemplate().DisplayName;
	strContact = `XEXPAND.ExpandString(m_strContactMadeBody);

	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateData");
	LibraryPanel.MC.QueueString(m_strContactMadeTitle);
	LibraryPanel.MC.QueueString(class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS(GetRegion().GetMyTemplate().DisplayName));
	LibraryPanel.MC.QueueString(strContact);
	LibraryPanel.MC.QueueString(m_strContactMadeIncome);
	LibraryPanel.MC.QueueString(GetContactIncomeString());
	LibraryPanel.MC.QueueString(m_strOK);
	LibraryPanel.MC.QueueString(""); //reward label
	LibraryPanel.MC.QueueString(""); //reward value
	LibraryPanel.MC.EndOp();

	//This panel has only one button, for confirm.
	Button2.DisableNavigation(); 
	Button2.Hide();
}
simulated function String GetContactIncomeString()
{
	return GetRegion().GetSupplyDropReward() @ m_strSupplies;
}
simulated function BuildOutpostBuiltAlert()
{
	local String strBody;
	local XGParamTag ParamTag;

	// Save camera
	bRestoreCameraPosition = true;
	XComHQPresentationLayer(Movie.Pres).CAMSaveCurrentLocation();

	if(bInstantInterp)
	{
		XComHQPresentationLayer(Movie.Pres).CAMLookAtEarth(GetRegion().GetHaven().Get2DLocation(), 0.5f, 0);
	}
	else
	{
		XComHQPresentationLayer(Movie.Pres).CAMLookAtEarth(GetRegion().GetHaven().Get2DLocation(), 0.5f);
	}

	// Body
	ParamTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	ParamTag.StrValue0 = GetRegion().GetMyTemplate().DisplayName;
	strBody = `XEXPAND.ExpandString(m_strOutpostBuiltBody);

	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateData");
	LibraryPanel.MC.QueueString(m_strOutpostBuiltTitle);
	LibraryPanel.MC.QueueString(class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS(GetRegion().GetMyTemplate().DisplayName));
	LibraryPanel.MC.QueueString(strBody);
	LibraryPanel.MC.QueueString(m_strOutpostBuiltIncome);
	LibraryPanel.MC.QueueString(GetContactIncomeString());
	LibraryPanel.MC.QueueString(m_strOK);
	LibraryPanel.MC.EndOp();

	//This panel has only one button, for confirm.
	Button2.DisableNavigation(); 
	Button2.Hide();

}
simulated function BuildContinentAlert()
{
	local XComGameState_StrategyCard ContinentBonusCard;
	local string BonusInfo, BonusSummary;

	if( LibraryPanel == none )
	{
		`RedScreen("UI Problem with the alerts! Couldn't find LibraryPanel for current eAlertName: " $ eAlertName);
		return;
	}

	// Save camera
	bRestoreCameraPosition = true;
	XComHQPresentationLayer(Movie.Pres).CAMSaveCurrentLocation();

	if(bInstantInterp)
	{
		XComHQPresentationLayer(Movie.Pres).CAMLookAtEarth(GetContinent().Get2DLocation(), 0.75f, 0);
	}
	else
	{
		XComHQPresentationLayer(Movie.Pres).CAMLookAtEarth(GetContinent().Get2DLocation(), 0.75f);
	}

	ContinentBonusCard = GetContinent().GetContinentBonusCard();

	BonusInfo = class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS(ContinentBonusCard.GetDisplayName());
	BonusInfo = class'UIUtilities_Text'.static.GetColoredText(BonusInfo, eUIState_Good);
	BonusInfo = m_strContinentBonusLabel $"\n" @ BonusInfo;

	BonusSummary = ContinentBonusCard.GetSummaryText();

	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateData");
	LibraryPanel.MC.QueueString(m_strContinentTitle);
	LibraryPanel.MC.QueueString(class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS(GetContinent().GetMyTemplate().DisplayName));
	LibraryPanel.MC.QueueString(BonusInfo);
	LibraryPanel.MC.QueueString(BonusSummary);
	LibraryPanel.MC.QueueString(m_strOK);
	LibraryPanel.MC.EndOp();

	//This panel has only one button, for confirm.
	Button2.DisableNavigation(); 
	Button2.Hide();
}
simulated function XComGameState_Continent GetContinent()
{
	return XComGameState_Continent(`XCOMHISTORY.GetGameStateForObjectID(
		class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(DisplayPropertySet, 'ContinentRef')));
}
simulated function BuildRegionUnlockedAlert()
{
	local String strUnlocked, strUnlockedHelp;
	local XGParamTag ParamTag;

	if( LibraryPanel == none )
	{
		`RedScreen("UI Problem with the alerts! Couldn't find LibraryPanel for current eAlertName: " $ eAlertName);
		return;
	}

	// Save camera
	bRestoreCameraPosition = true;
	XComHQPresentationLayer(Movie.Pres).CAMSaveCurrentLocation();

	if(bInstantInterp)
	{
		XComHQPresentationLayer(Movie.Pres).CAMLookAtEarth(GetRegion().Get2DLocation(), 0.75f, 0);
	}
	else
	{
		XComHQPresentationLayer(Movie.Pres).CAMLookAtEarth(GetRegion().Get2DLocation(), 0.75f);
	}

	// Body
	ParamTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));

	if( eAlertName == 'eAlert_RegionUnlocked' )
	{
		if( IsFirstUnlock() )
		{
			ParamTag.StrValue0 = GetRegion().GetMyTemplate().DisplayName;
			strUnlocked = `XEXPAND.ExpandString(m_strFirstUnlockedBody);
			strUnlockedHelp = m_strUnlockedHelp;
		}
		else
		{
			ParamTag.StrValue0 = GetUnlockingNeighbor(GetRegion()).GetMyTemplate().DisplayName;
			ParamTag.StrValue1 = GetRegion().GetMyTemplate().DisplayName;
			strUnlocked = `XEXPAND.ExpandString(m_strUnlockedBody);
			strUnlockedHelp = m_strUnlockedHelp;
		}
	}

	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateData");
	LibraryPanel.MC.QueueString(m_strUnlockedFlare);
	LibraryPanel.MC.QueueString(class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS(GetRegion().GetMyTemplate().DisplayName));
	LibraryPanel.MC.QueueString(strUnlocked);
	LibraryPanel.MC.QueueString(strUnlockedHelp);
	LibraryPanel.MC.QueueString(m_strOK);
	LibraryPanel.MC.EndOp();

	//This panel has only one button, for confirm.
	Button2.DisableNavigation(); 
	Button2.Hide();
}

simulated function bool IsFirstUnlock()
{
	return GetUnlockingNeighbor(GetRegion()) == XComGameState_WorldRegion(`XCOMHISTORY.GetGameStateForObjectID(XCOMHQ().StartingRegion.ObjectID));
}

simulated function XComGameState_WorldRegion GetUnlockingNeighbor(XComGameState_WorldRegion Region)
{
	local StateObjectReference NeighborRegionRef;
	local XComGameState_WorldRegion Neighbor;

	foreach Region.LinkedRegions(NeighborRegionRef)
	{
		Neighbor = XComGameState_WorldRegion(`XCOMHISTORY.GetGameStateForObjectID(NeighborRegionRef.ObjectID));

		if( Neighbor.HaveMadeContact() )
		{
			return Neighbor;
		}
	}

	return None;
}

simulated function BuildPointOfInterestAlert()
{
	local XComGameStateHistory History;
	local XGParamTag ParamTag;
	local XComGameState_PointOfInterest POIState;
	local TAlertPOIAvailableInfo kInfo;
	
	History = `XCOMHISTORY;
	POIState = XComGameState_PointOfInterest(History.GetGameStateForObjectID(
		class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(DisplayPropertySet, 'POIRef')));
	
	ParamTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	ParamTag.StrValue0 = POIState.GetResistanceRegionName();
	
	kInfo.zoomLocation = POIState.Get2DLocation();
	kInfo.strTitle = m_strPOITitle;
	kInfo.strLabel = m_strPOILabel;
	kInfo.strBody = m_strPOIBody;
	kInfo.strImage = m_strPOIImage;
	kInfo.strReport = POIState.GetDisplayName();
	kInfo.strReward = POIState.GetRewardDescriptionString();
	kInfo.strRewardIcon = POIState.GetRewardIconString();
	kInfo.strDurationLabel = m_strPOIDuration;
	kInfo.strDuration = class'UIUtilities_Text'.static.GetTimeRemainingString(POIState.GetNumScanHoursRemaining());
	kInfo.strInvestigate = m_strPOIInvestigate;
	kInfo.strIgnore = m_strNotNow;
	kInfo.strFlare = m_strPOIFlare;
	kInfo.strUIIcon = POIState.GetUIButtonIcon();
	kInfo.eColor = eUIState_Normal;
	kInfo.clrAlert = MakeLinearColor(0.75f, 0.75f, 0, 1);
		
	BuildPointOfInterestAvailableAlert(kInfo);
	
	if ((class'XComGameState_HeadquartersXCom'.static.GetObjectiveStatus('T0_M10_IntroToBlacksite') == eObjectiveState_InProgress) ||
		((class'XComGameState_HeadquartersXCom'.static.GetObjectiveStatus('T2_M0_CompleteGuerillaOps') == eObjectiveState_InProgress) && 
		((class'XComGameState_HeadquartersXCom'.static.GetObjectiveStatus('XP0_M1_TutorialLostAndAbandonedComplete') == eObjectiveState_InProgress) ||
		(class'XComGameState_HeadquartersXCom'.static.GetObjectiveStatus('XP0_M1_LostAndAbandonedComplete') == eObjectiveState_InProgress))))
	{
		Button2.DisableNavigation(); 
		Button2.Hide();
	}
}

simulated function BuildBlackMarketAvailableAlert()
{
	local XComGameStateHistory History;
	local XComGameState_BlackMarket BlackMarketState;
	local TAlertPOIAvailableInfo kInfo;

	History = `XCOMHISTORY;
	BlackMarketState = XComGameState_BlackMarket(History.GetSingleGameStateObjectForClass(class'XComGameState_BlackMarket'));
		
	kInfo.zoomLocation = BlackMarketState.Get2DLocation();
	kInfo.strTitle = m_strPOITitle;
	kInfo.strLabel = m_strPOILabel;
	kInfo.strBody = (BlackMarketState.NumTimesAppeared > 1 ? m_strBlackMarketAvailableAgainBody : m_strBlackMarketAvailableBody);
	kInfo.strImage = m_strPOIImage;
	kInfo.strReport = BlackMarketState.GetDisplayName();
	kInfo.strDurationLabel = m_strBlackMarketDuration;
	kInfo.strDuration = class'UIUtilities_Text'.static.GetTimeRemainingString(BlackMarketState.GetNumScanHoursRemaining());
	kInfo.strInvestigate = m_strPOIInvestigate;
	kInfo.strIgnore = m_strIgnore;
	kInfo.strFlare = m_strPOIFlare;
	kInfo.strUIIcon = BlackMarketState.GetUIButtonIcon();
	kInfo.eColor = eUIState_Normal;
	kInfo.clrAlert = MakeLinearColor(0.75f, 0.75f, 0, 1);

	BuildPointOfInterestAvailableAlert(kInfo);
}

simulated function BuildResourceCacheAvailableAlert()
{
	local XComGameStateHistory History;
	local XComGameState_ResourceCache CacheState;
	local TAlertPOIAvailableInfo kInfo;

	History = `XCOMHISTORY;
	CacheState = XComGameState_ResourceCache(History.GetSingleGameStateObjectForClass(class'XComGameState_ResourceCache'));
		
	kInfo.zoomLocation = CacheState.Get2DLocation();
	kInfo.strTitle = m_strResourceCacheAvailableTitle;
	kInfo.strLabel = m_strPOILabel;
	kInfo.strBody = m_strResourceCacheAvailableBody; 
	kInfo.strImage = m_strPOIImage;
	kInfo.strReport = CacheState.GetDisplayName();
	kInfo.strReward = CacheState.GetTotalResourceAmount();
	kInfo.strRewardIcon = "";
	kInfo.strInvestigate = m_strPOIInvestigate;
	kInfo.strIgnore = m_strIgnore;
	kInfo.strFlare = m_strPOIFlare;
	kInfo.strUIIcon = CacheState.GetUIButtonIcon();
	kInfo.eColor = eUIState_Normal;
	kInfo.clrAlert = MakeLinearColor(0.75f, 0.75f, 0, 1);

	BuildPointOfInterestAvailableAlert(kInfo);
}

simulated function BuildInstantResourceCacheAlert()
{
	local XComGameStateHistory History;
	local XComGameState_ResourceCache CacheState;

	if(LibraryPanel == none)
	{
		`RedScreen("UI Problem with the alerts! Couldn't find LibraryPanel for current eAlertName: " $ eAlertName);
		return;
	}

	History = `XCOMHISTORY;
	CacheState = XComGameState_ResourceCache(History.GetSingleGameStateObjectForClass(class'XComGameState_ResourceCache'));

	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateData");
	LibraryPanel.MC.QueueString(m_strInstantResourceCacheTitle);
	LibraryPanel.MC.QueueString(CacheState.GetDisplayName());
	LibraryPanel.MC.QueueString(m_strInstantResourceCacheBody);
	LibraryPanel.MC.QueueString("");
	LibraryPanel.MC.QueueString("");
	LibraryPanel.MC.QueueString("");
	LibraryPanel.MC.QueueString(CacheState.GetUIButtonIcon());
	LibraryPanel.MC.QueueString(m_strPOIImage);
	LibraryPanel.MC.QueueString(m_strCarryOn);
	LibraryPanel.MC.QueueString("");
	LibraryPanel.MC.QueueString(m_strPOIReward);
	LibraryPanel.MC.QueueString(CacheState.GetTotalResourceAmount());
	LibraryPanel.MC.EndOp();

	Button2.DisableNavigation(); 
	Button2.Hide();
}

simulated function BuildPointOfInterestAvailableAlert(TAlertPOIAvailableInfo kInfo)
{
	local String strPOIBody, strFirstParam, strFirstParamLabel;
	local bool bIncludeDuration;

	if( LibraryPanel == none )
	{
		`RedScreen("UI Problem with the alerts! Couldn't find LibraryPanel for current eAlertName: " $ eAlertName);
		return;
	}

	// Save camera
	bRestoreCameraPosition = true;
	XComHQPresentationLayer(Movie.Pres).CAMSaveCurrentLocation();

	if(bInstantInterp)
	{
		XComHQPresentationLayer(Movie.Pres).CAMLookAtEarth(kInfo.zoomLocation, 0.75f, 0);
	}
	else
	{
		XComHQPresentationLayer(Movie.Pres).CAMLookAtEarth(kInfo.zoomLocation, 0.75f);
	}

	// Body
	strPOIBody = `XEXPAND.ExpandString(kInfo.strBody) $ "\n";

	// If duration is included, set their values as the first params to display
	if (kInfo.strDurationLabel != "" && kInfo.strDuration != "")
	{
		strFirstParamLabel = kInfo.strDurationLabel;
		strFirstParam = kInfo.strDuration;
		bIncludeDuration = true;
	}
	else // Otherwise use the reward label and string as defaults
	{
		strFirstParamLabel = m_strPOIReward;
		strFirstParam = kInfo.strReward;
	}
		
	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateData");
	LibraryPanel.MC.QueueString(kInfo.strTitle);
	LibraryPanel.MC.QueueString(kInfo.strReport);
	LibraryPanel.MC.QueueString(strPOIBody);
	LibraryPanel.MC.QueueString(kInfo.strRewardIcon);
	LibraryPanel.MC.QueueString(strFirstParamLabel);
	LibraryPanel.MC.QueueString(strFirstParam);
	LibraryPanel.MC.QueueString(kInfo.strUIIcon);
	LibraryPanel.MC.QueueString(kInfo.strImage);
	LibraryPanel.MC.QueueString(kInfo.strInvestigate);
	LibraryPanel.MC.QueueString(kInfo.strIgnore);

	// If duration is included, add the rewards at the end if there is one
	if (bIncludeDuration && kInfo.strReport != "")
	{
		LibraryPanel.MC.QueueString(m_strPOIReward);
		LibraryPanel.MC.QueueString(kInfo.strReward);
	}

	LibraryPanel.MC.EndOp();
}

simulated function BuildPointOfInterestCompleteAlert()
{
	local XComGameStateHistory History;
	local XComGameState_PointOfInterest POIState;
	local String strPOIBody;

	if( LibraryPanel == none )
	{
		`RedScreen("UI Problem with the alerts! Couldn't find LibraryPanel for current eAlertName: " $ eAlertName);
		return;
	}

	History = `XCOMHISTORY;
	POIState = XComGameState_PointOfInterest(History.GetGameStateForObjectID(
		class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(DisplayPropertySet, 'POIRef')));

	// Save camera
	XComHQPresentationLayer(Movie.Pres).CAMSaveCurrentLocation();

	// Body
	strPOIBody = POIState.GetSummary();

	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateData");
	LibraryPanel.MC.QueueString(m_strPOICompleteLabel);
	LibraryPanel.MC.QueueString(POIState.GetDisplayName());
	LibraryPanel.MC.QueueString(strPOIBody);
	LibraryPanel.MC.QueueString(POIState.GetRewardIconString());
	LibraryPanel.MC.QueueString(m_strPOIReward);
	LibraryPanel.MC.QueueString(POIState.GetRewardValuesString());
	LibraryPanel.MC.QueueString(class'UIUtilities_Image'.const.MissionIcon_POI);
	LibraryPanel.MC.QueueString(POIState.GetImage());
	LibraryPanel.MC.QueueString(m_strOk);
	LibraryPanel.MC.QueueString(GetReturnToHQString());
	LibraryPanel.MC.EndOp();

	if ((class'XComGameState_HeadquartersXCom'.static.GetObjectiveStatus('T2_M0_CompleteGuerillaOps') == eObjectiveState_InProgress) ||
		(class'XComGameState_HeadquartersXCom'.static.GetObjectiveStatus('XP0_M1_TutorialLostAndAbandonedComplete') == eObjectiveState_InProgress) ||
		(class'XComGameState_HeadquartersXCom'.static.GetObjectiveStatus('XP0_M1_LostAndAbandonedComplete') == eObjectiveState_InProgress))
	{
		Button2.DisableNavigation(); 
		Button2.Hide();
	}
}

simulated function BuildResourceCacheCompleteAlert()
{
	local XComGameStateHistory History;
	local XComGameState_ResourceCache CacheState;
	local TAlertPOIAvailableInfo kInfo;

	History = `XCOMHISTORY;
	CacheState = XComGameState_ResourceCache(History.GetSingleGameStateObjectForClass(class'XComGameState_ResourceCache'));

	kInfo.zoomLocation = CacheState.Get2DLocation();
	kInfo.strTitle = m_strResourceCacheCompleteTitle;
	kInfo.strLabel = m_strResourceCacheCompleteLabel;
	kInfo.strBody = m_strResourceCacheCompleteBody;
	kInfo.strImage = m_strResourceCacheCompleteImage;
	kInfo.strReport = CacheState.GetDisplayName();
	kInfo.strReward = "";
	kInfo.strRewardIcon = "";

	kInfo.strInvestigate = GetReturnToHQString();
	kInfo.strIgnore = m_strIgnore;
	kInfo.strFlare = m_strResourceCacheCompleteFlare;
	kInfo.strUIIcon = CacheState.GetUIButtonIcon();
	
	BuildPointOfInterestAvailableAlert(kInfo);
}

private function string GetReturnToHQString()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Haven HavenState;
	local XGParamTag ParamTag;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	foreach History.IterateByClassType(class'XComGameState_Haven', HavenState)
	{
		if(HavenState.Region == XComHQ.StartingRegion)
		{
			break;
		}
	}

	ParamTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	ParamTag.StrValue0 = HavenState.GetDisplayName();

	return `XEXPAND.ExpandString(m_strPOIReturnToHQ);
}

simulated function BuildBlackMarketAlert()
{
	// Save camera
	XComHQPresentationLayer(Movie.Pres).CAMSaveCurrentLocation();

	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateData");
	LibraryPanel.MC.QueueString(m_strBlackMarketTitle);
	LibraryPanel.MC.QueueString(m_strBlackMarketLabel);
	LibraryPanel.MC.QueueString(m_strBlackMarketBody);
	LibraryPanel.MC.QueueString(m_strBlackMarketImage);
	LibraryPanel.MC.QueueString(m_strBlackMarketConfirm);
	LibraryPanel.MC.QueueString(m_strIgnore);
	LibraryPanel.MC.QueueString(m_strBlackMarketFooterLeft);
	LibraryPanel.MC.QueueString(m_strBlackMarketFooterRight);
	LibraryPanel.MC.QueueString(m_strBlackMarketLogoString);
	LibraryPanel.MC.EndOp();
}

function BuildHelpResHQGoodsAlert()
{
	local TAlertHelpInfo Info;
	
	Info.strTitle = m_strHelpResHQGoodsTitle;
	Info.strHeader = m_strHelpResHQGoodsHeader;
	Info.strDescription = m_strHelpResHQGoodsDescription;
	Info.strImage = m_strHelpResHQGoodsImage;

	Info.strConfirm = m_strRecruitNewStaff;
	Info.strCarryOn = m_strIgnore;

	BuildHelpAlert(Info);
}

function BuildHelpAlert(TAlertHelpInfo Info)
{
	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateData");
	LibraryPanel.MC.QueueString(Info.strHeader);
	LibraryPanel.MC.QueueString(Info.strTitle);
	LibraryPanel.MC.QueueString(Info.strDescription);
	LibraryPanel.MC.QueueString(Info.strImage);
	LibraryPanel.MC.QueueString(Info.strConfirm);
	LibraryPanel.MC.QueueString(Info.strCarryOn);
	LibraryPanel.MC.EndOp();

	if( Info.strConfirm == "" )
	{
		Button1.Hide(); 
		Button1.DisableNavigation();
	}

	if( Info.strCarryOn == "" )
	{
		Button2.DisableNavigation(); 
		Button2.Hide();
	}
}

simulated function BuildResearchCompleteAlert()
{
	local XComGameStateHistory History;
	local XComGameState_Tech TechState;
	local XComGameState_WorldRegion RegionState;
	local TAlertCompletedInfo kInfo;
	local XGParamTag ParamTag;

	History = `XCOMHISTORY;
	TechState = XComGameState_Tech(History.GetGameStateForObjectID(
		class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(DisplayPropertySet, 'TechRef')));

	kInfo.strName = TechState.GetDisplayName();
	kInfo.strHeaderLabel = m_strResearchCompleteLabel;
	kInfo.strBody = m_strResearchProjectComplete;

	if (TechState.GetMyTemplate().UnlockedDescription != "")
	{
		ParamTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));

		// Datapads
		if (TechState.IntelReward > 0)
		{
			ParamTag.StrValue0 = string(TechState.IntelReward);
		}

		// Facility Leads
		if (TechState.RegionRef.ObjectID != 0)
		{
			RegionState = XComGameState_WorldRegion(`XCOMHISTORY.GetGameStateForObjectID(TechState.RegionRef.ObjectID));
			ParamTag.StrValue0 = RegionState.GetDisplayName();
		}

		kInfo.strBody $= "\n" $ `XEXPAND.ExpandString(TechState.GetMyTemplate().UnlockedDescription);
	}

	kInfo.strConfirm = m_strAssignNewResearch;
	kInfo.strCarryOn = m_strCarryOn;
	kInfo.strImage = TechState.GetImage();
	kInfo = FillInTyganAlertComplete(kInfo);
	kInfo.eColor = eUIState_Warning;
	kInfo.clrAlert = MakeLinearColor(0.75, 0.75, 0.0, 1);

	BuildCompleteAlert(kInfo);
}

simulated function BuildShadowProjectCompleteAlert()
{
	local XComGameStateHistory History;
	local XComGameState_Tech TechState;
	local TAlertCompletedInfo kInfo;

	History = `XCOMHISTORY;
	TechState = XComGameState_Tech(History.GetGameStateForObjectID(
		class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(DisplayPropertySet, 'TechRef')));

	kInfo.strName = TechState.GetDisplayName();
	kInfo.strHeaderLabel = m_strShadowProjectCompleteLabel;
	kInfo.strBody = m_strShadowProjectComplete;
	kInfo.strConfirm = m_strViewReport;
	kInfo.strCarryOn = m_strCarryOn;
	kInfo.strImage = TechState.GetImage();

	kInfo = FillInShenAlertComplete(kInfo);
	
	kInfo.strHeadImage2 = "img:///UILibrary_Common.Head_Tygan";
	kInfo.Staff2ID = class'UIUtilities_Strategy'.static.GetXComHQ().GetHeadScientistRef();
	kInfo.strStaff2Title = class'UIUtilities_Strategy'.default.m_arrStaffTypes[eStaff_HeadScientist];

	kInfo.strHeaderIcon = class'UIUtilities_Image'.const.AlertIcon_Engineering; //TODO: combo image? 

	kInfo.eColor = eUIState_Psyonic;
	kInfo.clrAlert = MakeLinearColor(0.75, 0.0, 0.75, 1);

	BuildCompleteAlert(kInfo);
}

simulated function BuildItemCompleteAlert()
{
	local TAlertCompletedInfo kInfo;
	local X2ItemTemplate ItemTemplate;
	local X2ItemTemplateManager TemplateManager;

	TemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

	ItemTemplate = TemplateManager.FindItemTemplate(
		class'X2StrategyGameRulesetDataStructures'.static.GetDynamicNameProperty(DisplayPropertySet, 'ItemTemplate'));

	kInfo.strName = ItemTemplate.GetItemFriendlyName(, false);
	kInfo.strHeaderLabel = m_strItemCompleteLabel;
	kInfo.strBody = m_strManufacturingComplete;
	kInfo.strConfirm = m_strAssignNewProjects;
	kInfo.strCarryOn = m_strCarryOn;
	kInfo.strImage = ItemTemplate.strImage;
	kInfo = FillInShenAlertComplete(kInfo);
	kInfo.strHeadImage2 = "";
	kInfo.eColor = eUIState_Good;
	kInfo.clrAlert = MakeLinearColor(0.0, 0.75, 0.0, 1);

	BuildCompleteAlert(kInfo);
}

simulated function BuildProvingGroundProjectCompleteAlert()
{
	local XComGameStateHistory History;
	local XComGameState_Tech TechState;
	local TAlertCompletedInfo kInfo;
	local XGParamTag kTag;

	History = `XCOMHISTORY;
	TechState = XComGameState_Tech(History.GetGameStateForObjectID(
		class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(DisplayPropertySet, 'TechRef')));

	kInfo.strName = TechState.GetDisplayName();
	kInfo.strHeaderLabel = m_strProvingGroundProjectCompleteLabel;

	kTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	kTag.StrValue0 = kInfo.strName;

	kInfo.strBody = `XEXPAND.ExpandString(m_strProvingGroundProjectComplete);
	kInfo.strConfirm = m_strAssignNewProjects;
	kInfo.strCarryOn = m_strCarryOn;
	kInfo.strImage = TechState.GetImage();
	kInfo = FillInShenAlertComplete(kInfo);
	kInfo.eColor = eUIState_Warning;
	kInfo.clrAlert = MakeLinearColor(0.75, 0.75, 0.0, 1);

	BuildCompleteAlert(kInfo);
}

simulated function BuildFacilityCompleteAlert()
{
	local TAlertCompletedInfo kInfo;
	local XComGameStateHistory History;
	local XComGameState_FacilityXCom FacilityState;
	local XComGameState_Unit UnitState;
	local string CompletedStr, UnitName;
	local XComNarrativeMoment CompleteNarrative;
	local StateObjectReference FacilityRef;
	local X2FacilityTemplate FacilityTemplate;
	
	FacilityRef.ObjectID = class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(DisplayPropertySet, 'FacilityRef');
	History = `XCOMHISTORY;
	FacilityState = XComGameState_FacilityXCom(History.GetGameStateForObjectID(FacilityRef.ObjectID));
	UnitState = XComGameState_Unit(History.GetGameStateForObjectID(
		class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(DisplayPropertySet, 'UnitRef')));
	FacilityTemplate = FacilityState.GetMyTemplate();

	// Set up the string displaying extra info about the new facility's benefit
	if (FacilityTemplate.GetFacilityInherentValueFn != none)
	{
		CompletedStr = Repl(FacilityTemplate.CompletedSummary, "%VALUE", FacilityTemplate.GetFacilityInherentValueFn(FacilityRef));
	}
	else
	{
		CompletedStr = FacilityTemplate.CompletedSummary;
	}

	if (UnitState != None) // If there was a builder clearing the room, add a string indicating that they are now available
	{
		CompletedStr $= "\n" $ m_strBuilderAvailable;

		UnitName = UnitState.GetFullName();
		if ( class'X2StrategyGameRulesetDataStructures'.static.GetDynamicBoolProperty(DisplayPropertySet, 'bGhostUnit') ) // If the builder was a ghost, the unit who created it will still be staffed and have its name
			UnitName = Repl(UnitState.GetStaffSlot().GetMyTemplate().GhostName, "%UNITNAME", UnitName);

		CompletedStr = Repl(CompletedStr, "%BUILDERNAME", UnitName);
	}
	CompletedStr = class'UIUtilities_Text'.static.GetColoredText(CompletedStr, eUIState_Good, 20);
	     
	kInfo.strName = FacilityTemplate.DisplayName;
	kInfo.strHeaderLabel = m_strFacilityContructedLabel;
	kInfo.strBody = CompletedStr;
	kInfo.strConfirm = m_strViewFacility;
	kInfo.strCarryOn = m_strCarryOn;
	kInfo.strImage = FacilityTemplate.strImage;	
	kInfo = FillInShenAlertComplete(kInfo);
	kInfo.eColor = eUIState_Good;
	kInfo.clrAlert = MakeLinearColor(0.0, 0.75, 0.0, 1);

	if (FacilityTemplate.DataName == 'ShadowChamber')
		kInfo.strCarryOn = "";

	//bsg-crobinson (5.22.17): shift buttons when this screen is for training center
	if (FacilityTemplate.DisplayName == "Training Center" && `ISCONTROLLERACTIVE)
	{
		Button1.SetPosition(Button1.X, Button1.Y + 10);
		Button2.SetPosition(Button2.X, Button2.Y + 10);
	}
	//bsg-crobinson (5.22.17): end

	BuildCompleteAlert(kInfo);

	if(FacilityTemplate.FacilityCompleteNarrative != "")
	{
		CompleteNarrative = XComNarrativeMoment(`CONTENT.RequestGameArchetype(FacilityTemplate.FacilityCompleteNarrative));
		if(CompleteNarrative != None)
		{
			`HQPRES.UINarrative(CompleteNarrative);
		}
	}
}

simulated function BuildUpgradeCompleteAlert()
{
	local TAlertCompletedInfo kInfo;
	local X2FacilityUpgradeTemplate UpgradeTemplate;
	local X2StrategyElementTemplateManager TemplateManager;

	TemplateManager = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();

	UpgradeTemplate = X2FacilityUpgradeTemplate(TemplateManager.FindStrategyElementTemplate(
		class'X2StrategyGameRulesetDataStructures'.static.GetDynamicNameProperty(DisplayPropertySet, 'UpgradeTemplate')));

	kInfo.strName = UpgradeTemplate.DisplayName;
	kInfo.strHeaderLabel = m_strUpgradeContructedLabel;
	kInfo.strBody = m_strUpgradeComplete;
	kInfo.strConfirm = m_strAssignNewUpgrade;
	kInfo.strCarryOn = m_strCarryOn;
	kInfo.strImage = UpgradeTemplate.strImage;
	kInfo = FillInShenAlertComplete(kInfo);
	kInfo.eColor = eUIState_Good;
	kInfo.clrAlert = MakeLinearColor(0.0, 0.75, 0.0, 1);

	BuildCompleteAlert(kInfo);
}

simulated function BuildClearRoomCompleteAlert()
{
	local TAlertCompletedInfo kInfo;
	local XComGameStateHistory History;
	local XComGameState_HeadquartersRoom RoomState;
	local XComGameState_Unit UnitState;
	local StaffUnitInfo CurrentBuilderInfo;
	local string BuilderAvailableStr;
	local string UnitString, UnitName;
	local X2SpecialRoomFeatureTemplate SpecialRoomFeatureTemplate;
	local X2StrategyElementTemplateManager TemplateManager;
	local array<DynamicProperty> ArrayProperties, InnerProperties;
	local int Index;

	TemplateManager = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();

	SpecialRoomFeatureTemplate = X2SpecialRoomFeatureTemplate(TemplateManager.FindStrategyElementTemplate(
		class'X2StrategyGameRulesetDataStructures'.static.GetDynamicNameProperty(DisplayPropertySet, 'SpecialRoomFeatureTemplate')));

	History = `XCOMHISTORY;
	RoomState = XComGameState_HeadquartersRoom(History.GetGameStateForObjectID(
		class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(DisplayPropertySet, 'RoomRef')));

	kInfo.strName = SpecialRoomFeatureTemplate.ClearingCompletedText;
	kInfo.strHeaderLabel = m_strClearRoomCompleteLabel;
	kInfo.strBody = m_strClearRoomComplete;

	// If there were builders clearing the room, add a string indicating that they are now available
		UnitString = "";
	class'X2StrategyGameRulesetDataStructures'.static.GetDynamicArrayProperty(DisplayPropertySet, 'StaffUnitArray', ArrayProperties);
	for( Index = 0; Index < ArrayProperties.Length; ++Index )
		{
		InnerProperties.Length = 0;
		class'X2StrategyGameRulesetDataStructures'.static.GetDynamicArrayPropertyFromArray(ArrayProperties[Index].ValueArray, 'StaffUnitArrayInner', InnerProperties);
		class'X2StrategyGameRulesetDataStructures'.static.GetDynamicStaffUnitInfoProperties(InnerProperties, CurrentBuilderInfo);

			UnitState = XComGameState_Unit(History.GetGameStateForObjectID(CurrentBuilderInfo.UnitRef.ObjectID));
			if (Len(UnitString) > 0)
			{
				UnitString $= ", ";
			}
			
			UnitName = UnitState.GetName(eNameType_Full);
			if (CurrentBuilderInfo.bGhostUnit) // If the builder was a ghost, the unit who created it will still be staffed and have its name
				UnitName = Repl(UnitState.GetStaffSlot().GetMyTemplate().GhostName, "%UNITNAME", UnitName);

			UnitString $= UnitName;
		}
	UnitString = class'UIUtilities_Text'.static.FormatCommaSeparatedNouns(UnitString);

	if( Len(UnitString) > 0 )
	{
		BuilderAvailableStr = m_strBuilderAvailable;
		BuilderAvailableStr = Repl(BuilderAvailableStr, "%BUILDERNAME", UnitString);
		BuilderAvailableStr = class'UIUtilities_Text'.static.GetColoredText(BuilderAvailableStr, eUIState_Good, 20);
		kInfo.strBody $= "\n" $ BuilderAvailableStr;
	}
	
	kInfo.strBody $= "\n" $ m_strClearRoomLoot @ RoomState.strLootGiven;
	
	kInfo.strConfirm = m_strViewRoom;
	kInfo.strCarryOn = m_strCarryOn;
	kInfo.strImage = SpecialRoomFeatureTemplate.strImage;
	kInfo = FillInShenAlertComplete(kInfo);
	kInfo.eColor = eUIState_Good;
	kInfo.clrAlert = MakeLinearColor(0.0, 0.75, 0.0, 1);

	BuildCompleteAlert(kInfo);
}

simulated function BuildTrainingCompleteAlert(string TitleLabel)
{
	local XComGameState_Unit UnitState;
	local X2AbilityTemplate TrainedAbilityTemplate;
	local array<SoldierClassAbilityType> AbilityTree;
	local X2AbilityTemplateManager AbilityTemplateManager;
	local X2SoldierClassTemplate ClassTemplate;
	local XGParamTag kTag;
	local XComGameState_ResistanceFaction FactionState;
	local int i;
	local string AbilityIcon, AbilityName, AbilityDescription, ClassIcon, ClassName, RankName;
	
	if( LibraryPanel == none )
	{
		`RedScreen("UI Problem with the alerts! Couldn't find LibraryPanel for current eAlertName: " $ eAlertName);
		return;
	}

	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(
		class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(DisplayPropertySet, 'UnitRef')));
	ClassTemplate = UnitState.GetSoldierClassTemplate();
	ClassName = Caps(ClassTemplate.DisplayName);
	ClassIcon = ClassTemplate.IconImage;
	RankName = Caps(class'X2ExperienceConfig'.static.GetRankName(UnitState.GetRank(), ClassTemplate.DataName));
	
	FactionState = UnitState.GetResistanceFaction();

	kTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	kTag.StrValue0 = "";

	AbilityTemplateManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	AbilityTree = UnitState.GetRankAbilities(0);
	for( i = 0; i < AbilityTree.Length; ++i )
	{
		if (AbilityTree[i].AbilityName == '')
			continue;

		TrainedAbilityTemplate = AbilityTemplateManager.FindAbilityTemplate(AbilityTree[i].AbilityName);

		if( TrainedAbilityTemplate.bHideOnClassUnlock ) continue;

		// Ability Name
		AbilityName = TrainedAbilityTemplate.LocFriendlyName != "" ? TrainedAbilityTemplate.LocFriendlyName : ("Missing 'LocFriendlyName' for ability '" $ TrainedAbilityTemplate.DataName $ "'");

		// Ability Description
		AbilityDescription = TrainedAbilityTemplate.HasLongDescription() ? TrainedAbilityTemplate.GetMyLongDescription(, UnitState) : ("Missing 'LocLongDescription' for ability " $ TrainedAbilityTemplate.DataName $ "'");
		AbilityIcon = TrainedAbilityTemplate.IconImage;

		break; // Stop looping after we get information on an ability
	}

	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateData");
	LibraryPanel.MC.QueueString(TitleLabel);
	LibraryPanel.MC.QueueString("");
	LibraryPanel.MC.QueueString(ClassIcon);
	LibraryPanel.MC.QueueString(RankName);
	LibraryPanel.MC.QueueString(UnitState.GetName(eNameType_FullNick));
	LibraryPanel.MC.QueueString(ClassName);
	LibraryPanel.MC.QueueString(AbilityIcon);
	LibraryPanel.MC.QueueString(m_strNewAbilityLabel);
	LibraryPanel.MC.QueueString(AbilityName);
	LibraryPanel.MC.QueueString(AbilityDescription);
	LibraryPanel.MC.QueueString(m_strViewSoldier);
	LibraryPanel.MC.QueueString(m_strCarryOn);
	LibraryPanel.MC.EndOp();
	GetOrStartWaitingForStaffImage();

	//Set icons before hiding the button.
	Button1.SetGamepadIcon(class'UIUtilities_Input'.static.GetGamepadIconPrefix() $ class'UIUtilities_Input'.const.ICON_X_SQUARE);
	Button2.SetGamepadIcon(class'UIUtilities_Input'.static.GetAdvanceButtonIcon());
	
	//bsg-crobinson (5.17.17): Buttons need to be in a different area for this screen
	Button1.OnSizeRealized = OnTrainingButtonRealized;
	Button2.OnSizeRealized = OnTrainingButtonRealized;
	//bsg-crobinson (5.17.17): end

	// Hide "View Soldier" button if player is on top of avenger, prevents ui state stack issues
	if (Movie.Pres.ScreenStack.IsInStack(class'UIArmory_Promotion'))
	{
		Button1.Hide(); 
		Button1.DisableNavigation();
	}

	if (FactionState != none)
		SetFactionIcon(FactionState.GetFactionIcon());
}

//bsg-crobinson (5.17.17): Realize the buttons need to be in a different place for this alert
simulated function OnTrainingButtonRealized()
{
	Button1.SetX((-Button1.Width / 2.0) - 300);
	Button2.SetX((-Button2.Width / 2.0) - 300);
}
//bsg-crobinson (5.17.17): end

simulated function BuildPsiTrainingCompleteAlert(string TitleLabel)
{
	local XComGameState_Unit UnitState;
	local X2SoldierClassTemplate ClassTemplate;
	local XGParamTag kTag;
	local string AbilityIcon, AbilityName, AbilityDescription, ClassIcon, ClassName, RankName;
	local X2AbilityTemplate AbilityTemplate;
	local X2AbilityTemplateManager TemplateManager;

	TemplateManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();

	AbilityTemplate = TemplateManager.FindAbilityTemplate(
		class'X2StrategyGameRulesetDataStructures'.static.GetDynamicNameProperty(DisplayPropertySet, 'AbilityTemplate'));
	
	if (LibraryPanel == none)
	{
		`RedScreen("UI Problem with the alerts! Couldn't find LibraryPanel for current eAlertName: " $ eAlertName);
		return;
	}

	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(
		class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(DisplayPropertySet, 'UnitRef')));
	ClassTemplate = UnitState.GetSoldierClassTemplate();
	ClassName = Caps(ClassTemplate.DisplayName);
	ClassIcon = ClassTemplate.IconImage;
	RankName = Caps(class'X2ExperienceConfig'.static.GetRankName(UnitState.GetRank(), ClassTemplate.DataName));

	kTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	kTag.StrValue0 = "";

	// Ability Name
	AbilityName = AbilityTemplate.LocFriendlyName != "" ? AbilityTemplate.LocFriendlyName : ("Missing 'LocFriendlyName' for ability '" $ AbilityTemplate.DataName $ "'");

	// Ability Description
	AbilityDescription = AbilityTemplate.HasLongDescription() ? AbilityTemplate.GetMyLongDescription(, UnitState) : ("Missing 'LocLongDescription' for ability " $ AbilityTemplate.DataName $ "'");
	AbilityIcon = AbilityTemplate.IconImage;

	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateData");
	LibraryPanel.MC.QueueString(TitleLabel);
	LibraryPanel.MC.QueueString("");
	LibraryPanel.MC.QueueString(ClassIcon);
	LibraryPanel.MC.QueueString(RankName);
	LibraryPanel.MC.QueueString(UnitState.GetName(eNameType_FullNick));
	LibraryPanel.MC.QueueString(ClassName);
	LibraryPanel.MC.QueueString(AbilityIcon);
	LibraryPanel.MC.QueueString(m_strNewAbilityLabel);
	LibraryPanel.MC.QueueString(AbilityName);
	LibraryPanel.MC.QueueString(AbilityDescription);
	LibraryPanel.MC.QueueString(m_strContinueTraining);
	LibraryPanel.MC.QueueString(m_strCarryOn);
	LibraryPanel.MC.EndOp();
	GetOrStartWaitingForStaffImage();
	// Hide "Continue Training" button if player is on top of avenger, prevents ui state stack issues
	if(Movie.Pres.ScreenStack.IsInStack(class'UIArmory_Promotion'))
	{
		Button1.Hide(); 
		Button1.DisableNavigation();
	}
}

simulated function BuildSoldierPromotedAlert()
{
	local XComGameState_Unit UnitState;
	local X2SoldierClassTemplate ClassTemplate;
	local XGParamTag kTag;
	local string ClassIcon, ClassName, RankName, PromotionString;
	
	if (LibraryPanel == none)
	{
		`RedScreen("UI Problem with the alerts! Couldn't find LibraryPanel for current eAlertName: " $ eAlertName);
		return;
	}

	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(
		class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(DisplayPropertySet, 'UnitRef')));
	ClassTemplate = UnitState.GetSoldierClassTemplate();
	ClassName = Caps(ClassTemplate.DisplayName);
	ClassIcon = ClassTemplate.IconImage;
	RankName = Caps(class'X2ExperienceConfig'.static.GetRankName(UnitState.GetRank(), ClassTemplate.DataName));

	kTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	kTag.StrValue0 = UnitState.GetFullName();

	PromotionString = `XEXPAND.ExpandString(m_strSoldierPromoted);
	
	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateData");
	LibraryPanel.MC.QueueString(m_strSoldierPromotedLabel);
	LibraryPanel.MC.QueueString("");
	LibraryPanel.MC.QueueString(ClassIcon);
	LibraryPanel.MC.QueueString(RankName);
	LibraryPanel.MC.QueueString(UnitState.GetName(eNameType_FullNick));
	LibraryPanel.MC.QueueString(ClassName);
	LibraryPanel.MC.QueueString(""); // Ability Icon
	LibraryPanel.MC.QueueString(""); // Ability Label
	LibraryPanel.MC.QueueString(""); // Ability Name
	LibraryPanel.MC.QueueString(PromotionString); // Ability Description
	LibraryPanel.MC.QueueString(m_strCarryOn);
	LibraryPanel.MC.QueueString(m_strContinueTraining);
	LibraryPanel.MC.EndOp();
	GetOrStartWaitingForStaffImage();
	// Always hide the "Continue Training" button, since this is just an informational popup used during Covert Action rewards
	Button2.Hide(); 
	Button2.DisableNavigation();
}

simulated function BuildPsiLabIntroAlert()
{
	local TAlertAvailableInfo kInfo;
	local X2FacilityTemplate FacilityTemplate;
	local X2StrategyElementTemplateManager TemplateManager;

	TemplateManager = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();

	FacilityTemplate = X2FacilityTemplate(TemplateManager.FindStrategyElementTemplate(
		class'X2StrategyGameRulesetDataStructures'.static.GetDynamicNameProperty(DisplayPropertySet, 'FacilityTemplate')));

	kInfo.strTitle = m_strIntroToPsiLab;
	kInfo.strName = FacilityTemplate.DisplayName;
	kInfo.strBody = m_strIntroToPsiLabBody;
	kInfo.strConfirm = m_strAccept;
	kInfo.strImage = FacilityTemplate.strImage;
	kInfo.eColor = eUIState_Good;
	kInfo.clrAlert = MakeLinearColor(0.0, 0.75, 0.0, 1);

	kInfo = FillInShenAlertAvailable(kInfo);

	BuildAvailableAlert(kInfo);
}

simulated function BuildPsiOperativeIntroAlert()
{
	local XComGameState_Unit UnitState;
	local String IntroPsiOpTitle, IntroPsiOpBody;

	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(
		class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(DisplayPropertySet, 'UnitRef')));

	IntroPsiOpTitle = m_strPsiOperativeIntroTitle;
	IntroPsiOpTitle = Repl(IntroPsiOpTitle, "%UNITNAME", Caps(UnitState.GetName(eNameType_FullNick)));

	IntroPsiOpBody = Repl(m_strPsiOperativeIntroHelp, "%UNITNAME", UnitState.GetFullName());

	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateData");
	LibraryPanel.MC.QueueString(m_strSoldierShakenHeader); //ATTENTION
	LibraryPanel.MC.QueueString(IntroPsiOpTitle); //SOLDIER SHAKEN 
	LibraryPanel.MC.QueueString(UnitState.GetSoldierClassTemplate().IconImage); //ICON
	LibraryPanel.MC.QueueString(Caps(UnitState.GetName(eNameType_FullNick))); //STAFF AVAILABLE STRING
	LibraryPanel.MC.QueueString(m_strPsiOperativeIntro); //STAFF BONUS STRING
	LibraryPanel.MC.QueueString(IntroPsiOpBody); //STAFF BENEFIT STRING
	LibraryPanel.MC.QueueString("");
	LibraryPanel.MC.QueueString(m_strOK); //OK
	LibraryPanel.MC.EndOp();
	GetOrStartWaitingForStaffImage();
	//This panel has only one button, for confirm.
	Button2.DisableNavigation(); 
	Button2.Hide();

	if (`ISCONTROLLERACTIVE)
		Button1.SetPosition(Button1.X, Button1.Y + 25);
}

simulated function BuildTrainingCenterIntroAlert()
{
	local TAlertAvailableInfo kInfo;
	local X2FacilityTemplate FacilityTemplate;
	local X2StrategyElementTemplateManager TemplateManager;

	TemplateManager = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();

	FacilityTemplate = X2FacilityTemplate(TemplateManager.FindStrategyElementTemplate(
		class'X2StrategyGameRulesetDataStructures'.static.GetDynamicNameProperty(DisplayPropertySet, 'FacilityTemplate')));

	kInfo.strTitle = m_strTrainingCenterIntroLabel;
	kInfo.strName = FacilityTemplate.DisplayName;
	kInfo.strBody = m_strTrainingCenterIntroBody;
	kInfo.strConfirm = m_strAccept;
	kInfo.strImage = FacilityTemplate.strImage;
	kInfo.eColor = eUIState_Good;
	kInfo.clrAlert = MakeLinearColor(0.0, 0.75, 0.0, 1);

	kInfo = FillInShenAlertAvailable(kInfo);

	BuildAvailableAlert(kInfo);
}

simulated function BuildInfirmaryIntroAlert()
{
	local TAlertAvailableInfo kInfo;
	local X2FacilityTemplate FacilityTemplate;
	local X2StrategyElementTemplateManager TemplateManager;

	TemplateManager = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();

	FacilityTemplate = X2FacilityTemplate(TemplateManager.FindStrategyElementTemplate(
		class'X2StrategyGameRulesetDataStructures'.static.GetDynamicNameProperty(DisplayPropertySet, 'FacilityTemplate')));

	kInfo.strTitle = m_strInfirmaryIntroLabel;
	kInfo.strName = FacilityTemplate.DisplayName;
	kInfo.strBody = m_strInfirmaryIntroBody;
	kInfo.strConfirm = m_strAccept;
	kInfo.strImage = FacilityTemplate.strImage;
	kInfo.eColor = eUIState_Good;
	kInfo.clrAlert = MakeLinearColor(0.0, 0.75, 0.0, 1);

	kInfo = FillInShenAlertAvailable(kInfo);

	BuildAvailableAlert(kInfo);
}

simulated function BuildConstructionSlotOpenAlert()
{
	local XComGameState_HeadquartersRoom RoomState;
	local XComGameState_FacilityXCom Facility;
	local string SlotOpenStr;

	RoomState = XComGameState_HeadquartersRoom(`XCOMHISTORY.GetGameStateForObjectID(
		class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(DisplayPropertySet, 'RoomRef')));
	Facility = XComGameState_FacilityXCom(`XCOMHISTORY.GetGameStateForObjectID(RoomState.GetBuildFacilityProject().ProjectFocus.ObjectID));

	SlotOpenStr = m_strBuildStaffSlotOpen;
	SlotOpenStr = Repl(SlotOpenStr, "%FACILITYNAME", Facility.GetMyTemplate().DisplayName);
	
	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateData");
	LibraryPanel.MC.QueueString(m_strStaffSlotOpenLabel);
	LibraryPanel.MC.QueueString(Caps(Facility.GetMyTemplate().DisplayName));
	LibraryPanel.MC.QueueString(SlotOpenStr);
	LibraryPanel.MC.QueueString("" /*optional benefit string*/);
	LibraryPanel.MC.QueueString(Facility.GetMyTemplate().strImage);
	LibraryPanel.MC.QueueString(m_strOK);
	LibraryPanel.MC.QueueString(m_strCarryOn);
	LibraryPanel.MC.EndOp();

	ButtonGroup.Navigator.HorizontalNavigation = true;
}

simulated function BuildClearRoomSlotOpenAlert()
{
	local XComGameState_HeadquartersRoom RoomState;
	local string SlotOpenStr;
	
	RoomState = XComGameState_HeadquartersRoom(`XCOMHISTORY.GetGameStateForObjectID(
		class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(DisplayPropertySet, 'RoomRef')));

	SlotOpenStr = m_strClearRoomStaffSlotOpen;
	SlotOpenStr = Repl(SlotOpenStr, "%CLEARTEXT", RoomState.GetSpecialFeature().ClearingInProgressText);
	
	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateData");
	LibraryPanel.MC.QueueString(m_strStaffSlotOpenLabel);
	LibraryPanel.MC.QueueString(Caps(RoomState.GetSpecialFeature().UnclearedDisplayName));
	LibraryPanel.MC.QueueString(SlotOpenStr);
	LibraryPanel.MC.QueueString("" /*optional benefit string*/);
	LibraryPanel.MC.QueueString(RoomState.GetSpecialFeature().strImage);
	LibraryPanel.MC.QueueString(m_strOK);
	LibraryPanel.MC.QueueString(m_strCarryOn);
	LibraryPanel.MC.EndOp();
	
	ButtonGroup.Navigator.HorizontalNavigation = true;
}

simulated function BuildStaffSlotOpenAlert()
{
	local XComGameState_FacilityXCom FacilityState;
	local string SlotOpenStr, SlotBenefitStr;
	local X2FacilityTemplate FacilityTemplate;
	local X2StaffSlotTemplate StaffSlotTemplate;
	local X2StrategyElementTemplateManager TemplateManager;

	TemplateManager = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();

	StaffSlotTemplate = X2StaffSlotTemplate(TemplateManager.FindStrategyElementTemplate(
		class'X2StrategyGameRulesetDataStructures'.static.GetDynamicNameProperty(DisplayPropertySet, 'StaffSlotTemplate')));

	FacilityState = XComGameState_FacilityXCom(`XCOMHISTORY.GetGameStateForObjectID(
		class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(DisplayPropertySet, 'FacilityRef')));
	FacilityTemplate = FacilityState.GetMyTemplate();

	// Info displayed is different if the open staff slot is for a scientist or an engineer
	if (StaffSlotTemplate.bEngineerSlot)
	{
		SlotOpenStr = m_strEngStaffSlotOpen;	
	}
	else if (StaffSlotTemplate.bScientistSlot)
	{
		SlotOpenStr = m_strSciStaffSlotOpen;
	}
	SlotOpenStr = Repl(SlotOpenStr, "%FACILITYNAME", FacilityTemplate.DisplayName);
	
	// Set up the strings displaying extra info about the new staff slot's benefit
	SlotBenefitStr = m_strStaffSlotOpenBenefit @ StaffSlotTemplate.BonusEmptyText;
	SlotBenefitStr = SlotBenefitStr;
	
	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateData");
	LibraryPanel.MC.QueueString(m_strStaffSlotOpenLabel);
	LibraryPanel.MC.QueueString(Caps(FacilityTemplate.DisplayName));
	LibraryPanel.MC.QueueString(SlotOpenStr);
	LibraryPanel.MC.QueueString(SlotBenefitStr);
	LibraryPanel.MC.QueueString(FacilityTemplate.strImage);
	LibraryPanel.MC.QueueString(m_strOK);
	LibraryPanel.MC.QueueString(m_strCarryOn);
	LibraryPanel.MC.EndOp();

	ButtonGroup.Navigator.HorizontalNavigation = true;
}

simulated function TAlertCompletedInfo FillInShenAlertComplete(TAlertCompletedInfo kInfo)
{
	kInfo.strHeadImage1 = "img:///UILibrary_Common.Head_Shen";
	kInfo.Staff1ID = class'UIUtilities_Strategy'.static.GetXComHQ().GetHeadEngineerRef();
	kInfo.strStaff1Title = class'UIUtilities_Strategy'.default.m_arrStaffTypes[eStaff_HeadEngineer];
	kInfo.strHeaderIcon = class'UIUtilities_Image'.const.AlertIcon_Engineering_Black;

	return kInfo;
}

simulated function TAlertCompletedInfo FillInTyganAlertComplete(TAlertCompletedInfo kInfo)
{
	kInfo.strHeadImage1 = "img:///UILibrary_Common.Head_Tygan";
	kInfo.Staff1ID = class'UIUtilities_Strategy'.static.GetXComHQ().GetHeadScientistRef();
	kInfo.strStaff1Title = class'UIUtilities_Strategy'.default.m_arrStaffTypes[eStaff_HeadScientist];
	kInfo.strHeaderIcon = class'UIUtilities_Image'.const.AlertIcon_Science_Black;

	return kInfo;
}

simulated function BuildCompleteAlert(TAlertCompletedInfo kInfo)
{
	local XGParamTag ParamTag;
	local XComGameState_Unit Staff;

	Staff = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(kInfo.Staff1ID));

	if( LibraryPanel == none )
	{
		`RedScreen("UI Problem with the alerts! Couldn't find LibraryPanel for current eAlertName: " $ eAlertName);
		return;
	}
	
	// Body
	ParamTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	ParamTag.StrValue0 = kInfo.strName;
	kInfo.strBody = `XEXPAND.ExpandString(kInfo.strBody);

	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateData");
	LibraryPanel.MC.QueueNumber(class'X2StrategyGameRulesetDataStructures'.default.UIAlertTypes.Find(DisplayPropertySet.SecondaryRoutingKey));
	LibraryPanel.MC.QueueString(kInfo.strHeaderLabel);
	LibraryPanel.MC.QueueString(kInfo.strName);
	LibraryPanel.MC.QueueString(kInfo.strName);
	LibraryPanel.MC.QueueString(kInfo.strBody);
	LibraryPanel.MC.QueueString(kInfo.strStaff1Title);
	LibraryPanel.MC.QueueString(Staff.GetName(eNameType_Full));
	LibraryPanel.MC.QueueString(kInfo.strHeaderIcon);
	LibraryPanel.MC.QueueString(kInfo.strImage);
	LibraryPanel.MC.QueueString(kInfo.strHeadImage1);
	LibraryPanel.MC.QueueString(kInfo.strConfirm);
	LibraryPanel.MC.QueueString(kInfo.strCarryOn);
	LibraryPanel.MC.EndOp();

	if (kInfo.strCarryOn == "")
	{
		Button2.DisableNavigation(); 
		Button2.Hide();
	}
}

simulated function BuildResearchAvailableAlert()
{
	local XComGameStateHistory History;
	local XComGameState_Tech TechState;
	local TAlertAvailableInfo kInfo;

	History = `XCOMHISTORY;
	TechState = XComGameState_Tech(History.GetGameStateForObjectID(
		class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(DisplayPropertySet, 'TechRef')));

	kInfo.strTitle = m_strNewResearchAvailable;
	kInfo.strName = TechState.GetDisplayName();
	kInfo.strBody = TechState.GetSummary();
	kInfo.strConfirm = m_strAccept;
	kInfo.strImage = TechState.GetImage();
	kInfo.eColor = eUIState_Warning;
	kInfo.clrAlert = MakeLinearColor(0.75, 0.75, 0.0, 1);

	kInfo = FillInTyganAlertAvailable(kInfo);

	BuildAvailableAlert(kInfo);
}

simulated function BuildInstantResearchAvailableAlert()
{
	local XComGameStateHistory History;
	local XComGameState_Tech TechState;
	local TAlertAvailableInfo kInfo;
	local string StrBody;
	
	History = `XCOMHISTORY;
	TechState = XComGameState_Tech(History.GetGameStateForObjectID(
		class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(DisplayPropertySet, 'TechRef')));

	StrBody = Repl(m_strInstantResearchAvailableBody, "%TECHNAME", TechState.GetDisplayName());
	StrBody = Repl(StrBody, "%UNITNAME", TechState.GetMyTemplate().AlertString);

	kInfo.strTitle = Repl(m_strInstantResearchAvailable, "%TECHNAME", Caps(TechState.GetDisplayName()));
	kInfo.strName = TechState.GetDisplayName();
	kInfo.strBody = StrBody;
	kInfo.strConfirm = m_strAccept;
	kInfo.strImage = TechState.GetImage();
	kInfo.eColor = eUIState_Warning;
	kInfo.clrAlert = MakeLinearColor(0.75, 0.75, 0.0, 1);

	kInfo = FillInTyganAlertAvailable(kInfo);

	BuildAvailableAlert(kInfo);
}

simulated function BuildShadowProjectAvailableAlert()
{
	local XComGameStateHistory History;
	local XComGameState_Tech TechState;
	local TAlertAvailableInfo kInfo;

	History = `XCOMHISTORY;
	TechState = XComGameState_Tech(History.GetGameStateForObjectID(
		class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(DisplayPropertySet, 'TechRef')));

	kInfo.strTitle = m_strNewShadowProjectAvailable;
	kInfo.strName = TechState.GetDisplayName();
	kInfo.strBody = TechState.GetSummary();
	kInfo.strConfirm = m_strAccept;
	kInfo.strImage = TechState.GetImage();
	kInfo.eColor = eUIState_Psyonic;
	kInfo.clrAlert = MakeLinearColor(0.75, 0.0, 0.75, 1);

	kInfo = FillInTyganAlertAvailable(kInfo);

	BuildAvailableAlert(kInfo);
}

simulated function BuildItemAvailableAlert()
{
	local TAlertAvailableInfo kInfo;
	local X2ItemTemplate ItemTemplate;
	local X2ItemTemplateManager TemplateManager;

	TemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

	ItemTemplate = TemplateManager.FindItemTemplate(
		class'X2StrategyGameRulesetDataStructures'.static.GetDynamicNameProperty(DisplayPropertySet, 'ItemTemplate'));

	kInfo.strTitle = m_strNewItemAvailable;
	kInfo.strName = ItemTemplate.GetItemFriendlyName(, false);
	kInfo.strBody = ItemTemplate.GetItemBriefSummary();
	kInfo.strConfirm = m_strAccept;
	kInfo.strImage = ItemTemplate.strImage;
	kInfo.eColor = eUIState_Good;
	kInfo.clrAlert = MakeLinearColor(0.0, 0.75, 0.0, 1);

	kInfo = FillInShenAlertAvailable(kInfo);

	BuildAvailableAlert(kInfo);
}

simulated function BuildItemReceivedAlert()
{
	local TAlertAvailableInfo kInfo;
	local X2ItemTemplate ItemTemplate;
	local X2ItemTemplateManager TemplateManager;

	TemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

	ItemTemplate = TemplateManager.FindItemTemplate(
		class'X2StrategyGameRulesetDataStructures'.static.GetDynamicNameProperty(DisplayPropertySet, 'ItemTemplate'));

	kInfo.strTitle = m_strNewItemReceived;
	kInfo.strName = ItemTemplate.GetItemFriendlyName(, false);
	kInfo.strBody = ItemTemplate.GetItemBriefSummary() $ "\n\n" $ Repl(m_strItemReceivedInInventory, "%ITEMNAME", ItemTemplate.GetItemFriendlyName(, false));
	kInfo.strConfirm = m_strAccept;
	kInfo.strImage = ItemTemplate.strImage;
	kInfo.eColor = eUIState_Good;
	kInfo.clrAlert = MakeLinearColor(0.0, 0.75, 0.0, 1);

	kInfo = FillInShenAlertAvailable(kInfo);

	BuildAvailableAlert(kInfo);
}

simulated function BuildItemReceivedProvingGroundAlert()
{
	local XComGameState_Tech TechState;
	local TAlertAvailableInfo kInfo;
	local string TitleStr;
	local X2ItemTemplate ItemTemplate;
	local X2ItemTemplateManager TemplateManager;
		
	TemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

	ItemTemplate = TemplateManager.FindItemTemplate(
		class'X2StrategyGameRulesetDataStructures'.static.GetDynamicNameProperty(DisplayPropertySet, 'ItemTemplate'));

	TechState = XComGameState_Tech(`XCOMHISTORY.GetGameStateForObjectID(
		class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(DisplayPropertySet, 'TechRef')));
	TitleStr = Repl(m_strNewItemReceivedProvingGround, "%PROJECTNAME", Caps(TechState.GetDisplayName()));

	kInfo.strTitle = TitleStr;
	kInfo.strName = ItemTemplate.GetItemFriendlyName(, false);
	kInfo.strBody = ItemTemplate.GetItemBriefSummary() $ "\n\n" $ Repl(m_strItemReceivedInInventory, "%ITEMNAME", ItemTemplate.GetItemFriendlyName(, false));
	kInfo.strConfirm = m_strAccept;
	kInfo.strImage = ItemTemplate.strImage;
	kInfo.eColor = eUIState_Good;
	kInfo.clrAlert = MakeLinearColor(0.0, 0.75, 0.0, 1);

	kInfo = FillInShenAlertAvailable(kInfo);

	BuildAvailableAlert(kInfo);
}

simulated function BuildItemUpgradedAlert()
{
	local TAlertAvailableInfo kInfo;
	local X2ItemTemplate ItemTemplate;
	local X2ItemTemplateManager TemplateManager;

	TemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

	ItemTemplate = TemplateManager.FindItemTemplate(
		class'X2StrategyGameRulesetDataStructures'.static.GetDynamicNameProperty(DisplayPropertySet, 'ItemTemplate'));

	kInfo.strTitle = m_strNewItemUpgraded;
	kInfo.strName = ItemTemplate.GetItemFriendlyName(, false);
	kInfo.strBody = ItemTemplate.GetItemBriefSummary();
	kInfo.strConfirm = m_strAccept;
	kInfo.strImage = ItemTemplate.strImage;
	kInfo.eColor = eUIState_Good;
	kInfo.clrAlert = MakeLinearColor(0.0, 0.75, 0.0, 1);

	kInfo = FillInShenAlertAvailable(kInfo);

	BuildAvailableAlert(kInfo);
}

simulated function BuildProvingGroundProjectAvailableAlert()
{
	local XComGameStateHistory History;
	local XComGameState_Tech TechState;
	local TAlertAvailableInfo kInfo;

	History = `XCOMHISTORY;
	TechState = XComGameState_Tech(History.GetGameStateForObjectID(
		class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(DisplayPropertySet, 'TechRef')));

	kInfo.strTitle = m_strNewProvingGroundProjectAvailable;
	kInfo.strName = TechState.GetDisplayName();
	kInfo.strBody = TechState.GetSummary();
	kInfo.strConfirm = m_strAccept;
	kInfo.strImage = TechState.GetImage();
	kInfo.eColor = eUIState_Warning; 
	kInfo.clrAlert = MakeLinearColor(0.75, 0.75, 0.0, 1);

	kInfo = FillInShenAlertAvailable(kInfo);

	BuildAvailableAlert(kInfo);
}

simulated function BuildFacilityAvailableAlert()
{
	local TAlertAvailableInfo kInfo;
	local X2FacilityTemplate FacilityTemplate;
	local X2StrategyElementTemplateManager TemplateManager;

	TemplateManager = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();

	FacilityTemplate = X2FacilityTemplate(TemplateManager.FindStrategyElementTemplate(
		class'X2StrategyGameRulesetDataStructures'.static.GetDynamicNameProperty(DisplayPropertySet, 'FacilityTemplate')));

	kInfo.strTitle = m_strNewFacilityAvailable;
	kInfo.strName = FacilityTemplate.DisplayName;
	kInfo.strBody = FacilityTemplate.Summary;
	kInfo.strConfirm = m_strAccept;
	kInfo.strImage = FacilityTemplate.strImage;
	kInfo.eColor = eUIState_Good;
	kInfo.clrAlert = MakeLinearColor(0.0, 0.75, 0.0, 1);

	kInfo = FillInShenAlertAvailable(kInfo);

	BuildAvailableAlert(kInfo);
}

simulated function BuildUpgradeAvailableAlert()
{
	local TAlertAvailableInfo kInfo;
	local X2FacilityUpgradeTemplate UpgradeTemplate;
	local X2StrategyElementTemplateManager TemplateManager;

	TemplateManager = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();

	UpgradeTemplate = X2FacilityUpgradeTemplate(TemplateManager.FindStrategyElementTemplate(
		class'X2StrategyGameRulesetDataStructures'.static.GetDynamicNameProperty(DisplayPropertySet, 'UpgradeTemplate')));

	kInfo.strTitle = m_strNewUpgradeAvailable;
	kInfo.strName = UpgradeTemplate.DisplayName;
	kInfo.strBody = UpgradeTemplate.Summary;
	kInfo.strConfirm = m_strAccept;
	kInfo.strImage = UpgradeTemplate.strImage;
	kInfo.strConfirm = m_strAccept;
	kInfo.eColor = eUIState_Good;
	kInfo.clrAlert = MakeLinearColor(0.0, 0.75, 0.0, 1);

	kInfo = FillInShenAlertAvailable(kInfo);

	BuildAvailableAlert(kInfo);
}

simulated function BuildNewStaffAvailableAlert()
{
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState;
	local XComGameState_StaffSlot StaffSlot;
	local XComGameState_HeadquartersRoom Room;
	local XComGameState_FacilityXCom Facility;
	local array<XComGameState_StaffSlot> arrStaffSlots;
	local X2SoldierClassTemplate ClassTemplate;
	local XComGameState_ResistanceFaction FactionState;
	local string StaffAvailableTitle, StaffAvailableStr, StaffBonusStr, UnitTypeIcon;
	local float BonusAmt;
	local bool bWoundRecovery;

	if( LibraryPanel == none )
	{
		`RedScreen("UI Problem with the alerts! Couldn't find LibraryPanel for current eAlertName: " $ eAlertName);
		return;
	}

	History = `XCOMHISTORY;
	UnitState = XComGameState_Unit(History.GetGameStateForObjectID(
		class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(DisplayPropertySet, 'UnitRef')));
	bWoundRecovery = class'X2StrategyGameRulesetDataStructures'.static.GetDynamicBoolProperty(DisplayPropertySet, 'WoundRecovery');
	arrStaffSlots = XCOMHQ().GetAllEmptyStaffSlotsForUnit(UnitState);

	FactionState = UnitState.GetResistanceFaction();

	// First set up the string describing the inherent bonus of the new staff member
	if (UnitState.IsScientist())
	{
		BonusAmt = (UnitState.GetSkillLevel() * 100.0) / XCOMHQ().GetScienceScore(true);
				
		StaffBonusStr = m_strNewSciAvailable;
		StaffBonusStr = Repl(StaffBonusStr, "%AVENGERBONUS", Round(BonusAmt));
		StaffAvailableTitle = m_strNewStaffAvailableTitle;

		if(bWoundRecovery)
		{
			StaffAvailableTitle = m_strStaffRecoveredTitle;
		}

		StaffAvailableStr = m_strDoctorHonorific @ UnitState.GetFullName();

		UnitTypeIcon = class'UIUtilities_Image'.const.EventQueue_Science;
	}
	else if (UnitState.IsEngineer())
	{
		BonusAmt = XCOMHQ().GetNumberOfEngineers();

		StaffBonusStr = m_strNewEngAvailable;
		StaffBonusStr = Repl(StaffBonusStr, "%AVENGERBONUS", int(BonusAmt));
		StaffAvailableTitle = m_strNewStaffAvailableTitle;

		if(bWoundRecovery)
		{
			StaffAvailableTitle = m_strStaffRecoveredTitle;
		}

		StaffAvailableStr = UnitState.GetFullName();

		UnitTypeIcon = class'UIUtilities_Image'.const.EventQueue_Engineer;
	}
	else if (UnitState.IsSoldier())
	{
		if (arrStaffSlots.Length > 0)
			StaffBonusStr = m_strNewEngAvailable; // "New staffing opportunities available!"
		else
			StaffBonusStr = m_strNewSoldierAvailable; // "Awaiting orders in the Armory!"
		StaffAvailableTitle = m_strNewSoldierAvailableTitle;
		StaffAvailableStr = UnitState.GetName(eNameType_RankFull);

		ClassTemplate = UnitState.GetSoldierClassTemplate();
		UnitTypeIcon = ClassTemplate.IconImage;
	}


	// Then, if there are staffing slots available for the new staff, detail what benefits they could provide
	if (arrStaffSlots.Length > 0)
	{
		LibraryPanel.MC.BeginFunctionOp("UpdateFacilityList");
		
		foreach arrStaffSlots(StaffSlot)
		{
			if (StaffSlot.GetFacility() == none)
			{
				Room = StaffSlot.GetRoom();
				if (Room.UnderConstruction)
				{
					Facility = XComGameState_FacilityXCom(History.GetGameStateForObjectID(class'UIUtilities_Strategy'.static.GetXComHQ().GetFacilityProject(Room.GetReference()).ProjectFocus.ObjectID));
					LibraryPanel.MC.QueueString(Facility.GetMyTemplate().DisplayName);
				}
				else
					LibraryPanel.MC.QueueString(Room.GetSpecialFeature().UnclearedDisplayName);
			}
			else
				LibraryPanel.MC.QueueString(StaffSlot.GetFacility().GetMyTemplate().DisplayName);

			LibraryPanel.MC.QueueString(StaffSlot.GetBonusDisplayString());
		}

		LibraryPanel.MC.EndOp();
	}

	if(UnitState.GetMyTemplate().strAcquiredText != "")
	{
		StaffBonusStr = UnitState.GetMyTemplate().strAcquiredText;
	}

	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateData");
	LibraryPanel.MC.QueueString(m_strAttentionCommander);
	LibraryPanel.MC.QueueString(StaffAvailableTitle);
	LibraryPanel.MC.QueueString(UnitTypeIcon);
	LibraryPanel.MC.QueueString(StaffAvailableStr);
	LibraryPanel.MC.QueueString(StaffBonusStr);	
	LibraryPanel.MC.QueueString("");
	LibraryPanel.MC.QueueString(m_strAccept);
	LibraryPanel.MC.EndOp();
	GetOrStartWaitingForStaffImage();
	//This panel has only one button, for confirm.
	Button2.DisableNavigation(); 
	Button2.Hide();

	if(FactionState != none)
		SetFactionIcon(FactionState.GetFactionIcon());

}

simulated function BuildStaffInfoAlert()
{
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState;
	local XComGameState_StaffSlot StaffSlot;
	local XComGameState_HeadquartersRoom Room;
	local XComGameState_FacilityXCom Facility;
	local array<XComGameState_StaffSlot> arrStaffSlots;
	local X2SoldierClassTemplate ClassTemplate;
	local string StaffAvailableStr, UnitTypeIcon;

	if (LibraryPanel == none)
	{
		`RedScreen("UI Problem with the alerts! Couldn't find LibraryPanel for current eAlertName: " $ eAlertName);
		return;
	}

	History = `XCOMHISTORY;
	UnitState = XComGameState_Unit(History.GetGameStateForObjectID(
		class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(DisplayPropertySet, 'UnitRef')));
	arrStaffSlots = XCOMHQ().GetAllEmptyStaffSlotsForUnit(UnitState);
	
	// First set up the string describing the inherent bonus of the new staff member
	if (UnitState.IsScientist())
	{		
		StaffAvailableStr = m_strDoctorHonorific @ UnitState.GetFullName();
		UnitTypeIcon = class'UIUtilities_Image'.const.EventQueue_Science;
	}
	else if (UnitState.IsEngineer())
	{	
		StaffAvailableStr = UnitState.GetFullName();
		UnitTypeIcon = class'UIUtilities_Image'.const.EventQueue_Engineer;
	}
	else if (UnitState.IsSoldier())
	{
		StaffAvailableStr = UnitState.GetName(eNameType_RankFull);

		ClassTemplate = UnitState.GetSoldierClassTemplate();
		UnitTypeIcon = ClassTemplate.IconImage;
	}

	// Then, if there are staffing slots available for the new staff, detail what benefits they could provide
	if (arrStaffSlots.Length > 0)
	{
		LibraryPanel.MC.BeginFunctionOp("UpdateFacilityList");

		foreach arrStaffSlots(StaffSlot)
		{
			if (StaffSlot.GetFacility() == none)
			{
				Room = StaffSlot.GetRoom();
				if (Room.UnderConstruction)
				{
					Facility = XComGameState_FacilityXCom(History.GetGameStateForObjectID(class'UIUtilities_Strategy'.static.GetXComHQ().GetFacilityProject(Room.GetReference()).ProjectFocus.ObjectID));
					LibraryPanel.MC.QueueString(Facility.GetMyTemplate().DisplayName);
				}
				else
					LibraryPanel.MC.QueueString(StaffSlot.GetRoom().GetSpecialFeature().UnclearedDisplayName);
			}
			else
				LibraryPanel.MC.QueueString(StaffSlot.GetFacility().GetMyTemplate().DisplayName);

			LibraryPanel.MC.QueueString(StaffSlot.GetBonusDisplayString());
		}

		LibraryPanel.MC.EndOp();
	}

	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateData");
	LibraryPanel.MC.QueueString(m_strAttentionCommander);
	LibraryPanel.MC.QueueString(m_strStaffInfoTitle);
	LibraryPanel.MC.QueueString(UnitTypeIcon);
	LibraryPanel.MC.QueueString(StaffAvailableStr);
	LibraryPanel.MC.QueueString(m_strStaffInfoBonus);
	LibraryPanel.MC.QueueString("");
	LibraryPanel.MC.QueueString(m_strAccept);
	LibraryPanel.MC.EndOp();
	GetOrStartWaitingForStaffImage();
	//This panel has only one button, for confirm.
	Button2.DisableNavigation(); 
	Button2.Hide();
}

simulated function BuildConstructionSlotFilledAlert()
{
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState;
	local XComGameState_StaffSlot SlotState;
	local XComGameState_HeadquartersRoom RoomState;
	local XComGameState_FacilityXCom Facility;
	local string SlotFilledStr, SlotBenefitStr, strFacilityTypeIcon;
	local bool bGhostUnit;

	bGhostUnit = class'X2StrategyGameRulesetDataStructures'.static.GetDynamicBoolProperty(DisplayPropertySet, 'bGhostUnit');

	History = `XCOMHISTORY;
	UnitState = XComGameState_Unit(History.GetGameStateForObjectID(
		class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(DisplayPropertySet, 'UnitRef')));
	RoomState = XComGameState_HeadquartersRoom(History.GetGameStateForObjectID(
		class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(DisplayPropertySet, 'RoomRef')));
	Facility = XComGameState_FacilityXCom(History.GetGameStateForObjectID(RoomState.GetBuildFacilityProject().ProjectFocus.ObjectID));

	// If the unit is a ghost, use the slot that it is located in, instead of its owning unit
	if (bGhostUnit)
		SlotState = XComGameState_StaffSlot(History.GetGameStateForObjectID(
			class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(DisplayPropertySet, 'StaffSlotRef')));
	else
		SlotState = UnitState.GetStaffSlot();

	SlotFilledStr = m_strConstructionSlotFilledLabel;
	SlotFilledStr = Repl(SlotFilledStr, "%FACILITYNAME", Caps(Facility.GetMyTemplate().DisplayName));

	// Set up the strings displaying extra info about the new staff slot's benefit
	SlotBenefitStr = m_strConstructionSlotFilled;
	SlotBenefitStr = Repl(SlotBenefitStr, "%UNITNAME", SlotState.GetNameDisplayString());
	SlotBenefitStr = Repl(SlotBenefitStr, "%AVENGERBONUS", RoomState.GetBuildSlot().GetMyTemplate().GetAvengerBonusAmountFn(UnitState));
	
	if( UnitState.IsScientist() )
	{
		strFacilityTypeIcon = class'UIUtilities_Image'.const.AlertIcon_Science;
	}
	else if( UnitState.IsEngineer() )
	{
		strFacilityTypeIcon = class'UIUtilities_Image'.const.AlertIcon_Engineering;
	}

	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateData");
	LibraryPanel.MC.QueueString(m_strStaffSlotFilledTitle);
	LibraryPanel.MC.QueueString(Caps(Facility.GetMyTemplate().DisplayName));
	LibraryPanel.MC.QueueString(strFacilityTypeIcon);
	LibraryPanel.MC.QueueString(Caps(SlotState.GetNameDisplayString()));
	LibraryPanel.MC.QueueString(SlotFilledStr);
	LibraryPanel.MC.QueueString(SlotBenefitStr);
	LibraryPanel.MC.QueueString(bGhostUnit ? "img:///FX_Avenger_DecoScreen.GremlinPortrait_Conv" : "" );
	LibraryPanel.MC.QueueString(m_strOK);
	LibraryPanel.MC.EndOp();
	
	if (!bGhostUnit)
	{
		GetOrStartWaitingForStaffImage();
	}
	//This panel has only one button, for confirm.
	Button2.DisableNavigation(); 
	Button2.Hide();
}

simulated function BuildClearRoomSlotFilledAlert()
{
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState;
	local XComGameState_StaffSlot SlotState;
	local XComGameState_HeadquartersRoom RoomState;
	local string SlotFilledStr, SlotBenefitStr, strFacilityTypeIcon;
	local bool bGhostUnit;

	bGhostUnit = class'X2StrategyGameRulesetDataStructures'.static.GetDynamicBoolProperty(DisplayPropertySet, 'bGhostUnit');

	History = `XCOMHISTORY;
	UnitState = XComGameState_Unit(History.GetGameStateForObjectID(
		class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(DisplayPropertySet, 'UnitRef')));
	RoomState = XComGameState_HeadquartersRoom(History.GetGameStateForObjectID(
		class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(DisplayPropertySet, 'RoomRef')));

	// If the unit is a ghost, use the slot that it is located in, instead of its owning unit
	if (bGhostUnit)
		SlotState = XComGameState_StaffSlot(History.GetGameStateForObjectID(
			class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(DisplayPropertySet, 'StaffSlotRef')));
	else
		SlotState = UnitState.GetStaffSlot();

	SlotFilledStr = m_strClearRoomSlotFilledLabel;
	SlotFilledStr = Repl(SlotFilledStr, "%CLEARTEXT", Caps(RoomState.GetSpecialFeature().ClearingInProgressText));

	// Set up the strings displaying extra info about the new staff slot's benefit
	SlotBenefitStr = m_strClearRoomSlotFilled;
	SlotBenefitStr = Repl(SlotBenefitStr, "%UNITNAME", SlotState.GetNameDisplayString());
	SlotBenefitStr = Repl(SlotBenefitStr, "%CLEARTEXT", RoomState.GetSpecialFeature().ClearText);
	SlotBenefitStr = Repl(SlotBenefitStr, "%AVENGERBONUS", RoomState.GetBuildSlot().GetMyTemplate().GetAvengerBonusAmountFn(UnitState));
	
	if( UnitState.IsScientist() )
	{
		strFacilityTypeIcon = class'UIUtilities_Image'.const.AlertIcon_Science;
	}
	else if( UnitState.IsEngineer() )
	{
		strFacilityTypeIcon = class'UIUtilities_Image'.const.AlertIcon_Engineering;
	}

	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateData");
	LibraryPanel.MC.QueueString(m_strStaffSlotFilledTitle);
	LibraryPanel.MC.QueueString(Caps(RoomState.GetSpecialFeature().UnclearedDisplayName));
	LibraryPanel.MC.QueueString(strFacilityTypeIcon);
	LibraryPanel.MC.QueueString(Caps(SlotState.GetNameDisplayString()));
	LibraryPanel.MC.QueueString(SlotFilledStr);
	LibraryPanel.MC.QueueString(SlotBenefitStr);
	LibraryPanel.MC.QueueString(bGhostUnit ? "img:///FX_Avenger_DecoScreen.GremlinPortrait_Conv" : "");
	LibraryPanel.MC.QueueString(m_strOK);
	LibraryPanel.MC.EndOp();

	if (!bGhostUnit)
	{
		GetOrStartWaitingForStaffImage();
	}
	//This panel has only one button, for confirm.
	Button2.DisableNavigation(); 
	Button2.Hide();
}

simulated function BuildStaffSlotFilledAlert()
{
	local XComGameStateHistory History;
	local XComGameState_FacilityXCom FacilityState;
	local XComGameState_Unit UnitState;
	local XComGameState_StaffSlot SlotState;
	local string SlotFilledStr, SlotBenefitStr, strFacilityTypeIcon;
	local bool bGhostUnit;
	local X2StaffSlotTemplate StaffSlotTemplate;

	bGhostUnit = class'X2StrategyGameRulesetDataStructures'.static.GetDynamicBoolProperty(DisplayPropertySet, 'bGhostUnit');
	History = `XCOMHISTORY;
	FacilityState = XComGameState_FacilityXCom(History.GetGameStateForObjectID(
		class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(DisplayPropertySet, 'FacilityRef')));
	UnitState = XComGameState_Unit(History.GetGameStateForObjectID(
		class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(DisplayPropertySet, 'UnitRef')));
	
	// If the unit is a ghost, use the slot that it is located in, instead of its owning unit
	if (bGhostUnit)
		SlotState = XComGameState_StaffSlot(History.GetGameStateForObjectID(
			class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(DisplayPropertySet, 'StaffSlotRef')));
	else
		SlotState = UnitState.GetStaffSlot();

	StaffSlotTemplate = SlotState.GetMyTemplate();

	SlotFilledStr = m_strStaffSlotFilledLabel;
	SlotFilledStr = Repl(SlotFilledStr, "%FACILITYNAME", Caps(FacilityState.GetMyTemplate().DisplayName));

	// Set up the strings displaying extra info about the new staff slot's benefit
	SlotBenefitStr = StaffSlotTemplate.FilledText;
	SlotBenefitStr = Repl(SlotBenefitStr, "%UNITNAME", SlotState.GetNameDisplayString());
	SlotBenefitStr = Repl(SlotBenefitStr, "%SKILL", StaffSlotTemplate.GetContributionFromSkillFn(UnitState));
	SlotBenefitStr = Repl(SlotBenefitStr, "%AVENGERBONUS", StaffSlotTemplate.GetAvengerBonusAmountFn(UnitState));

	if( UnitState.IsScientist() )
	{
		strFacilityTypeIcon = class'UIUtilities_Image'.const.AlertIcon_Science;
	}
	else if( UnitState.IsEngineer() )
	{
		strFacilityTypeIcon = class'UIUtilities_Image'.const.AlertIcon_Engineering;
	}

	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateData");
	LibraryPanel.MC.QueueString(m_strStaffSlotFilledTitle);
	LibraryPanel.MC.QueueString(Caps(FacilityState.GetMyTemplate().DisplayName));
	LibraryPanel.MC.QueueString(strFacilityTypeIcon);
	LibraryPanel.MC.QueueString(Caps(SlotState.GetNameDisplayString()));
	LibraryPanel.MC.QueueString(SlotState.GetBonusDisplayString());
	LibraryPanel.MC.QueueString(SlotBenefitStr);
	LibraryPanel.MC.QueueString(bGhostUnit ? "img:///FX_Avenger_DecoScreen.GremlinPortrait_Conv" : "");

	LibraryPanel.MC.QueueString(m_strOK);
	LibraryPanel.MC.EndOp();

	if (!bGhostUnit)
	{
		GetOrStartWaitingForStaffImage();
	}

	//This panel has only one button, for confirm.
	Button2.DisableNavigation(); 
	Button2.Hide();
}

simulated function string GetOrStartWaitingForStaffImage()
{
	local StateObjectReference UnitRef;

	UnitRef.ObjectID = class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(DisplayPropertySet, 'UnitRef');

	if (UnitRef.ObjectID != 0)
	{
		`HQPRES.GetPhotoboothAutoGen().AddHeadShotRequest(UnitRef, 512, 512, UpdateAlertImage);
		`HQPRES.GetPhotoboothAutoGen().RequestPhotos();
	}

	return "";
}


simulated function UpdateAlertImage(StateObjectReference UnitRef)
{
	local XComGameState_CampaignSettings SettingsState;

	SettingsState = XComGameState_CampaignSettings(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings'));
	StaffPicture = `XENGINE.m_kPhotoManager.GetHeadshotTexture(SettingsState.GameIndex, UnitRef.ObjectID, 512, 512);

	LibraryPanel.MC.BeginFunctionOp("UpdateImage");
	LibraryPanel.MC.QueueString(class'UIUtilities_Image'.static.ValidateImagePath(PathName(StaffPicture)));
	LibraryPanel.MC.EndOp();
}

simulated function BuildSuperSoldierAlert()
{
	local XComGameState_Unit UnitState;

	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(
		class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(DisplayPropertySet, 'UnitRef')));

	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateData");
	LibraryPanel.MC.QueueString(m_strSoldierShakenHeader); //ATTENTION
	LibraryPanel.MC.QueueString(class'XComOnlineEventMgr'.default.m_sXComHeroSummonTitle); //SOLDIER SHAKEN 
	LibraryPanel.MC.QueueString(UnitState.GetSoldierClassTemplate() != none ? UnitState.GetSoldierClassTemplate().IconImage : ""); //ICON
	LibraryPanel.MC.QueueString(Caps(UnitState.GetName(eNameType_FullNick))); //STAFF AVAILABLE STRING
	LibraryPanel.MC.QueueString(""); //STAFF BONUS STRING
	LibraryPanel.MC.QueueString(class'XComOnlineEventMgr'.default.m_sXComHeroSummonText); //STAFF BENEFIT STRING
	LibraryPanel.MC.QueueString(""); //IMAGE (UPDATED IN PRESENTATION LAYER)
	LibraryPanel.MC.QueueString(class'UIDialogueBox'.default.m_strDefaultAcceptLabel); //OK
	LibraryPanel.MC.QueueString(class'UIDialogueBox'.default.m_strDefaultCancelLabel); //CANCEL
	LibraryPanel.MC.EndOp();

	LibraryPanel.MC.FunctionString("UpdateImage", class'X2StrategyGameRulesetDataStructures'.static.GetDynamicStringProperty(DisplayPropertySet, 'StaffPicture'));
}

simulated function BuildNegativeTraitAcquiredAlert()
{
	local XComGameState_Unit UnitState;
	local X2TraitTemplate NegativeTrait;
	local XGBaseCrewMgr CrewMgr;
	local XComGameState_HeadquartersRoom RoomState;
	local Vector ForceLocation;
	local Rotator ForceRotation;
	local XComUnitPawn UnitPawn;
	local X2SoldierClassTemplate ClassTemplate;
	local X2EventListenerTemplateManager EventTemplateManager;
	local string TraitDesc, ClassIcon, ClassName, RankName;
	
	if (LibraryPanel == none)
	{
		`RedScreen("UI Problem with the alerts! Couldn't find LibraryPanel for current eAlertName: " $ eAlertName);
		return;
	}

	EventTemplateManager = class'X2EventListenerTemplateManager'.static.GetEventListenerTemplateManager();

	NegativeTrait = X2TraitTemplate(EventTemplateManager.FindEventListenerTemplate(
		class'X2StrategyGameRulesetDataStructures'.static.GetDynamicNameProperty(DisplayPropertySet, 'PrimaryTraitTemplate')));

	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(
		class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(DisplayPropertySet, 'UnitRef')));
	ClassTemplate = UnitState.GetSoldierClassTemplate();
	
	if (UnitState.GetRank() > 0)
	{
		ClassName = Caps(ClassTemplate.DisplayName);
	}
	else
	{
		ClassName = "";
	}

	ClassIcon = ClassTemplate.IconImage;
	RankName = Caps(class'X2ExperienceConfig'.static.GetRankName(UnitState.GetRank(), ClassTemplate.DataName));

	TraitDesc = NegativeTrait.TraitDescription;
	if (NegativeTrait.TraitQuotes.Length > 0)
	{
		TraitDesc $= "\n\n" $ NegativeTrait.TraitQuotes[`SYNC_RAND(NegativeTrait.TraitQuotes.Length)];
	}

	// Move the camera
	CrewMgr = `GAME.GetGeoscape().m_kBase.m_kCrewMgr;
	RoomState = CrewMgr.GetRoomFromUnit(UnitState.GetReference());
	UnitPawn = CrewMgr.GetPawnForUnit(UnitState.GetReference());

	if(RoomState != none && UnitPawn != none)
	{
		ForceLocation = UnitPawn.GetHeadLocation();
		ForceLocation.X += 50;
		ForceLocation.Y -= 300;
		ForceRotation.Yaw = 16384;
		`HQPRES.CAMLookAtRoom(RoomState, `HQINTERPTIME, ForceLocation, ForceRotation);
	}

	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateData");
	LibraryPanel.MC.QueueString(m_strNegativeTraitAcquiredTitle);
	LibraryPanel.MC.QueueString("");
	LibraryPanel.MC.QueueString(ClassIcon);
	LibraryPanel.MC.QueueString(RankName);
	LibraryPanel.MC.QueueString(UnitState.GetName(eNameType_FullNick));
	LibraryPanel.MC.QueueString(ClassName);
	LibraryPanel.MC.QueueString(NegativeTrait.IconImage); // Ability Icon
	LibraryPanel.MC.QueueString(NegativeTrait.TraitFriendlyName); // Ability Label
	LibraryPanel.MC.QueueString(NegativeTrait.TraitScientificName); // Ability Name
	LibraryPanel.MC.QueueString(TraitDesc); // Ability Description
	LibraryPanel.MC.QueueString("");
	LibraryPanel.MC.QueueString(m_strOk);
	LibraryPanel.MC.EndOp();
	GetOrStartWaitingForStaffImage();
	// Always hide the "Continue" button, since this is just an informational popup
	Button2.SetGamepadIcon(class'UIUtilities_Input'.static.GetAdvanceButtonIcon()); //bsg-hlee (05.09.17): Changing the icon to A.
	Button1.Hide(); 
	Button1.DisableNavigation();
}

simulated function BuildPositiveTraitAcquiredAlert()
{
	local XComGameState_Unit UnitState;
	local X2TraitTemplate PositiveTrait, NegativeTrait;
	local X2EventListenerTemplateManager EventTemplateManager;

	EventTemplateManager = class'X2EventListenerTemplateManager'.static.GetEventListenerTemplateManager();

	PositiveTrait = X2TraitTemplate(EventTemplateManager.FindEventListenerTemplate(
		class'X2StrategyGameRulesetDataStructures'.static.GetDynamicNameProperty(DisplayPropertySet, 'PrimaryTraitTemplate')));
	NegativeTrait = X2TraitTemplate(EventTemplateManager.FindEventListenerTemplate(
		class'X2StrategyGameRulesetDataStructures'.static.GetDynamicNameProperty(DisplayPropertySet, 'SecondaryTraitTemplate')));

	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(
		class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(DisplayPropertySet, 'UnitRef')));

	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateData");
	LibraryPanel.MC.QueueString(m_strSoldierShakenHeader); //ATTENTION
	LibraryPanel.MC.QueueString(m_strPositiveTraitAcquiredTitle);
	LibraryPanel.MC.QueueString(""); //ICON
	LibraryPanel.MC.QueueString(Caps(UnitState.GetName(eNameType_FullNick))); //STAFF AVAILABLE STRING
	LibraryPanel.MC.QueueString("Positive Trait '" $ PositiveTrait.TraitFriendlyName $ "' acquired, replacing '" $ NegativeTrait.TraitFriendlyName $ "'."); //TODO: localize me
	LibraryPanel.MC.QueueString(PositiveTrait.TraitDescription); //TODO: localize me
	LibraryPanel.MC.QueueString("");
	LibraryPanel.MC.QueueString(m_strOK); //OK
	LibraryPanel.MC.EndOp();
	GetOrStartWaitingForStaffImage();
	//This panel has only one button, for confirm.
	Button2.DisableNavigation(); 
	Button2.Hide();
}

simulated function BuildSoldierShakenAlert()
{
	local XComGameState_Unit UnitState;

	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(
		class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(DisplayPropertySet, 'UnitRef')));

	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateData");
	LibraryPanel.MC.QueueString(m_strSoldierShakenHeader); //ATTENTION
	LibraryPanel.MC.QueueString(m_strSoldierShakenTitle); //SOLDIER SHAKEN 
	LibraryPanel.MC.QueueString(""); //ICON
	LibraryPanel.MC.QueueString(Caps(UnitState.GetName(eNameType_FullNick))); //STAFF AVAILABLE STRING
	LibraryPanel.MC.QueueString(m_strSoldierShaken); //STAFF BONUS STRING
	LibraryPanel.MC.QueueString(m_strSoldierShakenHelp); //STAFF BENEFIT STRING
	LibraryPanel.MC.QueueString("");
	LibraryPanel.MC.QueueString(m_strOK); //OK
	LibraryPanel.MC.EndOp();
	GetOrStartWaitingForStaffImage();
	//This panel has only one button, for confirm.
	Button2.DisableNavigation(); 
	Button2.Hide();
}

simulated function BuildSoldierShakenRecoveredAlert()
{
	local XComGameState_Unit UnitState;

	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(
		class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(DisplayPropertySet, 'UnitRef')));

	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateData");
	LibraryPanel.MC.QueueString(m_strSoldierShakenHeader); //ATTENTION
	LibraryPanel.MC.QueueString(m_strSoldierShakenRecoveredTitle); //SOLDIER RECOVERED FROM SHAKEN 
	LibraryPanel.MC.QueueString(""); //ICON
	LibraryPanel.MC.QueueString(Caps(UnitState.GetName(eNameType_FullNick))); //STAFF AVAILABLE STRING
	LibraryPanel.MC.QueueString(m_strSoldierShakenRecovered); //STAFF BONUS STRING
	LibraryPanel.MC.QueueString(m_strSoldierShakenRecoveredHelp); //STAFF BENEFIT STRING
	LibraryPanel.MC.QueueString("");
	LibraryPanel.MC.QueueString(m_strOK); //OK
	LibraryPanel.MC.EndOp();
	GetOrStartWaitingForStaffImage();
	//This panel has only one button, for confirm.
	Button2.DisableNavigation(); 
	Button2.Hide();
}

simulated function BuildWeaponUpgradesAvailableAlert()
{
	local TAlertAvailableInfo kInfo;

	kInfo.strTitle = m_strWeaponUpgradesAvailableTitle;
	kInfo.strName = "";
	kInfo.strBody = m_strWeaponUpgradesAvailableBody;
	kInfo.strConfirm = m_strAccept;
	kInfo.strImage = "img:///UILibrary_StrategyImages.ResearchTech.TECH_Modular_Weapons";
	kInfo.strConfirm = m_strAccept;
	kInfo.eColor = eUIState_Good;
	kInfo.clrAlert = MakeLinearColor(0.0, 0.75, 0.0, 1);

	kInfo = FillInShenAlertAvailable(kInfo);

	BuildAvailableAlert(kInfo);
}

simulated function BuildSoldierCustomizationsAvailableAlert()
{
	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateData");
	LibraryPanel.MC.QueueString(m_strSoldierShakenHeader); // Header (ATTENTION)
	LibraryPanel.MC.QueueString(m_strNewCustomizationsAvailableTitle); // Title
	LibraryPanel.MC.QueueString(m_strNewCustomizationsAvailableBody); // Body
	LibraryPanel.MC.QueueString(""); // Button 0
	LibraryPanel.MC.QueueString(m_strOK); // Button 1
	LibraryPanel.MC.EndOp();

	Button2.SetGamepadIcon(class'UIUtilities_Input'.static.GetAdvanceButtonIcon());
	Button1.Hide(); 
	Button1.DisableNavigation();
}

simulated function BuildForceUnderstrengthAlert()
{
	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateData");
	LibraryPanel.MC.QueueString(m_strSoldierShakenHeader); // Header (ATTENTION)
	LibraryPanel.MC.QueueString(m_strForceUnderstrengthTitle); // Title
	LibraryPanel.MC.QueueString(m_strForceUnderstrengthBody); // Body
	LibraryPanel.MC.QueueString(""); // Button 0
	LibraryPanel.MC.QueueString(m_strOK); // Button 1
	LibraryPanel.MC.EndOp();

	Button2.SetGamepadIcon(class'UIUtilities_Input'.static.GetAdvanceButtonIcon());
	Button1.Hide(); 
	Button1.DisableNavigation();
}

simulated function BuildWoundedSoldiersAllowedAlert()
{
	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateData");
	LibraryPanel.MC.QueueString(m_strSoldierShakenHeader); // Header (ATTENTION)
	LibraryPanel.MC.QueueString(m_strWoundedSoldiersAllowedTitle); // Title
	LibraryPanel.MC.QueueString(m_strWoundedSoldiersAllowedBody); // Body
	LibraryPanel.MC.QueueString(""); // Button 0
	LibraryPanel.MC.QueueString(m_strOK); // Button 1
	LibraryPanel.MC.EndOp();
	Button2.SetGamepadIcon(class'UIUtilities_Input'.static.GetAdvanceButtonIcon());

	Button1.Hide(); 
	Button1.DisableNavigation();
}

simulated function BuildStrongholdMissionWarningAlert()
{
	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateData");
	LibraryPanel.MC.QueueString(m_strSoldierShakenHeader); // Header (ATTENTION)
	LibraryPanel.MC.QueueString(m_strStrongholdMissionWarningTitle); // Title
	LibraryPanel.MC.QueueString(m_strStrongholdMissionWarningBody); // Body
	LibraryPanel.MC.QueueString(""); // Button 0
	LibraryPanel.MC.QueueString(m_strOK); // Button 1
	LibraryPanel.MC.EndOp();
	Button2.SetGamepadIcon(class'UIUtilities_Input'.static.GetAdvanceButtonIcon());

	Button1.Hide();
	Button1.DisableNavigation();
}

simulated function TAlertAvailableInfo FillInShenAlertAvailable(TAlertAvailableInfo kInfo)
{
	kInfo.strHeadImage1 = "img:///UILibrary_Common.Head_Shen";
	kInfo.Staff1ID = class'UIUtilities_Strategy'.static.GetXComHQ().GetHeadEngineerRef();
	kInfo.strStaff1Title = class'UIUtilities_Strategy'.default.m_arrStaffTypes[eStaff_HeadEngineer];
	kInfo.strHeaderIcon = class'UIUtilities_Image'.const.AlertIcon_Engineering_Black;

	return kInfo;
}

simulated function TAlertAvailableInfo FillInTyganAlertAvailable(TAlertAvailableInfo kInfo)
{
	kInfo.strHeadImage1 = "img:///UILibrary_Common.Head_Tygan";
	kInfo.Staff1ID = class'UIUtilities_Strategy'.static.GetXComHQ().GetHeadScientistRef();
	kInfo.strStaff1Title = class'UIUtilities_Strategy'.default.m_arrStaffTypes[eStaff_HeadScientist];
	kInfo.strHeaderIcon = class'UIUtilities_Image'.const.AlertIcon_Science_Black;

	return kInfo;
}

simulated function BuildAvailableAlert(TAlertAvailableInfo kInfo)
{
	local string UnitName;
	local XComGameState_Unit Staff;

	Staff = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(kInfo.Staff1ID));
	
	if( LibraryPanel == none )
	{
		`RedScreen("UI Problem with the alerts! Couldn't find LibraryPanel for current eAlertName: " $ eAlertName);
		return;
	}

	if(Staff.IsSoldier())
		UnitName = Staff.GetName(eNameType_RankFull);
	else
		UnitName = Staff.GetName(eNameType_Full);

	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateData");
	LibraryPanel.MC.QueueString(kInfo.strTitle);
	LibraryPanel.MC.QueueString(kInfo.strName);
	LibraryPanel.MC.QueueString(kInfo.strBody);
	LibraryPanel.MC.QueueString(kInfo.strStaff1Title);
	LibraryPanel.MC.QueueString(UnitName);
	LibraryPanel.MC.QueueString(kInfo.strImage);
	LibraryPanel.MC.QueueString(kInfo.strHeadImage1);
	LibraryPanel.MC.QueueString(kInfo.strConfirm);
	LibraryPanel.MC.QueueString(""); //Optional second button param that we don't currently use, but may in the future.
	LibraryPanel.MC.EndOp();

	//Since we aren't using it yet: 
	Button2.DisableNavigation(); 
	Button2.Hide();
}

simulated function BuildDarkEventAlert()
{
	local XComGameStateHistory History;
	local XComGameState_DarkEvent DarkEventState;

	History = `XCOMHISTORY;
	DarkEventState = XComGameState_DarkEvent(History.GetGameStateForObjectID(
		class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(DisplayPropertySet, 'DarkEventRef')));

	if( LibraryPanel == none )
	{
		`RedScreen("UI Problem with the alerts! Couldn't find LibraryPanel for current eAlertName: " $ eAlertName);
		return;
	}

	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateData");
	LibraryPanel.MC.QueueString(m_strDarkEventLabel);
	LibraryPanel.MC.QueueString(DarkEventState.GetDisplayName());
	LibraryPanel.MC.QueueString(DarkEventState.GetSummary());
	LibraryPanel.MC.QueueString(DarkEventState.GetQuote());
	LibraryPanel.MC.QueueString(DarkEventState.GetQuoteAuthor());
	LibraryPanel.MC.QueueString(DarkEventState.GetImage());
	LibraryPanel.MC.QueueString(m_strOK);
	LibraryPanel.MC.EndOp();

	Button2.DisableNavigation(); 
	Button2.Hide();

}

simulated function BuildMissionExpiredAlert()
{
	local XGParamTag ParamTag;
	local X2MissionSourceTemplate MissionSource;
	local String ExpiredStr;
	local XComGameStateHistory History;
	local XComGameState_MissionSite MissionState;

	History = `XCOMHISTORY;
		MissionState = XComGameState_MissionSite(History.GetGameStateForObjectID(
			class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(DisplayPropertySet, 'MissionRef')));

	ParamTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	ParamTag.StrValue0 = MissionState.GetWorldRegion().GetMyTemplate().DisplayName;

	MissionSource = MissionState.GetMissionSource();
	
	ExpiredStr = MissionSource.MissionExpiredText;
	if (MissionSource.bDisconnectRegionOnFail && !MissionState.GetWorldRegion().IsStartingRegion())
	{
		ExpiredStr @= m_strMissionExpiredLostContact;
	}
	ExpiredStr = `XEXPAND.ExpandString(ExpiredStr);

	BuildAlienSplashAlert(m_strMissionExpiredLabel, MissionSource.MissionPinLabel, ExpiredStr, m_strMissionExpiredImage, m_strOK, "");
	
	//Unused in this alert. 
	Button2.DisableNavigation(); 
	Button2.Hide();
}

simulated function BuildTimeSensitiveMissionAlert()
{
	local XGParamTag ParamTag;
	local X2MissionSourceTemplate MissionSource;
	local XComGameStateHistory History;
	local XComGameState_MissionSite MissionState;

	History = `XCOMHISTORY;
		MissionState = XComGameState_MissionSite(History.GetGameStateForObjectID(
			class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(DisplayPropertySet, 'MissionRef')));
	
	ParamTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	ParamTag.StrValue0 = MissionState.GetWorldRegion().GetMyTemplate().DisplayName;

	MissionSource = MissionState.GetMissionSource();
	
	BuildAlienSplashAlert(m_strTimeSensitiveMissionLabel, MissionSource.MissionPinLabel, `XEXPAND.ExpandString(m_strTimeSensitiveMissionText), m_strTimeSensitiveMissionImage, m_strFlyToMission, m_strSkipTimeSensitiveMission);
}

simulated function BuildAlienVictoryImminentAlert()
{
	BuildAlienSplashAlert("", m_strAlienVictoryImminentTitle, m_strAlienVictoryImminentBody, m_strTimeSensitiveMissionImage, m_strOK, "");
}

simulated function BuildTheRingAlert()
{
	local TAlertHelpInfo Info;
	local string BuildRingBody;
	local int idx;

	BuildRingBody = m_strBuildRingDescription $ "\n\n" $ m_strBuildRingBody;
	for (idx = 0; idx < m_strBuildRingList.Length; idx++)
	{
		BuildRingBody $= "\n -" @ m_strBuildRingList[idx];
	}

	Info.strTitle = m_strBuildRingTitle;
	Info.strHeader = m_strBuildRingHeader;
	Info.strDescription = BuildRingBody;
	Info.strImage = m_strBuildRingImage;
	Info.strConfirm = m_strOK;

	BuildHelpAlert(Info);
	
	//bsg-crobinson (5.23.17): Realign buttons
	Button1.OnSizeRealized = OnRingButtonRealized;
	Button2.OnSizeRealized = OnRingButtonRealized;
	//bsg-crobinson (5.23.17): end

	`HQPRES.m_kAvengerHUD.NavHelp.ClearButtonHelp();
}

//bsg-crobinson (5.23.17): Function to realize the buttons for ring alert
simulated function OnRingButtonRealized()
{
	Button1.SetX((-Button1.Width / 2.0) - 75);
	Button2.SetX((-Button1.Width / 2.0) - 75);
}
//bsg-crobinson (5.23.17): end

simulated function BuildLowIntelAlert()
{
	local TAlertHelpInfo Info;
	local string LowIntelBody;
	local int idx;

	LowIntelBody = m_strLowIntelDescription $ "\n\n" $ m_strLowIntelBody;
	for (idx = 0; idx < m_strLowIntelList.Length; idx++)
	{
		LowIntelBody $= "\n -" @ m_strLowIntelList[idx];
	}

	Info.strTitle = m_strLowIntelTitle;
	Info.strHeader = m_strLowIntelHeader;
	Info.strDescription = LowIntelBody;
	Info.strImage = m_strLowIntelImage;		
	Info.strCarryOn = m_strOK;

	BuildHelpAlert(Info);
	Button2.SetGamepadIcon(class'UIUtilities_Input'.static.GetAdvanceButtonIcon());
}

simulated function BuildLowSuppliesAlert()
{
	local TAlertHelpInfo Info;
	local string LowSuppliesBody;
	local int idx;

	LowSuppliesBody = m_strLowSuppliesDescription $ "\n\n" $ m_strLowSuppliesBody;
	for (idx = 0; idx < m_strLowSuppliesList.Length; idx++)
	{
		LowSuppliesBody $= "\n -" @ m_strLowSuppliesList[idx];
	}

	Info.strTitle = m_strLowSuppliesTitle;
	Info.strHeader = m_strLowSuppliesHeader;
	Info.strDescription = LowSuppliesBody;
	Info.strImage = m_strLowSuppliesImage;
	//Info.strCarryOn = m_strOK;
	Info.strConfirm = m_strOK;

	BuildHelpAlert(Info);
}

simulated function BuildLowScientistsAlert()
{
	local TAlertHelpInfo Info;
	local string LowScientistsBody;
	local int idx;

	LowScientistsBody = m_strLowScientistsDescription $ "\n\n" $ m_strLowScientistsBody;
	for (idx = 0; idx < m_strLowScientistsList.Length; idx++)
	{
		LowScientistsBody $= "\n -" @ m_strLowScientistsList[idx];
	}

	Info.strTitle = m_strLowScientistsTitle;
	Info.strHeader = m_strLowScientistsHeader;
	Info.strDescription = LowScientistsBody;
	Info.strImage = m_strLowScientistsImage;
	Info.strConfirm = m_strOK; //bsg-jneal (7.14.16): alert prompt uses A/X to close

	BuildHelpAlert(Info);
}

simulated function BuildLowEngineersAlert()
{
	local TAlertHelpInfo Info;
	local string LowEngineersBody;
	local int idx;

	LowEngineersBody = m_strLowEngineersDescription $ "\n\n" $ m_strLowEngineersBody;
	for (idx = 0; idx < m_strLowEngineersList.Length; idx++)
	{
		LowEngineersBody $= "\n -" @ m_strLowEngineersList[idx];
	}

	Info.strTitle = m_strLowEngineersTitle;
	Info.strHeader = m_strLowEngineersHeader;
	Info.strDescription = LowEngineersBody;
	Info.strImage = m_strLowEngineersImage;

	Info.strConfirm = m_strOK;

	BuildHelpAlert(Info);
}

simulated function BuildLowScientistsSmallAlert()
{
	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateData");
	LibraryPanel.MC.QueueString(m_strSoldierShakenHeader); // Header (ATTENTION)
	LibraryPanel.MC.QueueString(m_strLowScientistsSmallTitle); // Title
	LibraryPanel.MC.QueueString(m_strLowScientistsSmallBody); // Body
	LibraryPanel.MC.QueueString(m_strTellMeMore); // Button 0
	LibraryPanel.MC.QueueString(m_strOK); // Button 1
	LibraryPanel.MC.EndOp();
}

simulated function BuildLowEngineersSmallAlert()
{
	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateData");
	LibraryPanel.MC.QueueString(m_strSoldierShakenHeader); // Header (ATTENTION)
	LibraryPanel.MC.QueueString(m_strLowEngineersSmallTitle); // Title
	LibraryPanel.MC.QueueString(m_strLowEngineersSmallBody); // Body
	LibraryPanel.MC.QueueString(m_strTellMeMore); // Button 0
	LibraryPanel.MC.QueueString(m_strOK); // Button 1
	LibraryPanel.MC.EndOp();
}

simulated function BuildSupplyDropReminderAlert()
{
	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateData");
	LibraryPanel.MC.QueueString(m_strSoldierShakenHeader); // Header (ATTENTION)
	LibraryPanel.MC.QueueString(m_strSupplyDropReminderTitle); // Title
	LibraryPanel.MC.QueueString(m_strSupplyDropReminderBody); // Body
	LibraryPanel.MC.QueueString(""); // Button 0
	LibraryPanel.MC.QueueString(m_strOK); // Button 1
	LibraryPanel.MC.EndOp();

	Button1.Hide(); 
	Button1.DisableNavigation();
	Button2.SetGamepadIcon(class'UIUtilities_Input'.static.GetAdvanceButtonIcon());
}

simulated function BuildPowerCoilShieldedAlert()
{
	local string PowerCoilShieldedBody;
	local int idx;

	PowerCoilShieldedBody = m_strPowerCoilShieldedBody;
	for (idx = 0; idx < m_strPowerCoilShieldedList.Length; idx++)
	{
		PowerCoilShieldedBody $= "\n -" @ m_strPowerCoilShieldedList[idx];
	}

	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateData");
	LibraryPanel.MC.QueueString(m_strSoldierShakenHeader); // Header (ATTENTION)
	LibraryPanel.MC.QueueString(m_strPowerCoilShieldedTitle); // Title
	LibraryPanel.MC.QueueString(PowerCoilShieldedBody); // Body
	LibraryPanel.MC.QueueString(""); // Button 0
	LibraryPanel.MC.QueueString(m_strOK); // Button 1
	LibraryPanel.MC.EndOp();

	Button1.Hide(); 
	Button1.DisableNavigation();
	Button2.SetGamepadIcon(class'UIUtilities_Input'.static.GetAdvanceButtonIcon());
}

simulated function BuildLaunchMissionWarningAlert()
{
	local XComGameStateHistory History;
	local XComGameState_MissionSite MissionState;

	History = `XCOMHISTORY;
		MissionState = XComGameState_MissionSite(History.GetGameStateForObjectID(
			class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(DisplayPropertySet, 'MissionRef')));

	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateData");
	LibraryPanel.MC.QueueString(m_strLaunchMissionWarningHeader); // Header (ATTENTION)
	LibraryPanel.MC.QueueString(m_strLaunchMissionWarningTitle); // Title
	LibraryPanel.MC.QueueString(MissionState.GetMissionSource().MissionLaunchWarningText); // Body
	LibraryPanel.MC.QueueString(""); // Button 0
	LibraryPanel.MC.QueueString(m_strOK); // Button 1
	LibraryPanel.MC.EndOp();

	Button1.Hide(); 
	Button1.DisableNavigation();
}

simulated function BuildCovertActionsAlert()
{
	// Save camera
	XComHQPresentationLayer(Movie.Pres).CAMSaveCurrentLocation();
	bAlertTransitionsToMission = true;

	if (LibraryPanel == none)
	{
		`RedScreen("UI Problem with the alerts! Couldn't find LibraryPanel for current eAlertName: " $ eAlertName);
		return;
	}

	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateCouncilSplashData");
	LibraryPanel.MC.QueueString(m_strCovertActionsTitle);
	LibraryPanel.MC.QueueString(m_strCovertActionsLabel);
	LibraryPanel.MC.QueueString(m_strCovertActionsBody);
	LibraryPanel.MC.QueueString(m_strCovertActionsFlare);
	LibraryPanel.MC.QueueString(m_strCovertActionsConfirm);
	LibraryPanel.MC.QueueString(m_strIgnore);
	LibraryPanel.MC.EndOp();
}

simulated function BuildLostAndAbandonedAlert()
{
	local XComGameStateHistory History;
	local XComGameState_ResistanceFaction FactionState;
	local XGParamTag ParamTag;

	// Save camera
	XComHQPresentationLayer(Movie.Pres).CAMSaveCurrentLocation();
	bAlertTransitionsToMission = true;

	if (LibraryPanel == none)
	{
		`RedScreen("UI Problem with the alerts! Couldn't find LibraryPanel for current eAlertName: " $ eAlertName);
		return;
	}
	
	History = `XCOMHISTORY;
	FactionState = XComGameState_ResistanceFaction(History.GetGameStateForObjectID(
		class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(DisplayPropertySet, 'FactionRef')));

	ParamTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	ParamTag.StrValue0 = FactionState.GetFactionTitle();
	ParamTag.StrValue1 = FactionState.GetFactionName();

	SetFactionIcon(FactionState.GetFactionIcon());

	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateMissionSplashData");
	LibraryPanel.MC.QueueString(Caps(`XEXPAND.ExpandString(m_strLostAndAbandonedTitle))); // Title
	LibraryPanel.MC.QueueString(`XEXPAND.ExpandString(m_strLostAndAbandonedBody)); // Description
	LibraryPanel.MC.QueueString(""); // Faction Logo
	LibraryPanel.MC.QueueString(FactionState.GetFactionTitle()); // Faction Label
	LibraryPanel.MC.QueueString(FactionState.GetFactionName()); // Faction Name
	LibraryPanel.MC.QueueString(FactionState.GetLeaderImage());
	LibraryPanel.MC.QueueString(m_strLostAndAbandonedConfirm);
	LibraryPanel.MC.QueueString(m_strIgnore);
	LibraryPanel.MC.EndOp();

	Button2.DisableNavigation(); 
	Button2.Hide(); // Do not allow the player to skip L&A
}

simulated function BuildResistanceOpAlert()
{
	local XComGameStateHistory History;
	local XComGameState_ResistanceFaction FactionState;
	local XGParamTag ParamTag;

	// Save camera
	XComHQPresentationLayer(Movie.Pres).CAMSaveCurrentLocation();
	bAlertTransitionsToMission = true;

	if (LibraryPanel == none)
	{
		`RedScreen("UI Problem with the alerts! Couldn't find LibraryPanel for current eAlertName: " $ eAlertName);
		return;
	}

	History = `XCOMHISTORY;
	FactionState = XComGameState_ResistanceFaction(History.GetGameStateForObjectID(
		class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(DisplayPropertySet, 'FactionRef')));
	
	ParamTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	ParamTag.StrValue0 = FactionState.GetFactionTitle();
	ParamTag.StrValue1 = FactionState.GetFactionName();
	
	SetFactionIcon(FactionState.GetFactionIcon());

	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateMissionSplashData");
	LibraryPanel.MC.QueueString(Caps(`XEXPAND.ExpandString(m_strResistanceOpTitle))); // Title
	LibraryPanel.MC.QueueString(`XEXPAND.ExpandString(m_strResistanceOpBody)); // Description
	LibraryPanel.MC.QueueString(""); // Faction Logo
	LibraryPanel.MC.QueueString(FactionState.GetFactionTitle()); // Faction Label
	LibraryPanel.MC.QueueString(FactionState.GetFactionName()); // Faction Name
	LibraryPanel.MC.QueueString(FactionState.GetLeaderImage());
	LibraryPanel.MC.QueueString(m_strResistanceOpConfirm);
	LibraryPanel.MC.QueueString(m_strIgnore);
	LibraryPanel.MC.EndOp();
}

// XPack Chosen Alerts
function BuildChosenSplashAlert(String strHeader, String strChosenType, String strChosenName, String strChosenNickname, String strDescription, String strImage, String strButton1Label, String strButton2Label)
{
	if (LibraryPanel == none)
	{
		`RedScreen("UI Problem with the alerts! Couldn't find LibraryPanel for current eAlertName: " $ eAlertName);
		return;
	}

	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateChosenSplash");
	LibraryPanel.MC.QueueString(strHeader);
	LibraryPanel.MC.QueueString(strChosenType);
	LibraryPanel.MC.QueueString(strChosenName);
	LibraryPanel.MC.QueueString(strChosenNickname);
	LibraryPanel.MC.QueueString(strDescription);
	LibraryPanel.MC.QueueString(strImage);
	LibraryPanel.MC.QueueString(strButton1Label);
	LibraryPanel.MC.QueueString(strButton2Label);
	LibraryPanel.MC.EndOp();

	if (strButton2Label == "")
	{
		Button2.DisableNavigation(); 
		Button2.Hide();
	}
}

function BuildChosenIcon(StackedUIIconData IconInfo)
{
	local int i;

	LibraryPanel.MC.BeginFunctionOp("UpdateChosenIcon");
	LibraryPanel.MC.QueueBoolean(IconInfo.bInvert);
	for (i = 0; i < IconInfo.Images.Length; i++)
	{
		LibraryPanel.MC.QueueString("img:///" $ IconInfo.Images[i]);
	}

	LibraryPanel.MC.EndOp();
}

simulated function BuildChosenAmbushAlert()
{
	local XComGameState_ResistanceFaction FactionState;
	local XComGameState_AdventChosen ChosenState;
	local String strChosenType, strChosenName, strChosenNickname;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;
	FactionState = XComGameState_ResistanceFaction(History.GetGameStateForObjectID(
		class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(DisplayPropertySet, 'FactionRef')));

	if (FactionState != None)
	{
		ChosenState = FactionState.GetRivalChosen();
		strChosenType = ChosenState.GetChosenClassName();
		strChosenName = ChosenState.GetChosenName();
		strChosenNickname = ChosenState.GetChosenNickname();
	}

	// Save camera
	XComHQPresentationLayer(Movie.Pres).CAMSaveCurrentLocation();
	bAlertTransitionsToMission = true;

	if (LibraryPanel == none)
	{
		`RedScreen("UI Problem with the alerts! Couldn't find LibraryPanel for current eAlertName: " $ eAlertName);
		return;
	}
	
	BuildChosenSplashAlert(m_strChosenAmbushTitle, strChosenType, strChosenName, strChosenNickname, class'UIUtilities_Text'.static.GetColoredText(m_strChosenAmbushBody, eUIState_Header), 
						   m_strChosenAmbushImage, m_strChosenAmbushConfirm, "");

	BuildChosenIcon(ChosenState.GetChosenIcon());
}

simulated function BuildChosenStrongholdAlert()
{
	local XComGameState_ResistanceFaction FactionState;
	local XComGameState_AdventChosen ChosenState;
	local String strChosenType, strChosenName, strChosenNickname;
	local XComGameStateHistory History;
	
	History = `XCOMHISTORY;
	FactionState = XComGameState_ResistanceFaction(History.GetGameStateForObjectID(
		class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(DisplayPropertySet, 'FactionRef')));

	if (FactionState != None)
	{
		ChosenState = FactionState.GetRivalChosen();
		strChosenType = ChosenState.GetChosenClassName();
		strChosenName = ChosenState.GetChosenName();
		strChosenNickname = ChosenState.GetChosenNickname();
	}

	// Save camera
	XComHQPresentationLayer(Movie.Pres).CAMSaveCurrentLocation();
	bAlertTransitionsToMission = true;

	if (LibraryPanel == none)
	{
		`RedScreen("UI Problem with the alerts! Couldn't find LibraryPanel for current eAlertName: " $ eAlertName);
		return;
	}
	BuildChosenIcon(ChosenState.GetChosenIcon());
	BuildChosenSplashAlert(m_strChosenStrongholdTitle, strChosenType, strChosenName, strChosenNickname, class'UIUtilities_Text'.static.GetColoredText(m_strChosenStrongholdBody, eUIState_Header), 
						   m_strChosenStrongholdImage, m_strChosenStrongholdConfirm, m_strOK);
}

simulated function BuildChosenSabotageAlert()
{
	local XComGameStateHistory History;
	local XComGameState_ChosenAction ActionState;
	local XComGameState_AdventChosen ChosenState;
	local X2SabotageTemplate SabotageTemplate;
	local X2StrategyElementTemplateManager StratMgr;
	local string AlertTitle, AlertDescription;
	
	History = `XCOMHISTORY;
	StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
	ActionState = XComGameState_ChosenAction(History.GetGameStateForObjectID(class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(DisplayPropertySet, 'ActionRef')));
	ChosenState = XComGameState_AdventChosen(History.GetGameStateForObjectID(ActionState.ChosenRef.ObjectID));
	SabotageTemplate = X2SabotageTemplate(StratMgr.FindStrategyElementTemplate(ActionState.StoredTemplateName));

	if(LibraryPanel == none)
	{
		`RedScreen("UI Problem with the alerts! Couldn't find LibraryPanel for current eAlertName: " $ eAlertName);
		return;
	}

	if(ActionState.bActionFailed)
	{
		AlertTitle = m_strChosenSabotageFailedTitle;
		AlertDescription = m_strChosenSabotageFailedBody;
	}
	else
	{
		AlertTitle = m_strChosenSabotageTitle;
		AlertDescription = class'UIUtilities_Text'.static.GetColoredText(SabotageTemplate.DisplayName, eUIState_Bad, 24) $ "\n\n" $ 
			class'UIUtilities_Text'.static.GetColoredText(ActionState.StoredDescription, eUIState_Header);
	}

	BuildChosenIcon(ChosenState.GetChosenIcon());
	BuildChosenSplashAlert(AlertTitle, ChosenState.GetChosenClassName(), ChosenState.GetChosenName(), ChosenState.GetChosenNickname(),
						   AlertDescription, SabotageTemplate.ImagePath, class'UIDialogueBox'.default.m_strDefaultAcceptLabel, "");

	LibraryPanel.MC.FunctionVoid("UpdateChosenSabotage");
}

simulated function BuildChosenFavoredAlert()
{
	local XComGameStateHistory History;
	local XComGameState_AdventChosen ChosenState;
	local XGParamTag ParamTag;

	History = `XCOMHISTORY;
	ChosenState = XComGameState_AdventChosen(History.GetGameStateForObjectID(class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(DisplayPropertySet, 'ChosenRef')));

	if(LibraryPanel == none)
	{
		`RedScreen("UI Problem with the alerts! Couldn't find LibraryPanel for current eAlertName: " $ eAlertName);
		return;
	}

	ParamTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	ParamTag.StrValue0 = Caps(ChosenState.GetChosenClassName());

	BuildChosenIcon(ChosenState.GetChosenIcon());
	BuildChosenSplashAlert(`XEXPAND.ExpandString(m_strChosenFavoredTitle), ChosenState.GetChosenClassName(), ChosenState.GetChosenName(), ChosenState.GetChosenNickname(),
						   class'UIUtilities_Text'.static.GetColoredText(m_strChosenFavoredBody, eUIState_Header), "", class'UIDialogueBox'.default.m_strDefaultAcceptLabel, "");
}

simulated function BuildRescueSoldierAlert()
{
	local XComGameStateHistory History;
	local XComGameState_ResistanceFaction FactionState;
	local XComGameState_MissionSite MissionState;
	local XComGameState_Reward RewardState;
	local XComGameState_Unit UnitState;
	local XGParamTag ParamTag;

	// Save camera
	XComHQPresentationLayer(Movie.Pres).CAMSaveCurrentLocation();
	bAlertTransitionsToMission = true;

	if (LibraryPanel == none)
	{
		`RedScreen("UI Problem with the alerts! Couldn't find LibraryPanel for current eAlertName: " $ eAlertName);
		return;
	}

	History = `XCOMHISTORY;
	FactionState = XComGameState_ResistanceFaction(History.GetGameStateForObjectID(
		class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(DisplayPropertySet, 'FactionRef')));
	MissionState = XComGameState_MissionSite(History.GetGameStateForObjectID(
		class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(DisplayPropertySet, 'MissionRef')));
	if (MissionState.Rewards.Length > 0)
	{
		RewardState = XComGameState_Reward(History.GetGameStateForObjectID(MissionState.Rewards[0].ObjectID));
		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(RewardState.RewardObjectReference.ObjectID));
	}

	ParamTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	ParamTag.StrValue0 = UnitState.GetName(eNameType_RankFull);
	ParamTag.StrValue1 = FactionState.GetRivalChosen().GetChosenName();
	ParamTag.StrValue2 = FactionState.GetRivalChosen().GetChosenClassName();
	
	SetFactionIcon(FactionState.GetFactionIcon());

	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateMissionSplashData");
	LibraryPanel.MC.QueueString(Caps(`XEXPAND.ExpandString(m_strRescueSoldierTitle))); // Title
	LibraryPanel.MC.QueueString(`XEXPAND.ExpandString(m_strRescueSoldierBody)); // Description
	LibraryPanel.MC.QueueString(""); // Faction Logo
	LibraryPanel.MC.QueueString(FactionState.GetFactionTitle()); // Faction Label
	LibraryPanel.MC.QueueString(FactionState.GetFactionName()); // Faction Name
	LibraryPanel.MC.QueueString(m_strRescueSoldierImage);
	LibraryPanel.MC.QueueString(m_strRescueSoldierConfirm);
	LibraryPanel.MC.QueueString(m_strIgnore);
	LibraryPanel.MC.EndOp();
}

simulated function BuildInspiredResearchAvailableAlert()
{
	local XComGameStateHistory History;
	local XComGameState_Tech TechState;
	local TAlertAvailableInfo kInfo;
	
	History = `XCOMHISTORY;
	TechState = XComGameState_Tech(History.GetGameStateForObjectID(
		class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(DisplayPropertySet, 'TechRef')));
	
	kInfo.strTitle = Repl(m_strInspiredResearchAvailable, "%TECHNAME", class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS(TechState.GetDisplayName()));
	kInfo.strName = TechState.GetDisplayName();
	kInfo.strBody = Repl(m_strInspiredResearchAvailableBody, "%TECHNAME", TechState.GetDisplayName());
	kInfo.strConfirm = m_strAccept;
	kInfo.strImage = TechState.GetImage();
	kInfo.eColor = eUIState_Warning;
	kInfo.clrAlert = MakeLinearColor(0.75, 0.75, 0.0, 1);

	kInfo = FillInTyganAlertAvailable(kInfo);

	BuildAvailableAlert(kInfo);
}

simulated function BuildBreakthroughResearchAvailableAlert()
{
	local XComGameStateHistory History;
	local XComGameState_Tech TechState;
	local TAlertAvailableInfo kInfo;
	
	History = `XCOMHISTORY;
	TechState = XComGameState_Tech(History.GetGameStateForObjectID(
		class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(DisplayPropertySet, 'TechRef')));

	kInfo.strTitle = Repl(m_strBreakthroughResearchAvailable, "%TECHNAME", Caps(TechState.GetDisplayName()));
	kInfo.strName = TechState.GetDisplayName();
	kInfo.strBody = Repl(m_strBreakthroughResearchAvailableBody, "%TECHNAME", TechState.GetDisplayName());
	kInfo.strConfirm = m_strAccept;
	kInfo.strImage = TechState.GetImage();
	kInfo.eColor = eUIState_Warning;
	kInfo.clrAlert = MakeLinearColor(0.75, 0.75, 0.0, 1);

	kInfo = FillInTyganAlertAvailable(kInfo);

	BuildAvailableAlert(kInfo);
}

simulated function BuildBreakthroughResearchCompleteAlert()
{
	local XComGameStateHistory History;
	local XComGameState_Tech TechState;
	local X2TechTemplate TechTemplate;
	local TAlertAvailableInfo kInfo;
	local string TechSummary;

	History = `XCOMHISTORY;
	TechState = XComGameState_Tech(History.GetGameStateForObjectID(
		class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(DisplayPropertySet, 'TechRef')));

	kInfo.strTitle = Repl(m_strBreakthroughResearchComplete, "%TECHNAME", Caps(TechState.GetDisplayName()));
	kInfo.strName = TechState.GetDisplayName();

	TechTemplate = TechState.GetMyTemplate();
	TechSummary = TechState.GetSummary();
	if (TechTemplate.GetValueFn != none)
	{
		TechSummary = Repl(TechSummary, "%VALUE", TechTemplate.GetValueFn());
	}

	kInfo.strBody = TechSummary;
	kInfo.strConfirm = m_strAccept;
	kInfo.strImage = TechState.GetImage();
	kInfo.eColor = eUIState_Warning;
	kInfo.clrAlert = MakeLinearColor(0.75, 0.75, 0.0, 1);

	kInfo = FillInTyganAlertAvailable(kInfo);

	BuildAvailableAlert(kInfo);
}

simulated function BuildReinforcedUnderlayActiveAlert()
{
	local TAlertAvailableInfo kInfo;

	kInfo.strTitle = m_strReinforcedUnderlayTitle;
	kInfo.strName = "";
	kInfo.strBody = m_strReinforcedUnderlayBody;
	kInfo.strConfirm = m_strAccept;
	kInfo.strImage = "img:///UILibrary_XPACK_StrategyImages.Inv_ReinforcedUnderlay";
	kInfo.strConfirm = m_strAccept;
	kInfo.eColor = eUIState_Good;
	kInfo.clrAlert = MakeLinearColor(0.0, 0.75, 0.0, 1);

	kInfo = FillInShenAlertAvailable(kInfo);

	BuildAvailableAlert(kInfo);
}

simulated function BuildStrategyCardReceivedAlert()
{
	local TAlertAvailableInfo kInfo;
	local XComGameState_StrategyCard CardState;
	local XComGameState_ResistanceFaction FactionState;
	
	if (LibraryPanel == none)
	{
		`RedScreen("UI Problem with the alerts! Couldn't find LibraryPanel for current eAlertName: " $ eAlertName);
		return;
	}

	CardState = XComGameState_StrategyCard(`XCOMHISTORY.GetGameStateForObjectID(
		class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(DisplayPropertySet, 'CardRef')));
	FactionState = CardState.GetAssociatedFaction();
	
	SetFactionIcon(FactionState.GetFactionIcon());

	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateMissionSplashData");
	LibraryPanel.MC.QueueString(m_strNewStrategyCardReceivedTitle); // Title
	LibraryPanel.MC.QueueString(Caps(CardState.GetDisplayName()) $ "\n" $ CardState.GetSummaryText() $ "\n\n" $ m_strNewStrategyCardReceivedBody); // Description
	LibraryPanel.MC.QueueString(""); // Faction Logo
	LibraryPanel.MC.QueueString(FactionState.GetFactionTitle()); // Faction Label
	LibraryPanel.MC.QueueString(FactionState.GetFactionName()); // Faction Name
	LibraryPanel.MC.QueueString(CardState.GetImagePath());
	LibraryPanel.MC.QueueString(m_strAccept);
	LibraryPanel.MC.QueueString(m_strIgnore);
	LibraryPanel.MC.EndOp();
	
	BuildAvailableAlert(kInfo);
}

simulated function BuildComIntIntroAlert()
{
	local XComGameState_Unit UnitState;
	local String IntroComIntSubtitle, IntroComIntBody;

	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(
		class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(DisplayPropertySet, 'UnitRef')));

	IntroComIntSubtitle = m_strComIntIntro;
	IntroComIntSubtitle = Repl(IntroComIntSubtitle, "%COMINT", UnitState.GetCombatIntelligenceLabel());

	IntroComIntBody = Repl(m_strComIntIntroBody, "%UNITNAME", UnitState.GetFullName());

	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateData");
	LibraryPanel.MC.QueueString(m_strSoldierShakenHeader); //ATTENTION
	LibraryPanel.MC.QueueString(m_strComIntIntroTitle); //COMBAT INTELLIGENCE
	LibraryPanel.MC.QueueString(UnitState.GetSoldierClassTemplate().IconImage); //ICON
	LibraryPanel.MC.QueueString(Caps(UnitState.GetName(eNameType_FullNick))); //STAFF AVAILABLE STRING
	LibraryPanel.MC.QueueString(IntroComIntSubtitle); //Ex: Gifted Level Intelligence
	LibraryPanel.MC.QueueString(IntroComIntBody); //STAFF BENEFIT STRING
	LibraryPanel.MC.QueueString("");
	LibraryPanel.MC.QueueString(m_strOK); //OK
	LibraryPanel.MC.EndOp();
	GetOrStartWaitingForStaffImage();
	//This panel has only one button, for confirm.
	Button2.DisableNavigation(); 
	Button2.Hide();
}

simulated function BuildSitrepIntroAlert()
{
	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateData");
	LibraryPanel.MC.QueueString(m_strSitrepIntroHeader); // Header (ATTENTION)
	LibraryPanel.MC.QueueString(m_strSitrepIntroTitle); // Title
	LibraryPanel.MC.QueueString(m_strSitrepIntroBody); // Body
	LibraryPanel.MC.QueueString(""); // Button 0
	LibraryPanel.MC.QueueString(m_strOK); // Button 1
	LibraryPanel.MC.EndOp();

	Button1.Hide(); 
	Button1.DisableNavigation();
	Button2.SetGamepadIcon(class'UIUtilities_Input'.static.GetAdvanceButtonIcon());
}

simulated function BuildSoldierCompatibilityIntroAlert()
{
	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateData");
	LibraryPanel.MC.QueueString(m_strSoldierCompatibilityIntroHeader); // Header (ATTENTION)
	LibraryPanel.MC.QueueString(m_strSoldierCompatibilityIntroTitle); // Title
	LibraryPanel.MC.QueueString(m_strSoldierCompatibilityIntroBody); // Body
	LibraryPanel.MC.QueueString(""); // Button 0
	LibraryPanel.MC.QueueString(m_strOK); // Button 1
	LibraryPanel.MC.EndOp();

	Button1.Hide(); 
	Button1.DisableNavigation();
	Button2.SetGamepadIcon(class'UIUtilities_Input'.static.GetAdvanceButtonIcon());
}

simulated function BuildSoldierTiredAlert()
{
	local XComGameState_Unit UnitState;

	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(
		class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(DisplayPropertySet, 'UnitRef')));

	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateData");
	LibraryPanel.MC.QueueString(m_strSoldierShakenHeader); //ATTENTION
	LibraryPanel.MC.QueueString(m_strSoldierTiredTitle); //SOLDIER SHAKEN 
	LibraryPanel.MC.QueueString(""); //ICON
	LibraryPanel.MC.QueueString(Caps(UnitState.GetName(eNameType_FullNick))); //STAFF AVAILABLE STRING
	LibraryPanel.MC.QueueString(m_strSoldierTired); //STAFF BONUS STRING
	LibraryPanel.MC.QueueString(m_strSoldierTiredHelp); //STAFF BENEFIT STRING
	LibraryPanel.MC.QueueString("");
	LibraryPanel.MC.QueueString(m_strOK); //OK
	LibraryPanel.MC.EndOp();
	GetOrStartWaitingForStaffImage();
	//This panel has only one button, for confirm.
	Button2.DisableNavigation(); 
	Button2.Hide();
}

simulated function BuildResistanceOrdersIntroAlert()
{
	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateData");
	LibraryPanel.MC.QueueString(m_strResistanceOrdersIntroHeader); // Header (ATTENTION)
	LibraryPanel.MC.QueueString(m_strResistanceOrdersIntroTitle); // Title
	LibraryPanel.MC.QueueString(m_strResistanceOrdersIntroBody); // Body
	LibraryPanel.MC.QueueString(""); // Button 0
	LibraryPanel.MC.QueueString(m_strOK); // Button 1
	LibraryPanel.MC.EndOp();

	Button1.Hide(); 
	Button1.DisableNavigation();
	Button2.SetGamepadIcon(class'UIUtilities_Input'.static.GetAdvanceButtonIcon());
}

simulated function BuildCovertActionIntroAlert()
{
	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateData");
	LibraryPanel.MC.QueueString(m_strCovertActionIntroHeader); // Header (ATTENTION)
	LibraryPanel.MC.QueueString(m_strCovertActionIntroTitle); // Title
	LibraryPanel.MC.QueueString(m_strCovertActionIntroBody); // Body
	LibraryPanel.MC.QueueString(""); // Button 0
	LibraryPanel.MC.QueueString(m_strOK); // Button 1
	LibraryPanel.MC.EndOp();

	Button1.Hide(); 
	Button1.DisableNavigation();
	Button2.SetGamepadIcon(class'UIUtilities_Input'.static.GetAdvanceButtonIcon());
}

simulated function BuildCovertActionRiskIntroAlert()
{
	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateData");
	LibraryPanel.MC.QueueString(m_strCovertActionRiskIntroHeader); // Header (ATTENTION)
	LibraryPanel.MC.QueueString(m_strCovertActionRiskIntroTitle); // Title
	LibraryPanel.MC.QueueString(m_strCovertActionRiskIntroBody); // Body
	LibraryPanel.MC.QueueString(""); // Button 0
	LibraryPanel.MC.QueueString(m_strOK); // Button 1
	LibraryPanel.MC.EndOp();

	Button1.Hide(); 
	Button1.DisableNavigation();
	Button2.SetGamepadIcon(class'UIUtilities_Input'.static.GetAdvanceButtonIcon());
}

simulated function BuildCantChangeOrdersAlert()
{
	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateData");
	LibraryPanel.MC.QueueString(m_strCantChangeOrdersHeader); // Header (ATTENTION)
	LibraryPanel.MC.QueueString(m_strCantChangeOrdersTitle); // Title
	LibraryPanel.MC.QueueString(m_strCantChangeOrdersBody); // Body
	LibraryPanel.MC.QueueString(""); // Button 0
	LibraryPanel.MC.QueueString(m_strOK); // Button 1
	LibraryPanel.MC.EndOp();

	Button1.Hide();
	Button1.DisableNavigation();
	Button2.SetGamepadIcon(class'UIUtilities_Input'.static.GetAdvanceButtonIcon());
}

simulated function BuildConfirmCovertActionAlert()
{
	local XComGameState_CovertAction ActionState;
	local XComGameState_StaffSlot SlotState;
	local string RankImage, ClassImage, FancyFactionName;
	local int idx;
	local name FactionName;
	local XComGameState_Unit StaffUnit;

	ActionState = XComGameState_CovertAction(`XCOMHISTORY.GetGameStateForObjectID(
		class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(DisplayPropertySet, 'ActionRef')));
	
	SetFactionIcon(ActionState.GetFaction().FactionIconData);

	FactionName = ActionState.GetFaction().GetMyTemplateName();
	FancyFactionName = "<font color='#" $ class'UIUtilities_Colors'.static.GetColorForFaction(FactionName) $"'>" $ Caps(ActionState.GetFaction().FactionName) $"</font>";

	LibraryPanel.MC.BeginFunctionOp("UpdateCovertInfoBlade");
	LibraryPanel.MC.QueueString(m_strConfirmCovertActionLabel);
	LibraryPanel.MC.QueueString(Caps(ActionState.GetFaction().GetFactionTitle()));
	LibraryPanel.MC.QueueString(Caps(FancyFactionName));
	LibraryPanel.MC.QueueString(ActionState.GetImage());
	LibraryPanel.MC.QueueString(ActionState.GetDisplayName());
	LibraryPanel.MC.QueueString(m_strConfirmCovertActionReward);
	LibraryPanel.MC.QueueString(ActionState.GetRewardDescriptionString());
	LibraryPanel.MC.QueueString("");
	LibraryPanel.MC.EndOp();

	LibraryPanel.MC.BeginFunctionOp("UpdateCovertButtonBlade");
	LibraryPanel.MC.QueueString(m_strConfirmCovertActionLabel);
	LibraryPanel.MC.QueueString(m_strConfirmCovertActionOK);
	LibraryPanel.MC.QueueString(m_strCancel);
	LibraryPanel.MC.EndOp();

	LibraryPanel.MC.FunctionVoid("AnimateIn");


	for (idx = 0; idx < ActionState.StaffSlots.Length; idx++)
	{
		SlotState = ActionState.GetStaffSlot(idx);
		if (SlotState != none && SlotState.IsSlotFilled())
		{
			StaffUnit = SlotState.GetAssignedStaff(); 
			if (StaffUnit.IsSoldier())
			{
				RankImage = class'UIUtilities_Image'.static.GetRankIcon(StaffUnit.GetRank(), StaffUnit.GetSoldierClassTemplateName());
				ClassImage = StaffUnit.GetSoldierClassTemplate().IconImage;
			}
			else if (StaffUnit.IsScientist())
			{
				RankImage = "";
				ClassImage = class'UIUtilities_Image'.const.AlertIcon_Science;
			}
			else if( StaffUnit.IsEngineer())
			{
				RankImage = "";
				ClassImage = class'UIUtilities_Image'.const.AlertIcon_Engineering;
			}

			HelperConfirmCovertActionAlertUpdateSlot(idx, StaffUnit.GetFullName(), RankImage, ClassImage);
		}
	}
}

function HelperConfirmCovertActionAlertUpdateSlot(int Index, string Label, string RankIcon, string ClassIcon)
{
	LibraryPanel.MC.BeginFunctionOp("UpdateCovertSlot");
	LibraryPanel.MC.QueueString(string(Index));
	LibraryPanel.MC.QueueString(Label);
	LibraryPanel.MC.QueueString(RankIcon);
	LibraryPanel.MC.QueueString(ClassIcon);
	LibraryPanel.MC.EndOp();
}

function SetFactionIcon(StackedUIIconData factionIcon)
{
	local int i;
	LibraryPanel.MC.BeginFunctionOp("SetFactionIcon");

	LibraryPanel.MC.QueueBoolean(factionIcon.bInvert);
	for (i = 0; i < factionIcon.Images.Length; i++)
	{
		LibraryPanel.MC.QueueString("img:///" $ factionIcon.Images[i]);
	}
	LibraryPanel.MC.EndOp();
}

simulated function BuildNextCovertActionAlert()
{
	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateCovertOpData");
	LibraryPanel.MC.QueueString(m_strNextCovertActionTitle); //ATTENTION
	LibraryPanel.MC.QueueString(m_strNextCovertActionBody);
	LibraryPanel.MC.QueueString(m_strNextCovertActionConfirm); //OK
	LibraryPanel.MC.QueueString(m_strCarryOn); // Cancel
	LibraryPanel.MC.EndOp();
}

simulated function BuildRetributionAlert()
{
	local XComGameStateHistory History;
	local XComGameState_ChosenAction ActionState;
	local XComGameState_AdventChosen ChosenState;
	local XComGameState_WorldRegion RegionState;
	local XGParamTag ParamTag;
	local StackedUIIconData IconInfo;
	local string ChosenImage;
	local int i;
	

	History = `XCOMHISTORY;
	ActionState = XComGameState_ChosenAction(History.GetGameStateForObjectID(class'X2StrategyGameRulesetDataStructures'.static.GetDynamicIntProperty(DisplayPropertySet, 'ActionRef')));
	ChosenState = XComGameState_AdventChosen(History.GetGameStateForObjectID(ActionState.ChosenRef.ObjectID));
	RegionState = XComGameState_WorldRegion(History.GetGameStateForObjectID(ActionState.StoredReference.ObjectID));
	
	ChosenImage = ChosenState.GetChosenPortraitImage() $ "_sm";

	// Save camera
	bRestoreCameraPosition = true;
	XComHQPresentationLayer(Movie.Pres).CAMSaveCurrentLocation();

	if(bInstantInterp)
	{
		XComHQPresentationLayer(Movie.Pres).CAMLookAtEarth(RegionState.Get2DLocation(), 0.75f, 0);
	}
	else
	{
		XComHQPresentationLayer(Movie.Pres).CAMLookAtEarth(RegionState.Get2DLocation(), 0.75f);
	}

	//UpdateRetributionTitle("CHOSEN RETRIBUTION", "NEW JACK CITY");
	LibraryPanel.MC.BeginFunctionOp("UpdateRetributionTitle");
	LibraryPanel.MC.QueueString(m_strRetributionAlertTitle); // title
	LibraryPanel.MC.QueueString(RegionState.GetDisplayName());
	LibraryPanel.MC.EndOp();

	//UpdateRetributionDescription("Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec interdum, erat eget sollicitudin dapibus, diam justo pellentesque mauris, et vestibulum quam justo id turpis. ");
	LibraryPanel.MC.BeginFunctionOp("UpdateRetributionDescription");
	LibraryPanel.MC.QueueString(m_strRetributionAlertDescription); // description
	LibraryPanel.MC.EndOp();


	ParamTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	ParamTag.IntValue0 = -ActionState.StoredIntValue; //TODO @mnauta : 0 to 100 percent of income decreased. 

	//UpdateRetributionInfoPanel("INCOME DECREASED", "Monthly income in this region decreased by 20.", "KNOWLEDGE INCREASED", 2, "Chosen knowledge of XCOM operations has increased.");
	LibraryPanel.MC.BeginFunctionOp("UpdateRetributionInfoPanel");
	LibraryPanel.MC.QueueString(m_strRetributionAlertIncomeDecreasedTitle);
	LibraryPanel.MC.QueueString(`XEXPAND.ExpandString(m_strRetributionAlertIncomeDescription));
	LibraryPanel.MC.QueueString(m_strRetributionAlertKnowledgeTitle);
	LibraryPanel.MC.QueueNumber(ChosenState.GetKnowledgePercent(true, -ChosenState.KnowledgeFromLastAction)); //0 to 100 percent of knowledge start value. 
	LibraryPanel.MC.QueueNumber(ChosenState.GetKnowledgePercent(true)); // TODO @mnauta : 0 to 100 percent of knowledge end value. 
	LibraryPanel.MC.QueueString(m_strRetributionAlertKnowledgeDescription);
	LibraryPanel.MC.EndOp();

	//UpdateRetributionChosenPanel("../AssetLibraries/XPACK/Chosen/AdventChosen_Assassin.tga", "2", "ASSASSIN", "Firstname Lastname", "DESTROYER OF WORLDS");
	LibraryPanel.MC.BeginFunctionOp("UpdateRetributionChosenPanel");
	LibraryPanel.MC.QueueString(ChosenImage);//need to get the smaller image with alpha
	LibraryPanel.MC.QueueString(String(ChosenState.Level + 1));
	LibraryPanel.MC.QueueString(ChosenState.GetChosenClassName());
	LibraryPanel.MC.QueueString(ChosenState.GetChosenName());
	LibraryPanel.MC.QueueString(ChosenState.GetChosenNickname());
	LibraryPanel.MC.EndOp();

	IconInfo = ChosenState.GetChosenIcon();

	LibraryPanel.MC.BeginFunctionOp("UpdateRetributionChosenIcon");
	LibraryPanel.MC.QueueBoolean(IconInfo.bInvert);
	for (i = 0; i < IconInfo.Images.Length; i++)
	{
		LibraryPanel.MC.QueueString("img:///" $ IconInfo.Images[i]);
	}
	LibraryPanel.MC.EndOp();

	LibraryPanel.MC.FunctionVoid("AnimateIn");

	ButtonGroup.Hide();
	Button1.Hide(); 
	Button1.DisableNavigation();
	Button2.DisableNavigation(); 
	Button2.Hide();

	`HQPRES.m_kAvengerHUD.NavHelp.AddContinueButton(OnConfirmContinueButton);
}

simulated function BuildTempPopupAlert()
{
	local string Title, Header, Body;

	Title = class'X2StrategyGameRulesetDataStructures'.static.GetDynamicStringProperty(DisplayPropertySet, 'Title');
	Header = class'X2StrategyGameRulesetDataStructures'.static.GetDynamicStringProperty(DisplayPropertySet, 'Header');
	Body = class'X2StrategyGameRulesetDataStructures'.static.GetDynamicStringProperty(DisplayPropertySet, 'Body');
	
	// Send over to flash
	LibraryPanel.MC.BeginFunctionOp("UpdateData");
	LibraryPanel.MC.QueueString(m_strSoldierShakenHeader); //ATTENTION
	LibraryPanel.MC.QueueString(Title); //SOLDIER SHAKEN 
	LibraryPanel.MC.QueueString(""); //ICON
	LibraryPanel.MC.QueueString("TEMP POPUP FOR VO"); //STAFF AVAILABLE STRING
	LibraryPanel.MC.QueueString(Header); //STAFF BONUS STRING
	LibraryPanel.MC.QueueString(Body); //STAFF BENEFIT STRING
	LibraryPanel.MC.QueueString("");
	LibraryPanel.MC.QueueString(m_strOK); //OK
	LibraryPanel.MC.EndOp();

	//This panel has only one button, for confirm.
	Button2.DisableNavigation(); 
	Button2.Hide();
}

function AddChosenInfoPanel(XComGameState_AdventChosen SelectedChosen)
{
	local UIPanel ChosenInfoPanel; 
	local StackedUIIconData IconInfo;
	local int idx;

	ChosenInfoPanel = Spawn(class'UIPanel', LibraryPanel);
	ChosenInfoPanel.InitPanel(, 'Alert_ChosenRegionInfo');
	ChosenInfoPanel.ProcessMouseEvents(ChosenPanelProcessMouseEvents);

	ChosenInfoPanel.MC.BeginFunctionOp("SetChosenName");
	ChosenInfoPanel.MC.QueueString(Caps(SelectedChosen.GetChosenClassName()));
	ChosenInfoPanel.MC.QueueString(SelectedChosen.GetChosenName());
	ChosenInfoPanel.MC.QueueString(SelectedChosen.GetChosenNickname());
	ChosenInfoPanel.MC.QueueString(class'UIMission'.default.m_strChosenWarning2);
	ChosenInfoPanel.MC.QueueString(class'UIMission'.default.m_strChosenWarning);
	ChosenInfoPanel.MC.EndOp();

	IconInfo = SelectedChosen.GetChosenIcon();

	ChosenInfoPanel.MC.BeginFunctionOp("UpdateChosenIcon");
	ChosenInfoPanel.MC.QueueBoolean(IconInfo.bInvert);
	for (idx = 0; idx < IconInfo.Images.Length; idx++)
	{
		ChosenInfoPanel.MC.QueueString("img:///" $ IconInfo.Images[idx]);
	}
	ChosenInfoPanel.MC.EndOp();
}

function ChosenPanelProcessMouseEvents(UIPanel Panel, int Cmd)
{
	if( cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_UP )
	{
		if( !Movie.Pres.ScreenStack.IsInStack(class'UIChosenInfo') )
			Movie.Pres.UIChosenInformation(); 
	}
}

//-------------- EVENT HANDLING --------------------------------------------------------

simulated function OnReceiveFocus()
{
	super.OnReceiveFocus();

	if (bRestoreCameraPositionOnReceiveFocus)
	{
		XComHQPresentationLayer(Movie.Pres).CAMRestoreSavedLocation(0.0f); // Do an instant restore of the camera
	}
	
	// Clear any lingering nav help instructions if the user had pressed 'Tell me more'
	if(eAlertName == 'eAlert_Objective')
	{
		`HQPRES.m_kAvengerHUD.NavHelp.ClearButtonHelp();
	}

	PresentUIEffects();
	}
	
simulated function OnConfirmContinueButton()
{
	OnConfirmClicked(none);
}

simulated function OnConfirmClicked(UIButton button)
	{
	local delegate<X2StrategyGameRulesetDataStructures.AlertCallback> LocalCallbackFunction;

	if( DisplayPropertySet.CallbackFunction != none )
	{
		LocalCallbackFunction = DisplayPropertySet.CallbackFunction;
		LocalCallbackFunction('eUIAction_Accept', DisplayPropertySet, false);
	}
	
	// The callbacks could potentially remove this screen, so make sure we haven't been removed already
	if( !bIsRemoved )
		CloseScreen();
}
simulated function OnCancelClicked(UIButton button)
{
	local delegate<X2StrategyGameRulesetDataStructures.AlertCallback> LocalCallbackFunction;

	if (CanBackOut())
	{
		if( DisplayPropertySet.CallbackFunction != none )
		{
			LocalCallbackFunction = DisplayPropertySet.CallbackFunction;
			LocalCallbackFunction('eUIAction_Cancel', DisplayPropertySet, false);
		}

		if (!bIsRemoved)
			CloseScreen();
	}
}

simulated function TellMeMore(UIButton button) 
{
	bRestoreCameraPositionOnReceiveFocus = true;
	XComHQPresentationLayer(Movie.Pres).CAMSaveCurrentLocation();
	`HQPRES.UIViewObjectives(0);	
}

// Called when screen is removed from Stack
simulated function OnRemoved()
{
	//If removing an alert that moved the camera when it was displayed, restore the camera saved location
	// But skip any alert that next transitions to a Mission screen, since they will perform their own save & restore of the camera
	if (bRestoreCameraPosition && !bAlertTransitionsToMission)
	{
		XComHQPresentationLayer(Movie.Pres).CAMRestoreSavedLocation();
		`HQPRES.StrategyMap2D.ShowCursor();
	}

	super.OnRemoved();
	
	PlaySFX("Play_MenuClose");
}

simulated function bool CanBackOut()
{
	if( eAlertName == 'eAlert_GOps' && !class'XComGameState_HeadquartersXCom'.static.IsObjectiveCompleted('T0_M7_WelcomeToGeoscape'))
	{
		return false;
	}

	if ( eAlertName == 'eAlert_NewScanningSite' && !class'XComGameState_HeadquartersXCom'.static.IsObjectiveCompleted('T0_M10_IntroToBlacksite'))
	{
		return false;
	}

	if ( eAlertName == 'eAlert_FacilityComplete' && class'X2StrategyGameRulesetDataStructures'.static.GetDynamicNameProperty(DisplayPropertySet, 'FacilityTemplate') == 'ShadowChamber')
	{
		return false;
	}

	if (eAlertName == 'eAlert_ChosenAmbush')
	{
		return false;
	}

	if (eAlertName == 'eAlert_LostAndAbandoned')
	{
		return false;
	}

	return true;
}

//-------------- GAME DATA HOOKUP --------------------------------------------------------

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	local bool bHandled;
	//local UIButton CurrentButton; 

	if ( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg) )
		return false;

	bHandled = true;

	switch( cmd )
	{
`if(`notdefined(FINAL_RELEASE))
		case class'UIUtilities_Input'.const.FXS_KEY_TAB:
`endif
		case class'UIUtilities_Input'.const.FXS_BUTTON_B:
		case class'UIUtilities_Input'.const.FXS_KEY_ESCAPE:
		case class'UIUtilities_Input'.const.FXS_R_MOUSE_DOWN:
			if (eAlertName == 'eAlert_ScanComplete')
			{
				//bsg-jedwards (3.10.17) : Setting the condition for the occasion if "B" button will be used to continue.
				if ((class'XComGameState_HeadquartersXCom'.static.GetObjectiveStatus('T2_M0_CompleteGuerillaOps') != eObjectiveState_InProgress) && 
					(class'XComGameState_HeadquartersXCom'.static.GetObjectiveStatus('XP0_M1_TutorialLostAndAbandonedComplete') != eObjectiveState_InProgress) &&
					(class'XComGameState_HeadquartersXCom'.static.GetObjectiveStatus('XP0_M1_LostAndAbandonedComplete') != eObjectiveState_InProgress))
				{
					OnConfirmClicked(none);
				}
				//bsg-jedwards (3.10.17) : end
			}
			else if(`ISCONTROLLERACTIVE && (!Button2.bIsVisible || !Button1.bIsVisible)) //Button1+2 both can be "cancel"
			{
				//if we don't tell the user they can exit using the back button, we can't allow it
				return true;
			}
			else
			{
				if (!(eAlertName == 'eAlert_TrainingComplete' || eAlertName == 'eAlert_SoldierPromoted'))
				{
					OnCancelClicked(none);
				}
			}
			break;
		case class'UIUtilities_Input'.const.FXS_BUTTON_A:
		case class'UIUtilities_Input'.const.FXS_KEY_ENTER:
		case class'UIUtilities_Input'.const.FXS_KEY_SPACEBAR:
			if (eAlertName == 'eAlert_Contact' && (!CanAffordContact() || !CanMakeContact()))
			{
				break;
			}
			if (eAlertName =='eAlert_Outpost' && !CanAffordOutpost())
			{
				break;
			}
			if( Button2.IsSelectedNavigation() ) //if you've pressed down and selected the cancel button. 
			{
				OnCancelClicked(none);
			}
			else if (eAlertName == 'eAlert_ScanComplete')
			{
				OnConfirmClicked(none); //bsg-jedwards (3.10.17) : Allow the "A" button to be the primary confirmation button.
			}
			else if (eAlertName == 'eAlert_ClassEarned' || eAlertName == 'eAlert_TrainingComplete' || eAlertName == 'eAlert_SoldierPromoted')
			{
				OnCancelClicked(none);
			}
			else
			{
				OnConfirmClicked(none);
			}
			
			break;
		case class'UIUtilities_Input'.const.FXS_BUTTON_X:
			if (eAlertName == 'eAlert_Objective')
			{
				if (!(class'UIUtilities_Strategy'.static.GetXComHQ().AnyTutorialObjectivesInProgress())) //Button prompt hidden; disallow input too - BET 2016-06-08
				{
					TellMeMore(none);
				}
			}
			else if (eAlertName == 'eAlert_TrainingComplete' || eAlertName == 'eAlert_SoldierPromoted')
			{
				if (!Movie.Pres.ScreenStack.IsInStack(class'UIArmory_Promotion'))
				{
					OnConfirmClicked(none);
				}
			}

			break;
		default:
			bHandled = false;
			break;
	}

	return bHandled || super.OnUnrealCommand(cmd, arg);
}
//==============================================================================

defaultproperties
{
	Package = "/ package/gfxAlerts/Alerts";
	XPACK_Package = "/ package/gfxXPACK_Alerts/XPACK_Alerts";

	InputState = eInputState_Consume;
	bAlertTransitionsToMission = false;
	bRestoreCameraPosition = false;
	bConsumeMouseEvents = true;
}
