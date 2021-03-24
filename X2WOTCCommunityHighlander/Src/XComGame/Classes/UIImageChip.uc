//----------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIImageChip.uc
//  AUTHOR:  Brittany Steiner 9/1/2014
//  PURPOSE: UIPanel to for an image chip in the image selector grid. 
//----------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//----------------------------------------------------------------------------

class UIImageChip extends UIPanel;

var UIBGBox BG;  
var UIBGBox Highlight;  
var UIImage Image; 
var int index; 
var int Row; 
var int Col; 
var int PADDING_HIGHLIGHT;

delegate OnSelectDelegate(int iColorIndex);
delegate OnAcceptDelegate(int iColorIndex);

simulated function UIImageChip InitImageChip( optional name InitName, 
											optional int initIndex = -1,
											optional string initImagePath,
											optional string initLabel = "",
											optional float initX = 0,
											optional float initY = 0,
											optional float initSize = 0,
											optional float initRow = -1,
											optional float initCol = -1,
											optional delegate<OnSelectDelegate> initSelectDelegate,
											optional delegate<OnAcceptDelegate> initAcceptDelegate)
{
	InitPanel(InitName);

	Highlight = Spawn(class'UIBGBox', self);
	Highlight.bAnimateOnInit = false;
	Highlight.bIsNavigable = false;
	Highlight.InitBG('ChipHighlight');
	Highlight.SetColor(class'UIUtilities_Colors'.const.HILITE_HTML_COLOR);
	Highlight.Hide();
	
	Image = Spawn(class'UIImage', self);
	Image.bIsNavigable = false;
	Image.bAnimateOnInit = false;
	Image.InitImage('ImageChip', initImagePath);

	SetPosition(initX, initY);
	
	if( initSize != 0 )
		SetSize(initSize, initSize);
	else
		SetSize( class'UIImageChip'.default.width, class'UIImageChip'.default.height);

	index = initIndex;
	Row = initRow;
	Col = initCol; 

	OnSelectDelegate = initSelectDelegate;
	OnAcceptDelegate = initAcceptDelegate;

	Navigator.OnSelectedIndexChanged = OnSelectDelegate;

	return self; 
}

simulated function UIPanel SetSize(float newWidth, float newHeight)
{
	SetWidth(newWidth);
	SetHeight(newHeight);

	return self; 
}
simulated function SetWidth(float newWidth)
{
	width = newWidth;

	//Issue #295
	//Highlight.SetX( BG.X - (PADDING_HIGHLIGHT * 0.5) );
	//Call Highlight.SetX() with different 0 instead of BG.X if BG is 'none'.
	if (BG != none)
	{
		BG.SetWidth(width);
		Highlight.SetX( BG.X - (PADDING_HIGHLIGHT * 0.5) );
	}
	else
	{
		Highlight.SetX( 0 - (PADDING_HIGHLIGHT * 0.5) );
	}
	Highlight.SetWidth( PADDING_HIGHLIGHT + width );
	Image.SetWidth(width);
	//Image.SetX(BG.X);
}
simulated function SetHeight(float newHeight)
{
	height = newHeight;

	//Issue #295 - Add a 'none' check before accessing BG.
	//Highlight.SetY( BG.Y - (PADDING_HIGHLIGHT * 0.5) );
	//Call Highlight.SetY() with different 0 instead of BG.Y if BG is 'none'.
	if (BG != none)
	{
		BG.SetHeight(height);
		Highlight.SetY( BG.Y - (PADDING_HIGHLIGHT * 0.5) );
	}
	else
	{
		Highlight.SetY( 0 - (PADDING_HIGHLIGHT * 0.5) );
	}
	Highlight.SetHeight( PADDING_HIGHLIGHT + height );
	Image.SetHeight(height);
}

simulated function UIPanel LoadImage(string imagePath)
{
	Image.LoadImage(imagePath);
	return self; 
}

simulated function OnReceiveFocus()
{
	Highlight.Show();
	if(OnSelectDelegate != none)
		OnSelectDelegate( index );
}

simulated function OnLoseFocus()
{
	Highlight.Hide();
}

//------------------------------------------------------

simulated function OnMouseEvent(int cmd, array<string> args)
{
	super.OnMouseEvent(cmd, args);

	switch(cmd)
	{
		//TODO: this control BG doesn't get in and out calls yet, so these don't trigger. 
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_IN:
		OnReceiveFocus();
		break;
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_OUT:
		OnLoseFocus();
		break;
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_UP:
		if(OnAcceptDelegate != none)
			OnAcceptDelegate( index );
		break;
	}
}

//------------------------------------------------------

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	if( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg) )
		return false;

	switch( cmd )
	{
		case class'UIUtilities_Input'.const.FXS_BUTTON_A:
		case class'UIUtilities_Input'.const.FXS_KEY_ENTER:
		case class'UIUtilities_Input'.const.FXS_KEY_SPACEBAR:
			if(OnAcceptDelegate != none)
			{
				OnAcceptDelegate( index );
			}
			return true;
		default:
			if (Navigator.OnUnrealCommand(cmd, arg))
			{
				return true;
			}
			break;
	}

	return false;
}

//------------------------------------------------------


defaultproperties
{
	bIsNavigable = true;
	bAnimateOnInit = false;
	bProcessesMouseEvents = true;

	width = 64; 
	height = 64;

	PADDING_HIGHLIGHT = 6; 
}
