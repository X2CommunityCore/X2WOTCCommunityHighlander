//----------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UILadderUpgradeScreen.uc
//  AUTHOR:  Joe Cortese
//----------------------------------------------------------------------------
//  Copyright (c) 2018 Firaxis Games, Inc. All rights reserved.
//----------------------------------------------------------------------------

class UILadderSoldierInfo extends UIScreen
	dependson(UITacticalQuickLaunch_MapData);

var int m_SoldierStartIndex;
var int m_NumSoldiers;
var int ObjectID;

var X2Photobooth_StrategyAutoGen m_kPhotoboothAutoGen;
var X2Photobooth_TacticalLocationController m_kTacticalLocation;


var XComGameState_LadderProgress m_LadderData;

var array< Texture2D > StaffPictures;

var array< XComGameState_Unit > PrevStates;
var array< XComGameState_Unit > CurrentStates;

var UIButton PrevButton;
var UIButton NextButton;
var array<UIButton> LadderSoldierInfoButtons;

var UINavigationHelp NavHelp;

var localized string m_SaveAndQuitLadder;
var localized string m_NextMission;
var localized string m_MissionLabel;
var localized string m_MissionComplete;
var localized string m_RankUp;
var localized string m_NewSoldier;
var localized string m_NewAbilities;
var localized string m_KIA;
var localized string m_NewItems;

var localized string m_strHelpPrevPage;
var localized string m_strHelpNextPage;
var localized string m_strHelpSoldierInfo;


simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local string SoldierIconName;
	local StateObjectReference UnitStateRef;
	local XComGameState_Unit UnitState, PreviousUnitState;
	local XComGameState PendingStartState;
	local int i;

	super.InitScreen(InitController, InitMovie, InitName);
	
	PrevButton = Spawn(class'UIButton', self).InitButton('LeftButton', "", BackButtonClicked);
	PrevButton.Hide();
	PrevButton.DisableNavigation();

	NextButton = Spawn(class'UIButton', self).InitButton('RightButton', "", ContinueButtonClicked);	
	NextButton.DisableNavigation();

	for (i = 0; i < 3; i++)
	{
		SoldierIconName = "Soldier0"$i$".SoldierImage.SoldierInfoButton";
		LadderSoldierInfoButtons.AddItem(Spawn(class'UIButton', self));
		LadderSoldierInfoButtons[i].InitButton(name(SoldierIconName), , InfoButtonClicked, , 'X2InfoButton');
		//SoldierInfoPanels[i].AddChild(LadderSoldierInfoButtons[i]);
		
		LadderSoldierInfoButtons[i].SetPosition(135 + (i * 375), 275);
		LadderSoldierInfoButtons[i].DisableNavigation();
	}

	SetPosition( 400, 45);

	m_kTacticalLocation = new class'X2Photobooth_TacticalLocationController';
	m_kTacticalLocation.Init(OnStudioLoaded);

	PendingStartState = `XCOMHISTORY.GetStartState( );

	XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	m_LadderData = XComGameState_LadderProgress(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_LadderProgress'));

	XComHQ = XComGameState_HeadquartersXCom( PendingStartState.GetGameStateForObjectID( XComHQ.ObjectID ) );
	m_LadderData = XComGameState_LadderProgress( PendingStartState.GetGameStateForObjectID(m_LadderData.ObjectID ) );

	StaffPictures.Length = XComHQ.Squad.Length * 2; // keep enough space for a squad-wipe/replacement (although that's one more than worst case).
	for(i = 0; i <  XComHQ.Squad.Length; i++)
	{
		UnitStateRef = XComHQ.Squad[i];
		UnitState = XComGameState_Unit(PendingStartState.GetGameStateForObjectID(UnitStateRef.ObjectID));
		PreviousUnitState = m_LadderData.LastMissionState[ i ];

		if (UnitState.bMissionProvided)
			continue;

		if ((PreviousUnitState == none) || PreviousUnitState.IsAlive())
		{
			PrevStates.AddItem( PreviousUnitState );
			CurrentStates.AddItem( UnitState );
		}
		else
		{
			PrevStates.AddItem( PreviousUnitState );
			CurrentStates.AddItem( none );

			PrevStates.AddItem( none );
			CurrentStates.AddItem( UnitState );
		}
	}
	m_NumSoldiers = CurrentStates.Length;

	NavHelp = GetNavHelp();
	UpdateNavHelp();
}

function OnStudioLoaded()
{
	local int i;
	local XComGameState_LadderProgress LadderData;
	local XComGameState_Unit UnitState;

	LadderData = XComGameState_LadderProgress(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_LadderProgress'));

	m_kPhotoboothAutoGen = Spawn(class'X2Photobooth_StrategyAutoGen', self);
	m_kPhotoboothAutoGen.bLadderMode = true;
	m_kPhotoboothAutoGen.Init();
	m_kPhotoboothAutoGen.AutoGenSettings.FormationLocation = m_kTacticalLocation.GetFormationPlacementActor();

	for (i = 0; i < CurrentStates.Length; i++)
	{
		UnitState = CurrentStates[i] != none ? CurrentStates[i] : PrevStates[i];
		if (!LadderData.IsFixedNarrativeUnit(UnitState))
		{
			m_kPhotoboothAutoGen.AddHeadShotRequest(UnitState.GetReference(), 512, 512, HeadshotReceived);
		}
	}

	m_kPhotoboothAutoGen.RequestPhotos();
}

simulated function OnInit()
{
	local XComGameState_LadderProgress LadderData;
	
	LadderData = XComGameState_LadderProgress(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_LadderProgress'));
	ObjectID = LadderData.ObjectID;

	MC.BeginFunctionOp("SetScreenTitle");
	MC.QueueString(m_MissionComplete); // Title
	if (LadderData.LadderIndex < 10)
	{
		MC.QueueString(LadderData.NarrativeLadderNames[LadderData.LadderIndex]);//Mission Name
	}
	else
	{
		MC.QueueString(LadderData.LadderName);//Mission Name
	}
	
	MC.QueueString(m_MissionLabel);//Mission Label
	MC.QueueString(String(LadderData.LadderRung-1) $ "/" $ String(LadderData.LadderSize));//Mission Count
	MC.EndOp();

	MC.FunctionVoid("SetScreenFooter");

	super.OnInit();

	m_SoldierStartIndex = 0;
	UpdateData();

	NavHelp.ContinueButton.OffsetY = -90;

	if( `ISCONTROLLERACTIVE )
	{
		NavHelp.AddLeftHelp(class'UITacticalHUD_MouseControls'.default.m_strSoldierInfo, class'UIUtilities_Input'.const.ICON_Y_TRIANGLE);
	}
}

