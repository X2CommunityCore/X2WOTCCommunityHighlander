//---------------------------------------------------------------------------------------
 //  FILE:    UITacticalHUD_ShotWings.uc
 //  AUTHOR:  Brit Steiner --  11/2014
 //  PURPOSE: Pop-out wings for the player's current shot stats used in the TacticalHUD. 
 //---------------------------------------------------------------------------------------
 //  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
 //---------------------------------------------------------------------------------------

class UITacticalHUD_ShotWings extends UIPanel;

var public UIPanel LeftWingArea;
var public UIButton LeftWingButton;
var public UIText HitLabel;
var public UIText HitPercent;
var public UIMask HitMask;
var public UIPanel HitBodyArea;
var public UIStatList HitStatList;

var public UIPanel RightWingArea;
var public UIButton RightWingButton;

var public UIText DamageLabel;
var public UIText DamagePercent;
var public UIMask DamageMask;
var public UIPanel DamageBodyArea;
var public UIStatList DamageStatList;

var public UIText CritLabel;
var public UIText CritPercent;
var public UIMask CritMask;
var public UIPanel CritBodyArea;
var public UIStatList CritStatList;

var public UIScrollingText TargetName;

var bool bLeftWingOpen;
var bool bRightWingOpen;
var bool bLeftWingWasOpen;
var bool bRightWingWasOpen;

