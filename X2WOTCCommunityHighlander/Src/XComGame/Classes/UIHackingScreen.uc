//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIHackingScreen.uc
//  AUTHORS: Sam Batista
//
//  PURPOSE: Displays hacking overlay during tactical missions.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIHackingScreen extends UIScreen;

var XComGameStateContext_Ability OriginalContext;
var XComGameState_Ability FinalizeHackAbility, CancelHackAbility;
var XComGameState_Unit UnitState;
var XComGameState_Unit  TargetUnit;
var XComGameState_InteractiveObject ObjectState;
var XComGameState_BaseObject HackTargetObject;

var float m_introDuration;
var float m_hackDuration;

var bool m_SkullJacking;
var bool m_SkullMining;
var bool m_hackStarted;
var bool bWaitingForInput;
var int m_rewardsTaken;

var float HackOffense;
var float HackDefense;

// The index of the reward selected to be rolled for hacking
var int SelectedHackRewardOption;
var int HighlightedHackRewardOption;

var array<X2HackRewardTemplate> HackRewards;
var array<int>	HackRollMods;

var localized string strHackAbilityLabel;
var localized string strHackButtonLabel;
var localized string strHackConsoleButtonLabel;
var localized string strCancelHackButtonLabel;
var localized string strUnlockChanceLabel;
var localized string strRewardUnlockedLabel;
var localized string m_strAlienInfoTitle;
var localized string m_strAdventInfoTitle;
var localized string HackSuccessLabel;
var localized string HackFailedLabel;
var localized string HackCompleteAnyKeyToContinue;
var localized string GuaranteedHeader;
var localized string FeedbackHeader;
var localized string GuaranteedFailText;
var localized string FeedbackFailText;
var localized string ChooseRewardText;
var localized string m_AdventName;
var localized string m_AdvenOverride;
var localized string m_AdventInitialize;
var localized string HackCompleteConsoleAnyKeyToContinue;

var delegate<HackingCompleteCallback> OnHackingComplete;
var delegate<HackingRewardUnlockedCallback> OnHackingRewardUnlocked;

public delegate HackingCompleteCallback();
public delegate HackingRewardUnlockedCallback(int iRewardIndex);

