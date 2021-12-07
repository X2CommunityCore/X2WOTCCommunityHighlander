//---------------------------------------------------------------------------------------
//  Copyright (c) 2009-2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIChosenReveal extends UIScreen;

var UINavigationHelp NavHelp;

var localized string ChosenStrengthTitle;
var localized string ChosenWeaknessTitle;
var localized string RivalFactionTitle;

var string UnknownChosenTraitIcon;
var localized string UnknownChosenTraitName;
var localized string UnknownChosenTraitDescription;
var X2Camera_LookAtEnemyHead LookAtTargetCam;

simulated function OnInit()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersAlien AlienHQ;
	local XComGameState_Unit UnitState;
	local XComGameState_AdventChosen ChosenUnitState;
	local array<X2AbilityTemplate> ChosenStrengths, ChosenWeaknesses;
	local XComGameState_ResistanceFaction FactionState;
	local int i;

	super.OnInit();

	`HQPRES.StrategyMap2D.Hide();
	`PRES.HUDHide();

	History = `XCOMHISTORY;
	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));
	movie.Pres.m_kUIMouseCursor.Show();

	UnitState = class'XComGameState_Unit'.static.GetActivatedChosen();
	
	if (UnitState != none)
	{
		ChosenUnitState = AlienHQ.GetChosenOfTemplate(UnitState.GetMyTemplateGroupName());
		if (ChosenUnitState != none)
		{
			AddLookAtTargetCamera(UnitState.FindOrCreateVisualizer());
			SetTitles();
			SetChosenIcon(ChosenUnitState.GetChosenIcon());
			SetChosenName(ChosenUnitState.GetChosenClassName(), ChosenUnitState.GetChosenName(), ChosenUnitState.GetChosenNickname());

			ChosenStrengths = ChosenUnitState.GetChosenStrengths();
			
			for (i = 0; i < ChosenStrengths.Length; ++i)
			{
				if( ChosenStrengths[i].AbilityRevealEvent == '' || ChosenUnitState.RevealedChosenTraits.Find(ChosenStrengths[i].DataName) != INDEX_NONE )
				{
					SetStrengthData(i, ChosenStrengths[i].IconImage, ChosenStrengths[i].LocFriendlyName, ChosenStrengths[i].LocLongDescription);
				}
				else
				{
					SetStrengthData(i, UnknownChosenTraitIcon, UnknownChosenTraitName, UnknownChosenTraitDescription);
				}
			}

			ChosenWeaknesses = ChosenUnitState.GetChosenTraits(ChosenUnitState.Weaknesses); // For the UI, always get all the weaknesses.  We'll colorize them for the UI.
			for (i = 0; i < ChosenWeaknesses.Length; ++i)
			{
				if( ChosenWeaknesses[i].AbilityRevealEvent == '' || ChosenUnitState.RevealedChosenTraits.Find(ChosenWeaknesses[i].DataName) != INDEX_NONE )
				{
					SetWeaknessData(i, ChosenWeaknesses[i].IconImage, ChosenWeaknesses[i].LocFriendlyName, ChosenWeaknesses[i].LocLongDescription, ChosenUnitState.bIgnoreWeaknesses);
				}
				else
				{
					SetWeaknessData(i, UnknownChosenTraitIcon, UnknownChosenTraitName, UnknownChosenTraitDescription, ChosenUnitState.bIgnoreWeaknesses);
				}
			}

			FactionState = ChosenUnitState.GetRivalFaction();
			SetWeaknessFaction(FactionState.GetFactionName());
		}
	}

	NavHelp = Spawn(class'UINavigationHelp', self).InitNavHelp();
	NavHelp.AddRightHelp( class'UIUtilities_Text'.default.m_strGenericConfirm, class'UIUtilities_Input'.static.GetAdvanceButtonIcon(), CloseScreen);

	// If autotesting, auto - accept in a few moments
	if (WorldInfo.Game.MyAutoTestManager != none)
	{
		SetTimer(4.0, false, nameof(CloseScreen));
	}
}

function AddLookAtTargetCamera(Actor LookAtActor)
{
	if (LookAtTargetCam == none && LookAtActor.IsVisible())
	{
		LookAtTargetCam = new class'X2Camera_LookAtEnemyHead';
		LookAtTargetCam.ActorToFollow = LookAtActor;
		`CAMERASTACK.AddCamera(LookAtTargetCam);
	}
}

