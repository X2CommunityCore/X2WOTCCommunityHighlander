
class UIPersonnel_DropDownListItem extends UIButton dependson(XComGameState_Unit);

var StaffUnitInfo UnitInfo;
var StateObjectReference SlotRef;

var UIPersonnel_DropDownToolTip ItemToolTip;
var UIPersonnel_DropDown OwningMenu;
var bool bSizeRealized;

delegate OnDimensionsRealized();

simulated function InitListItem(UIPersonnel_DropDown Menu, StaffUnitInfo initUnitInfo, StateObjectReference initSlotRef)
{
	OwningMenu = Menu;
	UnitInfo = initUnitInfo;
	SlotRef = initSlotRef;

	InitPanel(); // must do this before adding children or setting data
	
	// Only spawn a tooltip if this is not an Empty item
	if (UnitInfo.UnitRef.ObjectID != 0)
	{
		ItemToolTip = Spawn(class'UIPersonnel_DropDownToolTip', Movie.Pres.m_kTooltipMgr);
		ItemToolTip.InitDropDownToolTip();
		ItemToolTip.UnitInfo = UnitInfo;
		ItemToolTip.SlotRef = SlotRef;
		ItemToolTip.targetPath = string(MCPath);
		ItemToolTip.tDelay = 0;

		ItemToolTip.ID = Movie.Pres.m_kTooltipMgr.AddPreformedTooltip(ItemToolTip);
		bHasTooltip = true;
	}

	ProcessMouseEvents(OnChildMouseEvent);

	UpdateData();
}

