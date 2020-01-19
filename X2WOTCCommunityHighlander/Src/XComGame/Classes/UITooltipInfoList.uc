//---------------------------------------------------------------------------------------
//  FILE:    UITooltipInfoList.uc
//  AUTHOR:  Brit Steiner --  4/3/2015
//  PURPOSE: This is an autoformatting list of data in a window, used in weapon and other tooltips. 
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class UITooltipInfoList extends UIPanel;

var UIPanel BG; 
var UIScrollingText TitleTextField;
var array<UIText> LabelFields;
var array<UIText> DescriptionFields;

var float LineHeight;
var float PADDING_LEFT;
var float PADDING_RIGHT;

// this delegate is triggered when Text size is calculated after setting Text data
delegate OnTextSizeRealized();

simulated function UITooltipInfoList InitTooltipInfoList(optional name InitName,
										  optional name InitLibID = '', 
										  optional int InitX = 0, 
										  optional int InitY = 0, 
										  optional int InitWidth, 
										  optional delegate<OnTextSizeRealized> TextSizeRealizedDelegate,
										  optional float InitLeftPadding = 14,
										  optional float InitRightPadding = 14)
{
	InitPanel(InitName, InitLibID);
	
	SetPosition(InitX, InitY);

	//We don't want to scale the movie clip, but we do want to save the values for formatting. 
	width = InitWidth;
	
	BG = Spawn(class'UIPanel', self).InitPanel('BGBoxSimple', class'UIUtilities_Controls'.const.MC_X2BackgroundSimple).SetSize(width, height);

	OnTextSizeRealized = TextSizeRealizedDelegate; 

	return self; 
}

simulated function RefreshData(array<UISummary_ItemStat> SummaryItems)
{
	RefreshDisplay(SummaryItems);
}

simulated function RefreshDisplay(array<UISummary_ItemStat> SummaryItems)
{
	local int i;
	local UIText LabelField, DescriptionField;

	if( SummaryItems.Length == 0 )
	{
		Hide();
		Height = 0;
		OnTextSizeRealized();
		return;
	}

	if( TitleTextField == none )
	{
		TitleTextField = Spawn(class'UIScrollingText', self).InitScrollingText('Title', "", width - PADDING_RIGHT - PADDING_LEFT, PADDING_LEFT);
	}
	TitleTextField.SetHTMLText(class'UIUtilities_Text'.static.StyleText(SummaryItems[0].Label, SummaryItems[0].LabelStyle));
	
	for( i = 1; i < SummaryItems.Length; i++ )
	{
		// Place new items if we need to. 
		if( i > LabelFields.Length)
		{
			LabelField = Spawn(class'UIText', self).InitText(Name("Label"$i));
			LabelField.SetWidth(Width - PADDING_LEFT - PADDING_RIGHT);
			LabelField.SetX(PADDING_LEFT);
			LabelFields.AddItem(LabelField);

			DescriptionField = Spawn(class'UIText', self).InitText(Name("Description"$i));
			DescriptionField.SetWidth(Width - PADDING_LEFT - PADDING_RIGHT);
			DescriptionField.SetX(PADDING_LEFT);
			DescriptionFields.AddItem(DescriptionField);
		}
		
		LabelField = LabelFields[i - 1];
		LabelField.SetHTMLText(class'UIUtilities_Text'.static.StyleText(SummaryItems[i].Label, SummaryItems[i].LabelStyle), OnChildTextRealized);
		LabelField.Show();
		LabelField.AnimateIn();

		DescriptionField = DescriptionFields[i - 1];
		DescriptionField.SetHTMLText(class'UIUtilities_Text'.static.StyleText(SummaryItems[i].Value, SummaryItems[i].ValueStyle), OnChildTextRealized);
		DescriptionField.Show();
		DescriptionField.AnimateIn();
	}

	// Hide any excess list items if we didn't use them. 
	/// HL-Docs: ref:Bugfixes; issue:303
	/// `UITooltipInfoList` no longer displays stale data like weapon upgrades from other units
	for( i = SummaryItems.Length - 1; i < LabelFields.Length; i++ ) // Issue #303, fix off-by-one error
	{
		LabelFields[i].Hide();
		DescriptionFields[i].Hide();
	}

	OnChildTextRealized();
}


simulated function DebugControl()
{
	local int i; 

	Spawn(class'UIPanel', self).InitPanel(, class'UIUtilities_Controls'.const.MC_GenericPixel).SetSize(width, height).SetAlpha(40);

	for( i = 0; i < LabelFields.Length; i++ )
	{
		LabelFields[i].DebugControl();
		DescriptionFields[i].DebugControl();
	}
}

simulated function OnChildTextRealized()
{
	local int i, NumVisible;
	local float CurrentY;
	local bool bAllTextRealized; 
	local UIText Label, Desc; 

	bAllTextRealized = true;
	CurrentY = TitleTextField.Height;

	for( i = 0; i < LabelFields.Length; i++ )
	{
		// LABELS ----------------------
		Label = LabelFields[i];

		if(!Label.bIsVisible || Label.HtmlText == "")
			continue;

		if(Label.HtmlText != "" && !Label.TextSizeRealized)
		{
			bAllTextRealized = false;
			break;
		}
		Label.SetY(CurrentY);

		CurrentY += Label.Height;

		// DESCRIPTIONS --------------
		Desc = DescriptionFields[i];
		if(Desc.HtmlText != "" && !Desc.TextSizeRealized)
		{
			bAllTextRealized = false;
			break;
		}
		Desc.SetY(CurrentY);
		CurrentY += Desc.Height + 10;
		NumVisible++;
	}

	if(bAllTextRealized)
	{
		Show();
		CurrentY += 5; //Bottom edge. 
		Height = CurrentY;
		BG.SetHeight(Height);
		if(OnTextSizeRealized != none)
			OnTextSizeRealized();
	} 
	else if(NumVisible == 0)
	{
		Hide();
		Height = 0;
		if(OnTextSizeRealized != none)
			OnTextSizeRealized();
	}
}

//Defaults: ------------------------------------------------------------------------------
defaultproperties
{
	LineHeight = 22.0; 
	PADDING_LEFT	= 14.0;
	PADDING_RIGHT	= 14.0;
}