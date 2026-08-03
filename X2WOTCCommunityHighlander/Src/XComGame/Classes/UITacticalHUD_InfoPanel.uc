//----------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UITacticalHUD_InfoPanel.uc
//  AUTHOR:  Tronster
//  PURPOSE: The information panel that is raised for a particular ability/shot 
//           type.
//----------------------------------------------------------------------------
//  Copyright (c) 2010 Firaxis Games, Inc. All rights reserved.
//----------------------------------------------------------------------------

class UITacticalHUD_InfoPanel extends UIPanel;
	//dependson(XGUnit);

//----------------------------------------------------------------------------
// CONSTANTS
//
enum eUI_BonusIcon
{
	eUIBonusIcon_Flanked,
	eUIBonusIcon_Height
};

var private XGUnit      m_kUnit;    //  saved for when the UI needs to update constantly

//Used for mouse hovering.
var string HitMCPath;
var string CritMCPath; 
var string InfoButtonMC; 

//----------------------------------------------------------------------------
// LOCALIZATION
//
var private UIPanel DamageContainer;

var localized string m_sMessageShotUnavailable; //Generic message 
var localized string m_sNoTargetsHelp;
var localized string m_sNoAmmoHelp;
var localized string m_sOverheatedHelp;
var localized string m_sMoveLimitedHelp;

var localized string m_sUnavailable;
var localized string m_sFreeAimingTitle;
var localized string m_sShotChanceLabel;
var localized string m_sCritChanceLabel;
var localized string m_sDamageRangeLabel;

//----------------------------------------------------------------------------
// METHODS
//
simulated function UITacticalHUD_InfoPanel InitInfoPanel()
{
	InitPanel();
	return self;
}

simulated function OnMouseEvent(int cmd, array<string> args)
{
	local string target;

	if( cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_UP)
	{
		target = args[args.Length-1];

		switch(target)
		{
		case "shotButton":
			UITacticalHUD(Screen).m_kAbilityHUD.OnAccept();
			break;
		case "theInfoButton":
			// TODO: Show Enemy Info Immediately 
			break;
		case "theBackButton":
			UITacticalHUD(Screen).CancelTargetingAction();
			break;
		}
	}
}

