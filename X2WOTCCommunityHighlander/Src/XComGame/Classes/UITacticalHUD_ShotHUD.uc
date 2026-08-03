//----------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UITacticalHUD_ShotHUD.uc
//  AUTHOR:  Tronster
//  PURPOSE: The information panel that is raised for a particular ability/shot 
//           type.
//----------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//----------------------------------------------------------------------------

class UITacticalHUD_ShotHUD extends UIPanel;

//----------------------------------------------------------------------------
// CONSTANTS
//
enum eUI_BonusIcon
{
	eUIBonusIcon_Flanked,
	eUIBonusIcon_Height
};

//Used for mouse hovering.
var string HitMCPath;
var string CritMCPath;
var string ShotButtonPath;

//----------------------------------------------------------------------------
// LOCALIZATION
//
var UIPanel DamageContainer;
var bool bIsShiney; 

var localized string m_sMessageShotUnavailable; //Generic message 
var localized string m_sNoTargetsHelp;
var localized string m_sNoAmmoHelp;
var localized string m_sOverheatedHelp;
var localized string m_sMoveLimitedHelp;

var localized string m_sUnavailable;
var localized string m_sShotChanceLabel;
var localized string m_sCritChanceLabel;
var localized string m_sDamageRangeLabel;

var localized string m_sEndTurnTooltip;
var localized string m_sRevealedTooltip;


var localized string m_sRevealText;
var localized string m_sEndTurnText;
var int TooltipEndTurnID;
var int TooltipRevealID;

//----------------------------------------------------------------------------
// METHODS
//
simulated function UITacticalHUD_ShotHUD InitShotHUD()
{
	InitPanel();

	RefreshTooltips();
	MC.BeginFunctionOp("SetIndicatorText");
	MC.QueueString(m_sRevealText);
	MC.QueueString(class'UIUtilities_Text'.static.AlignRight(m_sEndTurnText));
	MC.EndOp();
	return self;
}

function AnimateShotIn()
{
	MC.FunctionVoid("AnimateShotIn");
}

function AnimateShotOut()
{
	MC.FunctionVoid("AnimateShotOut");
}

function RefreshTooltips()
{
	//ID check is to prevent unnecessary repeated calls to the tooltip manageer 

	if( TooltipEndTurnID == -1 &&  UITacticalHUD(Owner).IsMenuRaised() )
	{
		TooltipEndTurnID = AddTextTooltip("endTurnMC", m_sEndTurnTooltip, Class'UIUtilities'.const.ANCHOR_MIDDLE_LEFT);
		TooltipRevealID = AddTextTooltip("revealedMC", m_sRevealedTooltip, Class'UIUtilities'.const.ANCHOR_MIDDLE_RIGHT);
	}
	
	if( TooltipEndTurnID != -1 && !UITacticalHUD(Owner).IsMenuRaised() )
	{
		Screen.Movie.Pres.m_kTooltipMgr.RemoveTooltipByID(TooltipEndTurnID);
		Screen.Movie.Pres.m_kTooltipMgr.RemoveTooltipByID(TooltipRevealID);

		TooltipEndTurnID = -1;
		TooltipRevealID = -1;
	}
}

simulated function AddTooltip(string childPath, string tooltipText, int newAnchor); //DEPRECATED 
simulated function int AddTextTooltip(string childPath, string tooltipText, int newAnchor)
{
	local UITextTooltip Tooltip;

	Tooltip = Screen.Spawn(class'UITextTooltip', Screen.Movie.Pres.m_kTooltipMgr); 
	Tooltip.InitTextTooltip();
	Tooltip.bFollowMouse = true;
	Tooltip.bRelativeLocation = false;
	Tooltip.tDelay = 0.0; //Instant
	Tooltip.SetAnchor( newAnchor );
	Tooltip.sBody = tooltipText;
	Tooltip.targetPath = string(MCPath) $ "." $ childPath;
	Tooltip.ID = Screen.Movie.Pres.m_kTooltipMgr.AddPreformedTooltip( Tooltip );
	return Tooltip.ID; 
}

simulated function OnMouseEvent(int cmd, array<string> args)
{
	local string target;

	target = args[args.Length-1];

	switch(cmd)
	{
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_IN:
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_OVER:
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_DRAG_OVER:
		switch(target)
		{
		case HitMCPath: UITacticalHUD(Screen).m_kShotInfoWings.LeftWingArea.OnReceiveFocus(); break;
		case CritMCPath: UITacticalHUD(Screen).m_kShotInfoWings.RightWingArea.OnReceiveFocus(); break;
		}
		break;
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_OUT:
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_DRAG_OVER:
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_RELEASE_OUTSIDE:
		switch(target)
		{
		case HitMCPath: UITacticalHUD(Screen).m_kShotInfoWings.LeftWingArea.OnLoseFocus(); break;
		case CritMCPath: UITacticalHUD(Screen).m_kShotInfoWings.RightWingArea.OnLoseFocus(); break;
		}
		break;
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_UP:
		switch(target)
		{
		case ShotButtonPath: UITacticalHUD(Screen).m_kAbilityHUD.OnAccept(); break;
		case HitMCPath: UITacticalHUD(Screen).m_kShotInfoWings.LeftWingMouseEvent(none, cmd); break;
		case CritMCPath: UITacticalHUD(Screen).m_kShotInfoWings.RightWingMouseEvent(none, cmd); break;
		}
		break;
	}
}