simulated function OnMouseEvent(int cmd, array<string> args)
{
	switch(cmd)
	{
		case class'UIUtilities_Input'.const.FXS_L_MOUSE_IN:
			`SOUNDMGR.PlaySoundEvent("Play_Mouseover");
			OwningMenu.ClearDelayTimer();
			break; 

		case class'UIUtilities_Input'.const.FXS_L_MOUSE_RELEASE_OUTSIDE: //Snap this shut when you've clicked elsewhere. 
			OwningMenu.CloseMenu();
			break;

		case class'UIUtilities_Input'.const.FXS_L_MOUSE_DRAG_OUT:
		case class'UIUtilities_Input'.const.FXS_L_MOUSE_OUT:
			OwningMenu.TryToStartDelayTimer(args);
			break;
	}

	super.OnMouseEvent(cmd, args);
}

simulated function OnCommand(string cmd, string arg)
{
	local array<string> sizeData;

	super.OnCommand(cmd, arg);

	if( cmd == "RealizeDimensions" )
	{
		sizeData = SplitString(arg, ",");
		X = float(sizeData[0]);
		Y = float(sizeData[1]);
		Width = float(sizeData[2]);
		Height = float(sizeData[3]);

		bSizeRealized = true;

		if (OnDimensionsRealized != none)
		{
			OnDimensionsRealized();
		}
	}
}

simulated function UpdateData()
{
	local XComGameStateHistory History;
	local XComGameState_Unit Unit, PairUnit;
	local string UnitName, UnitStatus, UnitTypeImage;
	local EUIPersonnelType UnitPersonnelType; 
	local EStaffStatus StafferStatus;
	local int StatusState;

	bSizeRealized = false;
	
	History = `XCOMHISTORY;
	Unit = XComGameState_Unit(History.GetGameStateForObjectID(UnitInfo.UnitRef.ObjectID));
	PairUnit = XComGameState_Unit(History.GetGameStateForObjectID(UnitInfo.PairUnitRef.ObjectID));
	if(Unit != none) //May be none of the slots are being cleared
	{
		StafferStatus = class'X2StrategyGameRulesetDataStructures'.static.GetStafferStatus(UnitInfo, , , StatusState);
		UnitStatus = class'UIUtilities_Text'.static.GetColoredText(class'UIUtilities_Strategy'.default.m_strStaffStatus[StafferStatus], StatusState);
		UnitName = Caps(Unit.GetFullName());
		
		if(Unit.IsSoldier())
		{
			UnitName = Caps(Unit.GetName(eNameType_RankFull));
			UnitPersonnelType = eUIPersonnel_Soldiers;
			if (PairUnit != none && PairUnit.IsSoldier())
			{
				UnitName @= class'UIUtilities_Text'.default.m_strAmpersand @ Caps(PairUnit.GetName(eNameType_RankFull));
				UnitTypeImage = "";
			}
			else
			{
				UnitTypeImage = Unit.GetSoldierRankIcon(); // Issue #408
			}
		}
		else if(Unit.IsEngineer())
		{
			if(UnitInfo.bGhostUnit) // If the unit is a ghost, replace Eng name with the Ghost name
				UnitName = Caps(Repl(Unit.GetStaffSlot().GetMyTemplate().GhostName, "%UNITNAME", UnitName));
			UnitPersonnelType = eUIPersonnel_Engineers;
			UnitTypeImage = class'UIUtilities_Image'.const.EventQueue_Engineer;
		}
		else if(Unit.IsScientist())
		{
			UnitPersonnelType = eUIPersonnel_Scientists;
			UnitTypeImage = class'UIUtilities_Image'.const.EventQueue_Science;
		}
		else // Passed in an empty ref
		{
			UnitName = class'UIUtilities_Strategy'.default.m_strEmptyStaff;
			UnitStatus = " "; // send a space specifically to clear out this field. 
			UnitPersonnelType = -1;
			UnitTypeImage = "";
		}
	}
	else // Passed in an empty ref
	{
		UnitName = class'UIUtilities_Strategy'.default.m_strEmptyStaff;
		UnitStatus = " "; // send a space specifically to clear out this field. 
		UnitPersonnelType = -1;
		UnitTypeImage = "";
	}

	AS_UpdateData(
		UnitName,
		"0", //string(Unit.GetSkillLevel()),
		UnitStatus,
		UnitPersonnelType,
		UnitTypeImage);
}

simulated function AS_UpdateData(string UnitName, 
								 string UnitSkill, 
								 string UnitStatus, 
								 int SkillType, 
								 string SkillImage )
{
	MC.BeginFunctionOp("update");
	MC.QueueString(UnitName);
	MC.QueueString(UnitSkill);
	MC.QueueString(UnitStatus);
	MC.QueueNumber(SkillType);
	MC.QueueString(SkillImage);
	MC.EndOp();
}

simulated function AnimateIn(optional float delay = -1.0)
{
	// this needs to be percent of total time in sec 
	if( delay == -1.0)
		delay = ParentPanel.GetChildIndex(self) * class'UIUtilities'.const.INTRO_ANIMATION_DELAY_PER_INDEX; 

	AddTweenBetween( "_alpha", 0, alpha, class'UIUtilities'.const.INTRO_ANIMATION_TIME, delay );
	AddTweenBetween( "_y", Y+10, Y, class'UIUtilities'.const.INTRO_ANIMATION_TIME*2, delay, "easeoutquad" );
}

simulated function OnChildMouseEvent(UIPanel control, int cmd)
{
	switch( control )
	{
	default:
		switch( cmd )
		{
		case class'UIUtilities_Input'.const.FXS_L_MOUSE_IN:
			OnReceiveFocus();
			MC.FunctionVoid("mouseIn");
			break;
		case class'UIUtilities_Input'.const.FXS_L_MOUSE_OUT:
			OnLoseFocus();
			MC.FunctionVoid("mouseOut");
			break;
		}
	}
}


simulated function OnReceiveFocus()
{
	MC.FunctionVoid("mouseIn");
}

simulated function OnLoseFocus()
{
	MC.FunctionVoid("mouseOut");
}

defaultproperties
{
	LibID = "StaffRowItem";

	height = 38;
	bProcessesMouseEvents = true;
	bIsNavigable = true;
	
	bShouldPlayGenericUIAudioEvents = false;
}