simulated function UITacticalHUD_ShotWings InitShotWings(optional name InitName, optional name InitLibID)
{
	local int TmpInt, ArrowButtonWidth, ArrowButtonOffset, StatsWidth, StatsOffset;
	local UIPanel HitLine, CritLine, DamageLine, HitBG, CritBG, LeftContainer, RightContainer; 

	InitPanel(InitName, InitLibID);

	StatsWidth = 188;
	StatsOffset = 24;
	ArrowButtonWidth = 16;
	ArrowButtonOffset = 4;

	// ----------
	// The wings are actually contained within the ShotHUD so they animate in and anchor properly -sbatista
	LeftWingArea = Spawn(class'UIPanel', UITacticalHUD(Screen).m_kShotHUD); 
	LeftWingArea.bAnimateOnInit = false;
	LeftWingArea.InitPanel('leftWing');
	
	HitBG = Spawn(class'UIPanel', LeftWingArea).InitPanel('wingBG');
	HitBG.bAnimateOnInit = false;
	HitBG.ProcessMouseEvents(LeftWingMouseEvent);

	LeftContainer = Spawn(class'UIPanel', LeftWingArea);
	LeftContainer.bAnimateOnInit = false;
	LeftContainer.InitPanel('wingContainer');

	LeftWingButton = Spawn(class'UIButton', LeftContainer);
	LeftWingButton.LibID = 'X2DrawerButton';
	LeftWingButton.bAnimateOnInit = false;
	LeftWingButton.InitButton(,,OnWingButtonClicked).SetPosition(ArrowButtonOffset, (height - 26) * 0.5);
	LeftWingButton.MC.ChildFunctionString("bg.arrow", "gotoAndStop", bLeftWingOpen ? "right" : "left");

	HitPercent = Spawn(class'UIText', LeftContainer);
	HitPercent.bAnimateOnInit = false;
	HitPercent.InitText('HitPercent');
	HitPercent.SetWidth(StatsWidth); 
	HitPercent.SetPosition(StatsOffset, 0);
	HitLabel = Spawn(class'UIText', LeftContainer);
	HitLabel.bAnimateOnInit = false;
	HitLabel.InitText('HitLabel');
	HitLabel.SetPosition(StatsOffset, 0);

	HitLine = Spawn(class'UIPanel', LeftContainer);
	HitLine.bAnimateOnInit = false;
	HitLine.InitPanel('HitHeaderLine', class'UIUtilities_Controls'.const.MC_GenericPixel);
	HitLine.SetPosition(StatsOffset, 24);
	HitLine.SetSize(StatsWidth, 2);
	HitLine.SetAlpha(50);

	TmpInt = HitLine.Y + 4;

	HitBodyArea = Spawn(class'UIPanel', LeftContainer); 
	HitBodyArea.bAnimateOnInit = false;
	HitBodyArea.InitPanel('HitBodyArea').SetPosition(HitLine.X, TmpInt);
	HitBodyArea.width = StatsWidth; 
	HitBodyArea.height = height - TmpInt;

	HitMask = Spawn(class'UIMask', LeftContainer).InitMask(, HitBodyArea);
	HitMask.SetPosition(HitBodyArea.X, HitBodyArea.Y); 
	HitMask.SetSize(StatsWidth, Height - 10);

	HitStatList = Spawn(class'UIStatList', HitBodyArea);
	HitStatList.bAnimateOnInit = false;
	HitStatList.InitStatList('StatListLeft',,,, HitBodyArea.Width, HitBodyArea.Height, 0, 0);

	// -----------
	// The wings are actually contained within the ShotHUD so they animate in and anchor properly -sbatista
	RightWingArea = Spawn(class'UIPanel', UITacticalHUD(Screen).m_kShotHUD); 
	RightWingArea.bAnimateOnInit = false;
	RightWingArea.InitPanel('rightWing');
	
	CritBG = Spawn(class'UIPanel', RightWingArea);
	CritBG.bAnimateOnInit = false;
	CritBG.InitPanel('wingBG');
	CritBG.ProcessMouseEvents(RightWingMouseEvent);

	RightContainer = Spawn(class'UIPanel', RightWingArea);
	RightContainer.bAnimateOnInit = false;
	RightContainer.InitPanel('wingContainer');

	RightWingButton = Spawn(class'UIButton', RightContainer);
	RightWingButton.LibID = 'X2DrawerButton';
	RightWingButton.bAnimateOnInit = false;
	RightWingButton.InitButton(,,OnWingButtonClicked).SetPosition(-ArrowButtonWidth - ArrowButtonOffset, (height - 26) * 0.5);
	RightWingButton.MC.FunctionString("gotoAndStop", "right");
	RightWingButton.MC.ChildFunctionString("bg.arrow", "gotoAndStop", bRightWingOpen ? "right" : "left");


	DamagePercent = Spawn(class'UIText', RightContainer);
	DamagePercent.bAnimateOnInit = false;
	DamagePercent.InitText('DamagePercent');
	DamagePercent.SetWidth(StatsWidth);
	DamagePercent.SetPosition(-StatsWidth - StatsOffset, 0);
	DamageLabel = Spawn(class'UIText', RightContainer);
	DamageLabel.bAnimateOnInit = false;
	DamageLabel.InitText('DamageLabel');
	DamageLabel.SetWidth(StatsWidth);
	DamageLabel.SetPosition(-StatsWidth - StatsOffset, 0);

	DamageLine = Spawn(class'UIPanel', RightContainer);
	DamageLine.bAnimateOnInit = false;
	DamageLine.InitPanel('DamageHeaderLine', class'UIUtilities_Controls'.const.MC_GenericPixel);
	DamageLine.SetSize(StatsWidth, 2);
	DamageLine.SetPosition(-StatsWidth - StatsOffset, 24);
	DamageLine.SetAlpha(50);

	TmpInt = DamageLine.Y + 4;

	DamageBodyArea = Spawn(class'UIPanel', RightContainer);
	DamageBodyArea.bAnimateOnInit = false;
	DamageBodyArea.InitPanel('DamageBodyArea').SetPosition(DamageLine.X, TmpInt);
	DamageBodyArea.width = StatsWidth;
	DamageBodyArea.height = height / 2 - TmpInt;

	DamageMask = Spawn(class'UIMask', RightContainer).InitMask(, DamageBodyArea);
	DamageMask.SetPosition(DamageBodyArea.X, DamageBodyArea.Y);
	DamageMask.SetSize(StatsWidth, DamageBodyArea.height);

	DamageStatList = Spawn(class'UIStatList', DamageBodyArea);
	DamageStatList.bAnimateOnInit = false;
	DamageStatList.InitStatList('DamageStatList', , , , DamageBodyArea.Width, DamageBodyArea.Height, 0, 0);


	TmpInt = height / 2 + 4;

	CritPercent = Spawn(class'UIText', RightContainer);
	CritPercent.bAnimateOnInit = false;
	CritPercent.InitText('CritPercent');
	CritPercent.SetWidth(StatsWidth); 
	CritPercent.SetPosition(-StatsWidth - StatsOffset, TmpInt);
	CritLabel = Spawn(class'UIText', RightContainer);
	CritLabel.bAnimateOnInit = false;
	CritLabel.InitText('CritLabel');
	CritLabel.SetWidth(StatsWidth);
	CritLabel.SetPosition(-StatsWidth - StatsOffset, TmpInt);

	CritLine = Spawn(class'UIPanel', RightContainer);
	CritLine.bAnimateOnInit = false;
	CritLine.InitPanel('CritHeaderLine', class'UIUtilities_Controls'.const.MC_GenericPixel);
	CritLine.SetSize(StatsWidth, 2);
	CritLine.SetPosition(-StatsWidth - StatsOffset, TmpInt + 24);
	CritLine.SetAlpha(50);

	TmpInt = CritLine.Y + 4;

	CritBodyArea = Spawn(class'UIPanel', RightContainer); 
	CritBodyArea.bAnimateOnInit = false;
	CritBodyArea.InitPanel('CritBodyArea').SetPosition(CritLine.X, TmpInt);
	CritBodyArea.width = StatsWidth;
	CritBodyArea.height = height - TmpInt; 

	CritMask = Spawn(class'UIMask', RightContainer).InitMask(, CritBodyArea);
	CritMask.SetPosition(CritBodyArea.X, CritBodyArea.Y); 
	CritMask.SetSize(StatsWidth, CritBodyArea.height);

	CritStatList = Spawn(class'UIStatList', CritBodyArea);
	CritStatList.bAnimateOnInit = false;
	CritStatList.InitStatList('StatListLeft',,,, CritBodyArea.Width, CritBodyArea.Height, 0, 0);

	Hide();

	return self; 
}