simulated function Update()
{
	local bool isValidShot;
	local string ShotName, ShotDescription, ShotDamage;
	local int HitChance, CritChance, TargetIndex, MinDamage, MaxDamage, AllowsShield;
	local ShotBreakdown kBreakdown;
	local StateObjectReference Shooter, Target, EmptyRef; 
	local XComGameState_Ability SelectedAbilityState;
	local X2AbilityTemplate SelectedAbilityTemplate;
	local AvailableAction SelectedUIAction;
	local AvailableTarget kTarget;
	local XGUnit ActionUnit;
	local UITacticalHUD TacticalHUD;
	local UIUnitFlag UnitFlag; 
	local WeaponDamageValue MinDamageValue, MaxDamageValue;
	local X2TargetingMethod TargetingMethod;
	local bool WillBreakConcealment, WillEndTurn;
	local XComGameStateHistory History;

	TacticalHUD = UITacticalHUD(Screen);

	SelectedUIAction = TacticalHUD.GetSelectedAction();
	if (SelectedUIAction.AbilityObjectRef.ObjectID > 0) //If we do not have a valid action selected, ignore this update request
	{
		History = `XCOMHISTORY;

		SelectedAbilityState = XComGameState_Ability(History.GetGameStateForObjectID(SelectedUIAction.AbilityObjectRef.ObjectID));
		SelectedAbilityTemplate = SelectedAbilityState.GetMyTemplate();
		ActionUnit = XGUnit(History.GetGameStateForObjectID(SelectedAbilityState.OwnerStateObject.ObjectID).GetVisualizer());
		TargetingMethod = TacticalHUD.GetTargetingMethod();
		if( TargetingMethod != None )
		{
			TargetIndex = TargetingMethod.GetTargetIndex();
			if( SelectedUIAction.AvailableTargets.Length > 0 && TargetIndex < SelectedUIAction.AvailableTargets.Length )
				kTarget = SelectedUIAction.AvailableTargets[TargetIndex];
		}

		//Update L3 help and OK button based on ability.
		//*********************************************************************************
		if (SelectedUIAction.bFreeAim)
		{
			AS_SetButtonVisibility(Movie.IsMouseActive(), false);
			isValidShot = true;
		}
		else if (SelectedUIAction.AvailableTargets.Length == 0 || SelectedUIAction.AvailableTargets[0].PrimaryTarget.ObjectID < 1)
		{
			AS_SetButtonVisibility(Movie.IsMouseActive(), false);
			isValidShot = false;
		}
		else
		{
			AS_SetButtonVisibility(Movie.IsMouseActive(), Movie.IsMouseActive());
			isValidShot = true;
		}

		//Set shot name / help text
		//*********************************************************************************
		ShotName = SelectedAbilityState.GetMyFriendlyName(kTarget.PrimaryTarget);

		if (SelectedUIAction.AvailableCode == 'AA_Success')
		{
			ShotDescription = SelectedAbilityState.GetMyHelpText();
			if (ShotDescription == "") ShotDescription = "Missing 'LocHelpText' from ability template.";
		}
		else
		{
			if (SelectedUIAction.AvailableCode == 'AA_AbilityUnavailable')
			{
				ShotDescription = SelectedAbilityState.GetMyHelpText();
			}
			else
			{
				ShotDescription = class'X2AbilityTemplateManager'.static.GetDisplayStringForAvailabilityCode(SelectedUIAction.AvailableCode);
			}

			if (ShotDescription == "") 
			{
				ShotDescription = "Missing 'LocHelpText' from ability template.";
			}
		}


		WillBreakConcealment = SelectedAbilityState.MayBreakConcealmentOnActivation(kTarget.PrimaryTarget.ObjectID);
		WillEndTurn = SelectedAbilityState.WillEndTurn();

		AS_SetShotInfo(ShotName, ShotDescription, WillBreakConcealment, WillEndTurn);

		// Disable Shot Button if we don't have a valid target.
		AS_SetShotButtonDisabled(!isValidShot);

		ResetDamageBreakdown();

		// In the rare case that this ability is self-targeting, but has a multi-target effect on units around it,
		// look at the damage preview, just not against the target (self).
		if( SelectedAbilityTemplate.AbilityTargetStyle.IsA('X2AbilityTarget_Self')
		   && SelectedAbilityTemplate.AbilityMultiTargetStyle != none 
		   && SelectedAbilityTemplate.AbilityMultiTargetEffects.Length > 0 )
		{
			SelectedAbilityState.GetDamagePreview(EmptyRef, MinDamageValue, MaxDamageValue, AllowsShield);
		}
		else
		{
			SelectedAbilityState.GetDamagePreview(kTarget.PrimaryTarget, MinDamageValue, MaxDamageValue, AllowsShield);
		}
		MinDamage = MinDamageValue.Damage;
		MaxDamage = MaxDamageValue.Damage;
		
		if (MinDamage > 0 && MaxDamage > 0)
		{
			if (MinDamage == MaxDamage)
				ShotDamage = String(MinDamage);
			else
				ShotDamage = MinDamage $ "-" $ MaxDamage;

			if( MinDamageValue.BonusDamageInfo.Length > 0 || MaxDamageValue.BonusDamageInfo.Length > 0 )
			{
				AddDamage(class'UIUtilities_Text'.static.GetColoredText(ShotDamage, eUIState_Warning2, 38), true);
			}
			else
			{
				AddDamage(class'UIUtilities_Text'.static.GetColoredText(ShotDamage, eUIState_Good, 36), true);
			}
		}

		//Set up percent to hit / crit values 
		//*********************************************************************************

		if (SelectedAbilityTemplate.AbilityToHitCalc != none && SelectedAbilityState.iCooldown == 0)
		{
			Shooter = SelectedAbilityState.OwnerStateObject;
			Target = kTarget.PrimaryTarget;

			SelectedAbilityState.LookupShotBreakdown(Shooter, Target, SelectedAbilityState.GetReference(), kBreakdown);
			HitChance = Clamp(((kBreakdown.bIsMultishot) ? kBreakdown.MultiShotHitChance : kBreakdown.FinalHitChance), 0, 100);
			CritChance = kBreakdown.ResultTable[eHit_Crit];

			if (HitChance > -1 && !kBreakdown.HideShotBreakdown)
			{
				AS_SetShotChance(class'UIUtilities_Text'.static.GetColoredText(m_sShotChanceLabel, eUIState_Header), HitChance);
				AS_SetCriticalChance(class'UIUtilities_Text'.static.GetColoredText(kBreakdown.SpecialCritLabel == "" ? m_sCritChanceLabel : kBreakdown.SpecialCritLabel, eUIState_Header), CritChance);
				TacticalHUD.SetReticleAimPercentages(float(HitChance) / 100.0f, float(CritChance) / 100.0f);
			}
			else
			{
				AS_SetShotChance("", -1);
				AS_SetCriticalChance("", -1);
				TacticalHUD.SetReticleAimPercentages(-1, -1);
			}
		}
		else
		{
			AS_SetShotChance("", -1);
			AS_SetCriticalChance("", -1);
		}
		TacticalHUD.m_kShotInfoWings.Show();	

		//Show preview points, must be negative
		UnitFlag = XComPresentationLayer(Owner.Owner).m_kUnitFlagManager.GetFlagForObjectID(Target.ObjectID);
		if( UnitFlag != none )
		{
			XComPresentationLayer(Owner.Owner).m_kUnitFlagManager.SetAbilityDamagePreview(UnitFlag, SelectedAbilityState, kTarget.PrimaryTarget);
		}

		//@TODO - jbouscher - ranges need to be implemented in a template friendly way.
		//Hide any current range meshes before we evaluate their visibility state
		if (!ActionUnit.GetPawn().RangeIndicator.HiddenGame)
		{
			ActionUnit.RemoveRanges();
		}
	}

	if (`REPLAY.bInTutorial)
	{
		if (SelectedAbilityTemplate != none && `TUTORIAL.IsNextAbility(SelectedAbilityTemplate.DataName) && `TUTORIAL.IsTarget(Target.ObjectID))
		{
			ShowShine();
		}
		else
		{
			HideShine();
		}
	}
	RefreshTooltips();
}

