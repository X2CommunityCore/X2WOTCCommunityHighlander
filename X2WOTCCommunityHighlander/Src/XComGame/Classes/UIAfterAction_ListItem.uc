//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UISquadSelect_MissionInfo
//  AUTHOR:  Sam Batista -- 5/1/14
//  PURPOSE: Displays information pertaining to a single soldier in the Headquarters Squad
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIAfterAction_ListItem extends UIPanel
	dependson(XComPhotographer_Strategy);

var StateObjectReference UnitReference;

var localized string m_strActive;
var localized string m_strWounded;
var localized string m_strMIA;
var localized string m_strKIA;
var localized string m_strMissionsLabel;
var localized string m_strKillsLabel;
var localized string m_strMemorialize;

var UIImage PsiMarkup;
var UIButton PromoteButton;
var UIButton MemorialButton;
var bool bShowPortrait;
var UIBondIcon BondIcon;
var bool m_bCanPromote;
var bool m_bKIA;
var int Index; 

simulated function UIAfterAction_ListItem InitListItem()
{
	InitPanel();

	PsiMarkup = Spawn(class'UIImage', self).InitImage(, class'UIUtilities_Image'.const.PsiMarkupIcon);
	PsiMarkup.SetScale(0.7).SetPosition(230, 130).Hide(); // starts off hidden until needed

	BondIcon = Spawn(class'UIBondIcon', self).InitBondIcon('bondIconMC', , OnClickBondIcon);

	CreateFlyoverTooltip();

	return self;
}