simulated function Update()
{
	local bool isValidShot;
	local string ShotName, ShotDescription, ShotDamage;
	local int HitChance, CritChance, TargetIndex, MinDamage, MaxDamage, AllowsShield;
	local ShotBreakdown kBreakdown;
	local StateObjectReference Shooter, Target; 
	local XComGameState_Ability SelectedAbilityState;
	local X2AbilityTemplate SelectedAbilityTemplate;
	local AvailableAction SelectedUIAction;
	local AvailableTarget kTarget;
	local XGUnit ActionUnit;
	local UITacticalHUD TacticalHUD;
	local WeaponDamageValue MinDamageValue, MaxDamageValue;

	TacticalHUD = UITacticalHUD(Screen);

	SelectedUIAction = TacticalHUD.GetSelectedAction();

	SelectedAbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(SelectedUIAction.AbilityObjectRef.ObjectID));
	SelectedAbilityTemplate = SelectedAbilityState.GetMyTemplate();
	ActionUnit = XGUnit(`XCOMHISTORY.GetGameStateForObjectID(SelectedAbilityState.OwnerStateObject.ObjectID).GetVisualizer());

	TargetIndex = TacticalHUD.GetTargetingMethod().GetTargetIndex();
	if( SelectedUIAction.AvailableTargets.Length > 0 && TargetIndex < SelectedUIAction.AvailableTargets.Length )
		kTarget = SelectedUIAction.AvailableTargets[TargetIndex];

	//Update L3 help and OK button based on ability.
	//*********************************************************************************
	if( SelectedUIAction.bFreeAim )
	{
		AS_SetButtonVisibility(Movie.IsMouseActive(), false);
		isValidShot = true;
	}
	else if( SelectedUIAction.AvailableTargets.Length == 0 || SelectedUIAction.AvailableTargets[0].PrimaryTarget.ObjectID < 1 )
	{
		AS_SetButtonVisibility(Movie.IsMouseActive(), false);
		isValidShot = false;
	}
	else
	{
		AS_SetButtonVisibility(Movie.IsMouseActive(), Movie.IsMouseActive());
		isValidShot = true;
	}

	// Disable Shot Button if we don't have a valid target.
	AS_SetShotButtonDisabled(!isValidShot);

	//Set shot name / help text
	//*********************************************************************************
	if( SelectedUIAction.bFreeAim )
		ShotName = m_sFreeAimingTitle $":" @ SelectedAbilityState.GetMyFriendlyName();
	else
		ShotName = SelectedAbilityState.GetMyFriendlyName();

	if( SelectedUIAction.AvailableCode == 'AA_Success' )
	{
		ShotDescription = SelectedAbilityState.GetMyHelpText();
		if(ShotDescription == "") ShotDescription = "Missing 'LocHelpText' from ability template.";
	}
	else
	{
		ShotDescription = class'X2AbilityTemplateManager'.static.GetDisplayStringForAvailabilityCode(SelectedUIAction.AvailableCode);
	}

	AS_SetShotInfo( ShotName, ShotDescription );

	ResetDamageBreakdown();

	SelectedAbilityState.GetDamagePreview(kTarget.PrimaryTarget, MinDamageValue, MaxDamageValue, AllowsShield);
	MinDamage = MinDamageValue.Damage;
	MaxDamage = MaxDamageValue.Damage;

	if (MinDamage > 0 && MaxDamage > 0)
	{
		if(MinDamage == MaxDamage)
			ShotDamage = String(MinDamage);
		else
			ShotDamage = MinDamage $ "-" $ MaxDamage;

		AddDamage(class'UIUtilities_Text'.static.GetColoredText(ShotDamage, eUIState_Good, 36), true);
	}

	//Set up percent to hit / crit values 
	//*********************************************************************************
		
	if( SelectedAbilityTemplate.AbilityToHitCalc != none && SelectedAbilityState.iCooldown == 0 )
	{
		Shooter = SelectedAbilityState.OwnerStateObject; 
		Target = kTarget.PrimaryTarget; 

		SelectedAbilityState.LookupShotBreakdown(Shooter, Target, SelectedAbilityState.GetReference(), kBreakdown);
		HitChance = min(((kBreakdown.bIsMultishot ) ? kBreakdown.MultiShotHitChance : kBreakdown.FinalHitChance ), 100);
		CritChance = kBreakdown.ResultTable[eHit_Crit];

		if( HitChance > -1 && !kBreakdown.HideShotBreakdown)
		{
			AS_SetShotChance(class'UIUtilities_Text'.static.GetColoredText(m_sShotChanceLabel, eUIState_Header), HitChance );
			AS_SetCriticalChance(class'UIUtilities_Text'.static.GetColoredText(kBreakdown.SpecialCritLabel == "" ? m_sCritChanceLabel : kBreakdown.SpecialCritLabel, eUIState_Header), CritChance );
			TacticalHUD.SetReticleAimPercentages(float(HitChance) / 100.0f, float(CritChance) / 100.0f);
		}
		else
		{
			AS_SetShotChance("", -1 );
			AS_SetCriticalChance("", -1 );
			TacticalHUD.SetReticleAimPercentages(-1, -1);
		}
	}
	else
	{
		AS_SetShotChance( "", -1 );
	}
	TacticalHUD.m_kShotInfoWings.Show();

	//@TODO - jbouscher - ranges need to be implemented in a template friendly way.
	//Hide any current range meshes before we evaluate their visibility state
	if( !ActionUnit.GetPawn().RangeIndicator.HiddenGame )
	{
		ActionUnit.RemoveRanges();
	}
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
	DamageContainer.AnchorBottomCenter().SetY(-118);
	DamageContainer.bAnimateOnInit = false;
	DamageContainer.Hide(); // start off hidden until text size is realized on all children

	DamageLabel = Spawn(class'UIText', DamageContainer).InitText(, m_sDamageRangeLabel,, RepositionDamageContainer);
	DamageLabel.bAnimateOnInit = false;
	DamageLabel.SetY(12);
}

simulated private function AddDamage(string label, optional bool isLastOne)
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

simulated private function string FormatModifiers( array<string> arrLabels, array<int> arrValues, optional string sValuePrefix = "", optional string sValueSuffix = "" )
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

simulated private function AS_SetShotInfo( string shotName, string helpText )
{
	Movie.ActionScriptVoid(MCPath$".SetShotInfo");
}
simulated private function AS_SetWeaponName( string weaponName )
{
	Movie.ActionScriptVoid(MCPath$".SetWeaponName");
}
simulated private function AS_SetCriticalChance( string label, float val )
{
	Movie.ActionScriptVoid(MCPath$".SetCriticalChance");
}
simulated private function AS_SetShotChance( string label, float val )
{
	Movie.ActionScriptVoid(MCPath$".SetShotChance");
}
simulated function AS_SetButtonVisibility(bool BackButtonVisible, bool GermanModeButtonVisible )
{
	Movie.ActionScriptVoid(MCPath$".SetButtonVisibility");
}
simulated private function AS_SetShotButtonDisabled( bool isDisabled )
{
	Movie.ActionScriptVoid(MCPath$".SetShotButtonDisabled");
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
public function string GetInfoButtonMCPath()
{
	return MCPath $ "." $ InfoButtonMC; 
}

//==============================================================================
//		DEFAULTS:
//==============================================================================

defaultproperties
{
	MCName = "theInfoBox";
	HitMCPath = "infoMC.statsHit";
	CritMCPath = "infoMC.statsCrit";
	InfoButtonMC = "infoMC.theInfoButton";
	bAnimateOnInit = false;

	Width = 680; 
}