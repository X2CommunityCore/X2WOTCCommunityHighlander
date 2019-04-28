
class UIArmory_PromotionPsiOp extends UIArmory_Promotion;

simulated function PopulateData()
{
	local int i, maxRank;
	local string AbilityIcon1, AbilityIcon2, AbilityName1, AbilityName2, HeaderString;
	local bool bHasAbility1, bHasAbility2, bHasRankAbility;
	local XComGameState_Unit Unit;
	local X2SoldierClassTemplate ClassTemplate;
	local X2AbilityTemplate AbilityTemplate1, AbilityTemplate2;
	local X2AbilityTemplateManager AbilityTemplateManager;
	local array<SoldierClassAbilityType> AbilityTree;
	local UIArmory_PromotionItem Item;
	local Vector ZeroVec;
	local Rotator UseRot;
	local XComUnitPawn UnitPawn;

	// We don't need to clear the list, or recreate the pawn here -sbatista
	//super.PopulateData();
	Unit = GetUnit();
	ClassTemplate = Unit.GetSoldierClassTemplate();
	AbilityTree = Unit.GetEarnedSoldierAbilities();

	HeaderString = m_strAbilityHeader;

	if (Unit.GetRank() != 1 && Unit.HasAvailablePerksToAssign())
	{
		HeaderString = m_strSelectAbility;
	}
	// Start Issue #106
	AS_SetTitle(Unit.GetSoldierClassIcon(), HeaderString, ClassTemplate.LeftAbilityTreeTitle, ClassTemplate.RightAbilityTreeTitle, Caps(Unit.GetSoldierClassDisplayName()));
	// End Issue #106

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

	// Check to see if Unit has just leveled up to Initiate, show a popup highlighting their new ability
	if (Unit.GetRank() == 1)
	{
		`HQPRES.UIPsiOperativeIntro(Unit.GetReference());
	}
	
	maxRank = ClassTemplate.GetMaxConfiguredRank(); // Issue #1
	AbilityTemplateManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();

	if (ClassRowItem == none)
	{
		ClassRowItem = Spawn(class'UIArmory_PromotionItem', self);
		ClassRowItem.MCName = 'classRow';
		ClassRowItem.InitPromotionItem(0);
		ClassRowItem.OnMouseEventDelegate = OnClassRowMouseEvent;

		if (Unit.GetRank() == 1)
			ClassRowItem.OnReceiveFocus();
	}

	ClassRowItem.ClassName = ClassTemplate.DataName;
	// Start Issue #408
	ClassRowItem.SetRankData(Unit.GetSoldierRankIcon(1), Caps(Unit.GetSoldierRankName(1)));
	// End Issue #408
		
	AbilityTemplate2 = AbilityTemplateManager.FindAbilityTemplate(AbilityTree[0].AbilityName);
	if (AbilityTemplate2 != none)
	{
		ClassRowItem.AbilityName2 = AbilityTemplate2.DataName;
		AbilityName2 = Caps(AbilityTemplate2.LocFriendlyName);
		AbilityIcon2 = AbilityTemplate2.IconImage;
	}
	else
	{
		ClassRowItem.AbilityName2 = AbilityTemplate2.DataName;
		AbilityName2 = class'UIUtilities_Text'.static.GetColoredText(m_strAbilityLockedTitle, eUIState_Disabled);
		AbilityIcon2 = class'UIUtilities_Image'.const.UnknownAbilityIcon;
	}

	ClassRowItem.SetEquippedAbilities(true, true);
	ClassRowItem.SetAbilityData("", "", AbilityIcon2, AbilityName2);
	// Start Issue #106
	ClassRowItem.SetClassData(Unit.GetSoldierClassIcon(), Caps(Unit.GetSoldierClassDisplayName()));
	// End Issue #106

	for (i = 2; i <= maxRank; ++i) // Issue #1 -- new maxRank needs to be included
	{
		Item = UIArmory_PromotionItem(List.GetItem(i - 2));
		if (Item == none)
			Item = UIArmory_PromotionItem(List.CreateItem(class'UIArmory_PromotionItem')).InitPromotionItem(i - 1);

		Item.Rank = i - 1;
		Item.ClassName = ClassTemplate.DataName;
		// Start Issue #408
		Item.SetRankData(Unit.GetSoldierRankIcon(i), Caps(Unit.GetSoldierRankName(i)));
		// End Issue #408

		AbilityTree = Unit.GetRankAbilities(Item.Rank);
		AbilityTemplate1 = AbilityTemplateManager.FindAbilityTemplate(AbilityTree[0].AbilityName);
		AbilityTemplate2 = AbilityTemplateManager.FindAbilityTemplate(AbilityTree[1].AbilityName);

		bHasAbility1 = Unit.HasSoldierAbility(AbilityTemplate1.DataName);
		bHasAbility2 = Unit.HasSoldierAbility(AbilityTemplate2.DataName);

		if (AbilityTemplate1 != none)
		{
			Item.AbilityName1 = AbilityTemplate1.DataName;
			AbilityName1 = bHasAbility1 ? Caps(AbilityTemplate1.LocFriendlyName) : class'UIUtilities_Text'.static.GetColoredText(m_strAbilityLockedTitle, eUIState_Disabled);
			AbilityIcon1 = bHasAbility1 ? AbilityTemplate1.IconImage : class'UIUtilities_Image'.const.UnknownAbilityIcon;
		}

		if (AbilityTemplate2 != none)
		{
			Item.AbilityName2 = AbilityTemplate2.DataName;
			AbilityName2 = bHasAbility2 ? Caps(AbilityTemplate2.LocFriendlyName) : class'UIUtilities_Text'.static.GetColoredText(m_strAbilityLockedTitle, eUIState_Disabled);
			AbilityIcon2 = bHasAbility2 ? AbilityTemplate2.IconImage : class'UIUtilities_Image'.const.UnknownAbilityIcon;
		}
		bHasRankAbility = bHasAbility1 || bHasAbility2;

		Item.SetAbilityData(AbilityIcon1, AbilityName1, AbilityIcon2, AbilityName2);
		Item.SetEquippedAbilities(bHasAbility1, bHasAbility2);

		Item.SetPromote(false);
		if (bHasRankAbility)
		{
			Item.SetDisabled(false);
		}
		else
		{
			Item.SetDisabled(true);
		}

		Item.RealizeVisuals();
	}

	class'UIUtilities_Strategy'.static.PopulateAbilitySummary(self, Unit);
	List.SetSelectedIndex(-1);
	PreviewRow(List, -1);
	Navigator.SetSelected(ClassRowItem);
}

simulated function PreviewRow(UIList ContainerList, int ItemIndex)
{
	local int i, Rank;
	local string TmpStr;
	local X2AbilityTemplate AbilityTemplate;
	local array<SoldierClassAbilityType> AbilityTree;
	local X2AbilityTemplateManager AbilityTemplateManager;
	local XComGameState_Unit Unit;

	Unit = GetUnit();

	if (ItemIndex == INDEX_NONE)
		Rank = 0;
	else
		Rank = UIArmory_PromotionItem(List.GetItem(ItemIndex)).Rank;

	MC.BeginFunctionOp("setAbilityPreview");

	AbilityTree = Unit.GetRankAbilities(Rank);
	AbilityTemplateManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	
	for (i = 0; i < NUM_ABILITIES_PER_RANK; ++i)
	{
		// Left icon is the class icon for the first item, show class icon plus class desc.
		if (i == 0 && Rank == 0)
		{
			// Start Issue #106
			MC.QueueString(Unit.GetSoldierClassIcon()); // icon
			MC.QueueString(Caps(Unit.GetSoldierClassDisplayName())); // name
			MC.QueueString(Unit.GetSoldierClassSummary()); // description
			// End Issue #106
			MC.QueueBoolean(true); // isClassIcon
		}
		else
		{
			// Right icon is the first ability the Psi Op learned on the first row item
			if (i == 1 && Rank == 0)
			{
				AbilityTree = Unit.GetEarnedSoldierAbilities();
				AbilityTemplate = AbilityTemplateManager.FindAbilityTemplate(AbilityTree[0].AbilityName);
			}
			else
				AbilityTemplate = AbilityTemplateManager.FindAbilityTemplate(AbilityTree[i].AbilityName);
			
			if (AbilityTemplate != none)
			{
				if (!Unit.HasSoldierAbility(AbilityTemplate.DataName))
				{
					MC.QueueString(class'UIUtilities_Image'.const.LockedAbilityIcon); // icon
					MC.QueueString(class'UIUtilities_Text'.static.GetColoredText(m_strAbilityLockedTitle, eUIState_Disabled)); // name
					MC.QueueString(class'UIUtilities_Text'.static.GetColoredText(m_strAbilityLockedDescription, eUIState_Disabled)); // description
					MC.QueueBoolean(false); // isClassIcon
				}
				else
				{
					MC.QueueString(AbilityTemplate.IconImage); // icon

					TmpStr = AbilityTemplate.LocFriendlyName != "" ? AbilityTemplate.LocFriendlyName : ("Missing 'LocFriendlyName' for " $ AbilityTemplate.DataName);
					MC.QueueString(Caps(TmpStr)); // name

					TmpStr = AbilityTemplate.HasLongDescription() ? AbilityTemplate.GetMyLongDescription(, Unit) : ("Missing 'LocLongDescription' for " $ AbilityTemplate.DataName);
					MC.QueueString(TmpStr); // description
					MC.QueueBoolean(false); // isClassIcon
				}
			}
			else
			{
				MC.QueueString(""); // icon
				MC.QueueString(string(AbilityTree[i].AbilityName)); // name
				MC.QueueString("Missing template for ability '" $ AbilityTree[i].AbilityName $ "'"); // description
				MC.QueueBoolean(false); // isClassIcon
			}
		}
	}

	MC.EndOp();
	
	if (Rank == 0)
	{
		ClassRowItem.SetSelectedAbility(1);
	}
	else
	{
		UIArmory_PromotionItem(List.GetItem(ItemIndex)).SetSelectedAbility(SelectedAbilityIndex);
	}

	UpdateNavHelp();
}