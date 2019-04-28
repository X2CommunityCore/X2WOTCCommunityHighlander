
class UISoldierBondListItem extends UIButton;

var UIPanel BG;

var StateObjectReference UnitRef;
var StateObjectReference ScreenUnitRef;

var UIButton ActivateBondButton; 
var localized string BondButtonLabel; 


simulated function InitListItem(StateObjectReference initUnitRef, StateObjectReference initScreenUnitRef)
{
	UnitRef = initUnitRef;
	ScreenUnitRef = initScreenUnitRef;

	InitPanel(); // must do this before adding children or setting data

	BG = Spawn(class'UIButton', self);
	BG.InitPanel('BondBGButton');
	BG.ProcessMouseEvents(OnSelectSoldier);
	
	ActivateBondButton = spawn(class'UIButton', self);
	ActivateBondButton.InitButton('makeBondButton', BondButtonLabel);
	ActivateBondButton.ProcessMouseEvents(OnConfirmBond);
	ActivateBondButton.DisableNavigation();
	ActivateBondButton.MC.FunctionBool("AnimateCohesion", true);

	ActivateBondButton.SetTooltipText(BondButtonLabel);

	//bsg-jneal (3.17.17): buttons and BG should not be navigable with controller
	if(`ISCONTROLLERACTIVE)
	{
		BG.DisableNavigation();
		ActivateBondButton.DisableNavigation();
	}
	//bsg-jneal (3.17.17): end

	UpdateData();
}

simulated function UpdateData()
{
	local XComGameState_Unit Unit, ScreenUnit;
	local StateObjectReference BondmateRef;
	local string classIcon, rankIcon, flagIcon;
	local X2SoldierClassTemplate SoldierClass;
	local SoldierBond BondData;
	local float CohesionPercent, CohesionMax;
	local array<int> CohesionThresholds;

	Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitRef.ObjectID));
	ScreenUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ScreenUnitRef.ObjectID));

	ScreenUnit.GetBondData(UnitRef, BondData);

	SoldierClass = Unit.GetSoldierClassTemplate();

	flagIcon = Unit.GetCountryTemplate().FlagImage;
	rankIcon = Unit.GetSoldierRankIcon(); // Issue #408
	// Start Issue #106
	classIcon = Unit.GetSoldierClassIcon();
	// End Issue #106

	CohesionThresholds = class'X2StrategyGameRulesetDataStructures'.default.CohesionThresholds;
	CohesionMax = float(CohesionThresholds[Clamp(BondData.BondLevel + 1, 0, CohesionThresholds.Length - 1)]);
	CohesionPercent = float(BondData.Cohesion) / CohesionMax;

	
	if( ScreenUnit.HasSoldierBond(BondmateRef) )
	{
		if( BondmateRef == UnitRef )
			SetGood(true);
		else
			SetDisabled(true);
	}
	
	if( Unit.HasSoldierBond(BondmateRef) )
	{
		if( BondmateRef != ScreenUnitRef )
			SetDisabled(true);
	}


	if( class'X2StrategyGameRulesetDataStructures'.static.CanHaveBondAtLevel(Unit, ScreenUnit, BondData.BondLevel + 1) )
	{
		SetGood(true);

		//bsg-jneal (3.17.17): do not show PC buttons when using controller
		if(!`ISCONTROLLERACTIVE)
		{
			ActivateBondButton.Show();
			MC.FunctionBool("CanShowBondButton", true);
		}
		else
		{
			ActivateBondButton.Hide();
			MC.FunctionBool("CanShowBondButton", false);
		}
		//bsg-jneal (3.17.17): end
	}
	else
	{
		ActivateBondButton.Hide();
		MC.FunctionBool("CanShowBondButton", false);
	}
	// Start Issue #106, #408
	AS_UpdateDataSoldier(Caps(Unit.GetName(eNameType_Full)),
						 Caps(Unit.GetName(eNameType_Nick)),
						 Caps(Unit.GetSoldierShortRankName()),
						rankIcon,
						Caps(SoldierClass != None ? Unit.GetSoldierClassDisplayName() : ""),
						classIcon,
						flagIcon,
						class'X2StrategyGameRulesetDataStructures'.static.GetSoldierCompatibilityLabel(BondData.Compatibility),
						CohesionPercent,
						IsDisabled);
	// End Issue #106, #408
}

simulated function AS_UpdateDataSoldier(string UnitName,
										string UnitNickname,
										string UnitRank,
										string UnitRankPath,
										string UnitClass,
										string UnitClassPath,
										string UnitCountryFlagPath,
										string UnitCompatibility,
										float UnitCohesion,
										bool bDisabled)
{
	MC.BeginFunctionOp("UpdateData");
	MC.QueueString(UnitName);
	MC.QueueString(UnitNickname);
	MC.QueueString(UnitRank);
	MC.QueueString(UnitRankPath);
	MC.QueueString(UnitClass);
	MC.QueueString(UnitClassPath);
	MC.QueueString(UnitCountryFlagPath);
	MC.QueueString(UnitCompatibility);
	MC.QueueNumber(UnitCohesion);
	MC.QueueBoolean(bDisabled);
	MC.EndOp();
}


simulated function AnimateIn(optional float delay = -1.0)
{
	// this needs to be percent of total time in sec 
	if( delay == -1.0 )
		delay = ParentPanel.GetChildIndex(self) * class'UIUtilities'.const.INTRO_ANIMATION_DELAY_PER_INDEX;

	AddTweenBetween("_alpha", 0, alpha, class'UIUtilities'.const.INTRO_ANIMATION_TIME, delay);
	AddTweenBetween("_y", Y + 10, Y, class'UIUtilities'.const.INTRO_ANIMATION_TIME * 2, delay, "easeoutquad");
}

function OnConfirmBond(UIPanel Panel, int Cmd)
{
	if( Cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_UP )
	{
		UISoldierBondScreen(Screen).OnConfirmBond(self);
	}
}

function OnSelectSoldier(UIPanel Panel, int Cmd)
{
	if( Cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_UP )
	{
		UISoldierBondScreen(Screen).OnSelectSoldier(UnitRef);
	}
}

defaultproperties
{
	LibID = "SoldierBondListItem";

width = 1110;
height = 55;
bIsNavigable = true;
bCascadeFocus = false;
}