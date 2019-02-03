//---------------------------------------------------------------------------------------
//  FILE:    UIChosenMissionSummary.uc
//  AUTHOR:  Mark Nauta  --  11/08/2016
//  PURPOSE: Summarizes encounter with the Chosen on the current mission
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class UIChosenMissionSummary extends UIScreen;

var XComGameState_Unit UnitState;
var XComGameState_Unit AffectedUnit;
var XComGameState_AdventChosen ChosenState;

var UINavigationHelp NavHelp;

var localized string ChosenDefeatedLabel;
var localized string ChosenEncounterTitle;
var localized string ChosenEncounterSubtitle;
var localized string ChosenActionsLabel;
var localized string CasualtiesLabel;
var localized string StrengthsLabel;
var localized string WeaknessesLabel;
var localized string ChosenKnowledgeLabel;
var localized string ChosenKnowledgeText;
var localized string SoldierCapturedLabel;
var localized string RewardLabel;
var localized string RewardType;

//---------------------------------------------------------------------------------------
simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	// Using base sound manager and PlaySoundEvent instead of Tactical sound manager and PlayPersistentSoundEvent
	// so that this plays on the same game object that super.InitScreen uses.
	`SOUNDMGR.PlaySoundEvent("PreventNextMenuOpen");

	super.InitScreen(InitController, InitMovie, InitName);

	NavHelp = Spawn(class'UINavigationHelp', self).InitNavHelp();
	NavHelp.AddContinueButton(CloseScreen);
}

//---------------------------------------------------------------------------------------
simulated function OnInit()
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_HeadquartersAlien AlienHQ;
	local XComGameState_Effect KidnapEffect, ExtractEffect;

	super.OnInit();

	// Grab Alien HQ
	History = `XCOMHISTORY;
	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));

	// Set Chosen UnitState
	UnitState = AlienHQ.GetChosenOnMission();

	// Set Chosen State
	ChosenState = AlienHQ.GetChosenOfTemplate(UnitState.GetMyTemplateGroupName());

	// Play Chosen fanfare
	`XTACTICALSOUNDMGR.PlayPersistentSoundEvent(ChosenState.GetMyTemplate().FanfareEvent);

	// Set Data
	SetChosenData();

	SetChosenIcon( ChosenState.GetChosenIcon() );

	KidnapEffect = UnitState.GetUnitApplyingEffectState('ChosenKidnapTarget');
	ExtractEffect = UnitState.GetUnitApplyingEffectState('ChosenExtractKnowledgeTarget');
	
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Trigger Event: Chosen Tactical Summary");
	if( UnitState.IsDead() )
	{
		`XEVENTMGR.TriggerEvent('ChosenSummaryDefeated', , , NewGameState);
		SetChosenImage(true);
		OnChosenDefeat();
	}
	else if(KidnapEffect != none)
	{
		`XEVENTMGR.TriggerEvent('ChosenSummaryCapture', , , NewGameState);
		SetChosenImage();
		AffectedUnit = XComGameState_Unit(History.GetGameStateForObjectID(KidnapEffect.ApplyEffectParameters.TargetStateObjectRef.ObjectID));
		OnChosenCapture();
	}
	else if(ExtractEffect != none)
	{
		`XEVENTMGR.TriggerEvent('ChosenSummaryExtract', , , NewGameState);
		SetChosenImage();
		AffectedUnit = XComGameState_Unit(History.GetGameStateForObjectID(ExtractEffect.ApplyEffectParameters.TargetStateObjectRef.ObjectID));
		OnChosenExtract();
	}
	else
	{
		SetChosenImage();
		// Pass in Blank data
		MC.BeginFunctionOp("SetChosenReward");
		MC.QueueString("");
		MC.QueueString("");
		MC.QueueString("");
		MC.EndOp();
	}
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

//---------------------------------------------------------------------------------------
simulated function SetChosenImage(optional bool bWasDefeated = false)
{
	local string DefeatedString;

	DefeatedString = "";

	if(bWasDefeated)
	{
		DefeatedString = ChosenDefeatedLabel;
	}

	MC.BeginFunctionOp("SetChosenImage");
	MC.QueueString(ChosenState.GetChosenPortraitImage());
	MC.QueueString(DefeatedString);
	MC.EndOp();
}

//---------------------------------------------------------------------------------------
simulated function SetChosenData()
{
	MC.BeginFunctionOp("SetChosenData");
	MC.QueueString(ChosenEncounterTitle);
	MC.QueueString(ChosenEncounterSubtitle);
	MC.QueueString(ChosenState.GetChosenClassName());
	MC.QueueString(ChosenState.GetChosenName());
	MC.QueueString(ChosenState.GetChosenNickname());
	MC.QueueString(ChosenState.GetChosenNarrativeFlavor());
	MC.QueueString(StrengthsLabel);
	MC.QueueString(ChosenState.GetStrengthsList());
	MC.QueueString(WeaknessesLabel);
	MC.QueueString(ChosenState.GetWeaknessesList());
	MC.EndOp();
}

