//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UISoldierBondConfirmScreen.uc
//  AUTHOR:  Joe Cortese
//  PURPOSE: Soldier bond confirmation screen.
//
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UISoldierBondConfirmScreen extends UIScreen
	dependson(X2Photobooth_AutoGenBase);

var localized string m_strTitle;
var localized string m_strConfirm;
var localized string m_strBenefits;

var localized string m_strMakePosterTitle;
var localized string m_strMakePosterBody;

var XComGameState_Unit Soldier1State;
var XComGameState_Unit Soldier2State;
var XComGameState_StaffSlot UnitSlotState;
var UINavigationHelp NavHelp;

var UIButton ConfirmButton;

simulated function OnInit()
{
	local string classIcon1, rankIcon1, classIcon2, rankIcon2;
	local int iRank1, iRank2, i;
	local X2SoldierClassTemplate SoldierClass1, SoldierClass2;
	local SoldierBond BondData;
	local X2DataTemplate BondedAbilityTemplate;
	local UISummary_Ability Data;
	local StateObjectReference unitRef;
	local X2AbilityTemplateManager AbilityTemplateMan;
	local X2AbilityTemplate AbilityTemplate;
	local X2Condition TestCondition;
	local X2Condition_Bondmate BondmateCondition;

	super.OnInit();

	ConfirmButton = Spawn(class'UIButton', self);
	ConfirmButton.InitButton('confirmButtonMC', , ConfirmClicked);
	if( `ISCONTROLLERACTIVE )
		ConfirmButton.Hide(); //Using the bottom nav help instead. 

	NavHelp = `HQPRES.m_kAvengerHUD.NavHelp;

	iRank1 = Soldier1State.GetRank();

	SoldierClass1 = Soldier1State.GetSoldierClassTemplate();

	rankIcon1 = class'UIUtilities_Image'.static.GetRankIcon(iRank1, SoldierClass1.DataName);
	classIcon1 = SoldierClass1.IconImage;

	Soldier1State.HasSoldierBond(unitRef, BondData);


	iRank2 = Soldier2State.GetRank();

	SoldierClass2 = Soldier2State.GetSoldierClassTemplate();

	rankIcon2 = class'UIUtilities_Image'.static.GetRankIcon(iRank2, SoldierClass2.DataName);
	classIcon2 = SoldierClass2.IconImage;

	SetBondData(BondData.BondLevel + 1, rankIcon1, classIcon1, SoldierClass1.DisplayName, Caps(Soldier1State.GetName(eNameType_Full)),
		rankIcon2, classIcon2, SoldierClass2.DisplayName, Caps(Soldier2State.GetName(eNameType_Full)), m_strBenefits);

	i = 0;
	AbilityTemplateMan = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();

	foreach AbilityTemplateMan.IterateTemplates(BondedAbilityTemplate)
	{
		AbilityTemplate = X2AbilityTemplate(BondedAbilityTemplate);

		BondmateCondition = none;
		foreach AbilityTemplate.AbilityTargetConditions(TestCondition)
		{
			BondmateCondition = X2Condition_Bondmate(TestCondition);

			if( BondmateCondition != none )
			{
				break;
			}
		}

		if( BondmateCondition == none )
		{
			foreach AbilityTemplate.AbilityShooterConditions(TestCondition)
			{
				BondmateCondition = X2Condition_Bondmate(TestCondition);

				if( BondmateCondition != none )
				{
					break;
				}
			}
		}

		if( BondmateCondition != none && 
			(BondmateCondition.MinBondLevel == BondData.BondLevel + 1) && 
		   BondmateCondition.RequiresAdjacency == EAR_AnyAdjacency )
		{
			Data = AbilityTemplate.GetUISummary_Ability();

			SetBenefitRow(i, Data.Name, Data.Description);
			++i;
		}
	}

	MC.BeginFunctionOp("SetConfirmButton");
	MC.QueueString(m_strConfirm);
	MC.EndOp();

	AnimateIn();
	RealizeNavHelp();
}

simulated function RealizeNavHelp()
{
	NavHelp.ClearButtonHelp();
	NavHelp.bIsVerticalHelp = `ISCONTROLLERACTIVE;
	NavHelp.AddBackButton(Cancel);

	if (`ISCONTROLLERACTIVE)
		NavHelp.AddSelectNavHelp();
}

function InitBondConfirm(XComGameState_Unit soldier1, XComGameState_Unit soldier2, XComGameState_StaffSlot SlotState)
{
	Soldier1State = soldier1;
	Soldier2State = soldier2;
	UnitSlotState = SlotState;
}

function SetBondData(int bondLevel, string Soldier1Rank, string Soldier1ClassIcon, string Soldier1ClassName, string Soldier1Name, 
						string Soldier2Rank, string Soldier2ClassIcon, string Soldier2ClassName, string Soldier2Name, string Benefit)
{
	MC.BeginFunctionOP("SetBondData");
	MC.QueueString(m_strTitle@bondLevel);
	MC.QueueNumber(bondLevel);
	MC.QueueString(Soldier1Rank);
	MC.QueueString(Soldier1ClassIcon);
	MC.QueueString(Soldier1ClassName);
	MC.QueueString(Soldier1Name);
	MC.QueueString(Soldier2Rank);
	MC.QueueString(Soldier2ClassIcon);
	MC.QueueString(Soldier2ClassName);
	MC.QueueString(Soldier2Name);
	MC.QueueString(Benefit);
	MC.EndOp();
}

