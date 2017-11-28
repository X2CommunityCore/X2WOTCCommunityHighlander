class UIAbilityInfoScreen extends UIScreen 
	dependson(UIQueryInterfaceUnit);

var XComGameState_Unit GameStateUnit;

var UIList ListAbilities;
var UIScrollbar Scrollbar;
var UINavigationHelp		m_NavHelp;

var localized array<String> StatLabelStrings;
var localized String HeaderAbilities;
var bool bIsChallengeModeScreen;

simulated function UIAbilityInfoScreen InitAbilityInfoScreen(XComPlayerController InitController, UIMovie InitMovie, 
	optional name InitName)
{
	InitScreen(InitController, InitMovie, InitName);

	return Self;
}

simulated function OnInit()
{
	local int i;
	local array<UIScrollingHTMLText> StatLabels;
	local UIButton closeButton; //bsg-jneal (5.9.17): hide the close button for now, not used at the moment but might be later

	super.OnInit();

	//bsg-jneal (5.9.17): hide the close button for now, not used at the moment but might be later
	closeButton = Spawn(class'UIButton', self);
	closeButton.InitButton('mc_closeBtn', "", , eUIButtonStyle_HOTLINK_BUTTON);
	closeButton.Hide();
	//bsg-jneal (5.9.17): end

	ListAbilities = Spawn(class'UIList', self, 'mc_perks');
	ListAbilities.InitList('mc_perks',,, 755, 418);

	for (i = 0; i < 7; i++)
	{
		StatLabels.AddItem(Spawn(class'UIScrollingHTMLText', Self));
		if (StatLabels[i] != None)
		{
			StatLabels[i].InitScrollingText(Name("mc_statLabel0" $ i));
			StatLabels[i].SetCenteredText(i < StatLabelStrings.Length ? StatLabelStrings[i] : "");
		}
	}

	m_NavHelp = PC.Pres.GetNavHelp();
	UpdateNavHelp();
		
	PopulateCharacterData();

	SimulateMouseHovers(true);
}

simulated function UpdateNavHelp()
{
	m_NavHelp.ClearButtonHelp();
	m_NavHelp.AddBackButton(BackButtonCallback);
}

simulated function BackButtonCallback()
{
	CloseScreen();
}

simulated function SetGameStateUnit(XComGameState_Unit InGameStateUnit)
{
	GameStateUnit = InGameStateUnit;
}

