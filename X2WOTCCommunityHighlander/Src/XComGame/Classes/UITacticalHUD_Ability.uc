//----------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UITacticalHUD_AbilityContainer.uc
//  AUTHOR:  Brit Steiner, Sam Batista
//  PURPOSE: Containers holding current soldiers ability icons.
//----------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//----------------------------------------------------------------------------

class UITacticalHUD_Ability extends UIPanel;

var localized string m_strCooldownPrefix; 
var localized string m_strChargePrefix;

var string m_strCooldown;
var string m_strCharge;
var string m_strAntennaText;
var string m_strHotkeyLabel;
var bool IsAvailable;
var bool bIsShiney; 
var int Index; 

var X2AbilityTemplate AbilityTemplate;    //Holds TEMPLATE data for the ability referenced by AvailableActionInfo. Ie. what icon does this ability use?

var UIIcon Icon;

simulated function UIPanel InitAbilityItem(optional name InitName)
{
	InitPanel(InitName);
	
	// Link up with existing IconControl in AbilityItem movieclip
	Icon = Spawn(class'UIIcon', self);
	Icon.InitIcon('IconMC',, false, true, 36); // 'IconMC' matches instance name of control in Flash's 'AbilityItem' Symbol
	Icon.SetPosition(-20, -20); // offset because we scale the icon
	
	return self;
}

simulated function ClearData()
{
	if (!bIsInited)
	{
		return;
	}

	SetAvailable(false);	
	SetCooldown("");
	SetCharge("");
	Icon.MC.FunctionVoid("hideSelectionBrackets");
	Icon.LoadIcon("");
	Icon.EnableMouseAutomaticColor(class'UIUtilities_Colors'.const.NORMAL_HTML_COLOR, class'UIUtilities_Colors'.const.BLACK_HTML_COLOR);
	Icon.SetAlpha(0.08f);
	RefreshShine();
	MC.FunctionBool("SetOverwatchButtonHelp", false);
}

