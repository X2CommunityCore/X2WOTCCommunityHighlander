//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIStrategyMap_MissionIcon.uc
//  AUTHOR:  Joe Cortese 7/13/2015
//  PURPOSE: UIPanel to load a dynamic image icon and set background coloring. 
//----------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//----------------------------------------------------------------------------
class UIStrategyMap_MissionIcon extends UIIcon
	config(UI);

var XComGameState_ScanningSite ScanSite;
var XComGameState_MissionSite MissionSite;
var UIStrategyMapItem MapItem;
var UIStrategyMap_MissionIconTooltip Tooltip;

var config float ZoomLevel;

var int idNum;

var bool bFocused;
var bool bMoveCamera;
simulated function UIStrategyMap_MissionIcon InitMissionIcon( optional int iD)
{
	local name IconInitName;

	idNum = iD;

	IconInitName = name("StrategyIcon"$iD);
	Super.InitIcon(IconInitName, , true, false, iD < 3? 48 : 64);
	
	mc.FunctionNum("SetIDNum", iD);

	return self;
}

simulated function SetSortedPosition(int numScanSites, int numMissions)
{
	mc.BeginFunctionOp("SetSortedPosition");
	mc.QueueNumber(numScanSites);
	mc.QueueNumber(numMissions);
	mc.EndOp();
}

simulated function LoadIconStack(StackedUIIconData iconData)
{
	local int i;

	MC.BeginFunctionOp("SetImageStack");
	MC.QueueBoolean(iconData.bInvert);
	for (i = 0; i < iconData.Images.Length; i++)
	{
		MC.QueueString("img:///" $ iconData.Images[i]);
	}

	MC.EndOp();
}

simulated function LoadSingleIcon(string newPath)
{
	if (ImagePath != newPath)
	{
		ImagePath = newPath;
		MC.BeginFunctionOp("SetImageStack");
		MC.QueueBoolean(false);
		MC.QueueString(class'UIUtilities_Image'.static.ValidateImagePath(ImagePath));
		MC.EndOp();
	}
}

simulated function SetScanSite(XComGameState_ScanningSite Scanner)
{
	local XComGameState_BlackMarket BlackMarket;

	MapItem = `HQPRES.StrategyMap2D.GetMapItem(Scanner);
	ScanSite = Scanner;
	MissionSite = none;
	OnClickedDelegate = ScanSite.AttemptSelectionCheckInterruption;
	if (XComGameState_Haven(Scanner) != none && ScanSite.CanBeScanned())
		LoadIconStack(XComGameState_Haven(Scanner).GetResistanceFaction().GetFactionIcon());
	else
		LoadSingleIcon(ScanSite.GetUIButtonIcon());

	HideTooltip();
	SetMissionIconTooltip(ScanSite.GetUIButtonTooltipTitle(), ScanSite.GetUIButtonTooltipBody());
	Show();

	BlackMarket = XComGameState_BlackMarket(Scanner);
	if (BlackMarket != None)
		AS_SetLock(BlackMarket.CanBeScanned()); // Black market icon is opposite, locked when it needs a scan
	else
	{
		if (XComGameState_Haven(Scanner) != none)
			AS_SetLock(false);
		else
			AS_SetLock(!ScanSite.CanBeScanned());
	}

	AS_SetGoldenPath(false);
}

simulated function SetMissionSite(XComGameState_MissionSite Mission)
{
	local bool bMissionLocked, bIsGoldenPath;
	local XComGameState_WorldRegion MissionRegion;

	MapItem = `HQPRES.StrategyMap2D.GetMapItem(Mission);
	MissionSite = Mission;
	ScanSite = none;
	OnClickedDelegate = MissionSite.AttemptSelectionCheckInterruption;
	LoadSingleIcon(MissionSite.GetUIButtonIcon());
	HideTooltip();
	SetMissionIconTooltip(MissionSite.GetUIButtonTooltipTitle(), MissionSite.GetUIButtonTooltipBody());
	Show();

	MissionRegion = MissionSite.GetWorldRegion();

	bMissionLocked = ((MissionRegion != none) && !MissionRegion.HaveMadeContact() && MissionSite.bNotAtThreshold);
	bIsGoldenPath = (MissionSite.GetMissionSource().bGoldenPath);

	if (MissionSite.Source == 'MissionSource_Broadcast')
		AS_SetLock(false); //Broadcast the Truth cannot be locked
	else if (MissionSite.Source == 'MissionSource_ChosenStronghold')
		AS_SetLock(MissionSite.bNotAtThreshold);
	else
		AS_SetLock(bMissionLocked);

	AS_SetGoldenPath(bIsGoldenPath);
}