function SetBenefitRow(int RowNum, string RowTitle, string RowLabel)
{
	MC.BeginFunctionOP("SetBenefitRow");
	MC.QueueNumber(RowNum);
	MC.QueueString(RowTitle);
	MC.QueueString(RowLabel);
	MC.EndOp();
}

function ConfirmClicked(UIButton Button)
{
	local XComGameState NewGameState;
	local SoldierBond BondData;
	local StaffUnitInfo UnitInfo;
	local TDialogueBoxData DialogData;
		
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Confirm Soldier Bond Project");
	Soldier1State = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', Soldier1State.ObjectID));
	Soldier2State = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', Soldier2State.ObjectID));

	Soldier1State.GetBondData(Soldier2State.GetReference(), BondData);
	if (BondData.BondLevel == 0) // If there is no bond between these units yet, give them one without doing the project
	{
		`XSTRATEGYSOUNDMGR.PlayPersistentSoundEvent("SoldierBond1_Confirm");

		class'X2StrategyGameRulesetDataStructures'.static.SetBondLevel(Soldier1State, Soldier2State, 1);

		// Reset the cohesion of the new bondmates with all other soldiers to 0
		class'X2StrategyGameRulesetDataStructures'.static.ResetNotBondedSoldierCohesion(NewGameState, Soldier1State, Soldier2State);

		`XEVENTMGR.TriggerEvent( 'BondCreated', Soldier1State, Soldier2State, NewGameState );
	}
	else if (UnitSlotState != none) // Otherwise, start a new Soldier Bond project for their training
	{
		`XSTRATEGYSOUNDMGR.PlayPersistentSoundEvent("SoldierBond2_Confirm");

		UnitInfo.UnitRef = Soldier1State.GetReference();
		UnitInfo.PairUnitRef = Soldier2State.GetReference();
		UnitSlotState.FillSlot(UnitInfo, NewGameState);
	}
	else
	{
		`RedScreen("@jweinhoffer @mnauta Soldier Bond Project staffing confirmed, but no staff slot was found.");
	}
	
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	
	// Ask the player if they want to make a poster when forming the first bond
	if (BondData.BondLevel == 0)
	{
		KickOffAutoGen();

		DialogData.eType = eDialog_Normal;
		DialogData.bMuteAcceptSound = true;
		DialogData.strTitle = m_strMakePosterTitle;
		DialogData.strAccept = class'UIUtilities_Text'.default.m_strGenericYes;
		DialogData.strCancel = class'UIUtilities_Text'.default.m_strGenericNO;
		DialogData.fnCallback = MakePosterCallback;
		DialogData.strText = m_strMakePosterBody;

		Movie.Pres.UIRaiseDialog(DialogData);
	}
	else
	{
		CloseScreen();
	}
}

simulated function KickOffAutoGen()
{
	`HQPRES.GetPhotoboothAutoGen().AddBondedSoldier(Soldier1State.GetReference());
	`HQPRES.GetPhotoboothAutoGen().RequestPhotos();
}

simulated function MakePosterCallback(Name Action)
{
	local UIArmory_Photobooth photoscreen;
	local PhotoboothDefaultSettings autoDefaultSettings;
	local AutoGenPhotoInfo requestInfo;
	
	requestInfo.TextLayoutState = ePBTLS_BondedSoldier;
	requestInfo.UnitRef = Soldier1State.GetReference();
	autoDefaultSettings = `HQPRES.GetPhotoboothAutoGen().SetupDefault(requestInfo);

	if (Action == 'eUIAction_Accept')
	{	
		photoscreen = XComHQPresentationLayer(Movie.Pres).UIArmory_Photobooth(Soldier1State.GetReference());
		photoscreen.DefaultSetupSettings = autoDefaultSettings;
	}

	CloseScreen();
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	local bool bHandled;

	bHandled = true;

	//bsg-hlee (05.15.17): Only allow releases or directional repeat.
	if ( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg) )
		return false;

	switch (cmd)
	{
	case class'UIUtilities_Input'.const.FXS_BUTTON_A :
	case class'UIUtilities_Input'.const.FXS_KEY_ENTER :
	case class'UIUtilities_Input'.const.FXS_KEY_SPACEBAR :
		ConfirmClicked(ConfirmButton);
		break;
	case class'UIUtilities_Input'.const.FXS_BUTTON_B :
	case class'UIUtilities_Input'.const.FXS_KEY_ESCAPE :
	case class'UIUtilities_Input'.const.FXS_R_MOUSE_DOWN :
		Cancel();
		break;
	default:
		bHandled = false;
		break;
	}
	return bHandled || super.OnUnrealCommand(cmd, arg);
}

simulated function Cancel()
{
	local XComGameState NewGameState;
	
	// If this screen was accessed by staffing units, remove them from the staff slots
	if (UnitSlotState != None)
	{	
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Empty Bond Staff Slots");	
		UnitSlotState.EmptySlot(NewGameState);
		UnitSlotState.GetLinkedStaffSlot().EmptySlot(NewGameState);
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}

	CloseScreen();
}

//bsg-hlee (05.15.17): Making nav help responsive to current focus.
simulated function OnLoseFocus()
{
	super.OnLoseFocus();
	NavHelp.ClearButtonHelp();
}

simulated function OnReceiveFocus()
{
	super.OnReceiveFocus();
	RealizeNavHelp();
}
//bsg-hlee (05.15.17): End

defaultproperties
{
	Package = "/ package/gfxXPACK_SoldierBondConfirm/XPACK_SoldierBondConfirm";
	InputState = eInputState_Consume;
	bHideOnLoseFocus = true;
}