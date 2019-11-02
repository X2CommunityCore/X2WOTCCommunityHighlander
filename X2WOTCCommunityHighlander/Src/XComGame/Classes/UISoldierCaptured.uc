
//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UISoldierCaptured.uc
//  AUTHOR:  Brit Steiner -- 1/24/2017
//  PURPOSE: This file controls the covert actions view
//---------------------------------------------------------------------------------------
//  Copyright (c) 2017 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UISoldierCaptured extends UIScreen;


var public localized String SoldierCapturedTitle;
var public localized String SoldierCapturedLabel;
var public localized String SoldierCapturedBody;
var public localized String SoldierCapturedBy;

var StateObjectReference ChosenRef;
var StateObjectReference TargetRef;
var bool bCapturedOnMission;

var Texture2D SoldierPicture;
var Texture2D PosterPicture;

var DynamicPropertySet DisplayPropertySet;

//----------------------------------------------------------------------------
// MEMBERS

simulated function OnInit()
{
	super.OnInit();

	if (`HQPRES.StrategyMap2D != none)
		`HQPRES.StrategyMap2D.Hide();

	BuildScreen();
}

simulated function BuildScreen()
{
	local XComGameState NewGameState;
	local XComGameState_AdventChosen ChosenState;
	local XComGameState_Unit UnitState;
	local String strChosenType, strChosenName, strChosenNickname, strBody;
	local XComGameStateHistory History;
	local XGParamTag ParamTag;
	local X2SoldierClassTemplate SoldierClass;
	local String strChosenFanfare;

	History = `XCOMHISTORY;
	ChosenState = XComGameState_AdventChosen(History.GetGameStateForObjectID(ChosenRef.ObjectID));
	UnitState = XComGameState_Unit(History.GetGameStateForObjectID(TargetRef.ObjectID));

	if( ChosenState != None )
	{
		strChosenType = "";
		strChosenName = ChosenState.GetChosenName();
		strChosenNickname = ChosenState.GetChosenClassName();
		if( ChosenState.GetFanfareSound( strChosenFanfare ) )
		{
			`XSTRATEGYSOUNDMGR.PlayPersistentSoundEvent( strChosenFanfare );
		}
	}

	ParamTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	ParamTag.StrValue0 = ChosenState.GetChosenName();
	ParamTag.StrValue1 = UnitState.GetFullName();
	strBody = `XEXPAND.ExpandString(SoldierCapturedBody);

	SoldierClass = UnitState.GetSoldierClassTemplate();

	AS_SetChosenIcon(ChosenState.GetChosenIcon());

	// Start Issue #106, #408
	AS_UpdateData(  GetOrStartWaitingForPosterImage(),
				  ""/*InspectingChosen.GetChosenIcon()*/,
					string(ChosenState.Level),
					Caps(strChosenType),
					strChosenName,
					Caps(strChosenNickname),
					UnitState.IsSoldier() ? UnitState.GetSoldierClassIcon() : UnitState.GetMPCharacterTemplate().IconImage,
					Caps(UnitState.GetSoldierRankIcon()),
					Caps(SoldierClass != None ? UnitState.GetSoldierClassDisplayName() : ""),
					Caps(UnitState.GetFullName()),
					Caps(UnitState.IsSoldier() ? UnitState.GetSoldierRankName() : ""),
					strBody);
	// End Issue #106, #408

	GetOrStartWaitingForStaffImage();
	if( `SCREENSTACK.IsTopScreen(self) )
	{
		MC.FunctionVoid("AnimateIn");
		`HQPRES.m_kAvengerHUD.NavHelp.AddContinueButton(OnContinue);
	}
	else
	{
		Hide();
	}

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Trigger Event: Soldier Captured");
	`XEVENTMGR.TriggerEvent(ChosenState.GetSoldierCapturedEvent(), , , NewGameState);
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

simulated function OnReceiveFocus()
{
	super.OnReceiveFocus();

	MC.FunctionVoid("AnimateIn");

	`HQPRES.m_kAvengerHUD.NavHelp.ClearButtonHelp();
	`HQPRES.m_kAvengerHUD.NavHelp.AddContinueButton(OnContinue);
	Show();
}

simulated function string GetOrStartWaitingForPosterImage()
{
	local XComGameState_Unit Unit;

	Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(TargetRef.ObjectID));
	`HQPRES.GetPhotoboothAutoGen().AddCapturedSoldier(Unit.GetReference(), UpdatePosterImage);
	`HQPRES.GetPhotoboothAutoGen().RequestPhotos();

	return "";
}