simulated function LowerShotHUD()
{
	ResetDamageBreakdown(true);
	RefreshTooltips();
}

simulated function ResetDamageBreakdown(optional bool RemoveOnly)
{
	local UIText DamageLabel;

	if(DamageContainer != none)
	{
		DamageContainer.Remove();
		if(RemoveOnly) return;
	}
	
	// Spawn container on the screen so anchoring works
	DamageContainer = Spawn(class'UIPanel', self).InitPanel();
	if (UITacticalHUD(Owner).m_kAbilityHUD.ActiveAbilities < 16)
	{
		DamageContainer.AnchorBottomCenter().SetY(-113);
	}
	else
	{
		DamageContainer.AnchorBottomCenter().SetY(-145);
	}
	DamageContainer.bAnimateOnInit = false;
	DamageContainer.Hide(); // start off hidden until text size is realized on all children

	DamageLabel = Spawn(class'UIText', DamageContainer).InitText(, m_sDamageRangeLabel,, RepositionDamageContainer);
	DamageLabel.bAnimateOnInit = false;
	DamageLabel.SetY(12);
}

simulated function AddDamage(string label, optional bool isLastOne)
{
	local UIPanel Divider;
	local UIText Text;

	Text = Spawn(class'UIText', DamageContainer);
	Text.InitText(, label, true, RepositionDamageContainer).SetHeight(50);
	Text.bAnimateOnInit = false;

	if(!isLastOne)
	{
		Divider = Spawn(class'UIPanel', DamageContainer);
		Divider.InitPanel(, class'UIUtilities_Controls'.const.MC_GenericPixel).SetSize(2, 40);
		Divider.bAnimateOnInit = false;
	}
}

