//---------------------------------------------------------------------------------------------
//  FILE:    UITacticalCharInfoScreen.uc
//  AUTHOR:  Jake Akemann - 2015/11/03
//  PURPOSE: Menu for console release to display all of the Character Info on the Tactical Map
//---------------------------------------------------------------------------------------------

class UITacticalCharInfoScreen extends UIScreen;

//----------------------------------------------------------------------------
// REFERENCES TO MEMBERS SET IN FLA
var UIList ListPerks;
var UIScrollbar Scrollbar;

//----------------------------------------------------------------------------
// LOCALIZATION
var localized array<String> StatLabelStrings;
var localized String Header_Passives;
var localized String Header_Bonuses;
var localized String Header_Penalties;

//----------------------------------------------------------------------------
// FUNCTIONS

simulated function UITacticalCharInfoScreen InitCharacterInfoScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	InitScreen(InitController,InitMovie,InitName);

	return Self;
}

simulated function OnInit()
{
	local int i;
	local UIButton NavHint;
	local array<UIScrollingHTMLText> StatLabels;

	super.OnInit();

	//Initialize the Container of Perks/Bonuses/Penalties
	ListPerks = Spawn(class'UIList',self, 'mc_perks');
	ListPerks.InitList('mc_perks',,,755,418);

	//Initialize the labels for the Stats
	for( i = 0; i < 7; i++ )
	{
		StatLabels.AddItem(Spawn(class'UIScrollingHTMLText',Self));
		if(StatLabels[i] != None)
		{
			StatLabels[i].InitScrollingText(Name("mc_statLabel0" $ i));
			StatLabels[i].SetCenteredText(i < StatLabelStrings.Length ? StatLabelStrings[i] : "");
		}
	}

	//Initialize the Button Nav Hint
	NavHint = Spawn(class'UIButton', Self);
	NavHint.InitButton('mc_closeBtn', class'UIUtilities_Text'.default.m_strGenericBack,,eUIButtonStyle_HOTLINK_WHEN_SANS_MOUSE);
	NavHint.SetGamepadIcon(class'UIUtilities_Input'.static.GetBackButtonIcon());
		
	//Initialize all of the data that pertains to the specific character
	PopulateCharacterData();

	//Triggers the external tooltips that display extra info
	//SimulateMouseHovers(true);
}