// Constructor
simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	local X2Action_Hack ActionOwner;
	local X2AbilityTemplate HackAbilityTemplate;
	local StateObjectReference FinalizeHackRef, CancelHackRef;

	super.InitScreen(InitController, InitMovie, InitName);

	bWaitingForInput = false;

	ActionOwner = X2Action_Hack(Owner);

	//  get the unit state from the input context as the action's unit may be a gremlin
	UnitState = XComGameState_Unit(OriginalContext.AssociatedState.GetGameStateForObjectID(OriginalContext.InputContext.SourceObject.ObjectID));
	TargetUnit = ActionOwner.TargetUnit;
	ObjectState = ActionOwner.ObjectState;

	HackTargetObject = ((TargetUnit == None) ? ObjectState : TargetUnit);

	// find the finialize ability that is paired with this hack action
	HackAbilityTemplate = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate(OriginalContext.InputContext.AbilityTemplateName);
	`assert(HackAbilityTemplate != none);

	FinalizeHackRef = UnitState.FindAbility(HackAbilityTemplate.FinalizeAbilityName);
	m_SkullJacking = (HackAbilityTemplate.FinalizeAbilityName == 'FinalizeSKULLJACK');
	m_SkullMining = (HackAbilityTemplate.FinalizeAbilityName == 'FinalizeSKULLMINE');
	MC.FunctionNum("SetScreenType", (m_SkullJacking || m_SkullMining) ? 1 : 0);
	
	//set up the advent splash screen text
	MC.BeginFunctionOp("SetAdventStartScreen");
	MC.QueueString(m_AdventName);
	MC.QueueString(m_AdvenOverride);
	MC.QueueString(m_AdventInitialize);
	MC.EndOp();

	`assert(FinalizeHackRef.ObjectID > 0);
	FinalizeHackAbility = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(FinalizeHackRef.ObjectID));
	`assert(FinalizeHackAbility != none);

	CancelHackRef = UnitState.FindAbility(HackAbilityTemplate.CancelAbilityName);
	`assert(CancelHackRef.ObjectID > 0);
	CancelHackAbility = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(CancelHackRef.ObjectID));
	`assert(CancelHackAbility != none);

	HackOffense = class'X2AbilityToHitCalc_Hacking'.static.GetHackAttackForUnit(UnitState, FinalizeHackAbility);
	HackDefense = class'X2AbilityToHitCalc_Hacking'.static.GetHackDefenseForTarget(HackTargetObject);

	// always select the first selectable hack reward (the one in slot 1)
	SelectedHackRewardOption = 1;
	HighlightedHackRewardOption = -1;
}

// Flash screen is initialized
simulated function OnInit()
{
	local string FinalHackLabelStr, CancelLabelStr;
	super.OnInit();

	AS_SetChooseRewards(ChooseRewardText);
	PopulateResultsInfo();
	if( `ISCONTROLLERACTIVE )
	{
		FinalHackLabelStr = Repl(strHackConsoleButtonLabel, "%A", class 'UIUtilities_Input'.static.HTML(class 'UIUtilities_Input'.static.GetAdvanceButtonIcon(),,0));
		AS_LocalizeButton(FinalHackLabelStr);

		if (CanCancel())
			CancelLabelStr = class 'UIUtilities_Input'.static.HTML(class 'UIUtilities_Input'.static.GetBackButtonIcon(), , -6) @ strCancelHackButtonLabel;
		else
			CancelLabelStr = "";

		MC.FunctionString("UpdateCancelButton", CancelLabelStr);
	}
	else
	{
		AS_LocalizeButton(strHackButtonLabel);

		MC.FunctionString("UpdateCancelButton", CanCancel() ? strCancelHackButtonLabel : "");
	}

	PopulateSoldierInfo();
	PopulateEnemyInfo();

	AS_SetMeterRolledScore(0);
	RefreshPreviewState();

	if( !m_SkullJacking && !m_SkullMining )
	{
		WorldInfo.PlayAkEvent(AkEvent'SoundTacticalUI_Hacking.Hack_Start');
	}
	SetTimer(3.3, False, 'StartScaryComputerLoopAkEvent');
}

simulated function bool CanCancel()
{
	return !m_SkullJacking && !m_SkullMining && !`REPLAY.bInReplay;
}

simulated function StartScaryComputerLoopAkEvent()
{
	if (`REPLAY.bInReplay && !`REPLAY.bInTutorial)
	{
		InitiateHack();
	}

	`Pres.SetHackUIBusy(true);
	WorldInfo.PlayAkEvent(AkEvent'SoundTacticalUI_Hacking.Scary_Computer_Loop');
}

