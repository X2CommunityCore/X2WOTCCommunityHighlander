class UIAdventOperations extends UIX2SimpleScreen;

var public localized String m_strTitle;
var public localized String m_strTitleHelp;
var public localized String m_strTitleHelpPending;
var public localized String m_strTitleHelpActive;
var public localized String m_strStatusLabel;
var public localized String m_strPreparing;
var public localized String m_strActive;
var public localized String m_strAlienFacility;
var public localized String m_strRetaliation;
var public localized String m_strWeek;
var public localized String m_strWeeks;
var public localized String m_strImminent;
var public localized String m_strUnknown;
var public localized String m_strShowActiveButton;
var public localized String m_strShowPendingButton;
var public localized String m_strReveal;
var public localized String m_strEstimated;
var public localized String m_strUnlockButton;

var bool bResistanceReport;
var bool bShowActiveEvents;
var array<StateObjectReference> ChosenDarkEvents;
var array<StateObjectReference> ActiveDarkEvents;
var UIButton FlipButton;
var string TitleHelp;

var name DisplayTag;
var string CameraTag;

//-------------- UI LAYOUT --------------------------------------------------------
simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	super.InitScreen(InitController, InitMovie, InitName);

	if(bResistanceReport)
	{
		`XSTRATEGYSOUNDMGR.PlaySoundEvent("GeoscapeAlerts_ADVENTControl");
	}
		
	BuildScreen(true);

	if(bResistanceReport)
	{
		`HQPRES.CAMLookAtNamedLocation(CameraTag, `HQINTERPTIME);
	}

	`HQPRES.StrategyMap2D.ClearDarkEvents();
	`HQPRES.StrategyMap2D.Hide();
}

simulated function BuildScreen( optional bool bAnimateIn = false )
{
	local int idx, NumEvents;

	MC.FunctionVoid("HideAllCards");

	BuildTitlePanel();

	if( !bShowActiveEvents )
	{
		NumEvents = class'UIUtilities_Strategy'.static.GetAlienHQ().ChosenDarkEvents.Length;

		for( idx = 0; idx < NumEvents; idx++ )
		{
			BuildDarkEventPanel(idx, false);
		}
	}
	else if( !bResistanceReport )
	{
		NumEvents = ALIENHQ().ActiveDarkEvents.Length;
		for( idx = 0; idx < NumEvents; idx++ )
		{
			BuildDarkEventPanel(idx, true);
		}
	}
	MC.FunctionNum("SetNumCards", NumEvents);
	RefreshNav();
	if(bAnimateIn) 
		MC.FunctionVoid("AnimateIn");
}

simulated function RefreshNav()
{
	local UINavigationHelp NavHelp; 
	NavHelp = `HQPRES.m_kAvengerHUD.NavHelp;

	NavHelp.ClearButtonHelp();

	// Carry On
	NavHelp.AddBackButton(OnContinueClicked);
	if ( `ISCONTROLLERACTIVE && bResistanceReport)
	{
		NavHelp.AddContinueButton();
	}

	if( !bResistanceReport )
	{
		if( ALIENHQ().ActiveDarkEvents.Length > 0 )
		{
			if( `ISCONTROLLERACTIVE )
			{
				if( bShowActiveEvents )
				{
					NavHelp.AddCenterHelp(m_strShowPendingButton, class'UIUtilities_Input'.static.GetGamepadIconPrefix() $ class'UIUtilities_Input'.const.ICON_Y_TRIANGLE, FlipScreenMode);
				}
				else
				{
					NavHelp.AddCenterHelp(m_strShowActiveButton, class'UIUtilities_Input'.static.GetGamepadIconPrefix() $ class'UIUtilities_Input'.const.ICON_Y_TRIANGLE, FlipScreenMode);
				}
			}
			else
			{
				if( bShowActiveEvents )
				{
					NavHelp.AddCenterHelp(m_strShowPendingButton,, FlipScreenMode);
				}
				else
				{
					NavHelp.AddCenterHelp(m_strShowActiveButton, , FlipScreenMode);
				}
			}
		}

		// Carry On
		NavHelp.AddBackButton(OnContinueClicked);
	}
	else
	{
		NavHelp.AddContinueButton(OnContinueClicked);
	}
}