simulated function PopulateCharacterData()
{
	local XGUnit kActiveUnit;
	local XComGameState_Unit kGameStateUnit;
	local UIScrollingHTMLText NameHeader;
	local UIScrollingText ClassNameLabel;
	local UIIcon ClassIcon;
	local X2SoldierClassTemplate SoldierClassTemplate;
	local X2MPCharacterTemplate UnitMPTemplate;

	if (PC != none && XComTacticalController(PC) != none)
	{
		kActiveUnit = XComTacticalController(PC).GetActiveUnit();

		if (kActiveUnit == none)
		{
			return;	
		}

		kGameStateUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(kActiveUnit.ObjectID));
	}
	else if (GameStateUnit != none)
	{
		kGameStateUnit = GameStateUnit;
	}

	if (kGameStateUnit == none)
	{
		return;
	}

	NameHeader = Spawn(class'UIScrollingHTMLText', Self);
	NameHeader.InitScrollingText('mc_nameLabel',"initializing...",,,,true);

	SoldierClassTemplate = kGameStateUnit.GetSoldierClassTemplate();
	if(SoldierClassTemplate != None)
	{
		//Show full name/rank
		NameHeader.SetTitle(kGameStateUnit.GetName(eNameType_FullNick));

		//Initialize Soldier-Class Name
		ClassNameLabel = Spawn(class'UIScrollingText', Self);
		ClassNameLabel.InitScrollingText('mc_classLabel');
		// Start Issue #106
		ClassNameLabel.SetHTMLText(kGameStateUnit.GetSoldierClassDisplayName());
		// End Issue #106
		//Initialize the Class Icon
		ClassIcon = Spawn(class'UIIcon', Self);
		ClassIcon.InitIcon('mc_classIcon',,,false,42,eUIState_Normal);
		// Start Issue #106
		ClassIcon.LoadIcon(kGameStateUnit.GetSoldierClassIcon());
		// End Issue #106
	}
	else
	{
		if (bIsChallengeModeScreen)
		{
			UnitMPTemplate = class'X2MPCharacterTemplateManager'.static.GetMPCharacterTemplateManager().FindMPCharacterTemplateByCharacterName(kGameStateUnit.GetMyTemplateName());
			kGameStateUnit.SetMPCharacterTemplate(UnitMPTemplate.DataName);

			//Don't ask for rank - Necessary to handle VIPs; asking for their rank shows them as "rookie"
			NameHeader.SetTitle(Caps(kGameStateUnit.GetMPCharacterTemplate().DisplayName));
			
			ClassNameLabel = Spawn(class'UIScrollingText', Self);
			ClassNameLabel.InitScrollingText('mc_classLabel');
			ClassNameLabel.SetHTMLText(kGameStateUnit.IsAdvent() ? class'UIMPSquadSelect_ListItem'.default.m_strAdvent : class'UIMPSquadSelect_ListItem'.default.m_strAlien);

			//Use the Class Icon to show ADVENT/Alien symbol instead
			ClassIcon = Spawn(class'UIIcon', Self);
			ClassIcon.InitIcon('mc_classIcon', , , false, 42, eUIState_Normal);
			ClassIcon.LoadIcon(kGameStateUnit.GetMPCharacterTemplate().IconImage);
		}
		else
		{
			//Don't ask for rank - Necessary to handle VIPs; asking for their rank shows them as "rookie"
			NameHeader.SetTitle(kGameStateUnit.GetName(eNameType_Full));

			//In place of the soldier-class name, show their character class (if different from their name)
			if (kGameStateUnit.GetName(eNameType_Full) != kGameStateUnit.GetMyTemplate().strCharacterName)
			{
				ClassNameLabel = Spawn(class'UIScrollingText', Self);
				ClassNameLabel.InitScrollingText('mc_classLabel');
				ClassNameLabel.SetHTMLText(kGameStateUnit.GetMyTemplate().strCharacterName);
			}

			//Use the Class Icon to show ADVENT/Alien symbol instead
			ClassIcon = Spawn(class'UIIcon', Self);
			ClassIcon.InitIcon('mc_classIcon', , , false, 42, eUIState_Normal);
			ClassIcon.LoadIcon(kGameStateUnit.GetMPCharacterTemplate().IconImage);
			//ClassIcon.SetForegroundColorState(eUIState_Normal);
		}
	}

	PopulateStatValues(kGameStateUnit);
	PopulateCharacterAbilities(kGameStateUnit);

	Navigator.Clear(); //Default Navigation can cause focus issues on this screen if left on (use OnUnrealCommand unless list selection becomes necessary) - JTA 2016/5/20
}