simulated function PopulateResultsInfo()
{
	local X2HackRewardTemplateManager templateMan;
	local X2HackRewardTemplate Template;
	local int i;
	local array<name> PossibleHackRewards;
	local Hackable HackableObject;
	local string FailText;

	HackableObject = Hackable(HackTargetObject);

	PossibleHackRewards = HackableObject.GetHackRewards(FinalizeHackAbility.GetMyTemplateName());

	templateMan = class'X2HackRewardTemplateManager'.static.GetHackRewardTemplateManager();

	templateMan = class'X2HackRewardTemplateManager'.static.GetHackRewardTemplateManager();
	for( i = 0; i < PossibleHackRewards.Length; i++ )
	{
		Template = templateMan.FindHackRewardTemplate(PossibleHackRewards[i]);

		if( Template == none )
		{
			`RedScreen("{@dkaplan} Hack Reward Template found to be unavailable:" @ PossibleHackRewards[i]);

			continue;
		}
		HackRewards.AddItem(Template);
	}

	for( i = 0; i < HackRewards.Length; i++ )
	{
		Template = HackRewards[i];

		if( i == 0 )
		{
			if( Template.bBadThing )
			{
				FailText = FeedbackHeader;
			}
			else
			{
				FailText = GuaranteedHeader;
			}
		}
		else
		{
			if( HackRewards[0].bBadThing )
			{
				FailText = FeedbackFailText;
			}
			else
			{
				FailText = GuaranteedFailText;
			}
		}

		AS_SetResultInfo(
			i, 
			false, 
			Template.GetFriendlyName(),
			Template.RewardImagePath,
			Template.GetDescription(HackTargetObject),
			strRewardUnlockedLabel, 
			strUnlockChanceLabel, 
			GetHackChance(i) $ "\%", 
			Template.bBadThing,
			FailText);
	}

	HackRollMods = HackableObject.GetHackRewardRollMods();

	//AS_SetMeter(0, MeterValue1, MeterValue2, OverridesReward0, OverridesReward1, MaxHackValue);
}

simulated function float GetHackChance(int RewardIndex)
{
	local X2HackRewardTemplate Template;
	local int HackRollMod;
	
	Template = HackRewards[RewardIndex];

	if( Template.bBadThing )
	{
		`Assert(SelectedHackRewardOption != 0);
		return 100.0 - GetHackChance(SelectedHackRewardOption);
	}
	else if( Template.MinHackSuccess == 0 )
	{
		return 100.0;
	}
	else
	{
		`Assert(HackDefense > 0);

		HackRollMod = ((HackRollMods.Length > RewardIndex) ? HackRollMods[RewardIndex] : 0);

		return Clamp((100.0 - (Template.MinHackSuccess + HackRollMod)) * HackOffense / HackDefense, 0.0, 100.0);
	}
}

simulated function PopulateSoldierInfo()
{
	local XGUnit Unit;

	Unit = XGUnit(UnitState.GetVisualizer());
	
	AS_SetSoldierInfo(class'UIUtilities_Text'.static.GetColoredText(Caps(`GET_RANK_STR(Unit.GetCharacterRank(), Unit.GetVisualizedGameState().GetSoldierClassTemplateName())), euiState_Faded, 17), 
						class'UIUtilities_Text'.static.GetColoredText(Caps(UnitState.GetName(eNameType_Full)), eUIState_Normal, 22), 
						class'UIUtilities_Text'.static.GetColoredText(Caps(UnitState.GetNickName(false)), eUIState_Header, 30),
						class'UIUtilities_Image'.static.GetRankIcon(Unit.GetCharacterRank(), Unit.GetVisualizedGameState().GetSoldierClassTemplateName()),
						UnitState.GetSoldierClassTemplate().IconImage,
						strHackAbilityLabel,
						string(int(HackOffense)));
}

simulated function PopulateEnemyInfo()
{
	local XComInteractiveLevelActor VisActor;
	local string factionName;
	local X2CharacterTemplate template;

	if(TargetUnit != none)
	{
		template = TargetUnit.GetMyTemplate();

		if(template.bIsAdvent)
		{
			factionName = m_strAdventInfoTitle;
		}
		else if(template.bIsAlien)
		{
			factionName = m_strAlienInfoTitle;
		}

		AS_SetEnemyInfo(class'UIUtilities_Text'.static.GetColoredText(Caps(factionName), euiState_Faded, 17), 
							class'UIUtilities_Text'.static.GetColoredText(Caps(TargetUnit.GetName(eNameType_Full)), eUIState_Normal, 22),
							"img:///" $ template.strHackIconImage,
							strHackAbilityLabel,
							string(int(HackDefense)));
	}
	else
	{
		VisActor = XComInteractiveLevelActor(ObjectState.GetVisualizer());
		AS_SetEnemyInfo("", 
						class'UIUtilities_Text'.static.GetColoredText(Caps(ObjectState.GetLootingName()), eUIState_Normal, 22),
						"img:///" $ class'Object'.static.PathName(VisActor.HackingIcon),
						strHackAbilityLabel,
						string(int(HackDefense)));
	}
}

