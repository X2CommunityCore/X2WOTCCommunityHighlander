
class UIPersonnel_SoldierListItem extends UIPersonnel_ListItem;

var UIImage PsiMarkup;
var UIBondIcon BondIcon;

var bool m_bIsDisabled;

var localized string BondmateTooltip; 

simulated function InitListItem(StateObjectReference initUnitRef)
{
	super.InitListItem(initUnitRef);

	PsiMarkup = Spawn(class'UIImage', self);
	PsiMarkup.InitImage('PsiPromote', class'UIUtilities_Image'.const.PsiMarkupIcon);
	PsiMarkup.Hide(); // starts off hidden until needed
}

 simulated function UpdateData()
{
	local XComGameState_Unit Unit;
	local string UnitLoc, status, statusTimeLabel, statusTimeValue, classIcon, rankIcon, flagIcon, mentalStatus;	
	local int iRank, iTimeNum;
	local X2SoldierClassTemplate SoldierClass;
	local XComGameState_ResistanceFaction FactionState;
	local SoldierBond BondData;
	local StateObjectReference BondmateRef;
	local XComGameState_Unit Bondmate;
	local int BondLevel; 
	
	Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitRef.ObjectID));

	iRank = Unit.GetRank();

	SoldierClass = Unit.GetSoldierClassTemplate();
	FactionState = Unit.GetResistanceFaction();

	class'UIUtilities_Strategy'.static.GetPersonnelStatusSeparate(Unit, status, statusTimeLabel, statusTimeValue);
	mentalStatus = "";

	if(Unit.IsActive())
	{
		Unit.GetMentalStateStringsSeparate(mentalStatus, statusTimeLabel, iTimeNum);
		statusTimeLabel = class'UIUtilities_Text'.static.GetColoredText(statusTimeLabel, Unit.GetMentalStateUIState());

		if(iTimeNum == 0)
		{
			statusTimeValue = "";
		}
		else
		{
			statusTimeValue = class'UIUtilities_Text'.static.GetColoredText(string(iTimeNum), Unit.GetMentalStateUIState());
		}
	}


	if( statusTimeValue == "" )
		statusTimeValue = "---";

	flagIcon = Unit.GetCountryTemplate().FlagImage;
	rankIcon = class'UIUtilities_Image'.static.GetRankIcon(iRank, SoldierClass.DataName);
	classIcon = SoldierClass.IconImage;

	// if personnel is not staffed, don't show location
	if( class'UIUtilities_Strategy'.static.DisplayLocation(Unit) )
		UnitLoc = class'UIUtilities_Strategy'.static.GetPersonnelLocation(Unit);
	else
		UnitLoc = "";

	if( BondIcon == none )
	{
		BondIcon = Spawn(class'UIBondIcon', self);
		if( `ISCONTROLLERACTIVE ) 
			BondIcon.bIsNavigable = false; 
	}

	if( Unit.HasSoldierBond(BondmateRef, BondData) )
	{
		Bondmate = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(BondmateRef.ObjectID));
		BondLevel = BondData.BondLevel;
		if( !BondIcon.bIsInited )
		{
			BondIcon.InitBondIcon('UnitBondIcon', BondData.BondLevel, , BondData.Bondmate);
		}
		BondIcon.Show();
		SetTooltipText(Repl(BondmateTooltip, "%SOLDIERNAME", Caps(Bondmate.GetName(eNameType_RankFull))));
		Movie.Pres.m_kTooltipMgr.TextTooltip.SetUsePartialPath(CachedTooltipID, true);
	}
	else if( Unit.ShowBondAvailableIcon(BondmateRef, BondData) )
	{
		BondLevel = BondData.BondLevel;
		if( !BondIcon.bIsInited )
		{
			BondIcon.InitBondIcon('UnitBondIcon', BondData.BondLevel, , BondmateRef);
		}
		BondIcon.Show();
		BondIcon.AnimateCohesion(true);
		SetTooltipText(class'XComHQPresentationLayer'.default.m_strBannerBondAvailable);
		Movie.Pres.m_kTooltipMgr.TextTooltip.SetUsePartialPath(CachedTooltipID, true);
	}
	else
	{
		if( !BondIcon.bIsInited )
		{
			BondIcon.InitBondIcon('UnitBondIcon', BondData.BondLevel, , BondData.Bondmate);
		}
		BondIcon.Hide();
		BondLevel = -1; 
	}

	AS_UpdateDataSoldier(Caps(Unit.GetName(eNameType_Full)),
					Caps(Unit.GetName(eNameType_Nick)),
					Caps(`GET_RANK_ABBRV(Unit.GetRank(), SoldierClass.DataName)),
					rankIcon,
					Caps(SoldierClass != None ? SoldierClass.DisplayName : ""),
					classIcon,
					status,
					statusTimeValue $"\n" $ Class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS(Class'UIUtilities_Text'.static.GetSizedText( statusTimeLabel, 12)),
					UnitLoc,
					flagIcon,
					false, //todo: is disabled 
					Unit.ShowPromoteIcon(),
					false, // psi soldiers can't rank up via missions
					mentalStatus,
					BondLevel);

	AS_SetFactionIcon(FactionState.GetFactionIcon());
}