simulated function Show()
{
	local int ScrollHeight;

	super.Show();

	if(UITacticalHUD(Screen) != none)
		RefreshData();
	else
		PopulateDebugData();

	if(bIsVisible)
	{
		LeftWingArea.Show();
		RightWingArea.Show();

		HitBodyArea.ClearScroll();
		DamageBodyArea.ClearScroll();
		CritBodyArea.ClearScroll();
		HitBodyArea.MC.SetNum("_alpha", 100);
		DamageBodyArea.MC.SetNum("_alpha", 100);
		CritBodyArea.MC.SetNum("_alpha", 100);
	
		//This will reset the scrolling upon showing this tooltip.
		ScrollHeight = (HitStatList.height > HitBodyArea.height ) ? HitStatList.height : HitBodyArea.height; 
		HitBodyArea.AnimateScroll(ScrollHeight, HitBodyArea.height);

		ScrollHeight = (DamageStatList.height > DamageBodyArea.height ) ? DamageStatList.height : DamageBodyArea.height;
		DamageBodyArea.AnimateScroll(ScrollHeight, DamageBodyArea.height);

		ScrollHeight = (CritStatList.height > CritBodyArea.height) ? CritStatList.height : CritBodyArea.height;
		CritBodyArea.AnimateScroll(ScrollHeight, CritBodyArea.height);
	}
}

