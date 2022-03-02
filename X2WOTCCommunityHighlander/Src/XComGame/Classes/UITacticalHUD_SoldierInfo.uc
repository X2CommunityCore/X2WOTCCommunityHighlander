//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UITacticalHUD_StatsContainer.uc
//  AUTHOR:  Brit Steiner
//  PURPOSE: Statistics on the currently selected soldier.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UITacticalHUD_SoldierInfo extends UIPanel;

var string HackingToolTipTargetPath;
var localized string FocusLevelLabel;
var localized array<string> FocusLevelDescriptions;
var string FocusToolTipTargetPath; 
var UIBondIcon BondIcon;
var int LastVisibleActiveUnitID;

// Issue #257
var UIImage IconImage;

// Pseudo-Ctor
simulated function UITacticalHUD_SoldierInfo InitStatsContainer()
{
	InitPanel();
	return self;
}

simulated function OnInit()
{
	local UIPanel BondIconPanel; 

	super.OnInit();
	
	UpdateStats();

	WorldInfo.MyWatchVariableMgr.RegisterWatchVariable( XComTacticalController(PC), 'm_kActiveUnit', self, UpdateStats);
	WorldInfo.MyWatchVariableMgr.RegisterWatchVariable( UITacticalHUD(screen), 'm_isMenuRaised', self, UpdateStats);
	WorldInfo.MyWatchVariableMgr.RegisterWatchVariable( XComPresentationLayer(Movie.Pres), 'm_kInventoryTactical', self, UpdateStats);

	HackingToolTipTargetPath = MCPath$".HackingInfoGroup.HackingInfo";
	FocusToolTipTargetPath = MCPath$".FocusLevel";

	BondIconPanel = Spawn(class'UIPanel', self).InitPanel('bondIconMC');
	BondIcon = Spawn(class'UIBondIcon', BondIconPanel).InitBondIcon('bondIconMC');
	BondIcon.ProcessMouseEvents();

	// Start Issue #257
	IconImage = Spawn(class'UIImage', self).InitImage();
	IconImage.OriginCenter();
	IconImage.SetPosition(49, -126);
	IconImage.Hide();
	// End Issue #257
}

simulated function OnMouseEvent(int cmd, array<string> args)
{
	local XGUnit kTargetUnit; 
	
	switch( cmd )
	{
		case class'UIUtilities_Input'.const.FXS_L_MOUSE_OUT:
			kTargetUnit = XComTacticalController(PC).GetActiveUnit();
			kTargetUnit.ShowMouseOverDisc(false);	
			//`BATTLE.PRES().GetCamera().m_kScrollView.SetLocationTarget(`BATTLE.PRES().GetCamera().m_kCurrentView.GetLookAt());
			//`CAMERAMGR.RemoveLookAt( kTargetUnit.Location );
			break;

		case class'UIUtilities_Input'.const.FXS_L_MOUSE_UP_DELAYED:
			//if( `CAMERAMGR.IsCameraBusyWithKismetLookAts() )
			//	return true;

			kTargetUnit = XComTacticalController(PC).GetActiveUnit();
			kTargetUnit.ShowMouseOverDisc();	
			//if( XComPresentationLayer(Owner)==None || !XComPresentationLayer(Owner).Get2DMovie().HasModalScreens() )
			//	`CAMERAMGR.AddLookAt( kTargetUnit.Location );
			
			Movie.Pres.PlayUISound(eSUISound_MenuSelect);
			break;

		case class'UIUtilities_Input'.const.FXS_L_MOUSE_DOUBLE_UP:
			kTargetUnit = XComTacticalController(PC).GetActiveUnit();

			if(kTargetUnit != none)
			{
				XComPresentationLayer(Movie.Pres).ZoomCameraIn(); //reset camera in case we're zoomed out
			}
			else
				Movie.Pres.PlayUISound(eSUISound_MenuClose);
			break; 
	}
}


