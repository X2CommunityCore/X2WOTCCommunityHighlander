//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UITurnOverlay.uc
//  AUTHOR:  Brit Steiner - 7/12/2010
//  PURPOSE: This file corresponds to the changing turns overlay in flash. 
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UITurnOverlay extends UIScreen;

//issue #188: added additional overlay under eTurnOverlay_Resistance so we could diffentriate between eTeam_One and eTeam_Two
enum ETurnOverlay
{
	eTurnOverlay_Local,
	eTurnOverlay_Remote,
	eTurnOverlay_Alien,
	eTurnOverlay_TheLost,
	eTurnOverlay_Chosen,
	eTurnOverlay_Resistance,
	eTurnOverlay_OtherTeam, 
};

var float m_fAnimateTime;
var float m_fAnimateRate;
var bool m_bXComTurn;
var bool m_bAlienTurn;
var bool m_bOtherTurn;
var bool m_bTheLostTurn;
var bool m_bReflexAction;
var bool m_bSpecialTurn;
var bool m_bChosenTurn;

var localized string       m_sXComTurn;
var localized string       m_sAlienTurn;
var localized string       m_sOtherTurn;
var localized string       m_sTheLostTurn;
var localized string       m_sExaltTurn;
var localized string       m_sReflexAction;
var localized string       m_sSpecialTurn;
var localized string       m_sChosenTurn;

var string XComTurnSoundResourcePath;
var string AlienTurnSoundResourcePath;
var string SpecialTurnSoundResourcePath;
var string ChosenTurnSoundResourcePath;
var string TheLostTurnSoundResourcePath;
var string ReflexStartAndLoopSoundResourcePath;
var string ReflexEndResourcePath;

var AkEvent XComTurnSound;
var AkEvent AlienTurnSound;
var AkEvent SpecialTurnSound;
var AkEvent ChosenTurnSound;
var AkEvent TheLostTurnSound;
//--------------------------------------------

var UITacticalHUD_InitiativeOrder				m_kInitiativeOrder;

//--------------------------------------------
// MEMBERS

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	super.InitScreen(InitController, InitMovie, InitName);

	// initiative order
	m_kInitiativeOrder = Spawn(class'UITacticalHUD_InitiativeOrder', self).InitInitiativeOrder();
}