simulated function RefreshData()
{
	local StateObjectReference	kEnemyRef;
	local StateObjectReference	Shooter, Target; 
	local AvailableAction       kAction;
	local AvailableTarget		kTarget;
	local XComGameState_Ability AbilityState;
	local ShotBreakdown         Breakdown;
	local UIHackingBreakdown    kHackingBreakdown;
	local int                   TargetIndex, iShotBreakdown;
	local ShotModifierInfo      ShotInfo;
	local bool bMultiShots;
	local string TmpStr;
	local X2TargetingMethod     TargetingMethod;
	local WeaponDamageValue		MinDamageValue, MaxDamageValue;
	local int					AllowsShield;

	kAction = UITacticalHUD(Screen).m_kAbilityHUD.GetSelectedAction();
	kEnemyRef = XComPresentationLayer(Movie.Pres).GetTacticalHUD().m_kEnemyTargets.GetSelectedEnemyStateObjectRef();
	AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(kAction.AbilityObjectRef.ObjectID));

	// Bail if we have  nothing to show -------------------------------------
	if( AbilityState == none )
	{
		Hide();
		return; 
	}

	//Don't show this normal shot breakdown for the hacking action ------------
	AbilityState.GetUISummary_HackingBreakdown( kHackingBreakdown, kEnemyRef.ObjectID );
	if( kHackingBreakdown.bShow ) 
	{
		Hide();
		return; 
	}

	// Refresh game data  ------------------------------------------------------

	// If no targeted icon, we're actually hovering the shot "to hit" info field, 
	// so use the selected enemy for calculation.
	TargetingMethod = UITacticalHUD(screen).GetTargetingMethod();
	if (TargetingMethod != none)
		TargetIndex = TargetingMethod.GetTargetIndex();
	if( kAction.AvailableTargets.Length > 0 && TargetIndex < kAction.AvailableTargets.Length )
	{
		kTarget = kAction.AvailableTargets[TargetIndex];
	}

	Shooter = AbilityState.OwnerStateObject; 
	Target = kTarget.PrimaryTarget; 

	iShotBreakdown = AbilityState.LookupShotBreakdown(Shooter, Target, AbilityState.GetReference(), Breakdown);

	// Hide if requested -------------------------------------------------------
	if (Breakdown.HideShotBreakdown)
	{
		Hide();

		if(bLeftWingOpen)
		{
			bLeftWingWasOpen = true;
			OnWingButtonClicked(LeftWingButton);
		}

		if(bRightWingOpen)
		{
			bRightWingWasOpen = true;
			OnWingButtonClicked(RightWingButton);
		}

		LeftWingButton.Hide();
		RightWingButton.Hide();
		return; 
	}
	else
	{
		UITacticalHUD(screen).m_kShotHUD.MC.FunctionVoid( "ShowHit" );
		UITacticalHUD(screen).m_kShotHUD.MC.FunctionVoid( "ShowCrit" );

		LeftWingButton.Show();
		RightWingButton.Show();

		if( !bLeftWingOpen && bLeftWingWasOpen )
		{
			bLeftWingWasOpen = false;
			OnWingButtonClicked(LeftWingButton);
		}

		if( !bRightWingOpen && bRightWingWasOpen )
		{
			bRightWingWasOpen = false;
			OnWingButtonClicked(RightWingButton);
		}
	}

	if (Target.ObjectID == 0)
	{
		Hide();
		return; 
	}

	// Gameplay special hackery for multi-shot display. -----------------------
	if(iShotBreakdown != Breakdown.FinalHitChance)
	{
		bMultiShots = true;
		ShotInfo.ModType = eHit_Success;
		ShotInfo.Value = iShotBreakdown - Breakdown.FinalHitChance;
		ShotInfo.Reason = class'XLocalizedData'.default.MultiShotChance;
		Breakdown.Modifiers.AddItem(ShotInfo);
		Breakdown.FinalHitChance = iShotBreakdown;
	}

	// Now update the UI ------------------------------------------------------
	Breakdown.Modifiers.Sort(SortModifiers);

	if (bMultiShots)
		HitLabel.SetHtmlText(class'UIUtilities_Text'.static.StyleText(class'XLocalizedData'.default.MultiHitLabel, eUITextStyle_Tooltip_StatLabel));
	else
		HitLabel.SetHtmlText(class'UIUtilities_Text'.static.StyleText(class'XLocalizedData'.default.HitLabel, eUITextStyle_Tooltip_StatLabel));

	TmpStr = ((Breakdown.bIsMultishot) ? Breakdown.MultiShotHitChance : Breakdown.FinalHitChance) $ "%";
	HitPercent.SetHtmlText(class'UIUtilities_Text'.static.StyleText(TmpStr, eUITextStyle_Tooltip_StatValue));
	HitStatList.RefreshData(ProcessHitCritBreakdown(Breakdown, eHit_Success));

	if(Breakdown.ResultTable[eHit_Crit] >= 0)
	{
		AbilityState.GetDamagePreview(Target, MinDamageValue, MaxDamageValue, AllowsShield);

		DamageLabel.SetHtmlText(class'UIUtilities_Text'.static.StyleText(class'XLocalizedData'.default.DamageLabel, eUITextStyle_Tooltip_StatLabel));
		TmpStr = string(MinDamageValue.Damage) $ "-" $ string(MaxDamageValue.Damage);
		DamagePercent.SetHtmlText(class'UIUtilities_Text'.static.StyleText(TmpStr, eUITextStyle_Tooltip_StatValue));
		DamageStatList.RefreshData(ProcessDamageBreakdown(MinDamageValue));

		CritLabel.SetHtmlText(class'UIUtilities_Text'.static.StyleText(Breakdown.SpecialCritLabel == "" ? class'XLocalizedData'.default.CritLabel : Breakdown.SpecialCritLabel, eUITextStyle_Tooltip_StatLabel));
		TmpStr = string(Breakdown.ResultTable[eHit_Crit]) $ "%";
		CritPercent.SetHtmlText(class'UIUtilities_Text'.static.StyleText(TmpStr, eUITextStyle_Tooltip_StatValue));
		CritStatList.RefreshData(ProcessHitCritBreakdown(Breakdown, eHit_Crit));
		RightWingArea.Show();
	}
	else
		RightWingArea.Hide();
}

