//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIEvent Queue 
//  AUTHOR:  Samuel Batista, Brit Steiner 
//  PURPOSE: Strategy game event queue and time display. 
//
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIEventQueue extends UIPanel;

var UIList		List;
var UIText		TimeDisplay;
var UIText		DateDisplay;
var UIButton    ExpandButton;

var localized string            ExpandButtonLabel;
var localized string            ShrinkButtonLabel;

var bool                        bIsExpanded;

// list item delegates to callback when their buttons are clicked
delegate OnUpButtonClicked(int ItemIndex);
delegate OnDownButtonClicked(int ItemIndex);
delegate OnCancelButtonClicked(int ItemIndex);

simulated function UIEventQueue InitEventQueue()
{
	InitPanel();

	AnchorBottomRight();

	//Scoot back over a little, relative to the flash asset locations. 
	SetY(-120);
	
	ExpandButton = Spawn(class'UIButton', self);
	ExpandButton.InitButton('ExpandButtonMC', "", ToggleExpanded);
	ExpandButton.DisableNavigation();

	List = Spawn(class'UIList', self);
	List.InitList('', -125, 0, Width, Height, , false);
	List.Navigator.HorizontalNavigation = false;
	List.bStickyHighlight = false;
	HideList();

	Navigator.HorizontalNavigation = false;

	return self;
}