simulated function bool OnCancel(optional string arg = "")
{
	local XComGameStateContext_Ability CancelContext;

	`assert(!m_hackStarted);
	`assert(CancelHackAbility != none);

	CancelContext = class'XComGameStateContext_Ability'.static.BuildContextFromAbility(CancelHackAbility, OriginalContext.InputContext.PrimaryTarget.ObjectID);
	`GAMERULES.SubmitGameStateContext(CancelContext);

	ClearTimer('StartScaryComputerLoopAkEvent');

	WorldInfo.PlayAkEvent(AkEvent'SoundTacticalUI_Hacking.Stop_Hacking_All');

	HackEnded();

	return true;
}

simulated function OnMouseEvent(int cmd, array<string> args)
{
	switch(cmd)
	{
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_UP:
		if(!m_hackStarted)
		{
			if(args[args.Length - 1] == "cancelButton")
			{
				if( CanCancel() )
				{
					OnCancel();
				}
			}
			else if( args[args.Length - 2] == "hackButton" )
			{
			    InitiateHack();
		    }
		}
		break;
	}
}

simulated function bool OnUnrealCommand(int ucmd, int ActionMask)
{
	local bool bHandled;

	// Ignore releases, just pay attention to presses.
	if ( !CheckInputIsReleaseOrDirectionRepeat(ucmd, ActionMask) )
		return true;
	
	if( bWaitingForInput )
	{
		HackEnded();
	}

	bHandled = false;
	switch(ucmd)
	{
		case (class'UIUtilities_Input'.const.FXS_BUTTON_A) :
		case (class'UIUtilities_Input'.const.FXS_KEY_ENTER):
		case (class'UIUtilities_Input'.const.FXS_KEY_SPACEBAR):
			
			if( !m_hackStarted )
			{
				InitiateHack();
				bHandled = true;
			}
			break;

		case (class'UIUtilities_Input'.const.FXS_BUTTON_B):
		case (class'UIUtilities_Input'.const.FXS_KEY_ESCAPE):
		case class'UIUtilities_Input'.const.FXS_R_MOUSE_DOWN:
			if( CanCancel() )
			{
				OnCancel();			
				bHandled = true;
			}
			else
			{
				//Consider a cancel handled as well ( ie. don't bring up the pause menu )
				bHandled = true;
			}
			break;
		case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_LEFT:
		case class'UIUtilities_Input'.const.FXS_DPAD_LEFT:
			if(!m_hackStarted) //bsg-crobinson (5.17.17): Don't allow movement if hack has started
			{
				SelectedHackRewardOption = 1;
				HighlightedHackRewardOption = 1;
				RefreshPreviewState();
			}
			break;
		
		case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_RIGHT:
		case class'UIUtilities_Input'.const.FXS_DPAD_RIGHT:
			if(!m_hackStarted) //bsg-crobinson (5.17.17): Don't allow movement if hack has started
			{
				SelectedHackRewardOption = 2;
				HighlightedHackRewardOption = 2;
				RefreshPreviewState();
			}
			break;
	}

	// consume all other input
	return super.OnUnrealCommand(ucmd, ActionMask) || bHandled;
}

simulated function OnCommand( string cmd, string arg )
{
	switch(cmd)
	{
	case "HackEnded":
		WorldInfo.PlayAkEvent(AkEvent'SoundTacticalUI_Hacking.Stop_Hack_Bar_Fill');
		if (`REPLAY.bInReplay && !`REPLAY.bInTutorial)
		{
			HackEnded();
		}
		else
		{
		bWaitingForInput = true;
		}
		break;
	case "UnlockReward":
		switch(m_rewardsTaken)
		{
		case 0:
			WorldInfo.PlayAkEvent(AkEvent'SoundTacticalUI_Hacking.Unlock_First_Item');
			break;
		case 1:
			WorldInfo.PlayAkEvent(AkEvent'SoundTacticalUI_Hacking.Unlock_Second_Item');
			break;
		case 2:
			WorldInfo.PlayAkEvent(AkEvent'SoundTacticalUI_Hacking.Unlock_Third_Item');
			break;
		default:
			WorldInfo.PlayAkEvent(AkEvent'SoundTacticalUI_Hacking.Do_The_Hack');
		}

		if (OnHackingRewardUnlocked != none)
		{
			OnHackingRewardUnlocked(m_rewardsTaken);
		}
		m_rewardsTaken++;
		
		break;

	case "SelectReward":
		SelectedHackRewardOption = int(arg);
		RefreshPreviewState();
		break;

	case "onReceiveFocus":
		HighlightedHackRewardOption = int(arg);
		RefreshPreviewState();
		break;

	case "onLoseFocus":
		HighlightedHackRewardOption = -1;
		RefreshPreviewState();
		break;
	}
}

function HackEnded()
{
	// close this UI
	if( OnHackingComplete != None )
	{
		OnHackingComplete();
	}
	`Pres.SetHackUIBusy(false);
}