simulated function OnClickBondIcon(UIBondIcon Icon)
{
	local XComGameState_Unit UnitState;

	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitReference.ObjectID));

	if(UnitState.GetSoldierClassTemplate().bCanHaveBonds )
	{
		`HQPRES.UISoldierBonds(UnitReference, true);
	}
}

simulated function UpdateData(optional StateObjectReference UnitRef)
{
	local int days, injuryHours;
	local bool bCanPromote, bKIA;
	local string statusLabel, statusText, daysLabel, daysText, ClassStr;
	local XComGameState_Unit Unit, Bondmate;
	local SoldierBond BondData;
	local StateObjectReference BondmateRef;
	//local XComGameState_ResistanceFaction FactionState; //Issue #1134, not needed
	local StackedUIIconData StackedClassIcon; // Variable for issue #1134

	UnitReference = UnitRef;

	Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitRef.ObjectID));

	//FactionState = Unit.GetResistanceFaction(); //Issue #1134, not needed

	if(Unit.bCaptured)
	{
		statusText = m_strMIA;
		statusLabel = "kia"; // corresponds to timeline label on 'AfterActionBG' mc in SquadList.fla
		bShowPortrait = true;
	}
	else if(Unit.IsAlive())
	{
		// TODO: Add support for soldiers MIA (missing in action)

		if(Unit.IsInjured() || Unit.GetStatus() == eStatus_Healing)
		{
			statusText = Caps(Unit.GetWoundStatus(injuryHours, true));
			statusLabel = "wounded"; // corresponds to timeline label on 'AfterActionBG' mc in SquadList.fla
			
			if( injuryHours > 0 )
			{
				days = injuryHours / 24;
				if( injuryHours % 24 > 0 )
					days += 1;

				daysLabel = class'UIUtilities_Text'.static.GetDaysString(days);
				daysText = string(days);
			}
		}
		else
		{
			statusText = m_strActive;
			statusLabel = "active"; // corresponds to timeline label on 'AfterActionBG' mc in SquadList.fla
		}

		if(Unit.HasPsiGift())
			PsiMarkup.Show();
		else
			PsiMarkup.Hide();
	}
	else
	{
		statusText = m_strKIA;
		statusLabel = "kia"; // corresponds to timeline label on 'AfterActionBG' mc in SquadList.fla
		bShowPortrait = true;
		bKIA = true;
		m_bKIA = bKIA;
	}

	WorldInfo.RemoteEventListeners.AddItem(self); //Listen for the remote event that tells us when we can capture a portrait

	bCanPromote = Unit.ShowPromoteIcon(); 
	//If there's no promote icon, the list item shouldn't be navigable
	bIsNavigable = bCanPromote;
	m_bCanPromote = bCanPromote; //stores a non-local version of the boolean

	// Don't show class label for rookies since their rank is shown which would result in a duplicate string
	if(Unit.GetRank() > 0)
	{
		// Start Issue #106
		ClassStr = class'UIUtilities_Text'.static.GetColoredText(Caps(Unit.GetSoldierClassDisplayName()), eUIState_Faded, 17);
		// End Issue #106
	}
	else
		ClassStr = "";

	// Start Issue #106, #408
	AS_SetData( class'UIUtilities_Text'.static.GetColoredText(Caps(Unit.GetSoldierRankName()), eUIState_Faded, 18),
				class'UIUtilities_Text'.static.GetColoredText(Caps(Unit.GetName(eNameType_Last)), eUIState_Normal, 22),
				class'UIUtilities_Text'.static.GetColoredText(Caps(Unit.GetName(eNameType_Nick)), eUIState_Header, 28),
				Unit.GetSoldierClassIcon(), Unit.GetSoldierRankIcon(),
				(bCanPromote) ? class'UISquadSelect_ListItem'.default.m_strPromote : "",
				statusLabel, statusText, daysLabel, daysText, m_strMissionsLabel, string(Unit.GetNumMissions()),
				m_strKillsLabel, string(Unit.GetNumKills()), false, ClassStr);
	// End Issue #106, #408

	AS_SetUnitHealth(class'UIUtilities_Strategy'.static.GetUnitCurrentHealth(Unit, true), class'UIUtilities_Strategy'.static.GetUnitMaxHealth(Unit));

	if( Unit.UsesWillSystem() )
	{
		AS_SetUnitWill(class'UIUtilities_Strategy'.static.GetUnitWillPercent(Unit), class'UIUtilities_Strategy'.static.GetUnitWillColorString(Unit));
	}
	else
	{
		AS_SetUnitWill(-1, "");
	}

	// Start Issue #1134
	StackedClassIcon = Unit.GetStackedClassIcon();
	if (StackedClassIcon.Images.Length > 0)
		AS_SetFactionIcon(StackedClassIcon);
	// End Issue #1134

	EnableNavigation(); // bsg-nlong (1.24.17): We will always want navigation now that the bond icon is a thing
	if( bCanPromote )
	{
		if( PromoteButton == none ) //This data will be refreshed several times, so beware not to spawn dupes. 
		{
			PromoteButton = Spawn(class'UIButton', self);
			PromoteButton.InitButton('promoteButtonMC', "", OnClickedPromote, eUIButtonStyle_NONE);
		}
		else
		{
			PromoteButton.OnClickedDelegate = OnClickedPromote;
		}

		PromoteButton.Show();
	}
	else
	{
		if (!bKIA)
		{
			if (PromoteButton != none)
			{
				PromoteButton.Remove();
			}
		}
	}

	if (bKIA)
	{
		if (PromoteButton == none) //This data will be refreshed several times, so beware not to spawn dupes. 
		{
			PromoteButton = Spawn(class'UIButton', self);
			PromoteButton.InitButton('promoteButtonMC', "", OnClickedMemorialize, eUIButtonStyle_NONE);
		}
		else
		{
			PromoteButton.OnClickedDelegate = OnClickedMemorialize;
		}
		PromoteButton.Show();

		MC.FunctionString("setDeadSoldierButton", m_strMemorialize);
	}
	else if (!bCanPromote)
	{
		if (PromoteButton != None)
			PromoteButton.Remove();
	}
	Navigator.Clear();
	
	if(!Unit.GetSoldierClassTemplate().bCanHaveBonds || m_bKIA)
	{
		BondIcon.SetBondLevel(-1);
		BondIcon.RemoveTooltip();
	}
	else if(Unit.HasSoldierBond(BondmateRef, BondData))
	{
		Bondmate = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(BondmateRef.ObjectID));
		if (Unit.IsAlive() && Bondmate.IsAlive())
		{
			BondIcon.SetBondLevel(BondData.BondLevel);

			if( Index == 5 )
				BondIcon.SetBondmateTooltip(BondmateRef, class'UIUtilities'.const.ANCHOR_TOP_RIGHT);
			else
				BondIcon.SetBondmateTooltip(BondmateRef);
		}
		else
		{
			BondIcon.SetBondLevel(0);
			BondIcon.AnimateCohesion(false);
			BondIcon.SetTooltipText(class'UISoldierBondScreen'.default.BondTitle);
		}
	}
	else if( Unit.HasSoldierBondAvailable(BondmateRef, BondData) )
	{
		BondIcon.SetBondLevel(0);
		BondIcon.AnimateCohesion(true);
		BondIcon.SetTooltipText(class'XComHQPresentationLayer'.default.m_strBannerBondAvailable);
	}
	else
	{
		BondIcon.SetBondLevel(0);
		BondIcon.AnimateCohesion(false);
		BondIcon.SetTooltipText(class'UISoldierBondScreen'.default.BondTitle);
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
		case class'UIUtilities_Input'.const.FXS_KEY_ENTER: //bsg-crobinson (5.5.17): allow enter to have functionality
		case class'UIUtilities_Input'.const.FXS_BUTTON_A:
			// bsg-nlong (1.24.17): Call the function depending on whether the promote icon is highlighted or the bind icon is
			if( m_bCanPromote && PromoteButton != none && bIsFocused && PromoteButton.bIsFocused)
				OnClickedPromote(None);
			else if (m_bKIA && PromoteButton != none && bIsFocused && PromoteButton.bIsFocused)
				OnClickedMemorialize(None);
			else
				OnClickBondIcon(None);

			// bsg-nlong (1.24.17): end
			return true;
		// bsg-nlong (1.24.17): If we put the promote button and the BondIcon in the Navigator it creates a infinite recursion
		// with the AfterAction Navigator. Since there are only 1-2 elements to select between we can easily manually code navigation here
		// bsg-jrebar (05/19/17): Keep focus on bond or promote
		case class'UIUtilities_Input'.const.FXS_ARROW_UP:
		case class'UIUtilities_Input'.const.FXS_ARROW_DOWN:
		case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_UP:
		case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_DOWN:
		case class'UIUtilities_Input'.const.FXS_DPAD_DOWN:
		case class'UIUtilities_Input'.const.FXS_DPAD_UP:
			if(OnUpDownInputHandler())
			{
				return true;
			}
		// bsg-jrebar (05/19/17): end
	}

	return super.OnUnrealCommand(cmd, arg);
}

// bsg-jrebar (05/19/17): Keep focus on bond or promote
simulated function bool OnUpDownInputHandler()
{
	if(m_bCanPromote && PromoteButton != none)
	{
		if( PromoteButton.bIsFocused )
		{
			PromoteButton.OnLoseFocus();
			BondIcon.OnReceiveFocus();
		}
		else
		{
			PromoteButton.OnReceiveFocus();
			BondIcon.OnLoseFocus();
		}
		return true;
	}
	else if(m_bKIA && PromoteButton != none)
	{
		PromoteButton.OnReceiveFocus();
		return true;
	}
	else
	{
		BondIcon.OnReceiveFocus();
		return true;
	}
}
// bsg-jrebar (05/19/17): end

simulated function OnClickedPromote(UIButton Button)
{
	AfterActionPromote();
}

simulated function AfterActionPromote()
{
	UIAfterAction(Screen).OnPromote(UnitReference);
}

simulated function OnClickedMemorialize(UIButton Button)
{
	local UIArmory_Photobooth photoscreen;
	local PhotoboothDefaultSettings autoDefaultSettings;
	local AutoGenPhotoInfo requestInfo;

	requestInfo.TextLayoutState = ePBTLS_DeadSoldier;
	requestInfo.UnitRef = UnitReference;
	autoDefaultSettings = `HQPRES.GetPhotoboothAutoGen().SetupDefault(requestInfo);
	autoDefaultSettings.SoldierAnimIndex.AddItem(-1);

	photoscreen = XComHQPresentationLayer(Movie.Pres).UIArmory_Photobooth(UnitReference);
	photoscreen.DefaultSetupSettings = autoDefaultSettings;
}