simulated function PopulateDebugData()
{
	local int i;
	local ShotBreakdown Breakdown;
	local ShotModifierInfo ShotInfo;

	Breakdown.Modifiers.Length = 0;
	for(i = 0; i < 10; i++)
	{
		ShotInfo.ModType = eHit_Success;
		ShotInfo.Value = 10;
		ShotInfo.Reason = "Test "$i;
		Breakdown.Modifiers.AddItem(ShotInfo);
	}

	HitLabel.SetHtmlText(class'UIUtilities_Text'.static.StyleText(class'XLocalizedData'.default.HitLabel, eUITextStyle_Tooltip_StatLabel));
	HitPercent.SetHtmlText(class'UIUtilities_Text'.static.StyleText("##%", eUITextStyle_Tooltip_StatValue));
	HitStatList.RefreshData(ProcessHitCritBreakdown(Breakdown, eHit_Success));
	LeftWingArea.Show();

	Breakdown.Modifiers.Length = 0;
	for(i = 0; i < 10; i++)
	{
		ShotInfo.ModType = eHit_Crit;
		ShotInfo.Value = 10;
		ShotInfo.Reason = "Test "$i;
		Breakdown.Modifiers.AddItem(ShotInfo);
	}

	CritLabel.SetHtmlText(class'UIUtilities_Text'.static.StyleText(Breakdown.SpecialCritLabel == "" ? class'XLocalizedData'.default.CritLabel : Breakdown.SpecialCritLabel, eUITextStyle_Tooltip_StatLabel));
	CritPercent.SetHtmlText(class'UIUtilities_Text'.static.StyleText("##%", eUITextStyle_Tooltip_StatValue));
	CritStatList.RefreshData(ProcessHitCritBreakdown(Breakdown, eHit_Crit));
	RightWingArea.Show();
}

simulated function int SortModifiers( ShotModifierInfo a, ShotModifierInfo b)
{
	if( B.Value > A.Value )
		return -1;
	else
		return 0; 
}