function InitiateHack()
{
	local int RewardIndex;
	local XComGameStateContext_Ability FinalContext;
	local int DisplayedScore, SelectedHackChance;
	local array<string> HackFriendlyNames;
	local array<string> HackDescriptions;
	local string FinalPressButtonToContinueStr;

	`assert(!m_hackStarted);
	`assert(FinalizeHackAbility != none);
	m_hackStarted = true;

	//Submitting the FinalizeHack game state will end up resetting the random duration of the hack (it's stored in the template, for some awful reason).
	//So we need to cache the description up-front to properly display the reward that the user received. Unfortunately, we don't know which one they got,
	//until after we've submitted the context. So, cache them all.
	for (RewardIndex = 0; RewardIndex < HackRewards.Length; RewardIndex++)
	{
		HackFriendlyNames.AddItem(HackRewards[RewardIndex].GetFriendlyName());
		HackDescriptions.AddItem(HackRewards[RewardIndex].GetDescription(None));
	}

	FinalContext = class'XComGameStateContext_Ability'.static.BuildContextFromAbility(FinalizeHackAbility, OriginalContext.InputContext.PrimaryTarget.ObjectID);
	`GAMERULES.SubmitGameStateContext(FinalContext);

	SelectedHackChance = GetHackChance(SelectedHackRewardOption);
	DisplayedScore = 100 - FinalContext.ResultContext.StatContestResult;

	if( FinalContext.ResultContext.StatContestResult < SelectedHackChance )
	{
		RewardIndex = SelectedHackRewardOption;
	}
	else
	{
		RewardIndex = 0;
		DisplayedScore = Max(DisplayedScore, Rand(100 - SelectedHackChance - 1) ); // roll a 2nd time in the range 0-Selected chance; display best result.  Note this does not affect the outcome of the hack at all, is only used for a more exciting display
	}

	AS_SetMeterRolledScore(DisplayedScore);

	FinalPressButtonToContinueStr = Repl(HackCompleteConsoleAnyKeyToContinue, "%A", class 'UIUtilities_Input'.static.HTML(class 'UIUtilities_Input'.static.GetAdvanceButtonIcon(),,-6));

	AS_UpdateHackComplete(
		HackRewards[RewardIndex].bBadThing ? HackFailedLabel : HackSuccessLabel,	// Title
		HackFriendlyNames[RewardIndex],									// Reward Name
		HackDescriptions[RewardIndex],								// Reward Description
		`ISCONTROLLERACTIVE ? FinalPressButtonToContinueStr :HackCompleteAnyKeyToContinue,												// Button Hint
		RewardIndex
		);

	AS_InitHack();
	WorldInfo.PlayAkEvent(AkEvent'SoundTacticalUI_Hacking.Do_The_Hack');
}


