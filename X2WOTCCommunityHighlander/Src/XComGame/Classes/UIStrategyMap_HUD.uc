//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIStrategyMap_HUD
//  AUTHOR:  Sam Batista
//  PURPOSE: This is a prototype control that displays 2D information in the Strategy Map.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIStrategyMap_HUD extends UIPanel
	dependson(XGMissionControlUI);

var localized string m_strDoomCounterLabel;
var localized string m_strDoomDays;
var localized string m_strDoomHours;
var localized string m_strDoomMinutes;
var localized string m_strDoomSeconds;
var localized string m_strDoomTitle; 
var localized string m_strMissing;
var localized string m_strResOrdersTooltip;
var localized string m_strChosenTooltip;

var UIPanel m_kDoomOverlay;
var bool	bHasSeenDoomMeter;
var UIButton m_kChosenInfoButton;
var UIButton m_kResistanceInfoButton;

var string m_strLog;
var public string PathToResistanceBar;
var public string PathToAlertBar;
var public string PathToClueBar;
var bool bMuteDoom;

var int CachedDoom; 
var bool bDoomCounterVisible;

// Constructor
simulated function UIStrategyMap_HUD InitStrategyMapHUD()
{
	InitPanel();

	CachedDoom = class'UIUtilities_Strategy'.static.GetAlienHQ().GetCurrentDoom();
	m_kDoomOverlay = Spawn(class'UIPanel', self).InitPanel(, 'DoomScreenEffect');
	SetDoomLabel(m_strDoomTitle);
	SetUpChosenButton(); 
	SetUpResInfoButton();

	UpdateData();
	Movie.Pres.SubscribeToUIUpdate(UpdateData);
	//TestScanButton();
	return self;
}

simulated function TestScanButton()
{
	local UIScanButton Scan;

	Scan = Spawn(class'UIScanButton', self).InitScanButton();
	Scan.SetPosition(100, 100);
	Scan.SetButtonType(eUIScanButtonType_Default);
	Scan.Expand();
	Scan.SetText("Default EXPANDED", "INTEL", "25", "DAYS");
	Scan.SetButtonIcon(class'UIUtilities_Image'.const.MissionIcon_Goldenpath);
	Scan.SetScanMeter(33);
	Scan.Realize();

	Scan = Spawn(class'UIScanButton', self).InitScanButton();
	Scan.SetPosition(600, 100);
	Scan.SetButtonType(eUIScanButtonType_Default);
	Scan.DefaultState();
	Scan.SetText("Default - DEFAULT", "INTEL", "25", "DAYS");
	Scan.SetButtonIcon(class'UIUtilities_Image'.const.MissionIcon_Goldenpath);
	Scan.SetScanMeter(33);
	Scan.Realize();

	// -----------------------------------------

	Scan = Spawn(class'UIScanButton', self).InitScanButton();
	Scan.SetPosition(100, 200);
	Scan.SetButtonType(eUIScanButtonType_BlackMarket);
	Scan.Expand();
	Scan.SetText("BLACK MARKET EXPANDED", "STUFF", "3", "DAYS");
	Scan.SetButtonIcon(class'UIUtilities_Image'.const.MissionIcon_BlackMarket);
	Scan.SetScanMeter(66);
	Scan.Realize();

	Scan = Spawn(class'UIScanButton', self).InitScanButton();
	Scan.SetPosition(600, 200);
	Scan.SetButtonType(eUIScanButtonType_BlackMarket);
	Scan.DefaultState();
	Scan.SetText("BLACK MARKET", "INTEL", "3", "DAYS");
	Scan.SetButtonIcon(class'UIUtilities_Image'.const.MissionIcon_BlackMarket);
	Scan.SetScanMeter(66);
	Scan.Realize();

	// -----------------------------------------

	Scan = Spawn(class'UIScanButton', self).InitScanButton();
	Scan.SetPosition(100, 300);
	Scan.SetButtonType(eUIScanButtonType_ResHQ);
	Scan.Expand();
	Scan.SetText("RESISTANCE HEADQUARTERSD", "STUFF", "3", "DAYS");
	Scan.SetButtonIcon(class'UIUtilities_Image'.const.MissionIcon_Resistance);
	Scan.SetScanMeter(90);
	Scan.Realize();

	Scan = Spawn(class'UIScanButton', self).InitScanButton();
	Scan.SetPosition(600, 300);
	Scan.SetButtonType(eUIScanButtonType_ResHQ);
	Scan.DefaultState();
	Scan.SetText("RESISTANCE HEADQUARTERS", "INTEL", "3", "DAYS");
	Scan.SetButtonIcon(class'UIUtilities_Image'.const.MissionIcon_Resistance);
	Scan.SetScanMeter(90);
	Scan.Realize();
}
simulated function UpdateMissingPersons()
{
	//local XComGameState_HeadquartersAlien AlienHQ;

	//AlienHQ = class'UIUtilities_Strategy'.static.GetAlienHQ();

	/*MC.BeginFunctionOp("UpdateMissingPeople");
	MC.QueueString(m_strMissing);
	MC.QueueString(string(AlienHQ.GetNumMissingPersons()));
	MC.EndOp();*/
}

