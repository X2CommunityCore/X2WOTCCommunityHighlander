//----------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIX2PanelHeader.uc
//  AUTHOR:  Jason Montgomery
//  PURPOSE: 
//----------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//----------------------------------------------------------------------------

class UIX2PanelHeader extends UIPanel;

var string title;
var string label;
var int headerWidth;
var bool flipped;

simulated function UIX2PanelHeader InitPanelHeader( optional name InitName, optional string initTitle, optional string initLabel )
{
	InitPanel(InitName);
	SetText(initTitle, initLabel);
	return self;
}

simulated function SetHeaderWidth( int theWidth, optional bool flip )
{
	if(theWidth != headerWidth || flip != flipped)
	{
		headerWidth = theWidth;
		flipped = flip;

		mc.BeginFunctionOp("setWidth");
		mc.QueueNumber(headerWidth);	
		mc.QueueBoolean(flipped);
		mc.EndOp();
	}
}

simulated function SetText( optional string theTitle, optional string theLabel )
{
	if(theTitle != title || theLabel != label)
	{
		title = theTitle;
		label = theLabel;

		mc.BeginFunctionOp("setText");
		mc.QueueString(title);
		mc.QueueString(label);
		mc.EndOp();
	}
}

defaultproperties
{
	LibID = "X2PanelHeader";
	height = 80;
}