simulated function SetSoldierImage( int UIIndex, int SoldierIndex, XComGameState_Unit UnitState )
{
	local XComGameState_LadderProgress LadderData;

	LadderData = XComGameState_LadderProgress(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_LadderProgress'));

	MC.BeginFunctionOp("SetSoldierImage");
	MC.QueueNumber(UIIndex); // Index 0-2

	if (StaffPictures[SoldierIndex] != none)
	{
		MC.QueueString(class'UIUtilities_Image'.static.ValidateImagePath(PathName(StaffPictures[SoldierIndex]))); // Picture Image
	}
	else if(LadderData.IsFixedNarrativeUnit(UnitState))
	{
		MC.QueueString(class'UIUtilities_Image'.static.ValidateImagePath("UILibrary_TLE_Common.TLE_Ladder_"$LadderData.LadderIndex$"_"$UnitState.GetLastName()));
	}
	else
	{
		MC.QueueString("");
	}

	MC.QueueString(UnitState.GetSoldierClassTemplate().IconImage); //Class Icon Image
	MC.QueueString(class'UIUtilities_Image'.static.GetRankIcon(UnitState.GetRank(), UnitState.GetSoldierClassTemplateName())); //Rank image
	
	if (LadderData.LadderIndex < 10)
	{
		MC.QueueString(class'XComGameState_LadderProgress'.static.GetUnitName(SoldierIndex, LadderData.LadderIndex)); //Unit Name
	}
	else
	{
		MC.QueueString(UnitState.GetFullName());
	}
	
	MC.QueueString(UnitState.GetSoldierClassTemplate().DisplayName); //Class Name
	MC.EndOp();
}

simulated function UpdateData()
{
	local XComGameState_Unit UnitState, PreviousUnitState;
	local int i, j, k, soldiersDisplayed;
	local bool bisDead, bFoundPreviousUnit;
	local array<XComGameState_Item> SoldierItems, PreviousSoldierItems;
	local XComGameState_Item CurrentItem, PreviousItem;
	local array<SoldierClassAbilityType> SoldierAbilities, PreviousSoldierAbilities;
	local SoldierClassAbilityType CurrentAbility, PreviousAbility;
	local name UpgradeName;
	local X2LadderUpgradeTemplate UpgradeTemplate;
	local Upgrade Entry;
	local X2LadderUpgradeTemplateManager TemplateManager;
	local name ItemName;

	TemplateManager = class'X2LadderUpgradeTemplateManager'.static.GetLadderUpgradeTemplateManager();

	UpgradeName = m_LadderData.ProgressionUpgrades[m_LadderData.ProgressionUpgrades.Length - 1];
	UpgradeTemplate = TemplateManager.FindUpgradeTemplate(UpgradeName);
	// make sure every unit on this leg of the mission is ready to go
	soldiersDisplayed = 0;
	for(i = m_SoldierStartIndex; (i <  m_SoldierStartIndex + 3) && (i < CurrentStates.Length); i++)
	{
		if (CurrentStates[i] != none)
		{
			LadderSoldierInfoButtons[soldiersDisplayed].Show();
			LadderSoldierInfoButtons[soldiersDisplayed].AnimateIn();
		}
		else
		{
			LadderSoldierInfoButtons[soldiersDisplayed].Hide();
		}
		UnitState = CurrentStates[ i ];

		bisDead = false;
		bFoundPreviousUnit = false;
		PreviousSoldierItems.Remove(0, PreviousSoldierItems.Length);
		PreviousSoldierAbilities.Remove(0, PreviousSoldierAbilities.Length);

		if (UnitState == none)
		{
			UnitState = PrevStates[i];
			`assert( UnitState != none );

			bisDead = true;

			PreviousSoldierItems = UnitState.GetAllInventoryItems( UnitState.GetParentGameState() );
			PreviousSoldierAbilities = UnitState.GetEarnedSoldierAbilities();
		}
		else if (PrevStates[ i ] != none)
		{
			bFoundPreviousUnit = true;
			PreviousUnitState = PrevStates[i];
			PreviousSoldierItems = PreviousUnitState.GetAllInventoryItems(PreviousUnitState.GetParentGameState());
			PreviousSoldierAbilities = PreviousUnitState.GetEarnedSoldierAbilities();
		}
			
		SoldierItems = UnitState.GetAllInventoryItems();
		SoldierAbilities = UnitState.GetEarnedSoldierAbilities();

		SetSoldierImage( soldiersDisplayed++, i, UnitState );

		MC.BeginFunctionOp("SetSoldierHeader");
		MC.QueueNumber(i - m_SoldierStartIndex);
		if (bisDead)
		{
			MC.QueueString(m_KIA);
			MC.QueueNumber(2);
		}
		else if (!bFoundPreviousUnit)
		{
			MC.QueueString(m_NewSoldier);
			MC.QueueNumber(1);
		}
		else
		{
			MC.QueueString(m_RankUp);
			MC.QueueNumber(0); //0 for rank up, 1 for new soldier, anything else for blank (this modifies color of header)
		}
		MC.EndOp();

		MC.BeginFunctionOp("SetAbilityHeader");
		MC.QueueNumber(i - m_SoldierStartIndex);
		if (bisDead)
		{
			MC.QueueString(m_KIA);
			MC.QueueNumber(2);
		}
		else
		{
			MC.QueueString(m_NewAbilities);
			MC.QueueNumber(1);
		}
		MC.EndOp();

		MC.BeginFunctionOp("SetItemHeader");
		MC.QueueNumber(i - m_SoldierStartIndex);
		if (bisDead)
		{
			MC.QueueString(m_KIA);
			MC.QueueNumber(2);
		}
		else
		{
			MC.QueueString(m_NewItems);
			MC.QueueNumber(1);
		}
		MC.EndOp();

		for (k = 0; k < PreviousSoldierItems.Length; k++)
		{
			PreviousItem = PreviousSoldierItems[k];
			for (j = SoldierItems.Length - 1; j >= 0; j--)
			{
				CurrentItem = SoldierItems[j];

				if (CurrentItem.GetMyTemplateName() == PreviousItem.GetMyTemplateName() ||  CurrentItem.GetMyTemplate().iItemSize <= 0)
				{
					SoldierItems.Remove(j, 1);
				}
			}
		}

		for (k = SoldierItems.Length - 1; k >= 0; --k)
		{
			if (SoldierItems[k].GetMyTemplateName() == 'XPad') // don't show xpad's for new soldiers.
				SoldierItems.Remove(k, 1);
			else if ((X2WeaponTemplate(SoldierItems[k].GetMyTemplate()) != none) && (X2WeaponTemplate(SoldierItems[k].GetMyTemplate()).InventorySlot == eInvSlot_TertiaryWeapon)) // skip paired items in favor of the display element
				SoldierItems.Remove(k, 1);
		}

		for (j = 0; j < SoldierItems.Length && !bisDead; j++)
		{
			CurrentItem = SoldierItems[j];
			AddItem(soldiersDisplayed - 1, j, CurrentItem.GetMyTemplateName(), CurrentItem.GetWeaponPanelImages());
		}
		
		if (InStr(UpgradeTemplate.ImagePath, "Modular_Weapons") != -1)
		{
			foreach UpgradeTemplate.Upgrades(Entry)
			{
				if ((Entry.ClassFilter != "") && (Entry.ClassFilter != string(UnitState.GetSoldierClassTemplate().DataName)))
					continue;

				foreach Entry.EquipmentNames(ItemName)
				{
					AddItem(soldiersDisplayed - 1, j++, ItemName);
				}
			}
		}

		for (k = 0; k < PreviousSoldierAbilities.Length; k++)
		{
			PreviousAbility = PreviousSoldierAbilities[k];
			for (j = SoldierAbilities.Length - 1; j >= 0; j--)
			{
				CurrentAbility = SoldierAbilities[j];

				if (CurrentAbility.AbilityName == PreviousAbility.AbilityName)
				{
					SoldierAbilities.Remove(j, 1);
				}
			}
		}

		for (j = 0; j < SoldierAbilities.Length && !bisDead; j++)
		{
			AddAbility(soldiersDisplayed - 1, j, SoldierAbilities[j].AbilityName);
		}
	}

	for (i = soldiersDisplayed; i < 3; i++)
	{
		MC.FunctionNum("HideSoldier", i);
		LadderSoldierInfoButtons[i].Hide();
	}

	UpdateNavHelp();
}

simulated function AddAbility(int SoldierIndex, int index, name AbilityName)
{
	local X2AbilityTemplateManager AbilityTemplateMgr;
	local X2AbilityTemplate AbilityTemplate;

	AbilityTemplateMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	AbilityTemplate = AbilityTemplateMgr.FindAbilityTemplate(AbilityName);
	
	MC.BeginFunctionOp("AddAbility");
	MC.QueueNumber(SoldierIndex);
	MC.QueueNumber(index);
	MC.QueueString(AbilityTemplate.IconImage);
	MC.QueueString(class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS(AbilityTemplate.LocFriendlyName));
	MC.EndOp();
}

simulated function AddItem(int SoldierIndex, int index, name ItemName, optional array<string> WeaponImages)
{
	local X2ItemTemplateManager ItemTemplateMgr;
	local X2ItemTemplate ItemTemplate;
	local int i;

	ItemTemplateMgr = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	ItemTemplate = ItemTemplateMgr.FindItemTemplate(ItemName);

	MC.BeginFunctionOp("AddItem");
	MC.QueueNumber(SoldierIndex);
	MC.QueueNumber(index);
	MC.QueueString(class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS(ItemTemplate.GetItemFriendlyName()));
	if (WeaponImages.Length <= 0)
	{
		MC.QueueString(ItemTemplate.strImage);
	}
	else
	{
		for (i = 0; i < WeaponImages.Length; i++)
		{
			MC.QueueString(WeaponImages[i]);
		}
	}
	MC.EndOp();
}

private simulated function HeadshotReceived(StateObjectReference UnitRef)
{
	local XComGameState_CampaignSettings SettingsState;
	local XComGameState_Unit UnitState;
	local UITLEUnitStats UnitStatsScreen;
	local int DisplayIndex, i;

	for (i = 0; i < CurrentStates.Length; i++)
	{
		if (CurrentStates[i] != none && CurrentStates[i].GetReference().ObjectID == UnitRef.ObjectID && StaffPictures[i] == none)
		{
			UnitState = CurrentStates[i];
			break;
		}
		
		if(PrevStates[i] != none && PrevStates[i].GetReference().ObjectID == UnitRef.ObjectID && StaffPictures[i] == none)
		{
			UnitState = PrevStates[i];
			break;
		}
	}

	if (i == CurrentStates.Length) 
		return;

	SettingsState = XComGameState_CampaignSettings(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings'));
	StaffPictures[i] = `XENGINE.m_kPhotoManager.GetHeadshotTexture(SettingsState.GameIndex, UnitRef.ObjectID, 512, 512);

	DisplayIndex = i - m_SoldierStartIndex;

	if ((DisplayIndex >= 0) && (DisplayIndex < 3))
		SetSoldierImage( DisplayIndex, i, UnitState );

	UnitStatsScreen = UITLEUnitStats(`SCREENSTACK.GetFirstInstanceOf(class'UITLEUnitStats'));

	if (UnitStatsScreen != none && UnitRef == UnitStatsScreen.m_UnitArray[UnitStatsScreen.m_CurrentIndex].GetReference())
	{
		UnitStatsScreen.UpdateData(UnitStatsScreen.m_UnitArray[UnitStatsScreen.m_CurrentIndex], UnitStatsScreen.m_CheckGameState);
	}
}

simulated function OnMouseEvent(int cmd, array<string> args)
{
	switch (cmd)
	{
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_IN :
		`SOUNDMGR.PlaySoundEvent("Play_Mouseover");
		break;
	}
}

public function NextMissionButtonClicked()
{
	local XComGameState_LadderProgress LadderData;
	
	Movie.Pres.PlayUISound(eSUISound_MenuSelect);

	`TACTICALRULES.bWaitingForMissionSummary = false;

	// clear out these references to the previous state, we don't need them and they may track back to the world about to be unloaded.
	LadderData = XComGameState_LadderProgress(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_LadderProgress'));
	LadderData.LastMissionState.Length = 0;
}

public function ContinueButtonClicked(UIButton Button)
{
	Movie.Pres.PlayUISound(eSUISound_MenuSelect);

	PrevButton.Show();
	
	if ( m_SoldierStartIndex + 3 < m_NumSoldiers)
	{
		m_SoldierStartIndex += 3;
	}
	
	if (m_NumSoldiers <= m_SoldierStartIndex + 3)
	{
		NextButton.Hide();
	}

	UpdateData();
}

public function BackButtonClicked(UIButton Button)
{
	Movie.Pres.PlayUISound(eSUISound_MenuSelect);

	NextButton.Show();

	if (0 > m_SoldierStartIndex - 3)
	{
		m_SoldierStartIndex = 0;
	}
	else
	{
		m_SoldierStartIndex -= 3;
	}

	if (m_SoldierStartIndex == 0)
	{
		PrevButton.Hide();
	}

	UpdateData();
}

public function InfoButtonClicked(UIButton Button)
{
	local int index;

	switch( Button )
	{
	case LadderSoldierInfoButtons[0]:
		index = 0;
		break;
	case LadderSoldierInfoButtons[1]:
		index = 1;
		break;
	case LadderSoldierInfoButtons[2]:
		index = 2;
		break;
	};
	DisplaySoldierInfo(index);
}

public function DisplaySoldierInfo(int index )
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local array<XComGameState_Unit> unitArray;
	local XComGameState PendingStartState;
	local int i;

	Movie.Pres.PlayUISound(eSUISound_MenuSelect);

	History = class'XComGameStateHistory'.static.GetGameStateHistory();
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	PendingStartState = `XCOMHISTORY.GetStartState( );
	XComHQ = XComGameState_HeadquartersXCom(PendingStartState.GetGameStateForObjectID(XComHQ.ObjectID));

	index += m_SoldierStartIndex;
	
	for (i = 0; i < CurrentStates.Length; i++)
	{
		if(CurrentStates[i] != none)
			unitArray.AddItem(CurrentStates[i]);
		else
		{
			if (i < index)
				index = index - 1;
		}
	}
	Movie.Pres.UITLEUnitStats(unitArray, index, PendingStartState);
}

simulated function CloseScreen()
{
	local XComGameState_LadderProgress LadderData;

	super.CloseScreen();

	m_kPhotoboothAutoGen.Destroy();

	`TACTICALRULES.bWaitingForMissionSummary = false;

	// clear out these references to the previous state, we don't need them and they may track back to the world about to be unloaded.
	LadderData = XComGameState_LadderProgress(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_LadderProgress'));
	LadderData.LastMissionState.Length = 0;
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	local bool bHandled;
	bHandled = true;

	if (!CheckInputIsReleaseOrDirectionRepeat(cmd, arg))
		return true;

	switch( cmd )
	{
	case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_RIGHT :
	case class'UIUtilities_Input'.const.FXS_ARROW_RIGHT :
	case class'UIUtilities_Input'.const.FXS_DPAD_RIGHT :
	case class'UIUtilities_Input'.const.FXS_KEY_D :
	case class'UIUtilities_Input'.const.FXS_BUTTON_RBUMPER :
		ContinueButtonClicked(none);
		break;

	case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_LEFT :
	case class'UIUtilities_Input'.const.FXS_ARROW_LEFT :
	case class'UIUtilities_Input'.const.FXS_DPAD_LEFT :
	case class'UIUtilities_Input'.const.FXS_KEY_A :
	case class'UIUtilities_Input'.const.FXS_BUTTON_LBUMPER :
		BackButtonClicked(none);
		break;

	case class'UIUtilities_Input'.const.FXS_BUTTON_A :
	case class'UIUtilities_Input'.const.FXS_KEY_ENTER :
	case class'UIUtilities_Input'.const.FXS_KEY_SPACEBAR :
		NextMissionButtonClicked();
		break;


	case class'UIUtilities_Input'.const.FXS_BUTTON_Y :
		DisplaySoldierInfo(0);
		break; 

	default:
		bHandled = false;
		break;
	}
	return bHandled;
}

simulated function UpdateNavHelp()
{
	NavHelp.ClearButtonHelp();
	NavHelp.AddContinueButton(NextMissionButtonClicked);

	if( `ISCONTROLLERACTIVE )
	{
		NavHelp.AddLeftStackHelp(m_strHelpSoldierInfo, class'UIUtilities_Input'.const.ICON_Y_TRIANGLE);

		if( m_SoldierStartIndex > 0 )
		{
			NavHelp.AddLeftStackHelp(m_strHelpPrevPage, class'UIUtilities_Input'.const.ICON_LB_L1);
		}

		if( m_NumSoldiers > m_SoldierStartIndex + 3 )
		{
			NavHelp.AddLeftStackHelp(m_strHelpNextPage, class'UIUtilities_Input'.const.ICON_RB_R1);
		}
	}

	NavHelp.Show();
}

simulated function UINavigationHelp GetNavHelp()
{
	local UINavigationHelp Result;
	Result = PC.Pres.GetNavHelp();
	if( Result == None )
	{
		if( `PRES != none ) // Tactical
		{
			Result = Spawn(class'UINavigationHelp', self).InitNavHelp();
			Result.SetX(-300); //offset to match the screen. 
			Result.SetY(-100); //offset to match the screen.
		}
		else if( `HQPRES != none ) // Strategy
			Result = `HQPRES.m_kAvengerHUD.NavHelp;
	}
	return Result;
}


defaultproperties
{
	Package = "/ package/gfxTLE_LadderLevelUp/TLE_LadderLevelUp";
	LibID = "SoldierScreen";
	InputState = eInputState_Consume;

	bHideOnLoseFocus = true;
}