simulated function PopulateStatValues(XComGameState_Unit kGameStateUnit)
{
	local int i, StatValueInt;
	local UIScrollingHTMLText StatLabel;
	local String StatLabelString;
	local EUISummary_UnitStats UnitStats;
	local int TempVal;

	UnitStats = kGameStateUnit.GetUISummary_UnitStats();

	// Screen is only shown when chars are at max stats, so max can be treated as current and armor/ability stats need to be applied
	for (i = 0; i < 7; ++i)
	{
		StatValueInt = -1;
		switch(i)
		{
		case 0:
			TempVal = UnitStats.MaxHP + kGameStateUnit.GetUIStatFromInventory(eStat_HP) + kGameStateUnit.GetUIStatFromAbilities(eStat_HP);
			StatLabelString = TempVal $ "/" $ TempVal;
			break;

		case 1:
			TempVal = UnitStats.Aim + kGameStateUnit.GetUIStatFromInventory(eStat_Offense) + kGameStateUnit.GetUIStatFromAbilities(eStat_Offense);
			StatValueInt = TempVal;
			break;

		case 2:
			TempVal = UnitStats.Tech + kGameStateUnit.GetUIStatFromInventory(eStat_Hacking) + kGameStateUnit.GetUIStatFromAbilities(eStat_Hacking);
			StatValueInt = TempVal;
			break;

		case 3:
			TempVal = UnitStats.MaxWill + kGameStateUnit.GetUIStatFromInventory(eStat_Will) + kGameStateUnit.GetUIStatFromAbilities(eStat_Will);
			StatLabelString = TempVal $ "/" $ TempVal;
			break;

		case 4:
			TempVal = UnitStats.Armor + kGameStateUnit.GetUIStatFromInventory(eStat_ArmorMitigation) + kGameStateUnit.GetUIStatFromAbilities(eStat_ArmorMitigation);
			StatValueInt = TempVal;
			break;

		case 5:
			TempVal = UnitStats.Dodge + kGameStateUnit.GetUIStatFromInventory(eStat_Dodge) + kGameStateUnit.GetUIStatFromAbilities(eStat_Dodge);
			StatValueInt = TempVal;
			break;

		case 6:
			TempVal = UnitStats.PsiOffense + kGameStateUnit.GetUIStatFromInventory(eStat_PsiOffense) + kGameStateUnit.GetUIStatFromAbilities(eStat_PsiOffense);
			StatValueInt = TempVal;
			break;

		default:
			StatLabelString = "";
			break;
		}
		
		if (StatValueInt >= 0)
		{
			StatLabelString = StatValueInt > 0 ? String(StatValueInt) : "---";
		}

		StatLabel = None;
		StatLabel = Spawn(class'UIScrollingHTMLText', Self);
		if (StatLabel != None)
		{
			StatLabel.InitScrollingText(Name('mc_statValue0' $ i));
			StatLabel.SetCenteredText(StatLabelString);
		}		
	}
}

simulated function PopulateCharacterAbilities(XComGameState_Unit kGameStateUnit)
{	
	AddAbilitiesToList(kGameStateUnit, HeaderAbilities);
}

simulated function array<X2AbilityTemplate> GetAbilityTemplates(XComGameState_Unit Unit, 
	optional XComGameState CheckGameState)
{
	local int i;
	local X2AbilityTemplate AbilityTemplate;
	local array<AbilitySetupData> AbilitySetupList;
	local array<SoldierClassAbilityType> AbilityTree;
	local X2AbilityTemplateManager AbilityTemplateManager;
	local array<X2AbilityTemplate> AbilityTemplates;
	local X2CharacterTemplate CharacterTemplate;
	local name AbilityName;

	if( Unit.IsSoldier() )
	{
		AbilityTree = Unit.GetEarnedSoldierAbilities();
		AbilityTemplateManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();

		for( i = 0; i < AbilityTree.Length; ++i )
		{
			AbilityTemplate = AbilityTemplateManager.FindAbilityTemplate(AbilityTree[i].AbilityName);
			if(AbilityTemplate != none && !AbilityTemplate.bDontDisplayInAbilitySummary )
			{
				AbilityTemplates.AddItem(AbilityTemplate);
			}
		}

		CharacterTemplate = Unit.GetMyTemplate();

		foreach CharacterTemplate.Abilities(AbilityName)
		{
			AbilityTemplate = AbilityTemplateManager.FindAbilityTemplate(AbilityName);
			if( AbilityTemplate != none &&
			   !AbilityTemplate.bDontDisplayInAbilitySummary &&
			   AbilityTemplate.ConditionsEverValidForUnit(Unit, true) )
			{
				AbilityTemplates.AddItem(AbilityTemplate);
			}
		}
	}
	else
	{
		AbilitySetupList = Unit.GatherUnitAbilitiesForInit(CheckGameState,, true);

		for (i = 0; i < AbilitySetupList.Length; ++i)
		{
			AbilityTemplate = AbilitySetupList[i].Template;
			if (!AbilityTemplate.bDontDisplayInAbilitySummary)
			{
				AbilityTemplates.AddItem(AbilityTemplate);
			}
		}
	}

	return AbilityTemplates;
}