simulated function UpdateData(int NewIndex, const out AvailableAction AvailableActionInfo)
{
	local XComGameState_BattleData BattleDataState;
	local bool bCoolingDown;
	local int iTmp;
	local XComGameState_Ability AbilityState;   //Holds INSTANCE data for the ability referenced by AvailableActionInfo. Ie. cooldown for the ability on a specific unit
	local bool OverwatchHelpVisible;
	local bool ReloadHelpVisible;

	// Start Issue #400
	local string BackgroundColor;
	local bool IsObjectiveAbility;
	// End Issue #400
	// Single variable for Issue #749
	local string ForegroundColor;

	Index = NewIndex; 

	//AvailableActionInfo function parameter holds UI-SPECIFIC data such as "is this ability visible to the HUD?" and "is this ability available"?
	AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(AvailableActionInfo.AbilityObjectRef.ObjectID));
	`assert(AbilityState != none);
	AbilityTemplate = AbilityState.GetMyTemplate();

	//Indicate whether the ability is available or not
	SetAvailable(AvailableActionInfo.AvailableCode == 'AA_Success');	

	//Cooldown handling
	bCoolingDown = AbilityState.IsCoolingDown();
	if(bCoolingDown)
		SetCooldown(m_strCooldownPrefix $ string(AbilityState.GetCooldownRemaining()));
	else
		SetCooldown("");

	//Set the icon
	if (AbilityTemplate != None)
	{
		Icon.LoadIcon(AbilityState.GetMyIconImage());
	
		// Set Antenna text, PC only
		if(Movie.IsMouseActive())
			SetAntennaText(class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS(AbilityState.GetMyFriendlyName()));

		OverwatchHelpVisible = AbilityTemplate.DefaultKeyBinding == class'UIUtilities_Input'.const.FXS_KEY_Y &&
			AvailableActionInfo.AvailableCode == 'AA_Success' &&
			UITacticalHUD_AbilityContainer(Owner).GetAbilityStateByHotKey(class'UIUtilities_Input'.const.FXS_KEY_Y) == AbilityState &&
			(!`REPLAY.bInTutorial || `TUTORIAL.IsNextAbility(AbilityTemplate.DataName));

		ReloadHelpVisible = AbilityTemplate.DefaultKeyBinding == class'UIUtilities_Input'.const.FXS_KEY_R &&
			AvailableActionInfo.AvailableCode == 'AA_Success' &&
			UITacticalHUD_AbilityContainer(Owner).GetAbilityStateByHotKey(class'UIUtilities_Input'.const.FXS_KEY_R) == AbilityState &&
			(!`REPLAY.bInTutorial || `TUTORIAL.IsNextAbility(AbilityTemplate.DataName));

		if (OverwatchHelpVisible && `ISCONTROLLERACTIVE)
		{
			MC.FunctionBool("SetOverwatchButtonHelp", true);
		}
		else if (ReloadHelpVisible && `ISCONTROLLERACTIVE)
		{
			MC.FunctionBool("SetReloadButtonHelp", true);
		}
		else
		{
			MC.FunctionBool("SetOverwatchButtonHelp", false);
		}
	}

	iTmp = AbilityState.GetCharges();
	if(iTmp >= 0 && !bCoolingDown)
		SetCharge(m_strChargePrefix $ string(iTmp));
	else
		SetCharge("");

	//Key the color of the ability icon on the source of the ability
	if (AbilityTemplate != None)
	{
		BattleDataState = XComGameState_BattleData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));

		// Start Issue #749
		// Deprecate Issue #400:
		// Instead of calling Icon.EnableMouseAutomaticColor() with different colors right in the if() else switch() statement,
		// store the foreground and icon colors in local variables, and call Icon.EnableMouseAutomaticColor() with them later, 
		// after both override event triggers.

		// Start Issue #400
		//
		// Add an event that allows listeners to override the ability's icon
		// color, whether it's an objective ability or not.
		IsObjectiveAbility = BattleDataState.IsAbilityObjectiveHighlighted(AbilityTemplate);
		if (IsObjectiveAbility || AbilityTemplate.AbilityIconColor != "")
		{
			BackgroundColor = IsObjectiveAbility ? class'UIUtilities_Colors'.const.OBJECTIVEICON_HTML_COLOR : AbilityTemplate.AbilityIconColor;
			TriggerOverrideAbilityIconColor(AbilityState, IsObjectiveAbility, BackgroundColor);
		}
		else
		{
			switch(AbilityTemplate.AbilitySourceName)
			{
			case 'eAbilitySource_Perk':
				BackgroundColor = class'UIUtilities_Colors'.const.PERK_HTML_COLOR;
				break;

			case 'eAbilitySource_Debuff':
				BackgroundColor = class'UIUtilities_Colors'.const.BAD_HTML_COLOR;
				break;

			case 'eAbilitySource_Psionic':
				BackgroundColor = class'UIUtilities_Colors'.const.PSIONIC_HTML_COLOR;
				break;

			case 'eAbilitySource_Commander': 
				BackgroundColor = class'UIUtilities_Colors'.const.GOOD_HTML_COLOR;
				break;
		
			case 'eAbilitySource_Item':
			case 'eAbilitySource_Standard':
			default:
				BackgroundColor = class'UIUtilities_Colors'.const.NORMAL_HTML_COLOR;
			}
		}

		ForegroundColor = class'UIUtilities_Colors'.const.BLACK_HTML_COLOR;

		TriggerOverrideAbilityIconColorImproved(AbilityState, IsObjectiveAbility, BackgroundColor, ForegroundColor);

		Icon.EnableMouseAutomaticColor(BackgroundColor, ForegroundColor);
		// End Issue #749
	}

	// HOTKEY LABEL (pc only)
	if(Movie.IsMouseActive())
	{
		iTmp = eTBC_Ability1 + Index;
		if( iTmp <= eTBC_Ability0 )
			SetHotkeyLabel(PC.Pres.m_kKeybindingData.GetPrimaryOrSecondaryKeyStringForAction(PC.PlayerInput, (eTBC_Ability1 + Index)));
		else
			SetHotkeyLabel("");
	}
	RefreshShine();
}

// Start Issue #400
/// HL-Docs: feature:OverrideAbilityIconColor; issue:400; tags:tactical
/// DEPRECATED - The `OverrideAbilityIconColor` event allows mods to override icon color
/// for objective abilities or abilities that have `AbilityIconColor` property 
/// set in their templates.
/// 
/// This event has been deprecated and should no longer be used. It is kept for
/// backwards compatibility. Use [OverrideAbilityIconColorImproved](../tactical/OverrideAbilityIconColorImproved.md) instead.
///
/// ```event
/// EventID: OverrideAbilityIconColor,
/// EventData: [in bool IsObjective, inout string BackgroundColor],
/// EventSource: XComGameState_Ability (AbilityState),
/// NewGameState: none
/// ```
static final function TriggerOverrideAbilityIconColor(XComGameState_Ability Ability, bool IsObjective, out string IconColor)
{
	local XComLWTuple OverrideTuple;

	OverrideTuple = new class'XComLWTuple';
	OverrideTuple.Id = 'OverrideAbilityIconColor';
	OverrideTuple.Data.Add(2);
	OverrideTuple.Data[0].kind = XComLWTVBool;
	OverrideTuple.Data[0].b = IsObjective;  // the color coming back
	OverrideTuple.Data[1].kind = XComLWTVString;
	OverrideTuple.Data[1].s = IconColor;  // the color coming back

	`XEVENTMGR.TriggerEvent('OverrideAbilityIconColor', OverrideTuple, Ability);

	IconColor = OverrideTuple.Data[1].s;
}
// End Issue #400

// Start Issue #749
/// HL-Docs: feature:OverrideAbilityIconColorImproved; issue:749; tags:tactical,compatibility
/// The `OverrideAbilityIconColorImproved` event allows mods to override background and foreground 
/// colors of ability icons. 
/// The "background" color is the color of the icon itself, and normally varies depending on
/// the `AbilitySourceName` property of the `X2AbilityTemplate`.
/// The "foreground" color is normally always black.
/// Default colors used by the game can be found in the `UIUtilities_Colors` class.
///
/// Performance note: this event gets triggered *a lot*, 
/// so try to avoid complex computations in listeners to reduce the performance hit. 
///
/// ```event
/// EventID: OverrideAbilityIconColorImproved,
/// EventData: [in bool IsObjective, inout string BackgroundColor, inout string ForegroundColor],
/// EventSource: XComGameState_Ability (AbilityState),
/// NewGameState: none
/// ```
///
/// ## Compatibility
/// This event takes precedence over the deprecated event [OverrideAbilityIconColor](../tactical/OverrideAbilityIconColor.md),
/// so any listener that changes ability icon colors will always overwrite any
/// changes made by listeners of the deprecated event.
static final function TriggerOverrideAbilityIconColorImproved(XComGameState_Ability Ability, bool IsObjective, out string BackgroundColor, out string ForegroundColor)
{
	local XComLWTuple OverrideTuple;

	OverrideTuple = new class'XComLWTuple';
	OverrideTuple.Id = 'OverrideAbilityIconColorImproved';
	OverrideTuple.Data.Add(3);
	OverrideTuple.Data[0].kind = XComLWTVBool;
	OverrideTuple.Data[0].b = IsObjective;  
	OverrideTuple.Data[1].kind = XComLWTVString;
	OverrideTuple.Data[1].s = BackgroundColor; 
	OverrideTuple.Data[2].kind = XComLWTVString;
	OverrideTuple.Data[2].s = ForegroundColor;

	`XEVENTMGR.TriggerEvent('OverrideAbilityIconColorImproved', OverrideTuple, Ability);

	BackgroundColor = OverrideTuple.Data[1].s;
	ForegroundColor = OverrideTuple.Data[2].s;
}
// End Issue #749

simulated function OnMouseEvent(int cmd, array<string> args)
{
	local UITacticalHUD_AbilityContainer AbilityContainer;

	super.OnMouseEvent(cmd, args);

	Index = int(GetRightMost(string(MCName)));
	AbilityContainer = UITacticalHUD_AbilityContainer(ParentPanel);

	switch(cmd)
	{
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_IN:
		AbilityContainer.ShowAOE(Index);
		break;
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_OUT:
		AbilityContainer.HideAOE(Index);
		break;

	case class'UIUtilities_Input'.const.FXS_L_MOUSE_UP_DELAYED:
		RefreshShine();
		AbilityContainer.AbilityClicked(Index);
		break;
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_DOUBLE_UP:
		if( AbilityContainer.AbilityClicked(Index) && AbilityContainer.GetTargetingMethod() != none )
		{
			AbilityContainer.OnAccept();
			AbilityContainer.ResetMouse();
			RefreshShine();
		}
		break;
	}
}

simulated function RefreshShine(optional bool bIgnoreMenuStatus = false)
{
	if( `REPLAY.bInTutorial )
	{
		if( ShouldShowShine(bIgnoreMenuStatus) )
		{
			ShowShine();
		}
		else
		{
			HideShine();
		}
	}
}

function bool ShouldShowShine( bool bIgnoreMenuStatus )
{
	if( AbilityTemplate != None && `TUTORIAL.IsNextAbility(AbilityTemplate.DataName) )
	{
		if( bIgnoreMenuStatus )
			return true; 

		if( !UITacticalHUD(Screen).IsMenuRaised() )
			return true; 

		if(UITacticalHUD(Screen).IsMenuRaised() && !UITacticalHUD_AbilityContainer(Owner).IsSelectedValue(Index) )
			return true;
	}
	 
	return false;
}

simulated function SetCooldown(string cooldown)
{
	if(m_strCooldown != cooldown)
	{
		m_strCooldown = cooldown;
		mc.FunctionString("SetCooldown", m_strCooldown);
	}
}

simulated function SetCharge(string charge)
{
	if(m_strCharge != charge)
	{
		m_strCharge = charge;
		mc.FunctionString("SetCharge", m_strCharge);
	}
}

simulated function SetAntennaText(string text)
{
	if(m_strAntennaText != text)
	{
		m_strAntennaText = text;
		mc.FunctionString("SetAntennaText", m_strAntennaText);
	}
}

simulated function SetHotkeyLabel(string hotkey)
{
	if(m_strHotkeyLabel != hotkey)
	{
		m_strHotkeyLabel = hotkey;
		mc.FunctionString("SetHotkeyLabel", m_strHotkeyLabel);
	}
}

simulated function ShowShine()
{
	if( !bIsShiney )
	{
		bIsShiney = true;
		mc.FunctionVoid("ShowShine");
	}
}

simulated function HideShine()
{
	if( bIsShiney )
	{
		bIsShiney = false;
		mc.FunctionVoid("HideShine");
	}
}

simulated function SetAvailable(bool Available)
{
	IsAvailable = Available;
	MC.FunctionBool("SetAvailable", IsAvailable);
}

simulated function Show()
{
	// visibility is controlled by AbilityContainer.as
	//super.Show();
	bIsVisible = true;
}

simulated function Hide()
{
	// visibility is controlled by AbilityContainer.as
	//super.Hide();
	bIsVisible = false;
}

defaultproperties
{
	LibID = "AbilityItem";

	bIsVisible = false; // Start off hidden
	IsAvailable = true;

	// The AbilityItem class in flash implements 'onMouseEvent' to provide custom mouse handling code -sbatista
	bProcessesMouseEvents = false;

	bAnimateOnInit = false;

	bIsShiney = false;
}