// Pinged when the active unit changed. 
simulated function UpdateStats()
{
	local XGUnit        kActiveUnit;

	// If not shown or ready, leave.
	if( !bIsInited )
		return;
	
	// Only update if new unit
	kActiveUnit = XComTacticalController(PC).GetActiveUnit();
	if( kActiveUnit == none )
	{
		Hide();
	}
	else
	{
		//UITacticalHUD(Screen).m_kInventory.m_kBackpack.Update( kActiveUnit );
		if( /*LastVisibleActiveUnitID != kActiveUnit.ObjectID*/ true ) // Issue #257, this is also called when refreshing after action
		{
			SetStats(kActiveUnit);
			SetHackingInfo(kActiveUnit);

			UpdateFocusLevelVisibility(kActiveUnit);
		}

		LastVisibleActiveUnitID = kActiveUnit.ObjectID;

		Show();
	}

	//This displays the L3 icon, which we need to handle dynamically from Unrealscript
	//AS_ToggleSoldierInfoTip(true);
}

simulated function UpdateFocusLevelVisibility(XGUnit ActiveUnit)
{
	local XComGameState_Unit UnitState;
	local XComLWTuple Tup; // Issue #257
	local XComGameState_Ability AbilityState;
	
	Movie.Pres.m_kTooltipMgr.RemoveTooltipsByPartialPath(FocusToolTipTargetPath);

	AbilityState = UITacticalHUD(Screen).m_kAbilityHUD.GetCurrentSelectedAbility();

	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ActiveUnit.ObjectID));
	if( UnitState != None )
	{
		// Start Issue #257
		Tup = class'CHHelpers'.static.GetFocusTuple(UnitState);
		if (Tup.Data[0].b)
		{
			ShowFocusLevel();
			// SetFocusLevel runs "async", while AS_SetMCColor runs sync. However, we should be initialized here already
			AS_SetMCColor(MCPath$".FocusLevel.theMeter", Tup.Data[3].s);
			if (Tup.Data[4].s != "")
			{
				IconImage.LoadImage(Tup.Data[4].s);
			}
			else
			{
				IconImage.Hide();
			}
			SetFocusLevel( ActiveUnit, Tup.Data[1].i, Tup.Data[2].i, AbilityState != none? AbilityState.GetFocusCost(UnitState) : 0, "<font color=\"" $ Repl(Tup.Data[3].s, "0x", "#") $ "\">" $ Tup.Data[6].s $ "</font>");
			Movie.Pres.m_kTooltipMgr.AddNewTooltipTextBox(Tup.Data[5].s,
															0,
															0,
															FocusToolTipTargetPath,
															Tup.Data[6].s @ Tup.Data[1].i,
															,
															,
															true);
		// End Issue #257

			return;
		}
	}

	HideFocusLevel();
}

// Issue #257, additional parameter
simulated function SetFocusLevel(XGUnit ActiveUnit, int FocusLevel, int MaxFocus, optional int preview = 0, optional string Label = default.FocusLevelLabel)
{
	MC.BeginFunctionOp("SetFocusLevelLabel");
	MC.QueueString(Label);
	MC.EndOp();

	MC.BeginFunctionOp("SetFocusLevel");
	MC.QueueNumber(FocusLevel);
	MC.QueueNumber(MaxFocus);
	MC.QueueNumber(preview);		//	preview number
	MC.EndOp();
}

simulated function HideFocusLevel()
{
	IconImage.Hide(); // Issue #257
	MC.BeginFunctionOp("HideFocusLevel");
	MC.EndOp();
}

simulated function ShowFocusLevel()
{
	IconImage.Show(); // Issue #257
	MC.BeginFunctionOp("ShowFocusLevel");
	MC.EndOp();
}

simulated function PreviewFocusLevel(XComGameState_Unit UnitState, int Preview)
{
	// Start Issue #257
	local XComLWTuple Tup;

	if (UnitState != none)
		Tup = class'CHHelpers'.static.GetFocusTuple(UnitState);

	if (UnitState == none || !Tup.Data[0].b)
	{
		HideFocusLevel();
		return;
	}

	MC.BeginFunctionOp("SetFocusLevel");
	MC.QueueNumber(Tup.Data[1].i);
	MC.QueueNumber(Tup.Data[2].i);
	MC.QueueNumber(Preview);
	MC.EndOp();
	// End Issue #257
}