// Required because we need to take text size into account
simulated function RepositionDamageContainer()
{
	local int i, NextX;
	local UIPanel Control;
	local UIText Text;
	local bool bAllTextRealized;

	// Do nothing if we just added the label and nothing else
	if(DamageContainer.NumChildren() == 1)
		return;
	
	NextX = 0;
	bAllTextRealized = true;
	for(i = 0; i < DamageContainer.Children.Length; ++i)
	{
		Control = DamageContainer.GetChildAt(i);
		Control.SetX(NextX);
		NextX += 10;

		Text = UIText(Control);
		if( Text != none )
		{
			if( Text.TextSizeRealized )
				NextX += Text.Width;
			else
				bAllTextRealized = false;
		}
	}

	if( bAllTextRealized )
	{
		DamageContainer.SetX(NextX * -0.5);
		DamageContainer.Show();
		DamageContainer.AnimateIn(0);
	}
}

simulated function string FormatModifiers( array<string> arrLabels, array<int> arrValues, optional string sValuePrefix = "", optional string sValueSuffix = "" )
{
	local int i; 
	local string displayString, strLabel, strValue; 

	displayString = "";

	for( i=0; i < arrLabels.length; i++)
	{
		strLabel = arrLabels[i];
		strValue= string(arrValues[i]);

		if( displayString == "" )
				displayString = strLabel @ sValuePrefix $ strValue $ sValueSuffix;
		else
			displayString = displayString $"<br />"  $ strLabel @ sValuePrefix $ strValue $ sValueSuffix;
	}

	return displayString;
}

//==============================================================================
//		FLASH INTERFACE:
//==============================================================================

simulated function AS_SetShotInfo(string shotName, string helpText, bool WillBreakConcealment, bool WillEndTurn)
{
	MC.BeginFunctionOp("SetShotInfo");
	MC.QueueString(shotName);
	MC.QueueString(helpText);
	MC.QueueBoolean(WillBreakConcealment);
	MC.QueueBoolean(WillEndTurn);
	MC.EndOp();
}
simulated function AS_SetCriticalChance( string label, float val )
{
	MC.BeginFunctionOp("SetCriticalChance");
	MC.QueueString(label);
	MC.QueueNumber(val);
	MC.EndOp();
}
simulated function AS_SetShotChance( string label, float val )
{
	MC.BeginFunctionOp("SetShotChance");
	MC.QueueString(label);
	MC.QueueNumber(val);
	MC.EndOp();
}
simulated function AS_SetButtonVisibility(bool BackButtonVisible, bool GermanModeButtonVisible )
{
	MC.BeginFunctionOp("SetButtonVisibility");
	MC.QueueBoolean(BackButtonVisible);
	MC.QueueBoolean(GermanModeButtonVisible);
	MC.EndOp();
}
simulated function AS_SetShotButtonDisabled( bool isDisabled )
{
	MC.FunctionBool("SetShotButtonDisabled", isDisabled);
}

simulated function ShowShine()
{
	if( !bIsShiney )
	{
		bIsShiney = true;
		MC.FunctionVoid("ShowShine");

		AS_SetShotButtonDisabled(false);
	}
}

simulated function HideShine()
{
	if( bIsShiney )
	{
		bIsShiney = false;
		MC.FunctionVoid("HideShine");
	}

	AS_SetShotButtonDisabled(true);
}


//==============================================================================
//		TOOLTIP PATHS:
//==============================================================================

public function string GetHitMCPath()
{
	return MCPath $ "." $ HitMCPath; 
}
public function string GetCritMCPath()
{
	return MCPath $ "." $ CritMCPath; 
}

//==============================================================================
//		DEFAULTS:
//==============================================================================

defaultproperties
{
	MCName = "shotHUD";
	HitMCPath = "statsHit";
	CritMCPath = "statsCrit";
	ShotButtonPath = "shotButton";
	bAnimateOnInit = false;

	Width = 680; 
}