event OnRemoteEvent(name RemoteEventName)
{	
	super.OnRemoteEvent(RemoteEventName);

	// Only take head shot picture once
	if(RemoteEventName == 'PostM_ShowSoldierHUD')
	{
		`HQPRES.GetPhotoboothAutoGen().AddHeadShotRequest(UnitReference, 128, 128, UpdateAfterActionImage, , , true);
		`HQPRES.GetPhotoboothAutoGen().RequestPhotos();

		`GAME.GetGeoscape().m_kBase.m_kCrewMgr.TakeCrewPhotobgraph(UnitReference, , true);
	}
}

simulated function UpdateAfterActionImage(StateObjectReference UnitRef)
{
	local XComGameState_CampaignSettings SettingsState;
	local Texture2D SoldierPicture;

	if (bShowPortrait)
	{
		SettingsState = XComGameState_CampaignSettings(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings'));
		SoldierPicture = `XENGINE.m_kPhotoManager.GetHeadshotTexture(SettingsState.GameIndex, UnitRef.ObjectID, 128, 128);
		AS_SetDeadSoldierImage(class'UIUtilities_Image'.static.ValidateImagePath(PathName(SoldierPicture)), m_strMemorialize);
	}
}

// same as UISquadSelect_ListItem
simulated function AnimateIn(optional float AnimationIndex = -1.0)
{
	MC.FunctionNum("animateIn", AnimationIndex);
}