simulated function SetStats( XGUnit kActiveUnit )
{
	local XComGameState_Unit StateUnit;
	local string charName, charNickname, charRank, charClass;
	local bool isLeader, isLeveledUp, showBonus, showPenalty;
	local float aimPercent;
	local array<UISummary_UnitEffect> BonusEffects, PenaltyEffects; 
	local X2SoldierClassTemplateManager SoldierTemplateManager;
	//local XComGameState_ResistanceFaction FactionState; //Issue #1134, not needed
	local StateObjectReference BondmateRef;
	local SoldierBond BondInfo;
	local XComGameState_HeadquartersXCom XComHQ;
	local StackedUIIconData StackedClassIcon; // Variable for issue #1134

	StateUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(kActiveUnit.ObjectID));
	
	//FactionState = StateUnit.GetResistanceFaction(); //Issue #1134, not needed

	if( StateUnit.GetMyTemplateName() == 'AdvPsiWitchM2' )
	{
		charName = StateUnit.GetName(eNameType_Full);

		charRank = "img:///UILibrary_Common.rank_fieldmarshall";
		SoldierTemplateManager = class'X2SoldierClassTemplateManager'.static.GetSoldierClassTemplateManager();
		charClass = SoldierTemplateManager.FindSoldierClassTemplate('PsiOperative').IconImage;
		aimPercent = StateUnit.GetCurrentStat(eStat_Offense);
	}
	else 
	{
		charName = StateUnit.GetName(eNameType_Full);
		charNickname = StateUnit.GetNickName();

		if( StateUnit.IsSoldier() )
		{
			charRank = StateUnit.GetSoldierRankIcon(); // Issue #408
			// Start Issue #106
			charClass = StateUnit.GetSoldierClassIcon();
			// End Issue #106
			isLeveledUp = StateUnit.CanRankUpSoldier();
			aimPercent = StateUnit.GetCurrentStat(eStat_Offense);
		}
		else if( StateUnit.IsCivilian() )
		{
			//charRank = string(-2); // TODO: show civilian icon 
			//charClass = "";
			aimPercent = -1;
		}
		else // is enemy
		{
			//charRank = string(99); //TODO: show alien icon 
			charClass = StateUnit.IsAdvent() ? "img:///UILibrary_Common.UIEvent_advent" : "img:///UILibrary_Common.UIEvent_alien";
			aimPercent = -1;
		}
	}

	// TODO:
	isLeader = false;

	BonusEffects = StateUnit.GetUISummary_UnitEffectsByCategory(ePerkBuff_Bonus);
	PenaltyEffects = StateUnit.GetUISummary_UnitEffectsByCategory(ePerkBuff_Penalty);

	showBonus = (BonusEffects.length > 0 ); 
	showPenalty = (PenaltyEffects.length > 0);

	AS_SetStats(charName, charNickname, charRank, charClass, isLeader, isLeveledUp, aimPercent, showBonus, showPenalty);
	// Start Issue #1134
	StackedClassIcon = StateUnit.GetStackedClassIcon();
	if (StackedClassIcon.Images.Length > 0)
		AS_SetFactionIcon(StackedClassIcon);
	// End Issue #1134

	if( StateUnit.HasSoldierBond(BondmateRef, BondInfo) )
	{
		XComHQ = `XCOMHQ;
		AS_SetBondInfo(BondInfo.BondLevel, XComHQ.IsUnitInSquad(BondmateRef));
		BondIcon.SetBondLevel(BondInfo.BondLevel);
		BondIcon.SetBondmateTooltip(BondmateRef);
	}
	else
	{
		AS_SetBondInfo(-1, false);
		BondIcon.SetBondLevel(-1);
		BondIcon.SetBondmateTooltip(BondmateRef); //NoneRef
	}
}

simulated function AS_SetStats(string soldierName, string soldierNickname, string soldierRank, string soldierClass, bool isLeader, 
							   bool isLeveledUp, float aimPercent, bool showBonus, bool showPenalty )
{
	MC.BeginFunctionOp("SetStats");
	MC.QueueString(soldierName);
	MC.QueueString(soldierNickname);
	MC.QueueString(soldierRank);
	MC.QueueString(soldierClass);
	MC.QueueBoolean(isLeader);
	MC.QueueBoolean(isLeveledUp);
	MC.QueueNumber(aimPercent);
	MC.QueueBoolean(showBonus);
	MC.QueueBoolean(showPenalty);
	MC.EndOp();
}

simulated function AS_ToggleSoldierInfoTip(bool bShow)
{
	MC.BeginFunctionOp("ToggleSoldierInfoTip");
	MC.QueueBoolean(bShow);
	MC.EndOp();
}

simulated function SetHackingInfo(XGUnit kActiveUnit)
{
	local XComGameState_Unit StateUnit;
	local X2HackRewardTemplateManager HackRewardTemplateManager;
	local X2HackRewardTemplate HackRewardTemplate;
	local int HackRewardIndex;

	MC.FunctionVoid("ClearHacking");

	Movie.Pres.m_kTooltipMgr.RemoveTooltipsByPartialPath(HackingToolTipTargetPath);

	HackRewardTemplateManager = class'X2HackRewardTemplateManager'.static.GetHackRewardTemplateManager();
	StateUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(kActiveUnit.ObjectID));
	for( HackRewardIndex = 0; HackRewardIndex < StateUnit.CurrentHackRewards.Length && HackRewardIndex < 3; ++HackRewardIndex )
	{
		if( HackRewardIndex < StateUnit.CurrentHackRewards.Length )
		{
			HackRewardTemplate = HackRewardTemplateManager.FindHackRewardTemplate(StateUnit.CurrentHackRewards[HackRewardIndex]);
		}
		else
		{
			HackRewardTemplate = None;
		}

		if( HackRewardTemplate != None )
		{
			UpdateHacking(HackRewardIndex, class'UIUtilities_Image'.const.HackRewardIcon, HackRewardTemplate.GetFriendlyName(), HackRewardTemplate.GetDescription(StateUnit));
		}
		else
		{
			UpdateHacking(HackRewardIndex, "", "", "");
		}
	}

	// DEBUG EXAMPLE: uncomment to see this in action. 
	//UpdateHacking(0, class'UIUtilities_Image'.const.MissionObjective_HackWorkstation /*icon path*/, "HACK0" /*ability name*/, "Tooltip info!" /*desc*/);
	//UpdateHacking(1, class'UIUtilities_Image'.const.MissionObjective_HackWorkstation /*icon path*/, "HACK1" /*ability name*/, "More Tooltips!" /*desc*/);
	//UpdateHacking(2, class'UIUtilities_Image'.const.MissionObjective_HackWorkstation /*icon path*/, "HACK2" /*ability name*/, "Happy super tooltip time" /*desc*/);
}

// Blank strings will hide this widget. 
// Three of these are plopped on the stage. 
simulated function UpdateHacking(int Index, string Path, string AbilityName, string AbilityDesc)
{
	local UITextTooltip Tooltip;

	MC.BeginFunctionOp("SetHacking");
	MC.QueueNumber(Index);
	MC.QueueString(Path);
	MC.QueueString(AbilityName);
	MC.EndOp();

	// Add a tooltip 
	if( AbilityDesc != "" )
	{
		Tooltip = Spawn(class'UITextTooltip', Movie.Pres.m_kTooltipMgr);
		Tooltip.InitTextTooltip();
		Tooltip.sTitle = AbilityName;
		Tooltip.sBody = AbilityDesc;
		Tooltip.bUsePartialPath = true;
		Tooltip.targetPath = HackingToolTipTargetPath$Index;

		Movie.Pres.m_kTooltipMgr.AddPreformedTooltip(Tooltip);
	}
}

public function AS_SetFactionIcon(StackedUIIconData IconInfo)
{
	local int i;

	if (IconInfo.Images.Length > 0)
	{
		MC.BeginFunctionOp("SetUnitFactionIcon");
		MC.QueueBoolean(IconInfo.bInvert);
		for (i = 0; i < IconInfo.Images.Length; i++)
		{
			MC.QueueString("img:///" $ Repl(IconInfo.Images[i], ".tga", "_sm.tga"));
		}

		MC.EndOp();
	}
}

public function AS_SetBondInfo(int BondLevel, bool bOnMission)
{
	MC.BeginFunctionOp("SetBondIcon");
	MC.QueueNumber(BondLevel);
	MC.QueueBoolean(bOnMission);
	MC.EndOp();
}

defaultproperties
{
	MCName = "soldierInfo";
	bAnimateOnInit = false;
}