simulated function UpdateData()
{
	local int i;
	local int CurrentDoom;
	local int MaxDoom;
	local XComGameState_HeadquartersAlien AlienHQ;
	local XComGameState_HeadquartersResistance ResHQ;
	local XComGameState NewGameState;
	local bool bPlayedSound;
	
	bPlayedSound = false;

	if(Movie.Stack.GetCurrentClass() != class'UIStrategyMap') return;

	AlienHQ = class'UIUtilities_Strategy'.static.GetAlienHQ(true);
	ResHQ = class'UIUtilities_Strategy'.static.GetResistanceHQ();

	//This function can be called after we've lost the game and are in the process of cleaning up.
	//In that case, AlienHQ can be None - just abort here.
	if (AlienHQ == None)
		return;

	//UpdateMissingPersons();

	if(AlienHQ.AIMode == "Lose" && AlienHQ.AtMaxDoom())
	{
		UpdateLoseTimer();

		if(!bDoomCounterVisible)
		{
			ShowDoomCounter();
		}
		
		m_kDoomOverlay.Show();
		m_kDoomOverlay.MC.FunctionString("gotoAndPlay", "_level" $ int(Lerp(1, 3, AlienHQ.GetAIModeTimerFraction())));
	}
	else
	{
		if(bDoomCounterVisible)
		{
			HideDoomCounter();
		}


		m_kDoomOverlay.Hide();
		
	}

	if (AlienHQ.HaveMetAnyChosen() && !UIStrategyMap(Owner).IsInFlightMode())
	{
		m_kChosenInfoButton.Show();
	}
	else
	{
		m_kChosenInfoButton.Hide();
	}
	
	// Issue #365
	m_kResistanceInfoButton.SetVisible(ShouldShowResInfoButton(ResHQ));

	//bsg-crobinson (5.23.17): Hide these buttons if using a controller
	if (`ISCONTROLLERACTIVE)
	{
		m_kChosenInfoButton.Hide();
		m_kResistanceInfoButton.Hide();
	}
	//bsg-crobinson (5.23.17): end

	//MC.FunctionVoid("UpdateClueMeter"); // no params hides the meter
	
	// Takes in an array of numbers that indicate the type of block to spawn:
	//	0 - empty
	//  1 - filled
	//	2 - blinking
	//	-1 - threshold / separator
	if( AlienHQ.AIMode == "Lose" )
	{
		// No params will hide the pip meter.
		MC.FunctionVoid("UpdateDoomMeter");
	}
	else if( AlienHQ.GetCurrentDoom(true) > 0 || AlienHQ.bHasSeenDoomMeter)
	{
		if (!AlienHQ.bHasSeenDoomMeter)
		{
			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Show Doom Meter");
			AlienHQ = XComGameState_HeadquartersAlien(NewGameState.ModifyStateObject(AlienHQ.Class, AlienHQ.ObjectID));
			AlienHQ.bHasSeenDoomMeter = true;
			`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
		}

		MC.BeginFunctionOp("UpdateDoomMeter");
		//Begin Issue #550
		//Chaching doom values below as a change to GetCurrentDoom activates an event and if that function is called
		//on each iteration of the loop it could cause unneded work to be done by the listener.
		MaxDoom = AlienHQ.GetMaxDoom();	
		CurrentDoom = AlienHQ.GetCurrentDoom();
		//End Issue #550
		
		for (i = 0; i < MaxDoom; ++i)
		{
			if(i < CurrentDoom)
			{
				if(i >= CachedDoom)
				{
					if(!bPlayedSound)
					{
						if(!bMuteDoom)
						{
							`XSTRATEGYSOUNDMGR.PlaySoundEvent("Geoscape_DoomIncrease");
						}

						bPlayedSound = true;
					}
					
					MC.QueueNumber(2); //New blocks are 2
				}
				else
				{
					MC.QueueNumber(1); //Regular block is 1
				}	
			}
			else
			{
				if(i < CachedDoom)
				{
					if(!bPlayedSound)
					{
						`XSTRATEGYSOUNDMGR.PlaySoundEvent("Geoscape_DoomDecrease");
						bPlayedSound = true;
					}
					
					MC.QueueNumber(3); // Blocks to remove
				}
				else
				{
					MC.QueueNumber(0); //Empties
				}
			}
		}

		MC.EndOp();
	}

	CachedDoom = AlienHQ.GetCurrentDoom();

	`HQPRES.m_kAvengerHUD.ShowEventQueue(true);
	
	// Force any alerts which somehow got buried to the top of the stack
	if (`HQPRES.ScreenStack.HasInstanceOf(class'UIAlert'))
	{
		// The alert is not at the top of the stack, because earlier in this function we return if the top is not UIStrategyMap
		`HQPRES.ScreenStack.MoveToTopOfStack(class'UIAlert');
		`HQPRES.ScreenStack.ForceStackOrder(`HQPRES.Get2DMovie());
	}
}

// Start issue #365
/// HL-Docs: feature:Geoscape_ResInfoButtonVisible; issue:365; tags:strategy,ui
/// Allows overriding whether the resistance info button should be visible.
/// Default: After the first month if any faction met and not in flight.
///
/// ```event
/// EventID: Geoscape_ResInfoButtonVisible,
/// EventData: [inout bool ShouldShow, in bool InFlight],
/// EventSource: UIStrategyMap_HUD (HUDScreen),
/// NewGameState: none
/// ```
simulated protected function bool ShouldShowResInfoButton(XComGameState_HeadquartersResistance ResHQ)
{
	local XComLWTuple Tuple;
	local bool bInFlight;

	bInFlight = UIStrategyMap(Owner).IsInFlightMode();

	Tuple = new class'XComLWTuple';
 	Tuple.Id = 'Geoscape_ResInfoButtonVisible';
 	Tuple.Data.Add(2);
 	Tuple.Data[0].kind = XComLWTVBool;
 	Tuple.Data[0].b = ResHQ.NumMonths > 0 && ResHQ.HaveMetAnyFactions() && !bInFlight; 
	Tuple.Data[1].kind = XComLWTVBool;
 	Tuple.Data[1].b = bInFlight;

 	`XEVENTMGR.TriggerEvent('Geoscape_ResInfoButtonVisible', Tuple, self, none);

	return Tuple.Data[0].b;
}
// End issue #365

simulated function UpdateLoseTimer()
{
	local XComGameState_HeadquartersAlien AlienHQ;
	local int Days, Hours, Minutes, Seconds;

	AlienHQ = class'UIUtilities_Strategy'.static.GetAlienHQ();

	AlienHQ.GetTimerDisplayValues(Days, Hours, Minutes, Seconds);
	MC.BeginFunctionOp("SetDoomCounter");
	MC.QueueString(m_strDoomCounterLabel);
	MC.QueueString(FormatIntValueString(Days));
	MC.QueueString(m_strDoomDays);
	MC.QueueString(FormatIntValueString(Hours));
	MC.QueueString(m_strDoomHours);
	MC.QueueString(FormatIntValueString(Minutes));
	MC.QueueString(m_strDoomMinutes);
	MC.QueueString(FormatIntValueString(Seconds));
	MC.QueueString(m_strDoomSeconds);
	MC.EndOp();

}

function string FormatIntValueString(int Value)
{
	if(Value < 10)
	{
		return ("0" $ Value);
	}
	
	return ("" $ Value);
}

//----------------------------------------------------------------

simulated function AddOption( int iIndex, string sLabel, int iState )
{
	MC.BeginFunctionOp("AddOption");
	MC.QueueNumber(iIndex);
	MC.QueueString(sLabel);
	MC.QueueNumber(iState);
	MC.EndOp();
}

simulated function UpdateInfo( string techName, string infoText, string descText, string imageLabel  )
{
	MC.BeginFunctionOp("UpdateInfo");
	MC.QueueString(techName);
	MC.QueueString(infoText);
	MC.QueueString(descText);
	MC.QueueString(imageLabel);
	MC.EndOp();
}

simulated function SetDateTime( string label )
{
	MC.FunctionString("SetDateTime", label);
}

simulated function SetDoomLabel( string label )
{
	MC.FunctionString("SetDoomLabel", label);
}

simulated function SetEventLog( string log )
{
	MC.FunctionString("SetEventLog", log);
}

simulated function ShowDoomCounter()
{
	MC.FunctionVoid("ShowDoomCounter");
	bDoomCounterVisible = true;
}

simulated function HideDoomCounter()
{
	MC.FunctionVoid("HideDoomCounter");
	bDoomCounterVisible = false;
}

simulated function StartDoomAddedEffect()
{
	MC.FunctionVoid("ShowDoomPulse");
}

simulated function StopDoomAddedEffect()
{
	MC.FunctionVoid("HideDoomPulse");
}

simulated function StartDoomRemovedEffect()
{
	MC.FunctionVoid("ShowXcomPulse");
}

simulated function StopDoomRemovedEffect()
{
	MC.FunctionVoid("HideXcomPulse");
}

simulated function SetDoomMessage(string Message, bool bRemove, optional bool bMuteAlert = false)
{
	bMuteDoom = bMuteAlert;

	if(bRemove)
	{
		MC.FunctionString("SetDoomMessageRemove", Message);
	}
	else
	{
		MC.FunctionString("SetDoomMessage", Message);
	}
}

// Takes in an array of numbers that indicate the type of block to spawn:
//	0 - empty
//  1 - filled
//	2 - blinking

simulated function UpdatePopularSupportMeter( optional array<int> BlockTypes )
{
	//local int i;
	MC.BeginFunctionOp("UpdatePopularSupportMeter");
	/*for(i = 0; i < BlockTypes.Length; ++i)
		MC.QueueNumber(BlockTypes[i]);*/
	MC.EndOp();
}
simulated function UpdateAlertMeter( optional array<int> BlockTypes )
{
	// DISABLING ALERT: per design, but not deleting because they reserve the right to make it reappear differently. 2/3/2015 bsteiner 
 	//local int i;
	MC.BeginFunctionOp("UpdateAlertMeter");
	/*for(i = 0; i < BlockTypes.Length; ++i)
		MC.QueueNumber(BlockTypes[i]);*/
	MC.EndOp();
	
}

simulated function UpdateSupportTooltip( int index, string title, string description, bool thresholdActivated )
{
/*
	MC.BeginFunctionOp("UpdateSupportTooltip");
	/ *MC.QueueNumber(index);
	MC.QueueString(class'UIUtilities_Text'.static.GetColoredText(title, thresholdActivated ? eUIState_Good : eUIState_Disabled));
	MC.QueueString(class'UIUtilities_Text'.static.GetColoredText(description, thresholdActivated ? eUIState_Good : eUIState_Disabled));
	MC.QueueBoolean(thresholdActivated);* /
	MC.EndOp();*/
}

simulated function UpdateAlertTooltip( int index, string title, string description, bool thresholdActivated )
{
}

simulated function ShowAllThresholdTooltips()
{
	MC.FunctionVoid("ShowAllThresholdTooltips");
}
	
simulated function HideAllThresholdTooltips( optional bool noFade )
{
	MC.FunctionBool("HideAllThresholdTooltips", noFade);
}

simulated function OnCommand( string cmd, string arg )
{
	switch(cmd)
	{
	case "PlayDoomAddSound":
		`XSTRATEGYSOUNDMGR.PlaySoundEvent("Geoscape_Doom_Bar_Increase");
		break;
	case "PlayDoomRemoveSound":
		`XSTRATEGYSOUNDMGR.PlaySoundEvent("Geoscape_DoomBarDecrease");
		break;
	}
}


function SetUpChosenButton()
{
	m_kChosenInfoButton = Spawn(class'UIButton', self);
	m_kChosenInfoButton.InitButton('StrategyHUD_ChosenInfoButton', , OnClickChosenInfoButton);
	m_kChosenInfoButton.SetTooltipText(m_strChosenTooltip);
}

function SetUpResInfoButton()
{
	m_kResistanceInfoButton = Spawn(class'UIButton', self);
	m_kResistanceInfoButton.InitButton('StrategyHUD_ResistanceInfoButton', , OnStrategyPolicyClicked);
	m_kResistanceInfoButton.SetTooltipText(m_strResOrdersTooltip);
}

simulated function OnClickChosenInfoButton(UIButton Button)
{
	if( Movie.Pres.ScreenStack.GetScreen(class'UIChosenReveal') == none )
		`HQPRES.UIChosenInformation();
}

simulated function OnStrategyPolicyClicked(UIButton Button)
{
	if( Movie.Pres.ScreenStack.GetScreen(class'UIStrategyPolicy') == none )
		`HQPRES.UIStrategyPolicy(false, true);
}

//----------------------------------------------------------------

event Destroyed()
{
	Movie.Pres.m_kTooltipMgr.RemoveTooltips(self);
	Movie.Pres.UnsubscribeToUIUpdate(UpdateData);
	super.Destroyed();
}

defaultproperties
{
	LibID     = "StrategyMapHUD";

	PathToResistanceBar = ".resistanceMeter";
	PathToAlertBar = ".alertMeter";
	PathToClueBar = ".clueMeter";
}