simulated function OnInit()
{
	local string TeamOneTurn, TeamTwoTurn; //issue #188: added string variables so mods can alter what's shown when the game is told to show the "Other" turn or "Reflex Action"
	local XComLWTuple Tuple;
	local bool OverrideStrings; //plus added variables for event hook
	
	TeamOneTurn = m_sReflexAction;
	TeamTwoTurn = m_sOtherTurn;
	OverrideStrings = false;

	Tuple = new class'XComLWTuple';
	Tuple.id = 'SetFourthTeamStrings';
	Tuple.Data.Add(3);
	
	Tuple.Data[0].kind = XComLWTVObject;
	Tuple.Data[0].b = OverrideStrings;

	Tuple.Data[1].kind = XComLWTVString;
	Tuple.Data[1].s = TeamOneTurn;
	
	Tuple.Data[2].kind = XComLWTVString;
	Tuple.Data[2].s = TeamTwoTurn;

	`XEVENTMGR.TriggerEvent('SetFourthTeamStrings', Tuple);

	OverrideStrings = Tuple.Data[0].b;
	if(OverrideStrings){
		TeamOneTurn = Tuple.Data[1].s;
		TeamTwoTurn = Tuple.Data[2].s;
	}
	super.OnInit();

	//When starting a match, this UI element was showing a spurious "reflex action" label for one frame (though nothing called for a reflex action in any way). 
	//Force it to be hidden until something actually wants to trigger it.
	Invoke("HideReflexAction");

	if( WorldInfo.NetMode == NM_Standalone && `BATTLE.m_kDesc != None && `BATTLE.m_kDesc.m_iMissionType == eMission_ExaltRaid )		
		SetDisplayText( m_sAlienTurn, m_sXComTurn, m_sExaltTurn, m_sTheLostTurn, m_sReflexAction, m_sSpecialTurn, m_sChosenTurn);
	else
		SetDisplayText( m_sAlienTurn, m_sXComTurn, TeamTwoTurn, m_sTheLostTurn, TeamOneTurn, m_sSpecialTurn, m_sChosenTurn);

	if(`PRES.m_bUIShowMyTurnOnOverlayInit)
	{
		PulseXComTurn();		
	}
	else if(`PRES.m_bUIShowOtherTurnOnOverlayInit)
	{
		PulseOtherTurn();		
	}
	else if( `PRES.m_bUIShowTheLostTurnOnOverlayInit )
	{
		PulseTheLostTurn();
	}
	else if( `PRES.m_bUIShowChosenTurnOnOverlayInit )
	{
		PulseChosenTurn();
	}
	else if(`PRES.m_bUIShowReflexActionOnOverlayInit)
	{
		ShowReflexAction(); 
	}
	else if( `PRES.m_bUIShowSpecialTurnOnOverlayInit )
	{
		ShowSpecialTurn();
	}

	if(!WorldInfo.IsConsoleBuild())
	{
		Invoke("HideBlackBars");
	}
	else
	{
		if( Movie.m_v2FullscreenDimension == Movie.m_v2ViewportDimension )
		{
			Invoke("HideBlackBars");
		}
		else
		{
			AS_ShowBlackBars(); 
		}
	}

	ShowOrHideInitiative();

	XComTurnSound = AkEvent(DynamicLoadObject(XComTurnSoundResourcePath, class'AkEvent'));
	AlienTurnSound = AkEvent(DynamicLoadObject(AlienTurnSoundResourcePath, class'AkEvent'));
	SpecialTurnSound = AkEvent(DynamicLoadObject(SpecialTurnSoundResourcePath, class'AkEvent'));
	ChosenTurnSound = AkEvent(DynamicLoadObject(ChosenTurnSoundResourcePath, class'AkEvent'));
	TheLostTurnSound = AkEvent(DynamicLoadObject(TheLostTurnSoundResourcePath, class'AkEvent'));
}

simulated function Show()
{
	super.Show();

	ShowOrHideInitiative();
}

simulated function ShowOrHideInitiative()
{
	local XComTacticalCheatManager Cheat;

	Cheat = `CHEATMGR;
	if( Cheat != None && Cheat.bShowInitiative )
	{
		m_kInitiativeOrder.Show();
	}
	else
	{
		m_kInitiativeOrder.Hide();
	}
}


//==============================================================================
// 		UNIQUE FUNCTIONS:
//==============================================================================

simulated function SetDisplayText(string alienText, string xcomText, string p2Text, string TheLostText, string reflexText, optional string specialOverlayText, optional string ChosenText )
{
	local ASValue myValue;
	local Array<ASValue> myArray;

	myValue.Type = AS_String;

	myValue.s = alienText;
	myArray.AddItem( myValue );

	myValue.s = xcomText;
	myArray.AddItem( myValue );

	myValue.s = p2Text;
	myArray.AddItem( myValue );

	myValue.s = reflexText;
	myArray.AddItem(myValue);

	myValue.s = specialOverlayText;
	myArray.AddItem(myValue);

	myValue.s = TheLostText;
	myArray.AddItem(myValue);

	myValue.s = ChosenText;
	myArray.AddItem(myValue);

	Invoke("SetText", myArray);
}

//--------------------------------------
simulated function ShowAlienTurn() 
{
	m_bAlienTurn = true;

	// Still playing last animation?
	if ( m_fAnimateTime != 0 )
		ClearTimer( 'AnimateOut' );
	
	m_fAnimateTime = 0;

	if(!class'XComGameState_Cheats'.static.GetVisualizedCheatsObject().DisableTurnOverlay)
	{
		Show();

		SetTimer( m_fAnimateRate, true, 'AnimateIn' );

		Invoke("ShowAlienTurn");

		WorldInfo.PlayAkEvent(AlienTurnSound);
	}
}

