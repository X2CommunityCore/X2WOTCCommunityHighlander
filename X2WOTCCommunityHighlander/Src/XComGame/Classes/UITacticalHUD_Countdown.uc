class UITacticalHUD_Countdown extends UIPanel
	implements(X2VisualizationMgrObserverInterface); 

var localized string m_strReinforcementsTitle;
var localized string m_strReinforcementsBody;

simulated function UITacticalHUD_Countdown InitCountdown()
{
	InitPanel();
	return self;
}

simulated function OnInit()
{
	local XComGameState_AIReinforcementSpawner AISpawnerState;

	super.OnInit();

	AS_SetCounterText(m_strReinforcementsTitle, m_strReinforcementsBody);

	// Initialize at the correct values 
	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_AIReinforcementSpawner', AISpawnerState)
	{
		RefreshCounter(AISpawnerState);
		break;
	}

	//And subscribe to any future changes 
	`XCOMVISUALIZATIONMGR.RegisterObserver(self);
}

// --------------------------------------

event OnActiveUnitChanged(XComGameState_Unit NewActiveUnit);
event OnVisualizationIdle();

event OnVisualizationBlockComplete(XComGameState AssociatedGameState)
{
	local XComGameState_AIReinforcementSpawner AISpawnerState;
	local string sTitle, sBody, sColor;  // Issue #449

	// Start Issue #449
	//
	// Check whether any listeners want to force the display of the reinforcements
	// alert. If so, display it and update its text and color based on the values
	// provided by the dominant listener.
	if (CheckForReinforcementsOverride(sTitle, sBody, sColor, AssociatedGameState))
	{
		AS_SetCounterText(sTitle, sBody);
		AS_SetMCColor( MCPath$".dags", sColor);
		Show();
		return;
	}
	// End Issue #449
	
	foreach AssociatedGameState.IterateByClassType(class'XComGameState_AIReinforcementSpawner', AISpawnerState)
	{
		RefreshCounter(AISpawnerState);
		break;
	}
}

simulated function RefreshCounter(XComGameState_AIReinforcementSpawner AISpawnerState)
{
	if( AISpawnerState.Countdown > 0 )
	{
		AS_SetCounterTimer(AISpawnerState.Countdown);
		Show(); 
	}
	else
	{
		Hide();
	}
}

simulated function AS_SetCounterText( string title, string label )
{ Movie.ActionScriptVoid( MCPath $ ".SetCounterText" ); }

simulated function AS_SetCounterTimer( int iTurns )
{ Movie.ActionScriptVoid( MCPath $ ".SetCounterTimer" ); }

// Start Issue #449
//
// This method sends an `OverrideReinforcementsAlert` event that allows listeners
// to both force the display of the reinforcements alert and change its text and
// color.
//
// The event takes the form:
//
//   {
//       ID: OverrideReinforcementsAlert,
//       Data: [ out bool DisplayRNFAlert, out string Title, out string BodyText,
//               out string AlertColor, in XComGameState AssociatedGameState ]
//       Source: self (UITacticalHUD_Countdown)
//   }
// 
simulated function bool CheckForReinforcementsOverride(out string sTitle, out string sBody, out string sColor, XComGameState AssociatedGameState)
{
	local XComLWTuple OverrideTuple;
	
	// Allow mods to control the counter visualization. The  should return a bool flag and if the flag
	// is true, the out params hold strings to use to update the UI. The first two strings are the title
	//  and body strings respectively (REINFORCEMENTS and INCOMING in vanilla). The third string is the
	// color to use for the dags control.
	OverrideTuple = new class'XComLWTuple';
	OverrideTuple.Id = 'OverrideReinforcementsAlert';
	OverrideTuple.Data.Add(5);
	OverrideTuple.Data[0].kind = XComLWTVBool;
	OverrideTuple.Data[0].b = false;  // Force display of the reinforcement alert?
	OverrideTuple.Data[1].kind = XComLWTVString;
	OverrideTuple.Data[1].s = "";  // Reinforcement alert title (REINFORCEMENTS in vanilla)
	OverrideTuple.Data[2].kind = XComLWTVString;
	OverrideTuple.Data[2].s = "";  // Reinforcement alert body (INCOMING in vanilla)
	OverrideTuple.Data[3].kind = XComLWTVString;
	OverrideTuple.Data[3].s = "";  // Reinforcement alert color
	OverrideTuple.Data[4].kind = XComLWTVObject;
	OverrideTuple.Data[4].o = AssociatedGameState;  // Reinforcement alert color

	`XEVENTMGR.TriggerEvent('OverrideReinforcementsAlert', OverrideTuple, self);

	sTitle = OverrideTuple.Data[1].s;
	sBody = OverrideTuple.Data[2].s;
	sColor = OverrideTuple.Data[3].s;

	return OverrideTuple.Data[0].b;
}
// End Issue 449

// --------------------------------------
defaultproperties
{
	MCName = "theCountdown";
	bAnimateOnInit = false;
	bIsVisible = false; // only show when gameplay needs it
	Height = 80; // used for objectives placement beneath this element as well. 
}