//------------------------------------------------------

simulated function AS_SetData( string firstName, string lastName, string nickName,
							   string classIcon, string rankIcon, string promote, 
							   string statusLabel, string statusText, string daysLabel, string daysText,
							   string missionsLabel, string missionsText, string killsLabel, string killsText, bool isPsiPromote, string className)
{
	mc.BeginFunctionOp("setData");
	mc.QueueString(firstName);
	mc.QueueString(lastName);
	mc.QueueString(nickName);
	mc.QueueString(classIcon);
	mc.QueueString(rankIcon);
	mc.QueueString(promote);
	mc.QueueString(statusLabel);
	mc.QueueString(statusText);
	mc.QueueString(daysLabel);
	mc.QueueString(daysText);
	mc.QueueString(missionsLabel);
	mc.QueueString(missionsText);
	mc.QueueString(killsLabel);
	mc.QueueString(killsText);
	mc.QueueBoolean(isPsiPromote);
	mc.QueueString(className);
	mc.EndOp();
}

simulated function AS_SetUnitHealth(int CurrentHP, int MaxHP)
{
	mc.BeginFunctionOp("setUnitHealth");
	mc.QueueNumber(CurrentHP);
	mc.QueueNumber(MaxHP);
	mc.EndOp();
}

simulated function AS_SetDeadSoldierImage(string ImagePath, string ButtonName)
{
	MC.BeginFunctionOp("setDeadSoldierImage");
	MC.QueueString(ImagePath);
	MC.QueueString(ButtonName);
	MC.EndOp();
}

simulated function OnReceiveFocus()
{
	super.OnReceiveFocus();

	if(PromoteButton != None && m_bCanPromote || m_bKIA)
	{
		PromoteButton.OnReceiveFocus();
	}
	// bsg-nlong (1.24.17): Put focus on the bond icon if we can't put it on the promote button
	else
	{
		BondIcon.OnReceiveFocus();
	}
	// bsg-nlong (1.24.17): end
}

simulated function OnLoseFocus()
{
	super.OnLoseFocus();

	if(PromoteButton != None)
	{
		PromoteButton.OnLoseFocus();
	}

	BondIcon.OnLoseFocus(); // bsg-nlong (1.24.17): Lose focus on the bond icon as well
}
simulated function AS_SetUnitWill(int WillPercent, string strColor)
{
	mc.BeginFunctionOp("setUnitWill");
	mc.QueueNumber(WillPercent);
	mc.QueueString(strColor);
	mc.EndOp();
}

simulated function AS_SetUnitFlyover(string Icon, string Label, string ColorStr)
{
	mc.BeginFunctionOp("setUnitFlyover");
	mc.QueueString(Icon);
	mc.QueueString(Label);
	mc.QueueString(ColorStr);
	mc.EndOp();
}

public function AS_SetFactionIcon(StackedUIIconData IconInfo)
{
	local int i;

	if (IconInfo.Images.Length > 0)
	{
		MC.BeginFunctionOp("setUnitFactionIcon");
		MC.QueueBoolean(IconInfo.bInvert);
		for (i = 0; i < IconInfo.Images.Length; i++)
		{
			MC.QueueString("img:///" $ Repl(IconInfo.Images[i], ".tga", "_sm.tga"));
		}

		MC.EndOp();
	}
}

simulated function CreateFlyoverTooltip()
{
	local UITooltipMgr Mgr;
	local XComGameState_Unit UnitState;

	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitReference.ObjectID));

	if( UnitState.GetMentalStateUIState() == eMentalState_Tired )
	{
		Mgr = XComHQPresentationLayer(Movie.Pres).m_kTooltipMgr;

		CachedTooltipId = Mgr.AddNewTooltipTextBox(class'UISquadSelect_ListItem'.default.m_strTiredTooltip,
												   10,
												   0,
												   string(MCPath) $".unitFlyover",
												   ,
												   ,
												   ,
												   true);
		bHasTooltip = true;
	}
}

defaultproperties
{
	LibID = "AfterActionListItem";
	bCascadeFocus = false;
	width = 282;
}

//------------------------------------------------------