function RemoveLookAtTargetCamera()
{
	local XComCamera Cam;

	Cam = XComCamera(GetALocalPlayerController().PlayerCamera);

	if (Cam != none && LookAtTargetCam != none)
	{
		Cam.CameraStack.RemoveCamera(LookAtTargetCam);
		LookAtTargetCam = none;
	}
}

function SetChosenName(string ChosenType,
					   string ChosenName,
					   string ChosenNickname)
{
	MC.BeginFunctionOp("SetChosenName");
	MC.QueueString(ChosenType);
	MC.QueueString(ChosenName);
	MC.QueueString(ChosenNickname);
	MC.EndOp();
}

function SetStrengthData(int StrengthIndex,
					     string StrengthIconPath,
					     string StrengthName,
						 string StrengthDescription)
{
	MC.BeginFunctionOp("SetStrengthData");
	MC.QueueNumber(StrengthIndex);
	MC.QueueString(StrengthIconPath);
	MC.QueueString(StrengthName);
	MC.QueueString(StrengthDescription);
	MC.EndOp();
}

function SetWeaknessData(int WeaknessIndex,
						 string WeaknessIconPath,
						 string WeaknessName,
						 string WeaknessDescription,
						 bool WeaknessesDisabled)
{
	MC.BeginFunctionOp("SetWeaknessData");
	MC.QueueNumber(WeaknessIndex);
	MC.QueueString(WeaknessIconPath);
	MC.QueueString(WeaknessName);
	MC.QueueString(WeaknessDescription);
	MC.QueueBoolean(WeaknessesDisabled);
	MC.EndOp();
}

function SetWeaknessFaction(string RivalFactionName)
{
	MC.BeginFunctionOp("SetWeaknessFaction");
	MC.QueueString(RivalFactionTitle);
	MC.QueueString(RivalFactionName);
	MC.EndOp();
}

function SetTitles()
{
	MC.FunctionString("SetStrengthTitle", ChosenStrengthTitle);
	MC.FunctionString("SetWeaknessTitle", ChosenWeaknessTitle);
}

function SetChosenIcon(StackedUIIconData IconInfo)
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

//==============================================================================
//		INPUT HANDLING:
//==============================================================================

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	if( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg) )
		return false;

	switch( cmd )
	{
	case class'UIUtilities_Input'.const.FXS_KEY_ESCAPE :
	case class'UIUtilities_Input'.const.FXS_R_MOUSE_DOWN :
	case class'UIUtilities_Input'.const.FXS_BUTTON_A :
	case class'UIUtilities_Input'.const.FXS_KEY_ENTER :
	case class'UIUtilities_Input'.const.FXS_KEY_SPACEBAR :
		CloseScreen();
		return true; 
	}

	return super.OnUnrealCommand(cmd, arg);
}

simulated function OnCommand(string cmd, string arg)
{
	`XEVENTMGR.TriggerEvent('UIChosenReveal_Loaded');
}

simulated function OnRemoved()
{
	super.OnRemoved();

	RemoveLookAtTargetCamera();
	`XEVENTMGR.TriggerEvent('UIChosenReveal_OnRemoved');
	`PRES.HUDShow();
}

DefaultProperties
{
	Package = "/ package/gfxXPACK_ChosenReveal/XPACK_ChosenReveal"
	InputState = eInputState_Consume
	bConsumeMouseEvents = true
	bShowDuringCinematic = true
	UnknownChosenTraitIcon = "img:///UILibrary_PerkIcons.UIPerk_unknown"
}