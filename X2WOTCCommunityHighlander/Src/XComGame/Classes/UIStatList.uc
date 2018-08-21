//---------------------------------------------------------------------------------------
//  FILE:    UIStatList.uc
//  AUTHOR:  Brit Steiner --  6/24/2014
//  PURPOSE: This is an autoformatting list of data in a column. Labels will autoscroll, 
//			 while values will right align and not scroll. Alternating background 
//			 tint slightly. 
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class UIStatList extends UIPanel;


struct TUIStatList_Item
{
	var int ID;
	var UIPanel BG; 
	var UIScrollingText Label;
	var UIText Value;
};

var float PADDING_LEFT;
var float PADDING_RIGHT;
var float VALUE_COL_SIZE; 

var float LineHeight;
var float LineHeight3D;
var array<TUIStatList_Item> Items;

delegate OnSizeRealized();

simulated function UIPanel InitStatList(optional name InitName, 
										  optional name InitLibID = '', 
										  optional int InitX = 0, 
										  optional int InitY = 0, 
										  optional int InitWidth, 
										  optional int InitHeight, 
										  optional float InitLeftPadding = 14, 
										  optional float InitRightPadding = 14)  
{
	InitPanel(InitName, InitLibID);
	
	SetPosition(InitX, InitY);

	//We don't want to scale the movie clip, but we do want to save the values for column formatting. 
	width = InitWidth; 
	height = InitHeight; 
	
	PADDING_LEFT = InitLeftPadding;
	PADDING_RIGHT = InitRightPadding;

	return self; 
}

simulated function RefreshData(array<UISummary_ItemStat> Stats, optional bool bAnimateIn = true)
{
	local int i, ActualLineHeight;
	local TUIStatList_Item Item;

	ActualLineHeight = Screen.bIsIn3D ? LineHeight3D : LineHeight;

	// Issue #235 start
	class'CHHelpers'.static.GroupItemStatsByLabel(Stats);
	// Issue #235 end

	for( i = 0; i < Stats.Length; i++ )
	{
		// Place new items if we need to. 
		if( i > Items.Length-1 )
		{
			Item.ID = i; 

			//Alternating lines have shaded background
			if( i % 2 == 0 )
			{
				Item.BG = Spawn(class'UIPanel', self).InitPanel(Name("BGShading"$i), class'UIUtilities_Controls'.const.MC_X2BackgroundShading).SetPosition(0, 3 + (i * ActualLineHeight)).SetSize(width, ActualLineHeight);
				Item.BG.bAnimateOnInit = bAnimateIn;
			}

			Item.Value = Spawn(class'UIText', self).InitText(Name("Value"$i));
			Item.Value.SetWidth(width - PADDING_RIGHT- PADDING_LEFT); 
			Item.Value.SetPosition(PADDING_RIGHT, i * ActualLineHeight); 
			Item.Value.bAnimateOnInit = bAnimateIn;

			Item.Label = Spawn(class'UIScrollingText', self).InitScrollingText(Name("Label"$i), "", width - PADDING_RIGHT - PADDING_LEFT, PADDING_LEFT, i * ActualLineHeight);
			Item.Label.bAnimateOnInit = bAnimateIn;

			Items.AddItem(Item);
		}
		
		// Grab our target item
		Item = Items[i]; 

		// Update the label
		if(Stats[i].LabelStyle == eUITextStyle_Tooltip_H1 || Stats[i].LabelStyle == eUITextStyle_Tooltip_H2 || Stats[i].LabelStyle == eUITextStyle_Tooltip_Body)
		{
			Item.Label.SetX(PADDING_LEFT);
			Item.Label.SetWidth( width );
		}
		else if(Stats[i].ValueStyle == eUITextStyle_Tooltip_HackStatValueLeft)
		{
			Item.Label.SetX(VALUE_COL_SIZE + PADDING_LEFT);
			Item.Label.SetWidth( width - PADDING_RIGHT- PADDING_LEFT - VALUE_COL_SIZE );
		}
		else
		{
			Item.Label.SetX(PADDING_LEFT);
			Item.Label.SetWidth( width - PADDING_RIGHT- PADDING_LEFT - VALUE_COL_SIZE );
		}

		Item.Label.SetHTMLText( class'UIUtilities_Text'.static.StyleText(Stats[i].Label, Stats[i].LabelStyle, Stats[i].LabelState, Screen.bIsIn3D));
		Item.Value.SetHTMLText( class'UIUtilities_Text'.static.StyleText(Stats[i].Value, Stats[i].ValueStyle, Stats[i].ValueState, Screen.bIsIn3D ));
		
		Item.Label.Show();
		Item.Value.Show();

		if(bAnimateIn) 
		{
			Item.Label.AnimateIn();
			Item.Value.AnimateIn(); 
		}

		if( i % 2 == 0 )
			Item.BG.Show();
	}


	// Hide any excess list items if we didn't use them. 
	for( i = Stats.Length; i < Items.Length; i++ )
	{
		Item = Items[i];
		Item.Label.Hide();
		Item.Value.Hide(); 
		Item.BG.Hide();
	}

	Height = Stats.Length * ActualLineHeight;

	if(OnSizeRealized != None)
		OnSizeRealized();
}

simulated function DebugControl()
{
	local int i; 

	Spawn(class'UIPanel', self).InitPanel(, class'UIUtilities_Controls'.const.MC_GenericPixel).SetSize(width, height).SetAlpha(20);

	for( i = 0; i < Items.Length; i++ )
	{
		Items[i].Label.DebugControl();
		Items[i].Value.DebugControl();
	}
}

//Defaults: ------------------------------------------------------------------------------
defaultproperties
{
	LineHeight = 22.0; 
	LineHeight3D = 30.0; 

	PADDING_LEFT	= 14.0;
	PADDING_RIGHT	= 14.0;
	VALUE_COL_SIZE	= 70;
}