simulated function AS_UpdateDataSoldier(string UnitName,
								 string UnitNickname, 
								 string UnitRank, 
								 string UnitRankPath, 
								 string UnitClass, 
								 string UnitClassPath, 
								 string UnitStatus, 
								 string UnitStatusValue, 
								 string UnitLocation, 
								 string UnitCountryFlagPath,
								 bool bIsDisabled, 
								 bool bPromote, 
								 bool bPsiPromote,
								 string UnitMentalState, 
								 int BondLevel)
{
	MC.BeginFunctionOp("UpdateData");
	MC.QueueString(UnitName);
	MC.QueueString(UnitNickname);
	MC.QueueString(UnitRank);
	MC.QueueString(UnitRankPath);
	MC.QueueString(UnitClass);
	MC.QueueString(UnitClassPath);
	MC.QueueString(UnitStatus);
	MC.QueueString(UnitStatusValue);
	MC.QueueString(UnitLocation);
	MC.QueueString(UnitCountryFlagPath);
	MC.QueueBoolean(bIsDisabled);
	MC.QueueBoolean(bPromote);
	MC.QueueBoolean(bPsiPromote);
	MC.QueueString(UnitMentalState);
	mc.QueueNumber(BondLevel);
	MC.EndOp();
}
simulated function AS_SetFactionIcon(StackedUIIconData IconInfo)
{
	local int i;

	if (IconInfo.Images.Length > 0)
	{
		MC.BeginFunctionOp("SetFactionIcon");
		MC.QueueBoolean(IconInfo.bInvert);
		for (i = 0; i < IconInfo.Images.Length; i++)
		{
			MC.QueueString("img:///" $ Repl(IconInfo.Images[i], ".tga", "_sm.tga"));
		}

		MC.EndOp();
	}
}

simulated function UIButton SetDisabled(bool disabled, optional string TooltipText)
{
	super.SetDisabled(disabled, TooltipText);
	//The list is force-refresh built, and sets enable/disabled, which then clears the tooltip inappropriately. 
	RefreshTooltipText();
	return self;
}

simulated function RefreshTooltipText()
{
	local XComGameState_Unit Unit;
	local SoldierBond BondData;
	local StateObjectReference BondmateRef;
	local XComGameState_Unit Bondmate;

	Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitRef.ObjectID));

	if( Unit.HasSoldierBond(BondmateRef, BondData) )
	{
		Bondmate = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(BondmateRef.ObjectID));
		SetTooltipText(Repl(BondmateTooltip, "%SOLDIERNAME", Caps(Bondmate.GetName(eNameType_RankFull))));
		Movie.Pres.m_kTooltipMgr.TextTooltip.SetUsePartialPath(CachedTooltipID, true);
	}
	else if( Unit.ShowBondAvailableIcon(BondmateRef, BondData) )
	{
		SetTooltipText(class'XComHQPresentationLayer'.default.m_strBannerBondAvailable);
		Movie.Pres.m_kTooltipMgr.TextTooltip.SetUsePartialPath(CachedTooltipID, true);
	}
	else
	{
		SetTooltipText("");
	}
}



defaultproperties
{
	LibID = "SoldierListItem";
}