simulated function AddAbilitiesToList(XComGameState_Unit kGameStateUnit, String Header_Text, 
	optional EUIState UIState = eUIState_Normal)
{
	local array<X2AbilityTemplate> Abilities;
	local UIText HeaderListItem;
	local UIListItemAbility ListItem;
	local int i;

	Abilities = GetAbilityTemplates(kGameStateUnit, XComGameState(kGameStateUnit.Outer));
	if (Abilities.Length > 0)
	{
		HeaderListItem = Spawn(class'UIText', ListAbilities.ItemContainer);
		HeaderListItem.LibID = 'mc_columnHeader';		
		HeaderListItem.InitText(,Header_Text);
		HeaderListItem.SetColor(class'UIUtilities_Colors'.static.GetHexColorFromState(UIState));
		HeaderListItem.SetHeight(40);

		for (i = 0; i < Abilities.Length; i++)
		{
			ListItem = Spawn(class'UIListItemAbility', ListAbilities.ItemContainer);
			ListItem.InitListItemPerk(Abilities[i], eUIState_Normal);
			ListItem.SetX(class'UIListItemAbility'.default.Padding);
		}
	}
}

simulated function HandleScrollBarInput(bool bDown)
{
	if (ListAbilities != none && ListAbilities.Scrollbar != none)
	{
		if (bDown)	
		{
			ListAbilities.Scrollbar.OnMouseScrollEvent(-1);
		}
		else			
		{
			ListAbilities.Scrollbar.OnMouseScrollEvent(1);
		}
		PlaySound(SoundCue'SoundUI.MenuScrollCue', true);
	}
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	switch (cmd)
	{
	case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_UP:
	case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_DOWN:
		HandleScrollBarInput(cmd == class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_DOWN);
		return true;

	case class'UIUtilities_Input'.const.FXS_BUTTON_B:
	case class'UIUtilities_Input'.const.FXS_KEY_ESCAPE:
	case class'UIUtilities_Input'.const.FXS_R_MOUSE_DOWN:
		if (CheckInputIsReleaseOrDirectionRepeat(cmd, arg))
		{
			CloseScreen();
		}

		return true;
	}

	return super.OnUnrealCommand(cmd, arg);
}

simulated function bool SimulateMouseHovers(bool bIsHovering)
{
	local UITooltipMgr Mgr;
	local String WeaponMCPath;
	local int MouseCommand;
	local UITacticalHUD TacticalHUD;

	if (bIsHovering)
	{
		MouseCommand = class'UIUtilities_Input'.const.FXS_L_MOUSE_IN;
	}
	else
	{
		MouseCommand = class'UIUtilities_Input'.const.FXS_L_MOUSE_OUT;	
	}

	Mgr = Movie.Pres.m_kTooltipMgr;

	TacticalHUD = UITacticalHUD(Movie.Pres.ScreenStack.GetScreen(class'UITacticalHUD'));
	if (TacticalHUD != None)
	{
		if (TacticalHUD.m_kInventory != None)
		{	
			WeaponMCPath = String(TacticalHUD.m_kInventory.m_kWeapon.MCPath);
			Mgr.OnMouse(WeaponMCPath, MouseCommand, WeaponMCPath);
		}
	}

	return true;
}

simulated function CloseScreen()
{
	SimulateMouseHovers(false);

	super.CloseScreen();	
}

defaultproperties
{
	Package = "/ package/gfxTacticalCharInfo/TacticalCharInfo";
	MCName = "mc_tacticalCharInfo";
	InputState = eInputState_Consume;
	bIsNavigable = true;
	bIsChallengeModeScreen = false;
}