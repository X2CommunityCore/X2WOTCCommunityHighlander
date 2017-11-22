//---------------------------------------------------------------------------------------
//  FILE:    UIArmory_PromotionHero.uc
//  AUTHOR:  Joe Weinhoffer
//   
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class UIArmory_PromotionHero extends UIArmory_Promotion;

const NUM_ABILITIES_PER_COLUMN = 4;

enum UIPromotionButtonState
{
	eUIPromotionState_Locked,
	eUIPromotionState_Normal,
	eUIPromotionState_Equipped
};

var array<UIArmory_PromotionHeroColumn> Columns;

var localized string m_strSharedAPLabel;
var localized string m_strSoldierAPLabel;
var localized string m_strBranchesLabel;
var localized string m_strNewRank;
var localized string m_strCostLabel;
var localized string m_strAPLabel;
var localized string m_strSharedAPWarning;
var localized string m_strSharedAPWarningSingular;
var localized string m_strPrereqAbility;

var int m_iCurrentlySelectedColumn;  // bsg-nlong (1.25.17): Used to track which column has focus

simulated function InitPromotion(StateObjectReference UnitRef, optional bool bInstantTransition)
{
	local UIArmory_PromotionHeroColumn Column;
	local XComGameState_Unit Unit; // bsg-nlong (1.25.17): Used to determine which column we should start highlighting

	// If the AfterAction screen is running, let it position the camera
	AfterActionScreen = UIAfterAction(Movie.Stack.GetScreen(class'UIAfterAction'));
	if (AfterActionScreen != none)
	{
		bAfterActionPromotion = true;
		PawnLocationTag = AfterActionScreen.GetPawnLocationTag(UnitRef, "Blueprint_AfterAction_HeroPromote");
		CameraTag = AfterActionScreen.GetPromotionBlueprintTag(UnitRef);
		DisplayTag = name(AfterActionScreen.GetPromotionBlueprintTag(UnitRef));
	}
	else
	{
		CameraTag = string(default.DisplayTag);
		DisplayTag = default.DisplayTag;
	}

	// Don't show nav help during tutorial, or during the After Action sequence.
	bUseNavHelp = class'XComGameState_HeadquartersXCom'.static.IsObjectiveCompleted('T0_M2_WelcomeToArmory') || Movie.Pres.ScreenStack.IsInStack(class'UIAfterAction');

	super.InitArmory(UnitRef, , , , , , bInstantTransition);
	
	Column = Spawn(class'UIArmory_PromotionHeroColumn', self);
	Column.MCName = 'rankColumn0';
	Column.InitPromotionHeroColumn(0);
	Columns.AddItem(Column);

	Column = Spawn(class'UIArmory_PromotionHeroColumn', self);
	Column.MCName = 'rankColumn1';
	Column.InitPromotionHeroColumn(1);
	Columns.AddItem(Column);

	Column = Spawn(class'UIArmory_PromotionHeroColumn', self);
	Column.MCName = 'rankColumn2';
	Column.InitPromotionHeroColumn(2);
	Columns.AddItem(Column);

	Column = Spawn(class'UIArmory_PromotionHeroColumn', self);
	Column.MCName = 'rankColumn3';
	Column.InitPromotionHeroColumn(3);
	Columns.AddItem(Column);

	Column = Spawn(class'UIArmory_PromotionHeroColumn', self);
	Column.MCName = 'rankColumn4';
	Column.InitPromotionHeroColumn(4);
	Columns.AddItem(Column);

	Column = Spawn(class'UIArmory_PromotionHeroColumn', self);
	Column.MCName = 'rankColumn5';
	Column.InitPromotionHeroColumn(5);
	Columns.AddItem(Column);

	Column = Spawn(class'UIArmory_PromotionHeroColumn', self);
	Column.MCName = 'rankColumn6';
	Column.InitPromotionHeroColumn(6);
	Columns.AddItem(Column);

	PopulateData();

	DisableNavigation(); // bsg-nlong (1.25.17): This and the column panel will have to use manual naviation, so we'll disable the navigation here

	MC.FunctionVoid("AnimateIn");

	// bsg-nlong (1.25.17): Focus a column so the screen loads with an ability highlighted
	if( `ISCONTROLLERACTIVE )
	{
		Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitReference.ObjectID));
		if( Unit != none )
		{
			m_iCurrentlySelectedColumn = m_iCurrentlySelectedColumn;
		}
		else
		{
			m_iCurrentlySelectedColumn = 0;
		}

		Columns[m_iCurrentlySelectedColumn].OnReceiveFocus();
	}
	// bsg-nlong (1.25.17): end
}

simulated function PopulateData()
{
	local XComGameState_Unit Unit;
	local X2SoldierClassTemplate ClassTemplate;
	local UIArmory_PromotionHeroColumn Column;
	local string HeaderString, rankIcon, classIcon;
	local int iRank, maxRank;
	local bool bHasColumnAbility, bHighlightColumn;
	local Vector ZeroVec;
	local Rotator UseRot;
	local XComUnitPawn UnitPawn;
	local XComGameState_ResistanceFaction FactionState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState NewGameState;
	
	Unit = GetUnit();
	ClassTemplate = Unit.GetSoldierClassTemplate();

	FactionState = Unit.GetResistanceFaction();
	
	rankIcon = class'UIUtilities_Image'.static.GetRankIcon(Unit.GetRank(), ClassTemplate.DataName);
	classIcon = ClassTemplate.IconImage;

	HeaderString = m_strAbilityHeader;
	if (Unit.GetRank() != 1 && Unit.HasAvailablePerksToAssign())
	{
		HeaderString = m_strSelectAbility;
	}

	XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	if (Unit.IsResistanceHero() && !XComHQ.bHasSeenHeroPromotionScreen)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Trigger Opened Hero Promotion Screen");
		XComHQ = XComGameState_HeadquartersXCom(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
		XComHQ.bHasSeenHeroPromotionScreen = true;
		`XEVENTMGR.TriggerEvent('OnHeroPromotionScreen', , , NewGameState);
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
	else if (Unit.GetRank() >= 2 && Unit.ComInt >= eComInt_Gifted)
	{
		// Check to see if Unit has high combat intelligence, display tutorial popup if so
		`HQPRES.UICombatIntelligenceIntro(Unit.GetReference());
	}

	if (ActorPawn == none || (Unit.GetRank() == 1 && bAfterActionPromotion)) //This condition is TRUE when in the after action report, and we need to rank someone up to squaddie
	{
		//Get the current pawn so we can extract its rotation
		UnitPawn = Movie.Pres.GetUIPawnMgr().RequestPawnByID(AfterActionScreen, UnitReference.ObjectID, ZeroVec, UseRot);
		UseRot = UnitPawn.Rotation;

		//Free the existing pawn, and then create the ranked up pawn. This may not be strictly necessary since most of the differences between the classes are in their equipment. However, it is easy to foresee
		//having class specific soldier content and this covers that possibility
		Movie.Pres.GetUIPawnMgr().ReleasePawn(AfterActionScreen, UnitReference.ObjectID);
		CreateSoldierPawn(UseRot);

		if (bAfterActionPromotion && !Unit.bCaptured)
		{
			//Let the pawn manager know that the after action report is referencing this pawn too			
			UnitPawn = Movie.Pres.GetUIPawnMgr().RequestPawnByID(AfterActionScreen, UnitReference.ObjectID, ZeroVec, UseRot);
			AfterActionScreen.SetPawn(UnitReference, UnitPawn);
		}
	}

	AS_SetRank(rankIcon);
	AS_SetClass(classIcon);
	AS_SetFaction(FactionState.GetFactionIcon());

	AS_SetHeaderData(Caps(FactionState.GetFactionTitle()), Caps(Unit.GetName(eNameType_FullNick)), HeaderString, m_strSharedAPLabel, m_strSoldierAPLabel);
	AS_SetAPData(GetSharedAbilityPoints(), Unit.AbilityPoints);
	AS_SetCombatIntelData(Unit.GetCombatIntelligenceLabel());
	AS_SetPathLabels(m_strBranchesLabel, ClassTemplate.AbilityTreeTitles[0], ClassTemplate.AbilityTreeTitles[1], ClassTemplate.AbilityTreeTitles[2], ClassTemplate.AbilityTreeTitles[3]);

	maxRank = class'X2ExperienceConfig'.static.GetMaxRank();

	for (iRank = 0; iRank < (maxRank - 1); ++iRank)
	{
		Column = Columns[iRank];
		bHasColumnAbility = UpdateAbilityIcons(Column);
		bHighlightColumn = (!bHasColumnAbility && (iRank+1) == Unit.GetRank());

		Column.AS_SetData(bHighlightColumn, m_strNewRank, class'UIUtilities_Image'.static.GetRankIcon(iRank+1, ClassTemplate.DataName), Caps(class'X2ExperienceConfig'.static.GetRankName(iRank+1, ClassTemplate.DataName)));
	}

	HidePreview();
}

function bool UpdateAbilityIcons(out UIArmory_PromotionHeroColumn Column)
{
	local X2AbilityTemplateManager AbilityTemplateManager;
	local X2AbilityTemplate AbilityTemplate, NextAbilityTemplate;
	local array<SoldierClassAbilityType> AbilityTree, NextRankTree;
	local XComGameState_Unit Unit;
	local UIPromotionButtonState ButtonState;
	local int iAbility;
	local bool bHasColumnAbility, bConnectToNextAbility;
	local string AbilityName, AbilityIcon, BGColor, FGColor;

	AbilityTemplateManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	Unit = GetUnit();
	AbilityTree = Unit.GetRankAbilities(Column.Rank);

	for (iAbility = 0; iAbility < NUM_ABILITIES_PER_COLUMN; iAbility++)
	{
		AbilityTemplate = AbilityTemplateManager.FindAbilityTemplate(AbilityTree[iAbility].AbilityName);
		if (AbilityTemplate != none)
		{
			if (Column.AbilityNames.Find(AbilityTemplate.DataName) == INDEX_NONE)
			{
				Column.AbilityNames.AddItem(AbilityTemplate.DataName);
			}

			// The unit is not yet at the rank needed for this column
			if (Column.Rank >= Unit.GetRank())
			{
				AbilityName = class'UIUtilities_Text'.static.GetColoredText(m_strAbilityLockedTitle, eUIState_Disabled);
				AbilityIcon = class'UIUtilities_Image'.const.UnknownAbilityIcon;
				ButtonState = eUIPromotionState_Locked;
				FGColor = class'UIUtilities_Colors'.const.BLACK_HTML_COLOR;
				BGColor = class'UIUtilities_Colors'.const.DISABLED_HTML_COLOR;
				bConnectToNextAbility = false; // Do not display prereqs for abilities which aren't available yet
			}
			else // The ability could be purchased
			{
				AbilityName = class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS(AbilityTemplate.LocFriendlyName);
				AbilityIcon = AbilityTemplate.IconImage;

				if (Unit.HasSoldierAbility(AbilityTemplate.DataName))
				{
					// The ability has been purchased
					ButtonState = eUIPromotionState_Equipped;
					FGColor = class'UIUtilities_Colors'.const.NORMAL_HTML_COLOR;
					BGColor = class'UIUtilities_Colors'.const.BLACK_HTML_COLOR;
					bHasColumnAbility = true;
				}
				else if(CanPurchaseAbility(Column.Rank, iAbility, AbilityTemplate.DataName))
				{
					// The ability is unlocked and unpurchased, and can be afforded
					ButtonState = eUIPromotionState_Normal;
					FGColor = class'UIUtilities_Colors'.const.PERK_HTML_COLOR;
					BGColor = class'UIUtilities_Colors'.const.BLACK_HTML_COLOR;
				}
				else
				{
					// The ability is unlocked and unpurchased, but cannot be afforded
					ButtonState = eUIPromotionState_Normal;
					FGColor = class'UIUtilities_Colors'.const.BLACK_HTML_COLOR;
					BGColor = class'UIUtilities_Colors'.const.DISABLED_HTML_COLOR;
				}
				
				// Look ahead to the next rank and check to see if the current ability is a prereq for the next one
				// If so, turn on the connection arrow between them
				if (Column.Rank < (class'X2ExperienceConfig'.static.GetMaxRank() - 2) && Unit.GetRank() > (Column.Rank + 1))
				{
					bConnectToNextAbility = false;
					NextRankTree = Unit.GetRankAbilities(Column.Rank + 1);
					NextAbilityTemplate = AbilityTemplateManager.FindAbilityTemplate(NextRankTree[iAbility].AbilityName);
					if (NextAbilityTemplate.PrerequisiteAbilities.Length > 0 && NextAbilityTemplate.PrerequisiteAbilities.Find(AbilityTemplate.DataName) != INDEX_NONE)
					{
						bConnectToNextAbility = true;
					}
				}

				Column.SetAvailable(true);
			}

			Column.AS_SetIconState(iAbility, false, AbilityIcon, AbilityName, ButtonState, FGColor, BGColor, bConnectToNextAbility);
		}
		else
		{
			Column.AbilityNames.AddItem(''); // Make sure we add empty spots to the name array for getting ability info
		}
	}

	// bsg-nlong (1.25.17): Select the first available/visible ability in the column
	while(`ISCONTROLLERACTIVE && !Column.AbilityIcons[Column.m_iPanelIndex].bIsVisible)
	{
		Column.m_iPanelIndex +=1;
		if( Column.m_iPanelIndex >= Column.AbilityIcons.Length )
		{
			Column.m_iPanelIndex = 0;
		}
	}
	// bsg-nlong (1.25.17): end

	return bHasColumnAbility;
}

function HidePreview()
{
	local XComGameState_Unit Unit;
	local X2SoldierClassTemplate ClassTemplate;
	local string ClassName, ClassDesc;

	Unit = GetUnit();
	ClassTemplate = Unit.GetSoldierClassTemplate();

	ClassName = Caps(ClassTemplate.DisplayName);
	ClassDesc = ClassTemplate.ClassSummary;

	// By default when not previewing an ability, display class data
	AS_SetDescriptionData("", ClassName, ClassDesc, "", "", "", "");
}

function PreviewAbility(int Rank, int Branch)
{
	local X2AbilityTemplateManager AbilityTemplateManager;
	local X2AbilityTemplate AbilityTemplate, PreviousAbilityTemplate;
	local XComGameState_Unit Unit;
	local array<SoldierClassAbilityType> AbilityTree;
	local string AbilityIcon, AbilityName, AbilityDesc, AbilityHint, AbilityCost, CostLabel, APLabel, PrereqAbilityNames;
	local name PrereqAbilityName;

	Unit = GetUnit();
	
	// Ability cost is always displayed, even if the rank hasn't been unlocked yet
	CostLabel = m_strCostLabel;
	APLabel = m_strAPLabel;
	AbilityCost = string(GetAbilityPointCost(Rank, Branch));
	if (!CanAffordAbility(Rank, Branch))
	{
		AbilityCost = class'UIUtilities_Text'.static.GetColoredText(AbilityCost, eUIState_Bad);
	}
	
	if (Rank >= Unit.GetRank())
	{
		AbilityIcon = class'UIUtilities_Image'.const.LockedAbilityIcon;
		AbilityName = class'UIUtilities_Text'.static.GetColoredText(m_strAbilityLockedTitle, eUIState_Disabled);
		AbilityDesc = class'UIUtilities_Text'.static.GetColoredText(m_strAbilityLockedDescription, eUIState_Disabled);

		// Don't display cost information for abilities which have not been unlocked yet
		CostLabel = "";
		AbilityCost = "";
		APLabel = "";
	}
	else
	{
		AbilityTemplateManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
		AbilityTree = Unit.GetRankAbilities(Rank);
		AbilityTemplate = AbilityTemplateManager.FindAbilityTemplate(AbilityTree[Branch].AbilityName);

		if (AbilityTemplate != none)
		{
			AbilityIcon = AbilityTemplate.IconImage;
			AbilityName = AbilityTemplate.LocFriendlyName != "" ? AbilityTemplate.LocFriendlyName : ("Missing 'LocFriendlyName' for " $ AbilityTemplate.DataName);
			AbilityDesc = AbilityTemplate.HasLongDescription() ? AbilityTemplate.GetMyLongDescription(, Unit) : ("Missing 'LocLongDescription' for " $ AbilityTemplate.DataName);
			AbilityHint = "";

			// Don't display cost information if the ability has already been purchased
			if (Unit.HasSoldierAbility(AbilityTemplate.DataName))
			{
				CostLabel = "";
				AbilityCost = "";
				APLabel = "";
			}
			else if (AbilityTemplate.PrerequisiteAbilities.Length > 0)
			{
				// Look back to the previous rank and check to see if that ability is a prereq for this one
				// If so, display a message warning the player that there is a prereq
				foreach AbilityTemplate.PrerequisiteAbilities(PrereqAbilityName)
				{
					PreviousAbilityTemplate = AbilityTemplateManager.FindAbilityTemplate(PrereqAbilityName);
					if (PreviousAbilityTemplate != none && !Unit.HasSoldierAbility(PrereqAbilityName))
					{
						if (PrereqAbilityNames != "")
						{
							PrereqAbilityNames $= ", ";
						}
						PrereqAbilityNames $= PreviousAbilityTemplate.LocFriendlyName;
					}
				}
				PrereqAbilityNames = class'UIUtilities_Text'.static.FormatCommaSeparatedNouns(PrereqAbilityNames);

				if (PrereqAbilityNames != "")
				{
					AbilityDesc = class'UIUtilities_Text'.static.GetColoredText(m_strPrereqAbility @ PrereqAbilityNames, eUIState_Warning) $ "\n" $ AbilityDesc;
				}
			}
		}
		else
		{
			AbilityIcon = "";
			AbilityName = string(AbilityTree[Branch].AbilityName);
			AbilityDesc = "Missing template for ability '" $ AbilityTree[Branch].AbilityName $ "'";
			AbilityHint = "";
		}		
	}
	
	AS_SetDescriptionData(AbilityIcon, AbilityName, AbilityDesc, AbilityHint, CostLabel, AbilityCost, APLabel);
}

simulated function ConfirmAbilitySelection(int Rank, int Branch)
{
	local XGParamTag LocTag;
	local TDialogueBoxData DialogData;
	local X2AbilityTemplate AbilityTemplate;
	local X2AbilityTemplateManager AbilityTemplateManager;
	local array<SoldierClassAbilityType> AbilityTree;
	local string ConfirmAbilityText;
	local int AbilityPointCost;

	PendingRank = Rank;
	PendingBranch = Branch;

	Movie.Pres.PlayUISound(eSUISound_MenuSelect);

	DialogData.eType = eDialog_Alert;
	DialogData.bMuteAcceptSound = true;
	DialogData.strTitle = m_strConfirmAbilityTitle;
	DialogData.strAccept = class'UIUtilities_Text'.default.m_strGenericYes;
	DialogData.strCancel = class'UIUtilities_Text'.default.m_strGenericNO;
	DialogData.fnCallback = ComfirmAbilityCallback;

	AbilityTree = GetUnit().GetRankAbilities(Rank);
	AbilityTemplateManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	AbilityTemplate = AbilityTemplateManager.FindAbilityTemplate(AbilityTree[Branch].AbilityName);
	AbilityPointCost = GetAbilityPointCost(Rank, Branch);
	
	LocTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	LocTag.StrValue0 = AbilityTemplate.LocFriendlyName;
	LocTag.IntValue0 = AbilityPointCost;
	ConfirmAbilityText = `XEXPAND.ExpandString(m_strConfirmAbilityText);

	// If the unit cannot afford the ability on their own, display a warning about spending Shared AP
	if (AbilityPointCost > GetUnit().AbilityPoints)
	{
		LocTag.IntValue0 = AbilityPointCost - GetUnit().AbilityPoints;

		if((AbilityPointCost - GetUnit().AbilityPoints) == 1)
			ConfirmAbilityText $= "\n\n" $ `XEXPAND.ExpandString(m_strSharedAPWarningSingular);
		else
			ConfirmAbilityText $= "\n\n" $ `XEXPAND.ExpandString(m_strSharedAPWarning);

	}

	DialogData.strText = ConfirmAbilityText;
	Movie.Pres.UIRaiseDialog(DialogData);
}

simulated function ComfirmAbilityCallback(Name Action)
{
	local XComGameStateHistory History;
	local bool bSuccess;
	local XComGameState UpdateState;
	local XComGameState_Unit UpdatedUnit;
	local XComGameStateContext_ChangeContainer ChangeContainer;

	if (Action == 'eUIAction_Accept')
	{
		History = `XCOMHISTORY;
		ChangeContainer = class'XComGameStateContext_ChangeContainer'.static.CreateEmptyChangeContainer("Resistance Hero Promotion");
		UpdateState = History.CreateNewGameState(true, ChangeContainer);

		UpdatedUnit = XComGameState_Unit(UpdateState.ModifyStateObject(class'XComGameState_Unit', GetUnit().ObjectID));
		bSuccess = UpdatedUnit.BuySoldierProgressionAbility(UpdateState, PendingRank, PendingBranch, GetAbilityPointCost(PendingRank, PendingBranch));

		if (bSuccess)
		{
			`GAMERULES.SubmitGameState(UpdateState);

			Header.PopulateData();
			PopulateData();
		}
		else
			History.CleanupPendingGameState(UpdateState);

		Movie.Pres.PlayUISound(eSUISound_SoldierPromotion);
	}
	else
		Movie.Pres.PlayUISound(eSUISound_MenuClickNegative);
}

//==============================================================================
simulated function AS_SetRank(string RankIcon)
{
	MC.BeginFunctionOp("SetRankIcon");
	MC.QueueString(RankIcon);
	MC.EndOp();
}

simulated function AS_SetClass(string ClassIcon)
{
	MC.BeginFunctionOp("SetClassIcon");
	MC.QueueString(ClassIcon);
	MC.EndOp();
}

simulated function AS_SetFaction(StackedUIIconData IconInfo)
{
	local int i;

	if (IconInfo.Images.Length > 0)
	{
		MC.BeginFunctionOp("SetFactionIcon");
		MC.QueueBoolean(IconInfo.bInvert);
		for (i = 0; i < IconInfo.Images.Length; i++)
		{
			MC.QueueString("img:///" $ IconInfo.Images[i]);
		}

		MC.EndOp();
	}
}

simulated function AS_SetHeaderData(string Faction, string UnitName, string AbilityLabel, string TeamAPLabel, string SoldierAPLabel)
{
	MC.BeginFunctionOp("SetHeaderData");
	MC.QueueString(Faction); // Faction
	MC.QueueString(UnitName); // Soldier Name
	MC.QueueString(AbilityLabel); // Ability Selection Label
	MC.QueueString(TeamAPLabel); // Team AP Label
	MC.QueueString(SoldierAPLabel); // Soldier AP Label
	MC.EndOp();
}

simulated function AS_SetAPData(int TeamAPValue, int SoldierAPValue)
{
	MC.BeginFunctionOp("SetAPData");
	MC.QueueString(string(TeamAPValue));
	MC.QueueString(string(SoldierAPValue));
	MC.EndOp();
}

simulated function AS_SetCombatIntelData( string Value )
{
	MC.BeginFunctionOp("SetCombatIntelData");
	MC.QueueString(class'UISoldierHeader'.default.m_strCombatIntel);
	MC.QueueString(Value);
	MC.EndOp();
}

simulated function AS_SetPathLabels(string RankLabel, string Path1Label, string Path2Label, string Path3Label, string Path4Label)
{
	MC.BeginFunctionOp("SetPathLabels");
	MC.QueueString(RankLabel); // Rank Label
	MC.QueueString(class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS(Path1Label));
	MC.QueueString(class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS(Path2Label));
	MC.QueueString(class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS(Path3Label));
	MC.QueueString(class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS(Path4Label));
	MC.EndOp();
}

simulated function AS_SetDescriptionData(string Icon, string AbilityName, string Description, string Hint, string CostLabel, string CostValue, string APLabel)
{
	MC.BeginFunctionOp("SetDescriptionData");
	MC.QueueString(Icon);
	MC.QueueString(AbilityName);
	MC.QueueString(Description);
	MC.QueueString(Hint);
	MC.QueueString(CostLabel);
	MC.QueueString(CostValue);
	MC.QueueString(APLabel);
	MC.EndOp();
}

// bsg-nlong (1.25.17): Manually coded navigation: There are some issues with using the Navigation issue. First is that Navigators /within/ the Next() and Prev() functions
// are handled by their children if possible. That means hitting left and right on the dpad with scroll up and down within the column. This is uneffected by bHorizontal flag.
// So if we want left and right to switch columns and up and down to switch abilities, manual navigation is necessary.
// Secondly, the ability icons focus is spread across three Uscript functions and one AS function, so we need to manually code focus for the icons instead of making a HeroAbilityIcon class
simulated function SelectNextColumn()
{
	local int newIndex;

	newIndex = m_iCurrentlySelectedColumn + 1;
	if( newIndex >= Columns.Length )
	{
		newIndex = 0;
	}

	ChangeSelectedColumn(m_iCurrentlySelectedColumn, newIndex);
}

simulated function SelectPrevColumn()
{
	local int newIndex;

	newIndex = m_iCurrentlySelectedColumn - 1;
	if( newIndex < 0 )
	{
		newIndex = Columns.Length -1;
	}
	
	ChangeSelectedColumn(m_iCurrentlySelectedColumn, newIndex);
}

simulated function ChangeSelectedColumn(int oldIndex, int newIndex)
{
	Columns[oldIndex].OnLoseFocus();
	Columns[newIndex].OnReceiveFocus();
	m_iCurrentlySelectedColumn = newIndex;

	Movie.Pres.PlayUISound(eSUISound_MenuSelect); //bsg-crobinson (5.11.17): Add sound
}

simulated static function bool CanCycleTo(XComGameState_Unit Soldier)
{
	if (`SCREENSTACK.IsInStack(class'UIFacility_TrainingCenter'))
	{
		return super.CanCycleTo(Soldier) && (Soldier.GetSoldierClassTemplate().bAllowAWCAbilities || Soldier.IsResistanceHero());
	}
	else
	{
		return super.CanCycleTo(Soldier);
	}
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	local bool bHandled;

	if (!CheckInputIsReleaseOrDirectionRepeat(cmd, arg))
	{
		return false;
	}

	bHandled = true;
	
	bHandled = Columns[m_iCurrentlySelectedColumn].OnUnrealCommand(cmd, arg); // bsg-nlong (1.25.17): Send the input to the column first and see if it can consume it
	if (bHandled) return true;

	switch(cmd)
	{
	case class'UIUtilities_Input'.const.FXS_DPAD_RIGHT:
	case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_RIGHT:
		SelectNextColumn();
		bHandled = true;
		break;
	case class'UIUtilities_Input'.const.FXS_DPAD_LEFT :
	case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_LEFT :
		SelectPrevColumn();
		bHandled = true;
		break;
	default:
		bHandled = false;
		break;
	}

	return bHandled || super.OnUnrealCommand(cmd, arg);
}

simulated function OnReceiveFocus()
{
	super.OnReceiveFocus();
	Columns[m_iCurrentlySelectedColumn].OnReceiveFocus();
}
// bsg-nlong (1.25.17): end

function bool CanAffordAbility(int Rank, int Branch)
{
	local XComGameState_Unit Unit;
	local XComGameState_HeadquartersXCom XComHQ;
	local int AbilityCost;

	Unit = GetUnit();
	XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	AbilityCost = GetAbilityPointCost(Rank, Branch);
	if (AbilityCost <= Unit.AbilityPoints)
	{
		return true;
	}
	else if (AbilityCost <= (Unit.AbilityPoints + XComHQ.GetAbilityPoints()))
	{
		return true;
	}

	return false;
}

function bool CanPurchaseAbility(int Rank, int Branch, name AbilityName)
{
	local XComGameState_Unit UnitState;

	UnitState = GetUnit();		
	return (Rank < UnitState.GetRank() && CanAffordAbility(Rank, Branch) && UnitState.MeetsAbilityPrerequisites(AbilityName));
}

function bool IsAbilityLocked(int Rank)
{
	if(Rank >= GetUnit().GetRank())
	{
		return true;
	}
	else
	{
		return false;
	}
}

function bool OwnsAbility(name AbilityName)
{
	return GetUnit().HasSoldierAbility(AbilityName);
}

function int GetAbilityPointCost(int Rank, int Branch)
{
	local XComGameState_Unit UnitState;
	local array<SoldierClassAbilityType> AbilityTree;
	local bool bPowerfulAbility;

	UnitState = GetUnit();
	AbilityTree = UnitState.GetRankAbilities(Rank);
	bPowerfulAbility = (class'X2StrategyGameRulesetDataStructures'.default.PowerfulAbilities.Find(AbilityTree[Branch].AbilityName) != INDEX_NONE);
	
	if (!UnitState.IsResistanceHero())
	{
		if (!UnitState.HasPurchasedPerkAtRank(Rank, 2) && Branch < 2)
		{
			// If this is a base game soldier with a promotion available, ability costs nothing since it would be their
			// free promotion ability if they "bought" it through the Armory
			return 0;
		}
		else if (bPowerfulAbility && Branch >= 2)
		{
			// All powerful shared AWC abilities for base game soldiers have an increased cost, 
			// excluding any abilities they have in their normal progression tree
			return class'X2StrategyGameRulesetDataStructures'.default.PowerfulAbilityPointCost;
		}
	}

	// All Colonel level abilities for Faction Heroes and any powerful XCOM abilities have increased cost for Faction Heroes
	if (UnitState.IsResistanceHero() && (bPowerfulAbility || (Rank >= 6 && Branch < 3)))
	{
		return class'X2StrategyGameRulesetDataStructures'.default.PowerfulAbilityPointCost;
	}
	
	return class'X2StrategyGameRulesetDataStructures'.default.AbilityPointCosts[Rank];
}

function int GetSharedAbilityPoints()
{
	local XComGameState_HeadquartersXCom XComHQ;
	local int AbilityPoints;

	XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	if (XComHQ != none)
	{
		AbilityPoints = XComHQ.GetAbilityPoints();
	}

	return AbilityPoints;
}

//==============================================================================

defaultproperties
{
	Package = "/ package/gfxXPACK_HeroAbilitySelect/XPACK_HeroAbilitySelect";
	LibID = "HeroAbilitySelect";
	bHideOnLoseFocus = false;
	bAutoSelectFirstNavigable = false;
	DisplayTag = "UIBlueprint_Promotion_Hero";
	CameraTag = "UIBlueprint_Promotion_Hero";
	bShowExtendedHeaderData = true;
}