simulated function BuildTitlePanel()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersAlien AlienHQ;
	local XComGameState_MissionCalendar CalendarState;
	local int WeekDiff;
	local TDateTime RetalDate;
	local string WeeksDisplay, RetaliationDisplay;
	local bool bHaveRetaliation;

	History = `XCOMHISTORY;
	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));
	CalendarState = XComGameState_MissionCalendar(History.GetSingleGameStateObjectForClass(class'XComGameState_MissionCalendar'));

	if(bResistanceReport)
	{
		TitleHelp = m_strTitleHelp;
	}
	else
	{
		if( bShowActiveEvents )
			TitleHelp = m_strTitleHelpActive;
		else
			TitleHelp = m_strTitleHelpPending;
	}
	
	WeekDiff = (class'X2StrategyGameRulesetDataStructures'.static.DifferenceInDays(AlienHQ.FacilityBuildEndTime, `STRATEGYRULES.GameTime)/7);

	if(WeekDiff > 1)
	{
		WeeksDisplay = string(WeekDiff) @ m_strWeeks;
		WeeksDisplay= class'UIUtilities_Text'.static.GetColoredText(WeeksDisplay, eUIState_Warning2);
	}
	else if(WeekDiff == 1)
	{
		WeeksDisplay = string(WeekDiff) @ m_strWeek;
		WeeksDisplay= class'UIUtilities_Text'.static.GetColoredText(WeeksDisplay, eUIState_Warning2);
	}
	else
	{
		WeeksDisplay = m_strImminent; 
		WeeksDisplay= class'UIUtilities_Text'.static.GetColoredText(WeeksDisplay, eUIState_Bad);
	}

	if(CalendarState.GetNextDateForMissionSource('MissionSource_Retaliation', RetalDate))
	{
		WeekDiff = (class'X2StrategyGameRulesetDataStructures'.static.DifferenceInDays(RetalDate, `STRATEGYRULES.GameTime) / 7);
		bHaveRetaliation = true;

		if(WeekDiff > 1)
		{
			RetaliationDisplay = string(WeekDiff) @ m_strWeeks;
			RetaliationDisplay = class'UIUtilities_Text'.static.GetColoredText(RetaliationDisplay, eUIState_Warning2);
		}
		else if(WeekDiff == 1)
		{
			RetaliationDisplay = string(WeekDiff) @ m_strWeek;
			RetaliationDisplay = class'UIUtilities_Text'.static.GetColoredText(RetaliationDisplay, eUIState_Warning2);
		}
		else
		{
			RetaliationDisplay = m_strImminent;
			RetaliationDisplay = class'UIUtilities_Text'.static.GetColoredText(RetaliationDisplay, eUIState_Bad);
		}
	}
	else
	{
		bHaveRetaliation = false;
		RetaliationDisplay = m_strUnknown; 
	}

	MC.BeginFunctionOp("UpdateDarkEventData");
	MC.QueueString(m_strTitle);
	MC.QueueString(TitleHelp);

	// Alien Facility countdown
	if (AlienHQ.bHasSeenFacility && AlienHQ.bBuildingFacility && AlienHQ.AIMode != "Lose")
	{
		MC.QueueString(m_strAlienFacility);
		MC.QueueString(WeeksDisplay);
		MC.QueueString(m_strEstimated);
	}
	else
	{
		MC.QueueString("");
		MC.QueueString("");
		MC.QueueString("");
	}

	// Retaliation Mission countdown
	if (AlienHQ.bHasSeenRetaliation && bHaveRetaliation)
	{
		MC.QueueString(m_strRetaliation);
		MC.QueueString(RetaliationDisplay);
		MC.QueueString(m_strEstimated);
	}
	else
	{
		MC.QueueString("");
		MC.QueueString("");
		MC.QueueString("");
	}
	
	MC.EndOp();
}

simulated function BuildDarkEventPanel(int Index, bool bActiveDarkEvent)
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_DarkEvent DarkEventState;
	local array<StrategyCostScalar> CostScalars;
	local bool bCanAfford, bIsChosen;
	local StateObjectReference NoneRef;

	local string StatusLabel, Quote, QuoteAuthor, UnlockButtonLabel; 
	
	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	CostScalars.Length = 0;

	if(bActiveDarkEvent)
	{
		DarkEventState = XComGameState_DarkEvent(History.GetGameStateForObjectID(ALIENHQ().ActiveDarkEvents[Index].ObjectID));
		ActiveDarkEvents[Index] = DarkEventState.GetReference();
	}
	else
	{
		DarkEventState = XComGameState_DarkEvent(History.GetGameStateForObjectID(ALIENHQ().ChosenDarkEvents[Index].ObjectID));
		ChosenDarkEvents[Index] = DarkEventState.GetReference();
	}
	
	if(DarkEventState != none)
	{
		// Trigger Central VO narrative if this Dark Event was generated by a Favored Chosen
		if (DarkEventState.bChosenActionEvent)
		{
			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Trigger Event: Favored Chosen Dark Event");
			`XEVENTMGR.TriggerEvent('FavoredChosenDarkEvent', , , NewGameState);
			`GAMERULES.SubmitGameState(NewGameState);
		}

		if(DarkEventState.bSecretEvent) 
		{
			if( `ISCONTROLLERACTIVE )
			{
			
				UnlockButtonLabel = class'UIUtilities_Text'.static.InjectImage(
					class'UIUtilities_Input'.static.GetGamepadIconPrefix() $ class'UIUtilities_Input'.const.ICON_X_SQUARE, 20, 20, -10) @ m_strReveal;
			}
			else
			{
				UnlockButtonLabel = m_strReveal;
				ChosenDarkEvents[Index] = DarkEventState.GetReference();
			}
			bCanAfford = XComHQ.CanAffordAllStrategyCosts(DarkEventState.RevealCost, CostScalars);

			MC.BeginFunctionOp("UpdateDarkEventCardLocked");
			MC.QueueNumber(index);
			MC.QueueString(DarkEventState.GetDisplayName());
			MC.QueueString(bCanAfford ? m_strUnlockButton : "");
			MC.QueueString(DarkEventState.GetCost());
			MC.QueueString(bCanAfford ? UnlockButtonLabel : "");
			MC.EndOp();
		}
		else
		{
			if( bActiveDarkEvent )
				StatusLabel = m_strActive;
			else
				StatusLabel = m_strPreparing;

			Quote = DarkEventState.GetQuote();
			QuoteAuthor = DarkEventState.GetQuoteAuthor();
			bIsChosen = DarkEventState.ChosenRef != NoneRef;

			//<workshop> MULTIPLE_SECRET_EVENT_REVEAL, BET, 2016-03-24
			//This was wrong - a nonsecret chosen (non-active) dark event would be improperly cached
			//DEL:
			// ActiveDarkEvents[Index] = DarkEventState.GetReference();
			//</workshop>

			MC.BeginFunctionOp("UpdateDarkEventCard");
			MC.QueueNumber(index);
			MC.QueueString(DarkEventState.GetDisplayName());
			MC.QueueString(m_strStatusLabel);
			MC.QueueString(StatusLabel);
			MC.QueueString(DarkEventState.GetImage());
			MC.QueueString(DarkEventState.GetSummary());
			MC.QueueString(Quote);
			MC.QueueString(QuoteAuthor);
			MC.QueueBoolean(bIsChosen);
			MC.EndOp();
		}
	}	
}