simulated function PulseAlienTurn() 
{
	if(!class'XComGameState_Cheats'.static.GetVisualizedCheatsObject().DisableTurnOverlay)
	{
		Show();
		Invoke("ShowAlienTurn");
		m_bAlienTurn = true;
	}
}

simulated function HideAlienTurn() 
{	
	m_bAlienTurn = false;

	if(!class'XComGameState_Cheats'.static.GetVisualizedCheatsObject().DisableTurnOverlay)
	{
		// Still playing last animation?
		if ( m_fAnimateTime != 0 )
			ClearTimer( 'AnimateIn' );

		m_fAnimateTime = 0;

		SetTimer( m_fAnimateRate, true, 'AnimateOut' );

		Invoke("HideAlienTurn");
	}
}


simulated function SetAlienScreenGlow( float fAmount ) 
{
	local MaterialInstanceConstant kMIC;
	kMIC = MaterialInstanceConstant'XComEngineMaterials.PPM_Vignette';
	kMIC.SetScalarParameterValue('Vignette_Intensity', fAmount);
}


simulated function AnimateIn(optional float Delay = -1.0)
{
	m_fAnimateTime += m_fAnimateRate;

	SetAlienScreenGlow( m_fAnimateTime * 2 );

	if ( m_fAnimateTime > 1 )
	{
		ClearTimer( 'AnimateIn' );
		m_fAnimateTime = 0;
	}
}


simulated function AnimateOut(optional float Delay = -1.0)
{
	m_fAnimateTime += m_fAnimateRate;

	SetAlienScreenGlow( 2 - (m_fAnimateTime * 2) );

	if ( m_fAnimateTime > 1 )
	{		
		ClearTimer( 'AnimateOut' );
		m_fAnimateTime = 0;
	}
}
simulated public function AS_ShowBlackBars()
{ 
	Show();
	Movie.ActionScriptVoid(MCPath$".ShowBlackBars"); 
}

//--------------------------------------
simulated function ShowXComTurn() 
{
	if(!class'XComGameState_Cheats'.static.GetVisualizedCheatsObject().DisableTurnOverlay)
	{
		Show();

		Invoke("ShowXComTurn");

		m_bXComTurn = true;

		WorldInfo.PlayAkEvent(XComTurnSound);
	}
}
simulated function PulseXComTurn() 
{
	if(!class'XComGameState_Cheats'.static.GetVisualizedCheatsObject().DisableTurnOverlay)
	{
		Show();

		Invoke("PulseXComTurn");
		m_bXComTurn = true;
	}
}
simulated function HideXComTurn() 
{
	if(!class'XComGameState_Cheats'.static.GetVisualizedCheatsObject().DisableTurnOverlay)
	{
		Invoke("HideXComTurn");
		m_bXComTurn = false;
	}
}
//--------------------------------------
simulated function ShowOtherTurn() 
{
	if(!class'XComGameState_Cheats'.static.GetVisualizedCheatsObject().DisableTurnOverlay)
	{
		Show();

		Invoke("ShowP2Turn");
		m_bOtherTurn = true;
	}
}
simulated function PulseOtherTurn() 
{
	if(!class'XComGameState_Cheats'.static.GetVisualizedCheatsObject().DisableTurnOverlay)
	{
		Show();

		Invoke("PulseP2Turn");
		m_bOtherTurn = true;
	}
}
simulated function HideOtherTurn() 
{
	if(!class'XComGameState_Cheats'.static.GetVisualizedCheatsObject().DisableTurnOverlay)
	{
		Invoke("HideP2Turn");
		m_bOtherTurn = false;
	}
}
//--------------------------------------
simulated function ShowTheLostTurn()
{
	if( !class'XComGameState_Cheats'.static.GetVisualizedCheatsObject().DisableTurnOverlay )
	{
		Show();

		Invoke("ShowLostTurn");

		WorldInfo.PlayAkEvent(TheLostTurnSound);

		m_bTheLostTurn = true;
	}
}
simulated function PulseTheLostTurn()
{
	if( !class'XComGameState_Cheats'.static.GetVisualizedCheatsObject().DisableTurnOverlay )
	{
		Show();

		Invoke("PulseLostTurn");
		m_bTheLostTurn = true;
	}
}
simulated function HideTheLostTurn()
{
	if( !class'XComGameState_Cheats'.static.GetVisualizedCheatsObject().DisableTurnOverlay )
	{
		Invoke("HideLostTurn");
		m_bTheLostTurn = false;
	}
}
//--------------------------------------
simulated function ShowChosenTurn()
{
	if( !class'XComGameState_Cheats'.static.GetVisualizedCheatsObject().DisableTurnOverlay )
	{
		Show();

		Invoke("ShowChosenTurn");

		WorldInfo.PlayAkEvent(ChosenTurnSound);

		m_bChosenTurn = true;
	}
}
simulated function PulseChosenTurn()
{
	if( !class'XComGameState_Cheats'.static.GetVisualizedCheatsObject().DisableTurnOverlay )
	{
		Show();

		Invoke("PulseChosenTurn");
		m_bChosenTurn = true;
	}
}
simulated function HideChosenTurn()
{
	if( !class'XComGameState_Cheats'.static.GetVisualizedCheatsObject().DisableTurnOverlay )
	{
		Invoke("HideChosenTurn");
		m_bChosenTurn = false;
	}
}
//--------------------------------------
simulated function ShowReflexAction() 
{
	Show();

	Invoke("ShowReflexAction");
	m_bReflexAction = true;
}