simulated function UpdateEventQueue(array<HQEvent> Events, bool bExpand, bool EnableEditControls)
{
	local bool bIsInStrategyMap, bHasEvents;
	local int i, NumItemsToShow;
	local UIEventQueue_ListItem ListItem;

	bIsExpanded = bExpand;
	bHasEvents = false;

	if(EnableEditControls)
	{
		// no shrinking if we are using edit controls, user needs to see stuff
		ExpandButton.Hide();
		bIsExpanded = true;
	}
	else if(Events.Length > 1) 
	{
		ExpandButton.Show();

		//This special funciton will also format location on the timeline. 
		if(bIsExpanded)
			MC.FunctionString("SetExpandButtonText", ShrinkButtonLabel);
		else
			MC.FunctionString("SetExpandButtonText", ExpandButtonLabel);

		//No buttons when in the strategy map. 
		if( UIStrategyMap(Movie.Stack.GetCurrentScreen()) != none )
		{
			ExpandButton.Hide();
			bIsExpanded = true;
		}
	}
	else
	{
		ExpandButton.Hide();
		bIsExpanded = false;
	}

	bIsInStrategyMap = `ScreenStack.IsInStack(class'UIStrategyMap');
	// Single Line for Issue #1578 - Allow mods to display the event queue while flying
	if (Events.Length > 0 && !bIsInStrategyMap || (`HQPRES.StrategyMap2D != none && (class'CHHelpers'.default.bShowEventQueueWhileFlying || `HQPRES.StrategyMap2D.m_eUIState != eSMS_Flight)))
	{
		if( bIsExpanded )
		{
			NumItemsToShow = Events.Length;
		}
		else
		{
			//Look through all events
			for (i = 0; i < Events.Length; i++)
			{
				if (Events[i].bActionEvent)
					bHasEvents = true;
			}

			if( bHasEvents )
				NumItemsToShow = 2; //If there's a covert action, show the action plus one event item. 
			else
				NumItemsToShow = 1;
		}
		
		if( List.ItemCount != NumItemsToShow )
			List.ClearItems();

		//Look through all events
		for( i = 0; i < Events.Length; i++ )
		{
			// Display the number of items to show PLUS all covert action events. 
			// Covert actions should never hide. 
			if( i < NumItemsToShow || Events[i].bActionEvent )
			{
				if( List.ItemCount <= i )
				{
					if( Events[i].bActionEvent )
						ListItem = Spawn(class'UIEventQueue_CovertActionListItem', List.itemContainer).InitListItem();
					else
						ListItem = Spawn(class'UIEventQueue_ListItem', List.itemContainer).InitListItem();

					ListItem.OnUpButtonClicked = OnUpButtonClicked;
					ListItem.OnDownButtonClicked = OnDownButtonClicked;
					ListItem.OnCancelButtonClicked = OnCancelButtonClicked;
				}
				else
					ListItem = UIEventQueue_ListItem(List.GetItem(i));

				ListItem.UpdateData(Events[i]);

				// determine which buttons the item should show based on it's location in the list 
				ListItem.AS_SetButtonsEnabled(EnableEditControls && i > 0,
											  EnableEditControls && i < (NumItemsToShow - 1),
											  EnableEditControls);
			}
		}

		List.SetY( -List.ShrinkToFit() - 10 );
		List.SetX( -List.GetTotalWidth() ); // This will take in to account the scrollbar padding or not, and stick the list neatly to the right edge of screen. 
		ShowList();
	}
	else
	{
		HideList();
	}
	
	RefreshDateTime();
}

function RefreshDateTime()
{
	local TDateTime dateTimeData;
	local string Hours, Minutes, Suffix;
	local XComGameState_HeadquartersXCom XComHQ;
	// Variables for Issue #1578 
	local TDateTime UTCTimeData;
	local string UTCHours, UTCMinutes, UTCSuffix;
	local int timeZoneDifference;
	local XComGameState_GeoscapeEntity DestinationEntity;
	local XComGameState_Skyranger Skyranger;

	if( `GAME.GetGeoscape() == none ) return; // stop log spam when in the shell testing. 

	// UNCOMMENT TO MAKE THE STOPPED CLOCK APPEAR RED
	//isGeoscapePaused = false;
	//isGeoscapePaused = `GAME.GetGeoscape().IsPaused();
	//eUIState_IsGeoscapePaused = isGeoscapePaused ? eUIState_Bad : eUIState_Normal;

	//When showing time, either through time of day or the clock - always show local time
	dateTimeData = `GAME.GetGeoscape().m_kDateTime; 
	XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	
	// Start Issue #1578
	/// HL-Docs: feature:GeoscapeClockOptions; issue:1578; tags:strategy
	/// Provide easily adjustable options for display of the Geoscape time by modders, to make the time display more intuitive 
	/// when the skyranger is flying (in this case, options are: 1. The timezone is only updated when the avenger lands, 
	/// 2. The timezone is updated only when the skyranger takes off, 3. Display UTC at all times and display the timezone 
	/// difference on the clock UI.
	UTCTimeData = dateTimeData;
	
	if(!class'CHHelpers'.default.bForceUTCAtAllTimes)
	{
		// Base Game
		if(!XComHQ.Flying)
		{
			class'X2StrategyGameRulesetDataStructures'.static.GetLocalizedTime(XComHQ.Get2DLocation(), dateTimeData);
		}
		// Option 1 - Display the source timezone when flying & update when the Avenger lands
		else if(class'CHHelpers'.default.bUseSourceTimeZoneWhenFlying)
		{
			class'X2StrategyGameRulesetDataStructures'.static.GetLocalizedTime(XComHQ.SourceLocation, dateTimeData);
		}
		// Option 2 - Display the destination timezone on takeoff
		else if(class'CHHelpers'.default.bUseDestinationTimeZoneWhenFlying)
		{
			DestinationEntity = XComGameState_GeoscapeEntity(`XCOMHISTORY.GetGameStateForObjectID(XComHQ.SelectedDestination.ObjectID));
			class'X2StrategyGameRulesetDataStructures'.static.GetLocalizedTime(DestinationEntity.Get2DLocation(), dateTimeData);
		}
		class'X2StrategyGameRulesetDataStructures'.static.GetTimeStringSeparated(dateTimeData, Hours, Minutes, Suffix);

		MC.BeginFunctionOp("RefreshDateTime");
		MC.QueueString(class'X2StrategyGameRulesetDataStructures'.static.GetDateString(dateTimeData));
		//RED: //MC.QueueString(class'UIUtilities_Text'.static.GetColoredText(class'X2StrategyGameRulesetDataStructures'.static.GetTimeString(dateTimeData), eUIState_IsGeoscapePaused));
		MC.QueueString(Hours);
		MC.QueueString(Minutes);
		MC.QueueString(Suffix);
		MC.EndOp();
	}
	else
	{
		// Option 3 - If bForceUTCAtAllTimes, the clock stays on UTC & displays the timezone as +/- instead of the AM/PM suffix
		If(XComHQ.IsSkyrangerDocked())
		{
			class'X2StrategyGameRulesetDataStructures'.static.GetLocalizedTime(XComHQ.Get2DLocation(), dateTimeData);
		}
		else
		{
			Skyranger = XComGameState_Skyranger(`XCOMHISTORY.GetGameStateForObjectID(XComHQ.SkyrangerRef.ObjectID));
			class'X2StrategyGameRulesetDataStructures'.static.GetLocalizedTime(Skyranger.Get2DLocation(), dateTimeData);
		}
		class'X2StrategyGameRulesetDataStructures'.static.GetTimeStringSeparated(UTCTimeData, UTCHours, UTCMinutes, UTCSuffix);		
		timeZoneDifference = class'X2StrategyGameRulesetDataStructures'.static.GetHour(dateTimeData) - class'X2StrategyGameRulesetDataStructures'.static.GetHour(UTCTimeData);

		if (timeZoneDifference < -12)
		{
			timeZoneDifference += 24;
		}
		else if (timeZoneDifference > 12)
		{
			timeZoneDifference -= 24;
		}
		// If we're on the international date line, display +12 instead of +12 or -12 depending which side we came from
		if (timeZoneDifference == -12)
		{		
			timeZoneDifference = 12;
		}
		MC.BeginFunctionOp("RefreshDateTime");
		MC.QueueString(class'X2StrategyGameRulesetDataStructures'.static.GetDateString(UTCTimeData));
		MC.QueueString(UTCHours);
		MC.QueueString(UTCMinutes);
		MC.QueueString(timeZoneDifference >=0 ? "+" $ string(timeZoneDifference) : string(timeZoneDifference));
		MC.EndOp();
	}
	// End Issue #1578	
}

simulated function HideDateTime()
{
	MC.FunctionVoid("HideDateTime");
}

simulated function ShowList()
{
	List.Show();
}

simulated function HideList()
{
	List.Hide();
}

simulated function DeactivateButtons()
{
	local int i; 
	
	for( i = 0; i < List.ItemCount; i++ )
	{
		List.GetItem(i).OnLoseFocus();
	}
}

simulated function ToggleExpanded(UIButton Button)
{
	bIsExpanded = !bIsExpanded;

	`SOUNDMGR.PlaySoundEvent("Generic_Mouse_Click");
	
	if( bIsExpanded ) 
		`SOUNDMGR.PlaySoundEvent("Play_MenuOpenSmall");
	else
		`SOUNDMGR.PlaySoundEvent("Play_MenuCloseSmall");

	//Need to clear items here, to force refresh of possible covert action line items 
	List.ClearItems();
	UIAvengerHUD(Screen).ShowEventQueue(bIsExpanded);
}

simulated function int GetListItemCount()
{
	return List.ItemCount;
}
simulated function bool OnUnrealCommand(int cmd, int arg)
{
	if (!CheckInputIsReleaseOrDirectionRepeat(cmd, arg))
	{
		return false;
	}

	switch (cmd)
	{
		case class'UIUtilities_Input'.const.FXS_BUTTON_R3:
			if (bIsVisible && ExpandButton.bIsVisible) 
			{
				ToggleExpanded(none);
				return true;
			}

		case class'UIUtilities_Input'.const.FXS_BUTTON_RTRIGGER:  
			if(OnUpButtonClicked != none && List.SelectedIndex > 0)
			{
        		OnUpButtonClicked(List.SelectedIndex); 
			}
			break; 

        case class'UIUtilities_Input'.const.FXS_BUTTON_LTRIGGER:    
        	if(OnDownButtonClicked != none && List.SelectedIndex >= 0 && List.SelectedIndex < List.ItemCount - 1)
        	{
				OnDownButtonClicked(List.SelectedIndex);
        	}
        	break; 

        case class'UIUtilities_Input'.const.FXS_BUTTON_X: //bsg-jneal (5.12.17): moving input to X/SQUARE
        	if(OnCancelButtonClicked != none)
        	{
				OnCancelButtonClicked(List.SelectedIndex);
        	}
			break;
	}

	return super.OnUnrealCommand(cmd, arg);
}
defaultproperties
{
	bIsExpanded = false;
	LibID = "X2EventList";

	Width = 355;
	Height = 700; 
	bIsNavigable = false; 
}