simulated function OnRevealClicked(int idx)
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_DarkEvent DarkEventState;
	local XComGameState_HeadquartersXCom XComHQ;
	local array<StrategyCostScalar> CostScalars;
	local bool bCanAfford;
	
	History = `XCOMHISTORY;

	//<workshop> MULTIPLE_SECRET_EVENT_REVEAL, BET, 2016-03-24
	//For the console version, we only have one button prompt to reveal a hidden dark event.
	//There may be multiple dark events to reveal, though. (To the user, they are equivalent until revealed.)
	//Pick the first one that we're able to reveal in this case.
	//INS:
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	CostScalars.Length = 0;
	if(idx == -1)
	{
		for(idx = 0; idx < ChosenDarkEvents.Length; idx++)
		{
			DarkEventState = XComGameState_DarkEvent(History.GetGameStateForObjectID(ChosenDarkEvents[idx].ObjectID));
			bCanAfford = XComHQ.CanAffordAllStrategyCosts(DarkEventState.RevealCost, CostScalars);
			if(DarkEventState != none && DarkEventState.bSecretEvent && bCanAfford)
				break;
		}
	}

	if(idx < 0 || idx >= ChosenDarkEvents.Length)
	{
		//No valid events to reveal; abort.
		return;
	}
	//</workshop>

	DarkEventState = XComGameState_DarkEvent(History.GetGameStateForObjectID(ChosenDarkEvents[idx].ObjectID));
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	CostScalars.Length = 0;
	bCanAfford = XComHQ.CanAffordAllStrategyCosts(DarkEventState.RevealCost, CostScalars);

	if(DarkEventState != none && DarkEventState.bSecretEvent && bCanAfford)
	{
		PlaySFX("Geoscape_Reveal_Dark_Event");
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Reveal Dark Event");
		DarkEventState = XComGameState_DarkEvent(NewGameState.ModifyStateObject(class'XComGameState_DarkEvent', DarkEventState.ObjectID));
		DarkEventState.RevealEvent(NewGameState);
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
		//<workshop> MULTIPLE_SECRET_EVENT_REVEAL, BET, 2016-03-24
		//DEL:
		//ChosenDarkEvents.Remove(idx, 1); //This was wrong - see prior comment about accounting for non-secret non-active events
		//</workshop>
		BuildDarkEventPanel(idx, false);
	}
}

simulated function FlipScreenMode()
{
	bShowActiveEvents = !bShowActiveEvents;
	BuildScreen();
}

simulated function CloseScreen()
{
	HQPRES().m_kAvengerHUD.NavHelp.ClearButtonHelp();

	super.CloseScreen();	

	if(bResistanceReport)
	{
		HQPRES().UIStrategyPolicy(bResistanceReport);
	}
	else if (`ScreenStack.IsInStack(class'UIStrategyMap'))
	{
		`GAME.GetGeoscape().Resume();
	}
}

simulated function UpdateNavHelp()
{
	if( HQPRES() != none )
	{
		HQPRES().m_kAvengerHUD.NavHelp.ClearButtonHelp();
	}
}

//-------------- EVENT HANDLING --------------------------------------------------------
simulated function OnContinueClicked()
{
	CloseScreen();	
}

simulated function OnMouseEvent(int cmd, array<string> args)
{
	local int iTargetCallback;

	switch( cmd )
	{
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_UP:
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_DOUBLE_UP:

		iTargetCallback = int(Split(args[args.length - 3], "Card0", true)); // this is dissecting the Flash path. 
		OnRevealClicked(iTargetCallback);
		break;
	}
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	if (!CheckInputIsReleaseOrDirectionRepeat(cmd, arg))
	{
		return false;
	}
	
	switch (cmd)
	{
		case class'UIUtilities_Input'.const.FXS_KEY_ENTER:
		case class'UIUtilities_Input'.const.FXS_BUTTON_A:
			if (bResistanceReport)
			{
				OnContinueClicked();
			}
			
			return true;

		case class'UIUtilities_Input'.const.FXS_BUTTON_B:
			OnContinueClicked();
			return true;	

		case class'UIUtilities_Input'.const.FXS_BUTTON_X:
			if (!bShowActiveEvents)
			{
				OnRevealClicked(-1); //Changed parameter from 2 to -1; Added handling code within OnRevealClicked. -MULTIPLE_SECRET_EVENT_REVEAL, BET, 2016-03-24 
			}

			return true;	

		case class'UIUtilities_Input'.const.FXS_BUTTON_Y:
			if (ALIENHQ().ActiveDarkEvents.Length > 0)
			{
				FlipScreenMode();
			}

			return true;		
	}

	return super.OnUnrealCommand(cmd, arg);
}
//-------------- GAME DATA HOOKUP --------------------------------------------------------

defaultproperties
{
	Package = "/ package/gfxDarkEvents/DarkEvents";
	bConsumeMouseEvents = true;

	DisplayTag = "UIDisplay_Council_DarkEvents"
	CameraTag = "UIDisplayCam_ResistanceScreen_ChosenEvents"
}