simulated function HideReflexAction() 
{
	XComPresentationLayer(Owner).HUDShow();
	ClearTimer('HideReflexAction');
	Invoke("HideReflexAction");
	m_bReflexAction = false;
}
//--------------------------------------
simulated function ShowSpecialTurn()
{
	if( !class'XComGameState_Cheats'.static.GetVisualizedCheatsObject().DisableTurnOverlay )
	{
		Show();

		Invoke("ShowSpecialTurn");
		m_bSpecialTurn = true;

		WorldInfo.PlayAkEvent(SpecialTurnSound);
	}
}
simulated function HideSpecialTurn()
{
	if( !class'XComGameState_Cheats'.static.GetVisualizedCheatsObject().DisableTurnOverlay )
	{
		Invoke("HideSpecialTurn");
		m_bSpecialTurn = false;
	}
}
//--------------------------------------

simulated function bool IsShowingAlienTurn()
{
	return m_bAlienTurn;
}
simulated function bool IsShowingXComTurn()
{
	return m_bXComTurn;
}
simulated function bool IsShowingOtherTurn()
{
	return m_bOtherTurn;
}
simulated function bool IsShowingTheLostTurn()
{
	return m_bTheLostTurn;
}
simulated function bool IsShowingChosenTurn()
{
	return m_bChosenTurn;
}
simulated function bool IsShowingReflexAction()
{
	return m_bReflexAction;
}
simulated function bool IsShowingSpecialTurn()
{
	return m_bSpecialTurn;
}

//==============================================================================
//		DEFAULTS:
//==============================================================================

defaultproperties
{
	MCName = "theTurnOverlay";
	Package = "/ package/gfxTurnOverlay/TurnOverlay";
	
	m_fAnimateRate = 0.01f;

	m_bXComTurn  = false;
	m_bAlienTurn = false;
	m_bOtherTurn = false;
	m_bTheLostTurn = false;
	m_bChosenTurn = false;
	m_bReflexAction = false;
	m_bSpecialTurn = false;

	bHideOnLoseFocus = false;

	XComTurnSoundResourcePath = "SoundTacticalUI.TacticalUI_XCOMTurn"
	AlienTurnSoundResourcePath = "SoundTacticalUI.TacticalUI_AlienTurn"
	SpecialTurnSoundResourcePath = "DLC_60_SoundTacticalUI.TacticalUI_AlienRulerTurn";
	ChosenTurnSoundResourcePath = "XPACK_SoundTacticalUI.ChosenTurn"
	TheLostTurnSoundResourcePath = "XPACK_SoundTacticalUI.LostTurn"

	//ReflexStartAndLoopSoundResourcePath;
	//ReflexEndResourcePath;
}