simulated function UpdatePosterImage(StateObjectReference UnitRef)
{
	local XComGameState_CampaignSettings SettingsState;

	SettingsState = XComGameState_CampaignSettings(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings'));

	MC.BeginFunctionOp("UpdatePosterImage");
	MC.QueueString(class'UIUtilities_Image'.static.ValidateImagePath(PathName(`XENGINE.m_kPhotoManager.GetCapturedPoster(SettingsState.GameIndex, UnitRef.ObjectID))));
	MC.EndOp();
}

simulated function string GetOrStartWaitingForStaffImage()
{
	`HQPRES.GetPhotoboothAutoGen().AddHeadShotRequest(TargetRef, 512, 512, UpdateSoldierImage);
	`HQPRES.GetPhotoboothAutoGen().RequestPhotos();

	return "";
}

simulated function UpdateSoldierImage(StateObjectReference UnitRef)
{
	local XComGameState_CampaignSettings SettingsState;

	// only care about call backs for the unit we care about
	if (UnitRef.ObjectID != TargetRef.ObjectID)
		return;

	SettingsState = XComGameState_CampaignSettings(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings'));
	SoldierPicture = `XENGINE.m_kPhotoManager.GetHeadshotTexture(SettingsState.GameIndex, UnitRef.ObjectID, 512, 512);

	MC.BeginFunctionOp("UpdateSoldierImage");
	MC.QueueString(class'UIUtilities_Image'.static.ValidateImagePath(PathName(SoldierPicture)));
	MC.EndOp();
}

public function AS_UpdateData( string Poster, 
							   string ChosenIcon, 
							   string ChosenLevel, 
							   string ChosenType, 
							   string ChosenName, 
							   string ChosenNickname, 
							   string ClassIcon, 
							   string RankIcon, 
							   string SoldierClass, 
							   string SoldierName, 
							   string Rank, 
							   string Description)
{
	MC.BeginFunctionOp("UpdateData");
	MC.QueueString(SoldierCapturedTitle); //default text
	MC.QueueString(Poster);
	MC.QueueString(ChosenIcon);
	MC.QueueString(ChosenLevel);
	MC.QueueString(ChosenType);
	MC.QueueString(ChosenName);
	MC.QueueString(ChosenNickname);
	MC.QueueString(ClassIcon);
	MC.QueueString(RankIcon);
	MC.QueueString(SoldierClass);
	MC.QueueString(SoldierName);
	MC.QueueString(Rank);
	MC.QueueString(SoldierCapturedBy);//default text
	MC.QueueString(Description);
	MC.EndOp();
}

function AS_SetChosenIcon(StackedUIIconData IconInfo)
{
	local int i;

	MC.BeginFunctionOp("UpdateChosenIcon");
	MC.QueueBoolean(IconInfo.bInvert);
	for (i = 0; i < IconInfo.Images.Length; i++)
	{
		MC.QueueString("img:///" $ IconInfo.Images[i]);
	}

	MC.EndOp();
}

//-----------------------------------------------------------------------

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	local bool bHandled;

	if( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg) )
		return false;

	bHandled = true;

	switch( cmd )
	{
	case class'UIUtilities_Input'.const.FXS_BUTTON_A :
	case class'UIUtilities_Input'.const.FXS_KEY_ENTER :
	case class'UIUtilities_Input'.const.FXS_KEY_SPACEBAR :

		OnContinue();
		break;

	default:
		bHandled = false;
		break;
	}

	return bHandled || super.OnUnrealCommand(cmd, arg);
}

simulated public function OnContinue()
{
	local XComGameState NewGameState;

	if (bCapturedOnMission)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Trigger Event: Soldier Captured Closed");
		`XEVENTMGR.TriggerEvent('SoldierCapturedClosed', , , NewGameState);
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}

	`HQPRES.m_kAvengerHUD.NavHelp.ClearButtonHelp();
	CloseScreen();
}

simulated function CloseScreen()
{
	`XSTRATEGYSOUNDMGR.PlayPersistentSoundEvent("ChosenPopupClose");
	super.CloseScreen();
}

//==============================================================================

defaultproperties
{
	Package = "/ package/gfxXPACK_SoldierCaptured/XPACK_SoldierCaptured";
	InputState = eInputState_Consume;
	bHideOnLoseFocus = true; 
}