simulated function OnMouseEvent(int cmd, array<string> args)
{
	local XComGameState_Haven HavenState;
	local XComGameState_BlackMarket BlackMarket;

	super.OnMouseEvent(cmd, args);

	HavenState = XComGameState_Haven(ScanSite);
	if (HavenState != None && !HavenState.IsResistanceFactionMet())
		return;

	BlackMarket = XComGameState_BlackMarket(ScanSite);
	
	switch(cmd)
	{
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_IN:
		if (bMoveCamera || `ISCONTROLLERACTIVE == false)
		{
			XComHQPresentationLayer(Movie.Pres).CAMSaveCurrentLocation();
		}
		MapItem.OnMouseIn();
		if (BlackMarket != none)
		{
			SetMissionIconTooltip(BlackMarket.GetUIButtonTooltipTitle(), BlackMarket.GetUIButtonTooltipBody());
			if (bMoveCamera || `ISCONTROLLERACTIVE == false)
			{
				XComHQPresentationLayer(Movie.Pres).CAMLookAtEarth(BlackMarket.Get2DLocation(), ZoomLevel);
			}
		}
		else if(ScanSite != none)
		{
			ScanSite = XComGameState_ScanningSite(`XCOMHISTORY.GetGameStateForObjectID(ScanSite.ObjectID)); // Force an update of Scan Site game state
			SetMissionIconTooltip(ScanSite.GetUIButtonTooltipTitle(), ScanSite.GetUIButtonTooltipBody());
			if (bMoveCamera || `ISCONTROLLERACTIVE == false)
			{
				XComHQPresentationLayer(Movie.Pres).CAMLookAtEarth(ScanSite.Get2DLocation(), ZoomLevel);
			}
		}
		else if( MissionSite != none )
		{
			SetMissionIconTooltip(MissionSite.GetUIButtonTooltipTitle(), MissionSite.GetUIButtonTooltipBody());
			if (bMoveCamera || `ISCONTROLLERACTIVE == false)
			{
				XComHQPresentationLayer(Movie.Pres).CAMLookAtEarth(MissionSite.Get2DLocation(), ZoomLevel);
			}
		}
		else
		{
			if (bMoveCamera || `ISCONTROLLERACTIVE == false)
			{
				XComHQPresentationLayer(Movie.Pres).CAMLookAtEarth(MissionSite.Get2DLocation(), ZoomLevel);
			}
		}
		break;
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_OUT:
		MapItem.OnMouseOut();
		if (bMoveCamera || `ISCONTROLLERACTIVE == false)
		{
			XComHQPresentationLayer(Movie.Pres).CAMRestoreSavedLocation();
		}
		break;
	};
}

simulated function HideTooltip()
{
	if( Tooltip != none )
	{
		Tooltip.HideTooltip();
	}
}

simulated function SetMissionIconTooltip(string Title, string Body)
{
	local XComGameState_Haven HavenState;
	HavenState = XComGameState_Haven(ScanSite);
	if (HavenState != None && !HavenState.IsResistanceFactionMet())
		return;

	if( Tooltip == none )
	{
		Tooltip = Spawn(class'UIStrategyMap_MissionIconTooltip', Movie.Pres.m_kTooltipMgr);
		Tooltip.InitMissionIconTooltip(Title, Body);

		//Tooltip.SetAnchor(class'UIUtilities'.const.ANCHOR_BOTTOM_CENTER); 
		Tooltip.bFollowMouse = true;

		Tooltip.targetPath = string(MCPath);
		Tooltip.bUsePartialPath = true;
		Tooltip.tDelay = 0.0;

		Tooltip.ID = Movie.Pres.m_kTooltipMgr.AddPreformedTooltip(Tooltip);
	}
	else
	{
		Tooltip.SetText(Title, Body);
	}
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	local array<string> EmptyArray;

	if (!CheckInputIsReleaseOrDirectionRepeat(cmd, arg))
	{
		return true;
	}

	switch(cmd)
	{
	case class'UIUtilities_Input'.const.FXS_BUTTON_A:
		if (`HQPRES.StrategyMap2D.XComHQ().GetCurrentScanningSite().ObjectID == ScanSite.ObjectID &&
			ScanSite.CanBeScanned())
		{
			`HQPRES.StrategyMap2D.ToggleScan();
		}
		else
		{
			EmptyArray.Length = 0;
			OnMouseEvent(class'UIUtilities_Input'.const.FXS_L_MOUSE_UP, EmptyArray);
		}

		return true;
	}

	return super.OnUnrealCommand(cmd, arg);
}

simulated function OnReceiveFocus()
{
	local array<string> EmptyArray;
	EmptyArray.Length = 0;

	if (Movie.IsMouseActive())
	{
		return;
	}

	if (bFocused)
	{
		return;
	}

	bFocused = true;

	MC.FunctionVoid("showSelectionBrackets"); //bsg-jneal (5.19.17): show greeble rings on focus received
	OnMouseEvent(class'UIUtilities_Input'.const.FXS_L_MOUSE_IN, EmptyArray);
}

simulated function OnLoseFocus()
{
	local array<string> EmptyArray;
	EmptyArray.Length = 0;

	if (Movie.IsMouseActive())
	{
		return;
	}

	if (!bFocused)
	{
		return;
	}
	
	bFocused = false;

	MC.FunctionVoid("hideSelectionBrackets"); //bsg-jneal (5.19.17): hide greeble rings when focus is lost
	OnMouseEvent(class'UIUtilities_Input'.const.FXS_L_MOUSE_OUT, EmptyArray);
}

simulated function AS_SetLock(bool isLocked)
{
	MC.FunctionBool("SetLock", isLocked);
}

simulated function AS_SetAlert(bool bShow)
{
	MC.FunctionBool("SetAlert", bShow);
}

simulated function AS_SetGoldenPath(bool bShow)
{
	MC.FunctionBool("SetGoldenPath", bShow);
}

simulated function Remove()
{
	Movie.Pres.m_kTooltipMgr.RemoveTooltipByTarget(string(MCPath));
	super.Remove();
}

defaultproperties
{
	LibID = "StrategyMapMissionIcon";
}