simulated function array<UISummary_ItemStat> ProcessDamageBreakdown(const out WeaponDamageValue DamageValue)
{
	local array<UISummary_ItemStat> Stats;
	local UISummary_ItemStat Item;
	local int i;
	local string strLabel, strValue, strPrefix;
	local EUIState eState;

	for( i = 0; i < DamageValue.BonusDamageInfo.Length; i++ )
	{
		if( DamageValue.BonusDamageInfo[i].Value < 0 )
		{
			eState = eUIState_Bad;
			strPrefix = "";
		}
		else
		{
			eState = eUIState_Normal;
			strPrefix = "+";
		}

		strLabel = class'UIUtilities_Text'.static.GetColoredText(class'Helpers'.static.GetMessageFromDamageModifierInfo(DamageValue.BonusDamageInfo[i]), eState);
		strValue = class'UIUtilities_Text'.static.GetColoredText(strPrefix $ string(DamageValue.BonusDamageInfo[i].Value), eState);

		Item.Label = strLabel;
		Item.Value = strValue;
		Stats.AddItem(Item);
	}

	return Stats;
}

simulated function array<UISummary_ItemStat> ProcessHitCritBreakdown( ShotBreakdown Breakdown, int eHitType )
{
	local array<UISummary_ItemStat> Stats; 
	local UISummary_ItemStat Item; 
	local int i; 
	local string strLabel, strValue, strPrefix; 
	local EUIState eState; 

	for( i=0; i < Breakdown.Modifiers.Length; i++)
	{		
		if( Breakdown.Modifiers[i].ModType == eHitType )
		{
			if( Breakdown.Modifiers[i].Value < 0 )
			{
				eState = eUIState_Bad;
				strPrefix = "";
			}
			else
			{
				eState = eUIState_Normal; 
				strPrefix = "+";
			}

			strLabel = class'UIUtilities_Text'.static.GetColoredText( Breakdown.Modifiers[i].Reason, eState );
			strValue = class'UIUtilities_Text'.static.GetColoredText( strPrefix $ string(Breakdown.Modifiers[i].Value) $ "%", eState );

			Item.Label = strLabel; 
			Item.Value = strValue;
			Stats.AddItem(Item);
		}
	}

	if( eHitType == eHit_Crit && Stats.length == 1 && Breakdown.ResultTable[eHit_Crit] == 0 )
		Stats.length = 0; 

	return Stats; 
}

simulated function LeftWingMouseEvent(UIPanel Control, int Cmd)
{
	if( Cmd != class'UIUtilities_Input'.const.FXS_L_MOUSE_UP || !LeftWingButton.bIsVisible) return;

	if( bLeftWingOpen )
	{
		LeftWingArea.MC.FunctionString("gotoAndPlay", "in");
		bLeftWingOpen = false;
	}
	else
	{
		LeftWingArea.MC.FunctionString("gotoAndPlay", "out");
		bLeftWingOpen = true;
	}

	LeftWingButton.MC.ChildFunctionString("bg.arrow", "gotoAndStop", bLeftWingOpen ? "right" : "left");
}
simulated function RightWingMouseEvent(UIPanel Control, int Cmd)
{
	if( Cmd != class'UIUtilities_Input'.const.FXS_L_MOUSE_UP || !RightWingButton.bIsVisible) return;

	if( bRightWingOpen )
	{
		RightWingArea.MC.FunctionString("gotoAndPlay", "in");
		bRightWingOpen = false;
	}
	else
	{
		RightWingArea.MC.FunctionString("gotoAndPlay", "out");
		bRightWingOpen = true;
	}

	RightWingButton.MC.ChildFunctionString("bg.arrow", "gotoAndStop", bRightWingOpen ? "right" : "left");
}
simulated function OnWingButtonClicked(UIButton Button)
{
	if(Button == LeftWingButton)
		LeftWingMouseEvent(Button, class'UIUtilities_Input'.const.FXS_L_MOUSE_UP);
	else if(Button == RightWingButton)
		RightWingMouseEvent(Button, class'UIUtilities_Input'.const.FXS_L_MOUSE_UP);
}

//Defaults: ------------------------------------------------------------------------------
defaultproperties
{
	Height = 160;
	bLeftWingOpen = true;
	bRightWingOpen = true;
	MCName = "shotWingsMC";
}