//sets any data that pertains specifically to the active character
simulated function PopulateCharacterData()
{
	local XGUnit kActiveUnit;
	local XComGameState_Unit kGameStateUnit;
	local UIScrollingHTMLText NameHeader;
	local UIScrollingText ClassNameLabel;
	local UIIcon ClassIcon;
	local X2SoldierClassTemplate SoldierClassTemplate;
	local X2MPCharacterTemplate UnitMPTemplate;
	local String NameString, Nickname, RankAbbrev, ClassIconString;
	local X2SoldierClassTemplateManager SoldierTemplateManager;

	kActiveUnit = XComTacticalController(PC).GetActiveUnit();

	if( kActiveUnit == none )
		return;	

	//used to determine almost all character data
	kGameStateUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(kActiveUnit.ObjectID));

	//Initialize Character Name Label
	NameHeader = Spawn(class'UIScrollingHTMLText', Self);
	NameHeader.InitScrollingText('mc_nameLabel',"initializing...",,,,true);	
	ClassIcon = Spawn(class'UIIcon', Self);
	ClassIcon.InitIcon('mc_classIcon', , , false, 42, eUIState_Normal);

	if( kGameStateUnit.GetMyTemplateName() == 'AdvPsiWitchM2' )
	{
		NameString = kGameStateUnit.GetName(eNameType_Full);

		SoldierTemplateManager = class'X2SoldierClassTemplateManager'.static.GetSoldierClassTemplateManager();
		ClassIconString = SoldierTemplateManager.FindSoldierClassTemplate('PsiOperative').IconImage;
	}
	else
	{
		//compile the displayed character name
		Nickname = kGameStateUnit.GetNickName(); //will not be used if returned empty
		RankAbbrev = `GET_RANK_ABBRV(kGameStateUnit.GetSoldierRank(), kGameStateUnit.GetSoldierClassTemplateName());
		NameString = kGameStateUnit.SafeGetCharacterFirstName() @ (Nickname != "\"\"" ? Nickname : "") @ kGameStateUnit.SafeGetCharacterLastName();

		SoldierClassTemplate = kGameStateUnit.GetSoldierClassTemplate();
		if( SoldierClassTemplate != None )
		{
			NameString = RankAbbrev @ NameString;
			//Initialize Class Name
			ClassNameLabel = Spawn(class'UIScrollingText', Self);
			ClassNameLabel.InitScrollingText('mc_classLabel');
			ClassNameLabel.SetHTMLText(SoldierClassTemplate.DisplayName);

			//Initialize the Class Icon
			ClassIconString = SoldierClassTemplate.IconImage;
		}
		else if(!kGameStateUnit.GetMyTemplate().bIsCivilian)
		{
			NameString = kGameStateUnit.GetMyTemplate().strCharacterName;
			
			UnitMPTemplate = class'X2MPCharacterTemplateManager'.static.GetMPCharacterTemplateManager().FindMPCharacterTemplateByCharacterName(kGameStateUnit.GetMyTemplateName());
			ClassIconString = UnitMPTemplate.IconImage;	
		}
	}

	ClassIcon.LoadIcon(ClassIconString);
	NameHeader.SetTitle(NameString);

	//Initialize Stat Values
	PopulateStatValues(kGameStateUnit);

	//Populate all character Effects (Perks/Bonuses/Penalities)
	PopulateCharacterEffects(kGameStateUnit, kActiveUnit);
}

simulated function PopulateStatValues(XComGameState_Unit kGameStateUnit)
{
	local int i, StatValueInt;
	local UIScrollingHTMLText StatLabel;
	local String StatLabelString;
	local EUISummary_UnitStats UnitStats;

	UnitStats = kGameStateUnit.GetUISummary_UnitStats();

	for( i = 0; i < 7; ++i )
	{
		StatValueInt = -1;
		switch(i)
		{
		case 0: //Health
			StatLabelString = UnitStats.CurrentHP $ "/" $ UnitStats.MaxHP;
			break;
		case 1: //AIM
			StatValueInt = UnitStats.Aim;
			break;
		case 2: //Hack
			StatValueInt = UnitStats.Tech;
			break;
		case 3: //Will
			StatLabelString = UnitStats.CurrentWill $ "/" $ UnitStats.MaxWill;
			break;
		case 4: //Armor
			StatValueInt = UnitStats.Armor;
			break;
		case 5: //Dodge
			StatValueInt = UnitStats.Dodge;
			break;
		case 6: //Psi Strength
			StatValueInt = UnitStats.PsiOffense;
			break;
		default:
			StatLabelString = "";
			break;
		}
		
		if(StatValueInt >= 0) //checks to see if the String was directly set above (Health)
		{
			StatLabelString = StatValueInt > 0 ? String(StatValueInt) : "---"; //does not display a "0"
		}

		StatLabel = None;
		StatLabel = Spawn(class'UIScrollingHTMLText', Self);
		if(StatLabel != None)
		{
			StatLabel.InitScrollingText(Name('mc_statValue0' $ i));
			StatLabel.SetCenteredText(StatLabelString);
		}		
	}
}

simulated function PopulateCharacterEffects(XComGameState_Unit kGameStateUnit, XGUnit kActiveUnit)
{	
	AddEffectsToList(ePerkBuff_Penalty,	kGameStateUnit, kActiveUnit, Header_Penalties,	eUIState_Bad);
	AddEffectsToList(ePerkBuff_Bonus,	kGameStateUnit, kActiveUnit, Header_Bonuses,	eUIState_Good);
	AddEffectsToList(ePerkBuff_Passive,	kGameStateUnit, kActiveUnit, Header_Passives);
}

simulated function AddEffectsToList(EPerkBuffCategory PassiveType, XComGameState_Unit kGameStateUnit, XGUnit kActiveUnit, String Header_Text, optional EUIState UIState = eUIState_Normal)
{
	local array<UISummary_UnitEffect> Effects;
	local UIText HeaderListItem;
	local UIListItemPerk ListItem;
	local int i;

	Effects = kGameStateUnit.GetUISummary_UnitEffectsByCategory(PassiveType);
	if(Effects.Length > 0)
	{
		//Adds header as a list item (there are multiple headers in the list that need to scroll fluidly)
		HeaderListItem = Spawn(class'UIText', ListPerks.ItemContainer);
		HeaderListItem.LibID = 'mc_columnHeader';		
		HeaderListItem.InitText(,Header_Text);
		HeaderListItem.SetColor(class'UIUtilities_Colors'.static.GetHexColorFromState(UIState));
		HeaderListItem.SetHeight(40);

		//Adds Effects/Perks/Bonuses/Penalties as list items beneath the header
		for(i = 0; i < Effects.Length; i++)
		{
			ListItem = Spawn(class'UIListItemPerk', ListPerks.ItemContainer);
			ListItem.InitListItemPerk(Effects[i], UIState);
			ListItem.SetX(class'UIListItemPerk'.default.Padding);
		}
	}
}

//----------------------------------------------------------------------------
// SCROLLING

simulated function HandleScrollBarInput(bool bDown)
{
	if ( ListPerks != None && ListPerks.Scrollbar != None )
	{
		if ( bDown )	ListPerks.Scrollbar.OnMouseScrollEvent(-1);
		else			ListPerks.Scrollbar.OnMouseScrollEvent(1);
	}
}

//----------------------------------------------------------------------------
// EVENT HANDLING

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	local bool bHandled;

	if ( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg)) //bsg-crobinson (5.10.17): Prevent multiple presses
		return true;

	switch( cmd )
	{
	case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_UP:
	case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_DOWN:
		HandleScrollBarInput(cmd == class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_DOWN);
		break;

	case class'UIUtilities_Input'.const.FXS_BUTTON_B:
	case class'UIUtilities_Input'.const.FXS_KEY_ESCAPE:
		CloseScreen();
		break;

	case class'UIUtilities_Input'.const.FXS_BUTTON_START:
		Movie.Pres.UIPauseMenu(); //bsg-crobinson (5.10.17): Bring up pause menu
		break;

	default:
		break;
	}

	bHandled = true;

	return bHandled;
}

//Opening this screen can trigger multiple mouse-tooltips to be shown
//This function simulates mouse-hovers by giving the tooltip manager 'OnMouse' commands
simulated function bool SimulateMouseHovers(bool bIsHovering)
{
	local UITooltipMgr Mgr;
	local String WeaponMCPath;
	local int MouseCommand;
	local UITacticalHUD TacticalHUD;

	if(bIsHovering)
		MouseCommand = class'UIUtilities_Input'.const.FXS_L_MOUSE_IN;
	else
		MouseCommand = class'UIUtilities_Input'.const.FXS_L_MOUSE_OUT;	

	Mgr = Movie.Pres.m_kTooltipMgr;

	TacticalHUD = UITacticalHUD(Movie.Pres.ScreenStack.GetScreen(class'UITacticalHUD'));
	if(TacticalHUD != None)
	{
		if(TacticalHUD.m_kInventory != None)
		{	
			//Tooltips that show weapon type, ammo, weapon-upgrades
			WeaponMCPath = String(TacticalHUD.m_kInventory.m_kWeapon.MCPath);
			Mgr.OnMouse(WeaponMCPath, MouseCommand, WeaponMCPath);
		}
	}

	return true;
}

simulated function CloseScreen()
{
	local UITacticalHUD TacticalHUD;
	//closes any tooltips that have been opened on this screen
	SimulateMouseHovers(false);
	TacticalHUD = UITacticalHUD(Movie.Pres.ScreenStack.GetScreen(class'UITacticalHUD'));
	TacticalHUD.Show();

	Super.CloseScreen();	
}

defaultproperties
{
	Package = "/ package/gfxTacticalCharInfo/TacticalCharInfo";
	MCName = "mc_tacticalCharInfo";
	InputState = eInputState_Consume;
	bIsNavigable = true;
}