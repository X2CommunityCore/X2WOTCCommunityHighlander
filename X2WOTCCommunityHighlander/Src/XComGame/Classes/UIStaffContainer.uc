//----------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIStaffContainer.uc
//  AUTHOR:  Brit Steiner 
//  PURPOSE: Staff container that will load in and format staff items. 
//----------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//----------------------------------------------------------------------------

class UIStaffContainer extends UIPanel
	dependson(UIStaffSlot);

var string Title;
var string Message;
var string Icon;
var string Skill;
var array<UIStaffSlot> StaffSlots; 

var UIPersonnel_DropDown m_kPersonnelDropDown;

var localized string DefaultStaffTitle; 

var UIStaffSlot SelectedStaffSlot;
simulated function UIStaffContainer InitStaffContainer(optional name InitName, optional string NewTitle = DefaultStaffTitle)
{
	InitPanel(InitName);
	
	SetTitle(NewTitle);

	return self;
}
simulated function bool IsEmpty()
{
	local int i;

	for (i = 0; i < StaffSlots.Length; ++i)
	{
		if (StaffSlots[i].IsSlotFilled())
			return false;
	}
	return true;
}


simulated function OnLoseFocus()
{
	local int i;

	super.OnLoseFocus();

	if(m_kPersonnelDropDown != none)
		m_kPersonnelDropDown.Hide();

	for(i = 0; i < StaffSlots.Length; ++i)
		StaffSlots[i].OnLoseFocus();
}

simulated function OnReceiveFocus()
{
	super.OnReceiveFocus();

	if(StaffSlots.Length > 0)
	{
		if(SelectedStaffSlot != none)
			SelectedStaffSlot.OnReceiveFocus();
		else if(Navigator.GetSelected() != none)
			Navigator.GetSelected().OnReceiveFocus();
		else
			StaffSlots[0].OnReceiveFocus();
	}
}

public simulated function HideDropDown(optional UIStaffSlot StaffSlot)
{
	if (m_kPersonnelDropDown == none)
		return;
	
	if (StaffSlot != none && m_kPersonnelDropDown.SlotRef != StaffSlot.StaffSlotRef)
		return;

	m_kPersonnelDropDown.TryToStartDelayTimer();
}

public simulated function ShowDropDown(UIStaffSlot StaffSlot)
{
	if (m_kPersonnelDropDown != none)
	{
		if (m_kPersonnelDropDown.SlotRef != StaffSlot.StaffSlotRef)
		{
			m_kPersonnelDropDown.onSelectedDelegate = StaffSlot.OnPersonnelSelected;
			m_kPersonnelDropDown.SlotRef = StaffSlot.StaffSlotRef;
			m_kPersonnelDropDown.UpdateData();
		}
	}
	else
	{
		m_kPersonnelDropDown = Spawn(class'UIPersonnel_DropDown', self);
		m_kPersonnelDropDown.onSelectedDelegate = StaffSlot.OnPersonnelSelected;
		m_kPersonnelDropDown.SlotRef = StaffSlot.StaffSlotRef;
		m_kPersonnelDropDown.InitDropDown();
	}

	if(!StaffSlot.bSizeRealized)
	{
		StaffSlot.QueueDropDownDisplay();
		m_kPersonnelDropDown.Hide();
	}
	else
	{
		m_kPersonnelDropDown.SetPosition(StaffSlot.X, StaffSlot.Y + StaffSlot.Height);
		m_kPersonnelDropDown.Show();
	}
	SelectedStaffSlot = StaffSlot;
}

simulated function Refresh(StateObjectReference LocationRef, delegate<UIStaffSlot.OnStaffUpdated> onStaffUpdatedDelegate)
{
	// Should be implemented by subclasses
}

simulated function UIStaffContainer SetTitle(string NewTitle)
{
	if( Title != NewTitle )
	{
		Title = NewTitle;
		MC.FunctionString("setTitle", NewTitle);
	}
	return self;
}

simulated function UIStaffContainer SetStaffSkill(string NewIcon, string NewSkill)
{
	if(Icon != NewIcon || Skill != NewSkill)
	{
		Icon = NewIcon;
		Skill = NewSkill;
		MC.BeginFunctionOp("setStaffSkill");
		MC.QueueString(Icon);
		MC.QueueString(Skill);
		MC.EndOp();
	}

	return self;
}

simulated function UIStaffContainer SetMessage(string NewMsg)
{
	if( Message != NewMsg )
	{
		Message = NewMsg;
		MC.FunctionString("setMessage", NewMsg);
	}
	return self;
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	if ( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg) )
		return false;

	if (super.OnUnrealCommand(cmd, arg))
		return true;


	if (m_kPersonnelDropDown != none && m_kPersonnelDropDown.bIsVisible)
	{
		return m_kPersonnelDropDown.OnUnrealCommand(cmd, arg);
	}

	return false;
}

simulated function SetTooltipText(string Text,
								  optional string TooltipTitle,
								  optional float OffsetX,
								  optional float OffsetY,
								  optional bool bRelativeLocation = class'UITextTooltip'.default.bRelativeLocation,
								  optional int TooltipAnchor = class'UITextTooltip'.default.Anchor,
								  optional bool bFollowMouse = class'UITextTooltip'.default.bFollowMouse,
								  optional float Delay = class'UITextTooltip'.default.tDelay)
{
	super.SetTooltipText(Text);
	ProcessMouseEventsForTooltip(true);
}

function ProcessMouseEventsForTooltip(bool bShouldInterceptMouse)
{
	if( bShouldInterceptMouse )
		MC.FunctionVoid("processMouseEvents");
	else
		MC.FunctionVoid("ignoreMouseEvents");
}

simulated function ClearSlots()
{
	MC.FunctionVoid("clear");
}

defaultproperties
{
	LibID = "StaffContainer";
	bIsNavigable = true;
}