function RefreshPreviewState()
{
	local int Index;
	local int Score;
	local bool bHighlightedOptionDisplayed;

	for( Index = 0; Index < 3; ++Index )
	{
		Score = Round(GetHackChance(Index));

		AS_SetRewardPanelPercent(Index, string(Score) $ "\%");

		if( Index == SelectedHackRewardOption )
		{
			AS_SetRewardPanelSelected(Index, true);
			AS_SetRewardPanelHighlight(Index, false);

			AS_SetMeterMarkerSelection(Score);
		}
		else if( Index == HighlightedHackRewardOption )
		{
			AS_SetRewardPanelSelected(Index, false);
			AS_SetRewardPanelHighlight(Index, true);

			AS_SetMeterMarkerPreview(Score);

			bHighlightedOptionDisplayed = true;
		}
		else
		{
			AS_SetRewardPanelSelected(Index, false);
			AS_SetRewardPanelHighlight(Index, false);
		}
	}

	AS_ShowMeterMarkerPreview(bHighlightedOptionDisplayed);
}

// ===========================================================================
//  ACTIONSCRIPT INTERFACE:
// ===========================================================================
simulated function AS_PopulateDebugData()
{
	Movie.ActionScriptVoid(MCPath $ ".onPopulateDebugData");
}
simulated function AS_InitHack()
{
	Movie.ActionScriptVoid(MCPath $ ".AnimateMeter");
}
simulated function AS_LocalizeButton(string buttonLabel)
{
	Movie.ActionScriptVoid(MCPath $ ".UpdateButton");
}
simulated function AS_SetChooseRewards(string buttonLabel)
{
	Movie.ActionScriptVoid(MCPath $ ".SetChooseRewards");
}


simulated function AS_SetResultInfo(
	int rewardID, 
	bool bUnlocked, 
	string unlockTitle, 
	string unlockImage, 
	string unlockDescription, 
	string unlockLabel, 
	string unlockChanceLabel, 
	string unlockChance, 
	bool bBadThing,
	string failText)
{
	Movie.ActionScriptVoid(MCPath $ ".UpdateRewardPanel");
}


simulated function AS_UpdateHackComplete(string Title, string Reward, string Description, string Hint, int Index)
{
	Movie.ActionScriptVoid(MCPath $ ".UpdateHackComplete");
}


simulated function AS_SetSoldierInfo(string rank, string unitName, string nickname, string rankPath, string unitClass, string hackLabel, string hackValue)
{
	movie.ActionScriptVoid(MCPath $".UpdateSoldier");
}
simulated function AS_SetEnemyInfo(string faction, string unitName, string image, string hackLabel, string hackValue)
{
	movie.ActionScriptVoid(MCPath $".UpdateEnemy");
}

simulated function AS_SetMeterRolledScore(int RolledScore)
{
	movie.ActionScriptVoid(MCPath $".SetMeterRolledScore");
}

simulated function AS_SetMeterMarkerSelection(int SelectedScore)
{
	movie.ActionScriptVoid(MCPath $".SetMeterMarkerSelection");
}

simulated function AS_SetMeterMarkerPreview(int HiglightedScore)
{
	movie.ActionScriptVoid(MCPath $".SetMeterMarkerPreview");
}

simulated function AS_ShowMeterMarkerPreview(bool bVisible)
{
	movie.ActionScriptVoid(MCPath $".ShowMeterMarkerPreview");
}

simulated function AS_SetRewardPanelPercent(int PanelIndex, string Score)
{
	movie.ActionScriptVoid(MCPath $".SetRewardPanelPercent");
}

simulated function AS_SetRewardPanelSelected(int PanelIndex, bool bSelected)
{
	movie.ActionScriptVoid(MCPath $".SetRewardPanelSelected");
}

simulated function AS_SetRewardPanelHighlight(int PanelIndex, bool bHighlighted)
{
	movie.ActionScriptVoid(MCPath $".SetRewardPanelHighlight");
}


// ===========================================================================
//  DEFAULTS:
// ===========================================================================
defaultproperties
{
	bHideOnLoseFocus = false;
	bShowDuringCinematic = true;
	m_introDuration = 1; // duration of intro animation (in seconds)
	m_hackDuration = 3; // duration of hacking sequence (in seconds)

	Package       = "/ package/gfxHackingScreen/HackingScreen";

	m_hackStarted = false;
}
