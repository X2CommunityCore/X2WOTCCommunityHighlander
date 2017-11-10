//----------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIListItemString.uc
//  AUTHOR:  Samuel Batista
//  PURPOSE: Basic List item control.
//
//  NOTE: Mouse events are handled by UIList class
//
//----------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//----------------------------------------------------------------------------

class UIListItemString extends UIPanel;

var public int    metadataInt;    // int variable for gameplay use
var public string metadataString; // string variable for gameplay use
var public Object metadataObject;

var string	Text;
var string	HtmlText;
var bool		bDisabled;
var bool		bIsBad; 
var bool		bIsGood;
var bool		bIsWarning;

var string	ConfirmText;
var UIButton		ConfirmButton;
var EUIConfirmButtonStyle ConfirmButtonStyle;
var int			ConfirmButtonStoredRightCol;
var int						ConfirmButtonArrowWidth; 
var int			ConfirmButtonStoredTopRow;
var UIPanel		AttentionIcon; 
var int			DefaultAttentionIconPadding;
var int			AttentionIconPadding;
var int			RightColumnPadding;

//var UIPanel BG;
var UIButton	ButtonBG;
var name ButtonBGLibID;

var UIList List;
var int	RightColDefaultPadding;

var bool bShouldSet3DHeight;

// Override InitPanel to run important listItem specific logic
simulated function UIPanel InitPanel(optional name InitName, optional name InitLibID)
{
	super.InitPanel(InitName, InitLibID);

	List = UIList(GetParent(class'UIList')); // list items must be owned by UIList.ItemContainer
	if(List == none)
	{
		ScriptTrace();
		`warn("UI list items must be owned by UIList.ItemContainer");
	}
	else if( !List.bIsHorizontal )
	{
		SetWidth(List.width);
		SetRightColPadding(RightColDefaultPadding + AttentionIconPadding);
		
		// HAX: Adjust button height when List item is shown in a 3D screen
		if(Screen.bIsIn3D && bShouldSet3DHeight)
		{
			Height = 40;
			MC.ChildSetNum("theButton", "_height", 32);
		}
		else
		{
			MC.ChildSetNum("theButton", "_height", 32);
		}
	}

	//Spawn in the init, so that set up functions have access to it's data. 
	ButtonBG = Spawn(class'UIButton', self);
	ButtonBG.bIsNavigable = false;
	ButtonBG.InitButton(ButtonBGLibID);
	ButtonBG.ProcessMouseEvents(OnChildMouseEvent);

	return self;
}

simulated function UIListItemString InitListItem(optional string InitText)
{
	InitPanel();
	SetText(InitText);
	return self;
}

simulated function UIListItemString SetRightColPadding(int NewPadding)
{
	if( RightColumnPadding != NewPadding )
	{
		RightColumnPadding = NewPadding;

		MC.FunctionNum("setRightColPadding", NewPadding);
	}
	return self;
}

simulated function NeedsAttention( bool bNeedsAttention, optional bool bIsObjective = false )
{
	if(AttentionIcon == none && bNeedsAttention)
	{
		// We have a member that will either connect to what is on stage, or will 
		// spawn a clip in for us to use. Only bother to create it if we need it. 
		AttentionIcon = Spawn(class'UIPanel', self).InitPanel('attentionIconMC', class'UIUtilities_Controls'.const.MC_AttentionIcon);
		AttentionIcon.SetSize(70, 70); //the animated rings count as part of the size. 
		AttentionIcon.SetPosition(2, 4);
		AttentionIcon.DisableNavigation();
	}

	//We only need to call across if the icon has been created, to update the icon and textfield placement. 
	if( AttentionIcon != none )
	{
		AttentionIcon.SetVisible(bNeedsAttention);
		if( bIsObjective )
		{
			AttentionIcon.MC.FunctionString("gotoAndPlay", "_goldenPath");
		}
		else
		{
			AttentionIcon.MC.FunctionString("gotoAndPlay", "_attention");
		}

		MC.FunctionBool("needsAttention", bNeedsAttention);

		AttentionIconPadding = bNeedsAttention ? DefaultAttentionIconPadding : 0;
	}
	// Call this regardless, to be sure that the size can update relative to the new state of the attention icon. 
	SetWidth(Width);
}

simulated function AnimateIn(optional float Delay = -1.0)
{
	// this needs to be percent of total time in sec 
	if( Delay == -1.0)
		Delay = ParentPanel.GetChildIndex(self) * class'UIUtilities'.const.INTRO_ANIMATION_DELAY_PER_INDEX; 

	AddTweenBetween( "_alpha", 0, Alpha, class'UIUtilities'.const.INTRO_ANIMATION_TIME, Delay );
	AddTweenBetween( "_y", Y + 10, Y, class'UIUtilities'.const.INTRO_ANIMATION_TIME * 2, Delay, "easeoutquad" );
}

simulated function SetWidth(float NewWidth)
{
	super.SetWidth(NewWidth);

	if( ConfirmButton != none )
		ConfirmButton.SetX(List.width - ConfirmButtonStoredRightCol);
	else
		SetRightColPadding(ConfirmButtonStoredRightCol + AttentionIconPadding);
}

simulated function UIListItemString SetText(string NewText)
{
	if(Text != NewText)
	{
		Text = NewText;
		SetHtmlText(class'UIUtilities_Text'.static.AddFontInfo(Text, Screen.bIsIn3D));
	}
	return self;
}

simulated function UIListItemString SetCenteredText(string NewText)
{
	return SetHtmlText(class'UIUtilities_Text'.static.AlignCenter(NewText));
}

simulated function UIListItemString SetHtmlText(string NewText)
{
	if(HtmlText != NewText)
	{
		HtmlText = NewText;
		mc.FunctionString("setHTMLText", HtmlText);
	}
	return self;
}

simulated function UIListItemString SetConfirmButtonStyle( EUIConfirmButtonStyle NewStyle, optional string txt = "", optional int rightColWidth = 0, optional int topRowHeight = -1, optional delegate<UIButton.OnClickedDelegate> ConfirmButtonClick, optional delegate<UIButton.OnClickedDelegate> ConfirmButtonDoubleClick){
	local name TypedLibID;
	
	switch(NewStyle)
	{
	case eUIConfirmButtonStyle_None:
		if( ConfirmButton != None )
			ConfirmButton.Remove();
		if( rightColWidth == 0 )
			rightColWidth = RightColDefaultPadding;
		break;
	case eUIConfirmButtonStyle_X:
		if( rightColWidth == 0 )
			rightColWidth = Height;
		TypedLibID = 'X2ClearButton';
		break;	
	case eUIConfirmButtonStyle_Check:
		if( rightColWidth == 0 )
			rightColWidth = Height;
		TypedLibID = 'X2CheckButton';
		break;
	case eUIConfirmButtonStyle_BuyEngineering:
		if( rightColWidth == 0 )
			rightColWidth = Height;
		TypedLibID = 'X2BuyEngineeringButton';
		break;
	case eUIConfirmButtonStyle_BuyScience:
		if( rightColWidth == 0 )
			rightColWidth = Height;
		TypedLibID = 'X2BuyScienceButton';
		break;
	case eUIConfirmButtonStyle_BuyCash:
		if( rightColWidth == 0 )
			rightColWidth = Height;
		TypedLibID = 'X2CashButton';
		break;
	case eUIConfirmButtonStyle_Default:
	default:
		TypedLibID = 'X2ConfirmButton';
		break;
	}

	if( ConfirmButtonStyle != NewStyle || ConfirmText != txt )
	{
		ConfirmText = txt;
		ConfirmButtonStyle = NewStyle;

		ConfirmButtonStoredRightCol = rightColWidth;
		ConfirmButtonStoredTopRow = topRowHeight;

		if( ConfirmButton == None )
		{
			ConfirmButton = Spawn(class'UIButton', self);
			ConfirmButton.LibID = TypedLibID;
			ConfirmButton.InitButton();
			ConfirmButton.SetResizeToText(true);
			ConfirmButton.OnClickedDelegate = ConfirmButtonClick != None ? ConfirmButtonClick : OnClickedConfirmButton;
			ConfirmButton.OnDoubleClickedDelegate = ConfirmButtonDoubleClick != None ? ConfirmButtonDoubleClick : OnClickedConfirmButton;
			ConfirmButton.OnMouseEventDelegate = OnChildMouseEvent;
			ConfirmButton.OnSizeRealized = RefreshConfirmButtonLocation;
			ConfirmButton.SetY(ConfirmButtonStoredTopRow);
			ConfirmButton.DisableNavigation();
			ConfirmButton.SetHeight(34);
		}

		if( ConfirmButtonStyle == eUIConfirmButtonStyle_Default )
		{
			ConfirmButton.SetText(ConfirmText);
		}

		ConfirmButton.SetX(Width - ConfirmButton.Width - ConfirmButtonStoredRightCol);
		ConfirmButton.SetDisabled(bDisabled);
		ConfirmButton.SetBad(bIsBad);
		RefreshConfirmButtonVisibility();
		Navigator.SetSelected(ConfirmButton);
	}

	return self;
}

simulated function RefreshConfirmButtonLocation()
{
	ConfirmButton.SetX(Width - ConfirmButton.Width - ConfirmButtonStoredRightCol);
	RefreshConfirmButtonVisibility();
}

simulated function RefreshConfirmButtonVisibility()
{
	if( ConfirmButton != none )
	{
		if( bIsFocused )
		{
			// initially it seems as though the visible flag gets stuck to true when it hasn't displayed yet. Turn off and on again.
			ConfirmButton.SetVisible(false);
			ConfirmButton.SetVisible(!bIsBad && !bDisabled);
			if( bIsBad || bDisabled )
			{
				SetRightColPadding( AttentionIconPadding + ConfirmButtonStoredRightCol );
			}
			else
			{
				SetRightColPadding(ConfirmButton.Width + ConfirmButtonArrowWidth + AttentionIconPadding + ConfirmButtonStoredRightCol);
			}
			if( `ISCONTROLLERACTIVE )
			{
				ConfirmButton.OnReceiveFocus();
			}
		}
		else
		{
			ConfirmButton.SetVisible(false);
			SetRightColPadding(ConfirmButtonStoredRightCol + AttentionIconPadding);
			if( `ISCONTROLLERACTIVE )
			{
				ConfirmButton.OnLoseFocus();
			}
		}
	}
	else
	{
		SetRightColPadding(ConfirmButtonStoredRightCol + AttentionIconPadding);
	}

}

simulated function OnClickedConfirmButton(UIButton Button)
{
	if( Button == ConfirmButton )
	{
		List.OnChildMouseEvent(self, class'UIUtilities_Input'.const.FXS_L_MOUSE_DOUBLE_UP);
	}
}

simulated function UIListItemString EnableListItem()
{
	return SetDisabled(false);
}
simulated function UIListItemString DisableListItem(optional string TooltipText)
{
	return SetDisabled(true, TooltipText);
}

simulated function UIListItemString SetDisabled(bool disabled, optional string TooltipText)
{
	if(disabled != bDisabled)
	{
		bDisabled = disabled;
		if(bDisabled)
			mc.FunctionVoid("disable");
		else
			mc.FunctionVoid("enable");

		if( ConfirmButton != none )
		{
			ConfirmButton.SetDisabled(bDisabled);
		}
	}

	RefreshConfirmButtonVisibility();

	// Set tooltip on BG since that's where our mouse events originate from
	if(TooltipText != "")
		ButtonBG.SetTooltipText(TooltipText);
	else if(ButtonBG.bHasTooltip)
		ButtonBG.RemoveTooltip();

	return self;
}

simulated function ShouldShowGoodState(bool isGood, optional string TooltipText)
{
	if( bIsGood != isGood )
	{
		bIsGood = isGood;
		if( bIsGood )
			mc.FunctionVoid("setGood");
		else
			mc.FunctionVoid("clearGood");
	}

	RefreshConfirmButtonVisibility();

	// Set tooltip on BG since that's where our mouse events originate from
	if( TooltipText != "" )
		ButtonBG.SetTooltipText(TooltipText);
	else if( ButtonBG.bHasTooltip )
		ButtonBG.RemoveTooltip();
}


simulated function UIListItemString SetBad(bool isBad, optional string TooltipText)
{
	if( bIsBad != isBad )
	{
		bIsBad = isBad;
		if( bIsBad )
			mc.FunctionVoid("setBad");
		else
			mc.FunctionVoid("clearBad");

		//ButtonBG.SetBad(bIsBad, TooltipText);

		if( ConfirmButton != none )
		{
			ConfirmButton.SetBad(bIsBad);
		}
	}

	RefreshConfirmButtonVisibility();

	// Set tooltip on BG since that's where our mouse events originate from
	if( TooltipText != "" )
		ButtonBG.SetTooltipText(TooltipText);
	else if( ButtonBG.bHasTooltip )
		ButtonBG.RemoveTooltip();

	return self;
}

simulated function UIListItemString SetWarning(bool isWarning, optional string TooltipText)
{
	if( bIsWarning != isWarning )
	{
		bIsWarning = isWarning;
		if( bIsWarning )
			mc.FunctionVoid("setWarning");
		else
			mc.FunctionVoid("clearWarning");

		//ButtonBG.SetWarning(bIsWarning, TooltipText);

		if( ConfirmButton != none )
		{
			ConfirmButton.SetWarning(bIsWarning);
		}
	}

	RefreshConfirmButtonVisibility();

	// Set tooltip on BG since that's where our mouse events originate from
	if( TooltipText != "" )
		ButtonBG.SetTooltipText(TooltipText);
	else if( ButtonBG.bHasTooltip )
		ButtonBG.RemoveTooltip();

	return self;
}

simulated function SetTooltipText(string TooltipText, 
								  optional string Title,
								  optional float OffsetX,
								  optional float OffsetY, 
								  optional bool bRelativeLocation   = class'UITextTooltip'.default.bRelativeLocation,
								  optional int TooltipAnchor        = class'UITextTooltip'.default.Anchor, 
								  optional bool bFollowMouse        = class'UITextTooltip'.default.bFollowMouse,
								  optional float Delay              = class'UITextTooltip'.default.tDelay)
{
	//Pass along to our ButtonBG, since that is the path that will process back.
	ButtonBG.SetTooltipText(TooltipText, Title, OffsetX, OffsetY, bRelativeLocation, TooltipAnchor, bFOllowMouse, Delay);
}


simulated function OnChildMouseEvent(UIPanel control, int cmd)
{
	switch( cmd )
	{
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_IN:
		MC.FunctionVoid("mouseIn");
		if( !List.bStickyClickyHighlight ) //selection on roll over 
		{
			OnReceiveFocus();
			// You need to let the list know about the mouse in, because a default selection on the list needs to be cleared 
			// if you mouseIn directly on another item.
			List.SetSelectedItem(self);
		}
		break;

	case class'UIUtilities_Input'.const.FXS_L_MOUSE_UP_DELAYED :
		if( List.bStickyClickyHighlight ) //selection on click 
		{
			// You need to let the list know about the mouse in, because a default selection on the list needs to be cleared 
			// if you mouseIn directly on another item.
			List.SetSelectedItem(self);
		}
		break;
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_OUT:
		if( !List.bStickyHighlight && !List.bStickyClickyHighlight )
		{
			OnLoseFocus();
			MC.FunctionVoid("mouseOut");
		}
		else if( List.bStickyClickyHighlight && List.GetSelectedItem() != self )
		{
			OnLoseFocus();
			MC.FunctionVoid("mouseOut");
		}
		break;
	}
}

simulated function OnLoseFocus()
{
	super.OnLoseFocus();
	if( List.bStickyHighlight )
	{
		MC.FunctionVoid("mouseOut");
	}
	else if( List.bStickyClickyHighlight && List.GetSelectedItem() != self )
	{
		MC.FunctionVoid("mouseOut");
	}

	RefreshConfirmButtonVisibility();
}

simulated function OnReceiveFocus()
{
	super.OnReceiveFocus();

	if( List.bStickyClickyHighlight )
	{
		List.SetSelectedItem(self);
	}

	RefreshConfirmButtonVisibility();
}


simulated function Hide()
{
	super.Hide();
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	if ( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg) )
		return false;

	if ((cmd == class'UIUtilities_Input'.const.FXS_KEY_ENTER ||
		 cmd == class'UIUtilities_Input'.const.FXS_BUTTON_A ||
		 cmd == class'UIUtilities_Input'.const.FXS_KEY_SPACEBAR))
	{
		if( ConfirmButton != none ) 
			return ConfirmButton.OnUnrealCommand(cmd, arg);

		// Start Issue #47: navigable button bg for UIListItemString start
		if (ButtonBG.OnUnrealCommand(cmd, arg))
		{
			return true;
		}
		// End Issue #47
	}

	return Navigator.OnUnrealCommand(cmd, arg);
}

defaultproperties
{
	LibID = "XComListItemString";
	bDisabled = false;
	bShouldSet3DHeight = true;

	width = 207; // size according to flash movie clip
	height = 37; // size according to flash movie clip

	ConfirmButtonStyle = eUIConfirmButtonStyle_NONE;
	ButtonBGLibID = "theButton"; // in flash 
	bCascadeFocus = false;
	RightColDefaultPadding = 12;
	ConfirmButtonArrowWidth = 10;
	DefaultAttentionIconPadding = 14; 
	ConfirmButtonStoredRightCol = 12; //Default to RightColDefaultPadding
}