//---------------------------------------------------------------------------------------
simulated function SetChosenIcon(StackedUIIconData IconInfo)
{
	local int i;

	MC.BeginFunctionOp("SetChosenIcon");
	MC.QueueBoolean(IconInfo.bInvert);
	for (i = 0; i < IconInfo.Images.Length; i++)
	{
		MC.QueueString("img:///" $ IconInfo.Images[i]);
	}

	MC.EndOp();
}

//---------------------------------------------------------------------------------------
simulated function OnChosenExtract()
{
	local int ChosenKnowledgeStartValue, ChosenKnowledgeEndValue;

	ChosenKnowledgeStartValue = ChosenState.GetKnowledgePercent(true);
	ChosenKnowledgeEndValue = ChosenState.GetKnowledgePercent(true, ChosenState.MissionKnowledgeExtracted);

	MC.BeginFunctionOp("SetChosenKnowledge");
	MC.QueueString(ChosenKnowledgeLabel);
	MC.QueueNumber(ChosenKnowledgeStartValue);
	MC.QueueNumber(ChosenKnowledgeEndValue);
	MC.QueueString(ChosenKnowledgeText);
	MC.EndOp();
}

//---------------------------------------------------------------------------------------
simulated function OnChosenCapture()
{
	local XComGameState_CampaignSettings SettingsState;
	local Texture2D SoldierPicture;

	SettingsState = XComGameState_CampaignSettings(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings'));
	SoldierPicture = `XENGINE.m_kPhotoManager.GetHeadshotTexture(SettingsState.GameIndex, AffectedUnit.ObjectID, 128, 128);

	MC.BeginFunctionOp("SetSoldierCapture");
	MC.QueueString(SoldierCapturedLabel);
	// Start Issue #106, #408
	MC.QueueString(AffectedUnit.GetSoldierClassIcon());
	MC.QueueString(AffectedUnit.GetSoldierRankIcon());
	MC.QueueString(AffectedUnit.GetSoldierRankName());
	MC.QueueString(AffectedUnit.GetName(eNameType_RankFull));
	MC.QueueString(AffectedUnit.GetSoldierClassDisplayName());
	// End Issue #106, #408
	MC.QueueString(class'UIUtilities_Image'.static.ValidateImagePath(PathName(SoldierPicture)));
	MC.EndOp();
}

//---------------------------------------------------------------------------------------
simulated function OnChosenDefeat()
{
	local X2AbilityPointTemplate APTemplate;
	local XComGameState_HeadquartersXCom XComHQ;
	local int NumPointsAwarded;

	APTemplate = class'X2EventListener_AbilityPoints'.static.GetAbilityPointTemplate( 'ChosenKilled' );
	`assert( APTemplate != none );

	XComHQ = XComGameState_HeadquartersXCom( `XCOMHISTORY.GetSingleGameStateObjectForClass( class'XComGameState_HeadquartersXCom' ) );
	`assert( XComHQ != none );

	NumPointsAwarded = APTemplate.NumPointsAwarded * XComHQ.BonusAbilityPointScalar;

	MC.BeginFunctionOp("SetChosenReward");
	MC.QueueString(RewardLabel);
	MC.QueueString("+"$NumPointsAwarded);
	MC.QueueString(RewardType);
	MC.EndOp();
}

//==============================================================================
//		INPUT HANDLING:
//==============================================================================
simulated function bool OnUnrealCommand(int ucmd, int arg)
{
	if(!CheckInputIsReleaseOrDirectionRepeat(ucmd, arg))
		return false;

	switch(ucmd)
	{
		// Consume 'B' button here so there is no UI functionality in Mission Summary
	case (class'UIUtilities_Input'.const.FXS_BUTTON_B):
	case (class'UIUtilities_Input'.const.FXS_KEY_ESCAPE):
		// Consume
		return true;

		// Consume the 'A' button so that it doesn't cascade down the input chain
	case (class'UIUtilities_Input'.const.FXS_BUTTON_A):
	case (class'UIUtilities_Input'.const.FXS_KEY_ENTER):
	case (class'UIUtilities_Input'.const.FXS_KEY_SPACEBAR):
		CloseScreen();
		return true;

	case class'UIUtilities_Input'.const.FXS_BUTTON_START :
		XComPresentationLayer(Movie.Pres).UIPauseMenu(true);
		return true;
	}

	return super.OnUnrealCommand(ucmd, arg);
}

//==============================================================================
//		CLEANUP:
//==============================================================================
simulated function CloseScreen()
{
	super.CloseScreen();

	`PRES.UIMissionSummaryScreen();
}

//---------------------------------------------------------------------------------------
DefaultProperties
{
	Package = "/ package/gfxXPACK_ChosenPostMission/XPACK_ChosenPostMission";
	MCName = "theScreen";

	InputState = eInputState_Consume;

	bConsumeMouseEvents = true;
}