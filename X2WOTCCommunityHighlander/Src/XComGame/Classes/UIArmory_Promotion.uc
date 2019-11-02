class UIArmory_Promotion extends UIArmory
	dependson(X2Photobooth, X2Photobooth_AutoGenBase);

const NUM_ABILITIES_PER_RANK = 2;

var XComGameState PromotionState;

var int PendingRank, PendingBranch;

var int PropagandaMinRank;
var localized string m_strMakePosterTitle;
var localized string m_strMakePosterBody;

var bool bAfterActionPromotion;	//Set to TRUE if we need to make a pawn and move the camera to the armory
var UIAfterAction AfterActionScreen; //If bAfterActionPromotion is true, this holds a reference to the after action screen
var UIArmory_PromotionItem ClassRowItem;

var localized string m_strSelectAbility;
var localized string m_strAbilityHeader;

var localized string m_strConfirmAbilityTitle;
var localized string m_strConfirmAbilityText;

var localized string m_strCorporalPromotionDialogTitle;
var localized string m_strCorporalPromotionDialogText;

var localized string m_strAWCUnlockDialogTitle;
var localized string m_strAWCUnlockDialogText;

var localized string m_strAbilityLockedTitle;
var localized string m_strAbilityLockedDescription;

var localized string m_strInfo;
var localized string m_strSelect;

var localized string m_strHotlinkToRecovery; 

var int SelectedAbilityIndex;

var UIList  List;

var bool bShownClassPopup, bShownCorporalPopup, bShownAWCPopup; // DEPRECATED bsteiner 3/24/2016 

var protected int previousSelectedIndexOnFocusLost;

simulated function InitPromotion(StateObjectReference UnitRef, optional bool bInstantTransition)
{
	// If the AfterAction screen is running, let it position the camera
	AfterActionScreen = UIAfterAction(Movie.Stack.GetScreen(class'UIAfterAction'));
	if(AfterActionScreen != none)
	{
		bAfterActionPromotion = true;
		PawnLocationTag = AfterActionScreen.GetPawnLocationTag(UnitRef);
		CameraTag = AfterActionScreen.GetPromotionBlueprintTag(UnitRef);
		DisplayTag = name(AfterActionScreen.GetPromotionBlueprintTag(UnitRef));
	}
	else
	{
		CameraTag = GetPromotionBlueprintTag(UnitRef);
		DisplayTag = name(GetPromotionBlueprintTag(UnitRef));
	}
	
	// Don't show nav help during tutorial, or during the After Action sequence.
	bUseNavHelp = class'XComGameState_HeadquartersXCom'.static.IsObjectiveCompleted('T0_M2_WelcomeToArmory') || Movie.Pres.ScreenStack.IsInStack(class'UIAfterAction');

	UnitReference = UnitRef;
	super.InitArmory(UnitRef,,,,,, bInstantTransition);

	List = Spawn(class'UIList', self).InitList('promoteList');
	List.OnSelectionChanged = PreviewRow;
	List.bStickyHighlight = false;
	List.bAutosizeItems = false;

	PopulateData();
	List.Navigator.LoopSelection = false;

	Navigator.Clear();
	Navigator.LoopSelection = false;
	if (ClassRowItem != None) 
	{
		Navigator.AddControl(ClassRowItem);
	}

	Navigator.AddControl(List);
	if (List.SelectedIndex < 0)
	{
		Navigator.SetSelected(ClassRowItem);
	}
	else
	{
		Navigator.SetSelected(List);
		UIArmory_PromotionItem(List.GetSelectedItem()).SetSelectedAbility(0); //bsg-crobinson (6.5.17): When first opening promote grab focus on left most skill
	}

	MC.FunctionVoid("animateIn");
}

simulated function OnInit()
{
	super.OnInit();

	SetTimer(0.1334, false, 'UpdateClassRowSelection');
}

simulated function UpdateClassRowSelection()
{
	if (List.SelectedIndex < 0)
	{
		ClassRowItem.SetSelectedAbility(1);
	}
}
simulated function UpdateNavHelp() // bsg-jrebar (4/21/17): Changed UI flow and button positions per new additions
{
	//<workshop> SCI 2016/4/12
	//INS:
	local int i;
	local string PrevKey, NextKey;
	local XGParamTag LocTag;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Unit Unit;
	Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitReference.ObjectID));

	if(!bIsFocused)
	{
		return;
	}

	NavHelp = `HQPRES.m_kAvengerHUD.NavHelp;

	NavHelp.ClearButtonHelp();
	//</workshop>

	if(UIAfterAction(Movie.Stack.GetScreen(class'UIAfterAction')) != none)
	{
		//<workshop> SCI 2016/3/1
		//WAS:
		//`HQPRES.m_kAvengerHUD.NavHelp.ClearButtonHelp();
		//`HQPRES.m_kAvengerHUD.NavHelp.AddContinueButton(OnCancel);
		NavHelp.AddBackButton(OnCancel);

		if (UIArmory_PromotionItem(List.GetSelectedItem()).bEligibleForPromotion && `ISCONTROLLERACTIVE)
		{
			NavHelp.AddSelectNavHelp();
		}

		//bsg-hlee (05.08.17): Remove the big continue button form the screen if controller. 
		//Also removed "A" press from OnUnrealCommand since "B" is already closing the screen.
		if(!`ISCONTROLLERACTIVE)
		{
			if (!XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitReference.ObjectID)).ShowPromoteIcon())
			{
				NavHelp.AddContinueButton(OnCancel);
			}
		}
		//bsg-hlee (05.08.17): End
	
		if(class'XComGameState_HeadquartersXCom'.static.IsObjectiveCompleted('T0_M7_WelcomeToGeoscape'))
			NavHelp.AddLeftHelp(m_strMakePosterTitle, class'UIUtilities_Input'.static.GetGamepadIconPrefix() $class'UIUtilities_Input'.const.ICON_X_SQUARE, MakePosterButton);


		if( `ISCONTROLLERACTIVE )
		{
			if( !UIArmory_PromotionItem(List.GetSelectedItem()).bIsDisabled )
			{
				NavHelp.AddCenterHelp(m_strInfo, class'UIUtilities_Input'.static.GetGamepadIconPrefix() $class'UIUtilities_Input'.const.ICON_LSCLICK_L3);
			}

			if (IsAllowedToCycleSoldiers() && class'UIUtilities_Strategy'.static.HasSoldiersToCycleThrough(UnitReference, CanCycleTo))
			{
				NavHelp.AddCenterHelp(m_strTabNavHelp, class'UIUtilities_Input'.static.GetGamepadIconPrefix() $ class'UIUtilities_Input'.const.ICON_LBRB_L1R1); // bsg-jrebar (5/23/17): Removing inlined buttons
			}

			NavHelp.AddCenterHelp(m_strRotateNavHelp, class'UIUtilities_Input'.static.GetGamepadIconPrefix() $ class'UIUtilities_Input'.const.ICON_RSTICK); // bsg-jrebar (5/23/17): Removing inlined buttons
		}
	}
	else
	{
		//<workshop> SCI 2016/4/12
		//WAS:
		//super.UpdateNavHelp();
		NavHelp.AddBackButton(OnCancel);
		
		if (UIArmory_PromotionItem(List.GetSelectedItem()).bEligibleForPromotion)
		{
			NavHelp.AddSelectNavHelp();
		}

		if (XComHQPresentationLayer(Movie.Pres) != none)
		{
			LocTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
			LocTag.StrValue0 = Movie.Pres.m_kKeybindingData.GetKeyStringForAction(PC.PlayerInput, eTBC_PrevUnit);
			PrevKey = `XEXPAND.ExpandString(PrevSoldierKey);
			LocTag.StrValue0 = Movie.Pres.m_kKeybindingData.GetKeyStringForAction(PC.PlayerInput, eTBC_NextUnit);
			NextKey = `XEXPAND.ExpandString(NextSoldierKey);

			if (class'XComGameState_HeadquartersXCom'.static.GetObjectiveStatus('T0_M7_WelcomeToGeoscape') != eObjectiveState_InProgress &&
				RemoveMenuEvent == '' && NavigationBackEvent == '' && !`ScreenStack.IsInStack(class'UISquadSelect'))
			{
				NavHelp.AddGeoscapeButton();
			}

			if (Movie.IsMouseActive() && IsAllowedToCycleSoldiers() && class'UIUtilities_Strategy'.static.HasSoldiersToCycleThrough(UnitReference, CanCycleTo))
			{
				NavHelp.SetButtonType("XComButtonIconPC");
				i = eButtonIconPC_Prev_Soldier;
				NavHelp.AddCenterHelp( string(i), "", PrevSoldier, false, PrevKey);
				i = eButtonIconPC_Next_Soldier; 
				NavHelp.AddCenterHelp( string(i), "", NextSoldier, false, NextKey);
				NavHelp.SetButtonType("");
			}
		}

		if (class'XComGameState_HeadquartersXCom'.static.IsObjectiveCompleted('T0_M7_WelcomeToGeoscape'))
		{
			if(`ISCONTROLLERACTIVE)
				NavHelp.AddLeftHelp(m_strMakePosterTitle, class'UIUtilities_Input'.static.GetGamepadIconPrefix() $class'UIUtilities_Input'.const.ICON_X_SQUARE, MakePosterButton);
			else
				NavHelp.AddLeftHelp(m_strMakePosterTitle, , MakePosterButton);
		}

		if( `ISCONTROLLERACTIVE )
		{
			if (!UIArmory_PromotionItem(List.GetSelectedItem()).bIsDisabled)
			{
				NavHelp.AddCenterHelp(m_strInfo, class'UIUtilities_Input'.static.GetGamepadIconPrefix() $class'UIUtilities_Input'.const.ICON_LSCLICK_L3);
			}

			if (IsAllowedToCycleSoldiers() && class'UIUtilities_Strategy'.static.HasSoldiersToCycleThrough(UnitReference, CanCycleTo))
			{
				NavHelp.AddCenterHelp(m_strTabNavHelp, class'UIUtilities_Input'.static.GetGamepadIconPrefix() $ class'UIUtilities_Input'.const.ICON_LBRB_L1R1); // bsg-jrebar (5/23/17): Removing inlined buttons
			}

			NavHelp.AddCenterHelp(m_strRotateNavHelp, class'UIUtilities_Input'.static.GetGamepadIconPrefix() $ class'UIUtilities_Input'.const.ICON_RSTICK); // bsg-jrebar (5/23/17): Removing inlined buttons
		}


		XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
		
		if( XComHQ.HasFacilityByName('RecoveryCenter') && IsAllowedToCycleSoldiers() && !`ScreenStack.IsInStack(class'UIFacility_TrainingCenter')
			&& !`ScreenStack.IsInStack(class'UISquadSelect') && !`ScreenStack.IsInStack(class'UIAfterAction') && Unit.GetSoldierClassTemplate().bAllowAWCAbilities)
		{
			if( `ISCONTROLLERACTIVE ) 
				NavHelp.AddRightHelp(m_strHotlinkToRecovery, class'UIUtilities_Input'.consT.ICON_BACK_SELECT);
			else
				NavHelp.AddRightHelp(m_strHotlinkToRecovery, , JumpToRecoveryFacility);
		}

		NavHelp.Show();
		//</workshop>
	}
}
// bsg-jrebar (4/21/17): end

simulated function JumpToRecoveryFacility()
{
	local XComGameStateHistory History;
	local XComGameState_FacilityXCom FacilityState;

	History = `XCOMHISTORY;

	foreach History.IterateByClassType(class'XComGameState_FacilityXCom', FacilityState)
	{
		if( FacilityState.GetMyTemplateName() == 'RecoveryCenter' && !FacilityState.IsUnderConstruction() )
		{
			`HQPRES.m_kAvengerHUD.Shortcuts.SelectFacilityHotlink(FacilityState.GetReference());
			return;
		}
	}
}

simulated function OnLoseFocus()
{
	super.OnLoseFocus();
	//<workshop> FIX_FOR_PROMOTION_LOST_FOCUS_ISSUE kmartinez 2015-10-28
	// only set our variable if we're not trying to set a default value.
	if( List.SelectedIndex != -1)
		previousSelectedIndexOnFocusLost = List.SelectedIndex;
	//List.SetSelectedIndex(-1);
	`HQPRES.m_kAvengerHUD.NavHelp.ClearButtonHelp();
}

// Don't allow soldier switching when promoting soldiers on top of avenger
simulated function bool IsAllowedToCycleSoldiers()
{
	return !Movie.Pres.ScreenStack.IsInStack(class'UIAfterAction');
}

simulated function PopulateData()
{
	local int i, maxRank, previewIndex;
	local string AbilityIcon1, AbilityIcon2, AbilityName1, AbilityName2, HeaderString;
	local bool bFirstUnnassignedRank, bHasAbility1, bHasAbility2, bHasRankAbility;
	local XComGameState_Unit Unit;
	local X2SoldierClassTemplate ClassTemplate;
	local X2AbilityTemplate AbilityTemplate1, AbilityTemplate2;
	local X2AbilityTemplateManager AbilityTemplateManager;
	local array<SoldierClassAbilityType> AbilityTree;
	local UIArmory_PromotionItem Item;
	local array<name> AWCAbilityNames;
	local Vector ZeroVec;
	local Rotator UseRot;
	local XComUnitPawn UnitPawn, GremlinPawn;

	// We don't need to clear the list, or recreate the pawn here -sbatista
	//super.PopulateData();
	Unit = GetUnit();
	ClassTemplate = Unit.GetSoldierClassTemplate();

	HeaderString = m_strAbilityHeader;

	if(Unit.GetRank() != 1 && Unit.HasAvailablePerksToAssign())
	{
		HeaderString = m_strSelectAbility;
	}

	// Start Issue #106
	AS_SetTitle(Unit.GetSoldierClassIcon(), HeaderString, ClassTemplate.LeftAbilityTreeTitle, ClassTemplate.RightAbilityTreeTitle, Caps(Unit.GetSoldierClassDisplayName()));
	// End Issue #106

	if(ActorPawn == none || (Unit.GetRank() == 1 && bAfterActionPromotion)) //This condition is TRUE when in the after action report, and we need to rank someone up to squaddie
	{
		//Get the current pawn so we can extract its rotation
		UnitPawn = Movie.Pres.GetUIPawnMgr().RequestPawnByID(AfterActionScreen, UnitReference.ObjectID, ZeroVec, UseRot);
		UseRot = UnitPawn.Rotation;

		//Free the existing pawn, and then create the ranked up pawn. This may not be strictly necessary since most of the differences between the classes are in their equipment. However, it is easy to foresee
		//having class specific soldier content and this covers that possibility
		Movie.Pres.GetUIPawnMgr().ReleasePawn(AfterActionScreen, UnitReference.ObjectID);
		CreateSoldierPawn(UseRot);

		if(bAfterActionPromotion && !Unit.bCaptured)
		{
			//Let the pawn manager know that the after action report is referencing this pawn too			
			UnitPawn = Movie.Pres.GetUIPawnMgr().RequestPawnByID(AfterActionScreen, UnitReference.ObjectID, ZeroVec, UseRot);
			AfterActionScreen.SetPawn(UnitReference, UnitPawn);
			GremlinPawn = Movie.Pres.GetUIPawnMgr().GetCosmeticPawn(eInvSlot_SecondaryWeapon, UnitReference.ObjectID);
			if (GremlinPawn != none)
				GremlinPawn.SetLocation(UnitPawn.Location);
		}
	}

	// Check to see if Unit needs to show a new class popup.
	if(Unit.bNeedsNewClassPopup)
	{
		AwardRankAbilities(ClassTemplate, 0);

		`HQPRES.UIClassEarned(Unit.GetReference());
		Unit.bNeedsNewClassPopup = false;  //Prevent from queueing up more of these popups on toggling soldiers. 

		Unit = GetUnit(); // we've updated the UnitState, update the Unit to reflect the latest changes
	}
	
	// Check for AWC Ability popup
	if(Unit.NeedsAWCAbilityPopup())
	{
		AWCAbilityNames = Unit.GetAWCAbilityNames();
		
		if(AWCAbilityNames.Length > 0)
		{
			ShowAWCDialog(AWCAbilityNames);
		}

		Unit = GetUnit();  // we've updated the UnitState, update the Unit to reflect the latest changes
	}

	previewIndex = -1;
	maxRank = ClassTemplate.GetMaxConfiguredRank(); // Issue #1
	AbilityTemplateManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();

	if(ClassRowItem == none)
	{
		ClassRowItem = Spawn(class'UIArmory_PromotionItem', self);
		ClassRowItem.MCName = 'classRow';
		ClassRowItem.InitPromotionItem(0);
		ClassRowItem.OnMouseEventDelegate = OnClassRowMouseEvent;

		if(Unit.GetRank() == 1)
			ClassRowItem.OnReceiveFocus();
	}

	ClassRowItem.ClassName = ClassTemplate.DataName;
	// Start Issue #408
	ClassRowItem.SetRankData(Unit.GetSoldierRankIcon(1), Caps(Unit.GetSoldierRankName(1)));
	// End Issue #408

	AbilityTree = Unit.GetRankAbilities(ClassRowItem.Rank);
	AbilityTemplate2 = AbilityTemplateManager.FindAbilityTemplate(AbilityTree[0].AbilityName);
	if(AbilityTemplate2 != none)
	{
		ClassRowItem.AbilityName2 = AbilityTemplate2.DataName;
		AbilityName2 = Caps(AbilityTemplate2.LocFriendlyName);
		AbilityIcon2 = AbilityTemplate2.IconImage;
	}
	else
	{
		AbilityTemplate1 = AbilityTemplateManager.FindAbilityTemplate(AbilityTree[1].AbilityName);
		ClassRowItem.AbilityName2 = AbilityTemplate1.DataName;
		AbilityName2 = Caps(AbilityTemplate1.LocFriendlyName);
		AbilityIcon2 = AbilityTemplate1.IconImage;
	}

	ClassRowItem.SetEquippedAbilities(true, true);
	ClassRowItem.SetAbilityData("", "", AbilityIcon2, AbilityName2);
	// Start Issue #106
	ClassRowItem.SetClassData(Unit.GetSoldierClassIcon(), Caps(Unit.GetSoldierClassDisplayName()));
	// End Issue #106

	for(i = 2; i <= maxRank; ++i) // Issue #1 -- new maxRank needs to be included
	{
		Item = UIArmory_PromotionItem(List.GetItem(i - 2));
		if(Item == none)
			Item = UIArmory_PromotionItem(List.CreateItem(class'UIArmory_PromotionItem')).InitPromotionItem(i - 1);

		Item.Rank = i - 1;
		Item.ClassName = ClassTemplate.DataName;
		// Start Issue #408
		Item.SetRankData(Unit.GetSoldierRankIcon(i), Caps(Unit.GetSoldierRankName(i)));
		// End Issue #408

		AbilityTree = Unit.GetRankAbilities(Item.Rank);

		AbilityTemplate1 = AbilityTemplateManager.FindAbilityTemplate(AbilityTree[0].AbilityName);
		if(AbilityTemplate1 != none)
		{
			Item.AbilityName1 = AbilityTemplate1.DataName;
			AbilityName1 = i > Unit.GetRank() ? class'UIUtilities_Text'.static.GetColoredText(m_strAbilityLockedTitle, eUIState_Disabled) : Caps(AbilityTemplate1.LocFriendlyName);
			AbilityIcon1 = i > Unit.GetRank() ? class'UIUtilities_Image'.const.UnknownAbilityIcon : AbilityTemplate1.IconImage;
		}

		AbilityTemplate2 = AbilityTemplateManager.FindAbilityTemplate(AbilityTree[1].AbilityName);
		if(AbilityTemplate2 != none)
		{
			Item.AbilityName2 = AbilityTemplate2.DataName;
			AbilityName2 = i > Unit.GetRank() ? class'UIUtilities_Text'.static.GetColoredText(m_strAbilityLockedTitle, eUIState_Disabled) : Caps(AbilityTemplate2.LocFriendlyName);
			AbilityIcon2 = i > Unit.GetRank() ? class'UIUtilities_Image'.const.UnknownAbilityIcon : AbilityTemplate2.IconImage;
		}

		bHasAbility1 = Unit.HasSoldierAbility(Item.AbilityName1);
		bHasAbility2 = Unit.HasSoldierAbility(Item.AbilityName2);
		bHasRankAbility = bHasAbility1 || bHasAbility2;

		Item.SetAbilityData(AbilityIcon1, AbilityName1, AbilityIcon2, AbilityName2);
		Item.SetEquippedAbilities(bHasAbility1, bHasAbility2);

		if(i == 1 || bHasRankAbility || (i == Unit.GetRank() && !Unit.HasAvailablePerksToAssign()))
		{
			Item.SetDisabled(false);
			Item.SetPromote(false);
		}
		else if(i > Unit.GetRank())
		{
			Item.SetDisabled(true);
			Item.SetPromote(false);
		}
		else // has available perks to assign
		{
			if(!bFirstUnnassignedRank)
			{
				previewIndex = i - 2;
				bFirstUnnassignedRank = true;
				Item.SetDisabled(false);
				Item.SetPromote(true);
				List.SetSelectedIndex(List.GetItemIndex(Item), true);
			}
			else
			{
				Item.SetDisabled(true);
				Item.SetPromote(false);
			}
		}

		Item.RealizeVisuals();
	}

	class'UIUtilities_Strategy'.static.PopulateAbilitySummary(self, Unit);
	PreviewRow(List, previewIndex);
	if (previewIndex < 0)
	{
		Navigator.SetSelected(ClassRowItem);
		ClassRowItem.OnReceiveFocus();
	}
	else
	{
		Navigator.SetSelected(List);
		List.SetSelectedIndex(previewIndex);
	}

	UpdateNavHelp();
}

simulated function OnClassRowMouseEvent(UIPanel Panel, int Cmd)
{
	if(Cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_IN || Cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_DRAG_OVER)
		PreviewRow(List, -1);
}

simulated function RequestPawn(optional Rotator DesiredRotation)
{
	local XComGameState_Unit UnitState;
	local name IdleAnimName;

	super.RequestPawn(DesiredRotation);

	UnitState = GetUnit();
	if(!UnitState.IsInjured() || UnitState.bRecoveryBoosted)
	{
		IdleAnimName = UnitState.GetMyTemplate().CustomizationManagerClass.default.StandingStillAnimName;

		// Play the "By The Book" idle to minimize character overlap with UI elements
		XComHumanPawn(ActorPawn).PlayHQIdleAnim(IdleAnimName);

		// Cache desired animation in case the pawn hasn't loaded the customization animation set
		XComHumanPawn(ActorPawn).CustomizationIdleAnim = IdleAnimName;
	}
}

// DEPRECATED bsteiner 3/24/2016
simulated function AwardRankAbilities(X2SoldierClassTemplate ClassTemplate, int Rank);
simulated function array<name> AwardAWCAbilities();
simulated function ShowCorporalDialog(X2SoldierClassTemplate ClassTemplate);
// END DEPRECATED ITEMS bsteiner 3/24/2016

simulated function ShowAWCDialog(array<name> AWCAbilityNames)
{
	local int i;
	local string tmpStr;
	local XGParamTag        kTag;
	local TDialogueBoxData  kDialogData;
	local X2AbilityTemplate AbilityTemplate;
	local X2AbilityTemplateManager AbilityTemplateManager;
	local XComGameState NewGameState;
	local XComGameState_Unit UnitState;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Display AWC Ability Popup");
	UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', UnitReference.ObjectID));
	UnitState.bSeenAWCAbilityPopup = true;
	`GAMERULES.SubmitGameState(NewGameState);

	kTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));

	kDialogData.strTitle = m_strAWCUnlockDialogTitle;

	kTag.StrValue0 = "";
	AbilityTemplateManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	for(i = 0; i < AWCAbilityNames.Length; ++i)
	{
		AbilityTemplate = AbilityTemplateManager.FindAbilityTemplate(AWCAbilityNames[i]);

		// Ability Name
		tmpStr = AbilityTemplate.LocFriendlyName != "" ? AbilityTemplate.LocFriendlyName : ("Missing 'LocFriendlyName' for ability '" $ AbilityTemplate.DataName $ "'");
		kTag.StrValue0 $= "- " $ Caps(tmpStr) $ ":\n";

		// Ability Description
		tmpStr = AbilityTemplate.HasLongDescription() ? AbilityTemplate.GetMyLongDescription(, GetUnit()) : ("Missing 'LocLongDescription' for ability " $ AbilityTemplate.DataName $ "'");
		kTag.StrValue0 $= tmpStr $ "\n\n";
	}

	kDialogData.strText = `XEXPAND.ExpandString(m_strAWCUnlockDialogText);
	kDialogData.strAccept = class'UIUtilities_Text'.default.m_strGenericOK;

	Movie.Pres.UIRaiseDialog(kDialogData);
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

	if(ItemIndex == INDEX_NONE)
		Rank = 0;
	else
		Rank = UIArmory_PromotionItem(List.GetItem(ItemIndex)).Rank;

	MC.BeginFunctionOp("setAbilityPreview");

	if(Rank >= Unit.GetRank())
	{
		for(i = 0; i < NUM_ABILITIES_PER_RANK; ++i)
		{
			MC.QueueString(class'UIUtilities_Image'.const.LockedAbilityIcon); // icon
			MC.QueueString(class'UIUtilities_Text'.static.GetColoredText(m_strAbilityLockedTitle, eUIState_Disabled)); // name
			MC.QueueString(class'UIUtilities_Text'.static.GetColoredText(m_strAbilityLockedDescription, eUIState_Disabled)); // description
			MC.QueueBoolean(false); // isClassIcon
		}
	}
	else
	{
		AbilityTree = Unit.GetRankAbilities(Rank);
		AbilityTemplateManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();

		for(i = 0; i < AbilityTree.Length; ++i)
		{
			// Left icon is the class icon for the first item, show class icon plus class desc.
			if(i == 0 && Rank == 0)
			{
				// Start Issue #106
				MC.QueueString(Unit.GetSoldierClassIcon()); // icon
				MC.QueueString(Caps(Unit.GetSoldierClassDisplayName())); // name
				MC.QueueString(Unit.GetSoldierClassSummary()); // description
				// End Issue #106
				MC.QueueBoolean(true); // isClassIcon
			}
			
			if( i > 0 || Rank > 0 //Subsequent abilities in the tree 
			   || (i == 0 && Rank == 0 && AbilityTree.length == 1) ) //or if first row, first rank, and there's only one ability to show. 

			{
				if (Rank == 0)
				{
					AbilityTemplate = AbilityTemplateManager.FindAbilityTemplate(AbilityTree[0].AbilityName);

					// If this is the first row and the class doesn't have a first ability, show the second ability instead
					if (AbilityTemplate == none)
					{
						AbilityTemplate = AbilityTemplateManager.FindAbilityTemplate(AbilityTree[1].AbilityName);
					}
				}
				else
				{
					AbilityTemplate = AbilityTemplateManager.FindAbilityTemplate(AbilityTree[i].AbilityName);
				}

				if(AbilityTemplate != none)
				{
					MC.QueueString(AbilityTemplate.IconImage); // icon

					TmpStr = AbilityTemplate.LocFriendlyName != "" ? AbilityTemplate.LocFriendlyName : ("Missing 'LocFriendlyName' for " $ AbilityTemplate.DataName);
					MC.QueueString(Caps(TmpStr)); // name

					TmpStr = AbilityTemplate.HasLongDescription() ? AbilityTemplate.GetMyLongDescription(, Unit) : ("Missing 'LocLongDescription' for " $ AbilityTemplate.DataName);
					MC.QueueString(TmpStr); // description
					MC.QueueBoolean(false); // isClassIcon
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

simulated function HideRowPreview()
{
	MC.FunctionVoid("hideAbilityPreview");
}

simulated function ConfirmAbilitySelection(int Rank, int Branch)
{
	local XGParamTag LocTag;
	local TDialogueBoxData DialogData;
	local X2AbilityTemplate AbilityTemplate;
	local X2AbilityTemplateManager AbilityTemplateManager;
	local array<SoldierClassAbilityType> AbilityTree;

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

	LocTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	LocTag.StrValue0 = AbilityTemplate.LocFriendlyName;
	DialogData.strText = `XEXPAND.ExpandString(m_strConfirmAbilityText);
	Movie.Pres.UIRaiseDialog(DialogData);
	UpdateNavHelp();
}

simulated function ComfirmAbilityCallback(Name Action)
{
	local XComGameStateHistory History;
	local bool bSuccess;
	local XComGameState UpdateState;
	local XComGameState_Unit UpdatedUnit;
	local XComGameStateContext_ChangeContainer ChangeContainer;

	if(Action == 'eUIAction_Accept')
	{
		History = `XCOMHISTORY;
		ChangeContainer = class'XComGameStateContext_ChangeContainer'.static.CreateEmptyChangeContainer("Soldier Promotion");
		UpdateState = History.CreateNewGameState(true, ChangeContainer);

		UpdatedUnit = XComGameState_Unit(UpdateState.ModifyStateObject(class'XComGameState_Unit', GetUnit().ObjectID));
		bSuccess = UpdatedUnit.BuySoldierProgressionAbility(UpdateState, PendingRank, PendingBranch);

		if(bSuccess)
		{
			`GAMERULES.SubmitGameState(UpdateState);

			Header.PopulateData();
			PopulateData();
		}
		else
			History.CleanupPendingGameState(UpdateState);

		Movie.Pres.PlayUISound(eSUISound_SoldierPromotion);
	}
	else 	// if we got here it means we were going to upgrade an ability, but then we decided to cancel
	{
		Movie.Pres.PlayUISound(eSUISound_MenuClickNegative);
		List.SetSelectedIndex(previousSelectedIndexOnFocusLost, true);
		UIArmory_PromotionItem(List.GetSelectedItem()).SetSelectedAbility(SelectedAbilityIndex);
	}
}

simulated function MakePosterButton()
{
	local UIArmory_Photobooth photoscreen;
	local PhotoboothDefaultSettings autoDefaultSettings;
	local AutoGenPhotoInfo requestInfo;

	requestInfo.TextLayoutState = ePBTLS_PromotedSoldier;
	requestInfo.UnitRef = UnitReference;
	autoDefaultSettings = `HQPRES.GetPhotoboothAutoGen().SetupDefault(requestInfo);
	autoDefaultSettings.SoldierAnimIndex.AddItem(-1); // Todo: change anims to duo pose.  -1 will randomize

	photoscreen = XComHQPresentationLayer(Movie.Pres).UIArmory_Photobooth(UnitReference);
	photoscreen.DefaultSetupSettings = autoDefaultSettings;
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	local XComGameStateHistory History;
	local bool bHandled;
	local name SoldierClassName;
	local XComGameState_Unit UpdatedUnit;
	local XComGameState UpdateState;
	local XComGameStateContext_ChangeContainer ChangeContainer;
	local XComGameState_Unit Unit;
	Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitReference.ObjectID));

	// Only pay attention to presses or repeats; ignoring other input types
	if ( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg) )
		return false;
	if (List.GetSelectedItem().OnUnrealCommand(cmd, arg))
	{
		UpdateNavHelp();
		return true;
	}

	bHandled = true;

	switch( cmd )
	{
		// DEBUG: Press Tab to rank up the soldier
		`if (`notdefined(FINAL_RELEASE))
		case class'UIUtilities_Input'.const.FXS_KEY_TAB:
			History = `XCOMHISTORY;
			ChangeContainer = class'XComGameStateContext_ChangeContainer'.static.CreateEmptyChangeContainer("DEBUG Unit Rank Up");
			UpdateState = History.CreateNewGameState(true, ChangeContainer);
			UpdatedUnit = XComGameState_Unit(UpdateState.ModifyStateObject(class'XComGameState_Unit', GetUnit().ObjectID));

			if (UpdatedUnit.GetRank() == 0)
				SoldierClassName = class'UIUtilities_Strategy'.static.GetXComHQ().SelectNextSoldierClass();

			UpdatedUnit.RankUpSoldier(UpdateState, SoldierClassName);

			`GAMERULES.SubmitGameState(UpdateState);

			PopulateData();
			break;
		`endif
		case class'UIUtilities_Input'.const.FXS_MOUSE_5:
		case class'UIUtilities_Input'.const.FXS_KEY_TAB:
		case class'UIUtilities_Input'.const.FXS_BUTTON_RBUMPER:
		case class'UIUtilities_Input'.const.FXS_MOUSE_4:
		case class'UIUtilities_Input'.const.FXS_KEY_LEFT_SHIFT:
		case class'UIUtilities_Input'.const.FXS_BUTTON_LBUMPER:
			// Prevent switching soldiers during AfterAction promotion
			if( UIAfterAction(Movie.Stack.GetScreen(class'UIAfterAction')) == none )
				bHandled = false;
			break;
		case class'UIUtilities_Input'.const.FXS_BUTTON_B:
		case class'UIUtilities_Input'.const.FXS_KEY_ESCAPE:
		case class'UIUtilities_Input'.const.FXS_R_MOUSE_DOWN:
			OnCancel();
			break;
		case class'UIUtilities_Input'.const.FXS_BUTTON_X: // bsg-jrebar (4/21/17): Changed UI flow and button positions per new additions
			MakePosterButton();
			break;
		case class'UIUtilities_Input'.const.FXS_BUTTON_SELECT : // bsg-jrebar (4/21/17): Changed UI flow and button positions per new additions
			//bsg-hlee (05.09.17): If the nav help does not how up do not allow the button to navigate to the facility. Condition taken from UpdateNavHelp when deciding to add the nav help or not.
			if( class'UIUtilities_Strategy'.static.GetXComHQ().HasFacilityByName('RecoveryCenter') && IsAllowedToCycleSoldiers() && !`ScreenStack.IsInStack(class'UIFacility_TrainingCenter')
			&& !`ScreenStack.IsInStack(class'UISquadSelect') && !`ScreenStack.IsInStack(class'UIAfterAction') && Unit.GetSoldierClassTemplate().bAllowAWCAbilities)
				JumpToRecoveryFacility();
		default:
			bHandled = false;
			break;
	}

	//if (List.Navigator.OnUnrealCommand(cmd, arg))
	//{
	//	return true;
	//}
	
	return bHandled || super.OnUnrealCommand(cmd, arg);
}

simulated function OnReceiveFocus()
{
	local int i;
	local XComHQPresentationLayer HQPres;

	super.OnReceiveFocus();

	HQPres = XComHQPresentationLayer(Movie.Pres);

	if(HQPres != none)
	{
		if(bAfterActionPromotion) //If the AfterAction screen is running, let it position the camera
			HQPres.CAMLookAtNamedLocation(AfterActionScreen.GetPromotionBlueprintTag(UnitReference), `HQINTERPTIME);
		else
			HQPres.CAMLookAtNamedLocation(CameraTag, `HQINTERPTIME);
	}

	for(i = 0; i < List.ItemCount; ++i)
	{
		UIArmory_PromotionItem(List.GetItem(i)).RealizePromoteState();
	}

	if (previousSelectedIndexOnFocusLost >= 0)
	{
		Navigator.SetSelected(List);
		List.SetSelectedIndex(previousSelectedIndexOnFocusLost);
		UIArmory_PromotionItem(List.GetSelectedItem()).SetSelectedAbility(SelectedAbilityIndex);
	}
	else
	{
		Navigator.SetSelected(ClassRowItem);
		ClassRowItem.SetSelectedAbility(1);
	}
	UpdateNavHelp();
}

simulated function string GetPromotionBlueprintTag(StateObjectReference UnitRef)
{
	local XComGameState_Unit UnitState;

	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitRef.ObjectID));
	if(UnitState.IsGravelyInjured())
		return default.DisplayTag $ "Injured";
	return string(default.DisplayTag);
}

simulated static function CycleToSoldier(StateObjectReference NewRef)
{
	local UIArmory_MainMenu MainMenu;

	super.CycleToSoldier(NewRef);

	// Prevent the spawning of popups while we reload the promotion screen
	MainMenu = UIArmory_MainMenu(`SCREENSTACK.GetScreen(class'UIArmory_MainMenu'));
	MainMenu.bIsHotlinking = true;

	// Reload promotion screen since we might need a separate instance (regular or psi promote) depending on unit
	`SCREENSTACK.PopFirstInstanceOfClass(class'UIArmory_Promotion');
	`HQPRES.UIArmory_Promotion(NewRef);

	MainMenu.bIsHotlinking = false;
}

simulated function OnRemoved()
{
	if(ActorPawn != none)
	{
		// Restore the character's default idle animation
		XComHumanPawn(ActorPawn).CustomizationIdleAnim = '';
		XComHumanPawn(ActorPawn).PlayHQIdleAnim();
	}

	// Reset soldiers out of view if we're promoting this unit on top of the avenger.
	// NOTE: This can't be done in UIAfterAction.OnReceiveFocus because that function might trigger when user dismisses the new class cinematic.
	if(AfterActionScreen != none)
	{
		AfterActionScreen.ResetUnitLocations();
	}

	super.OnRemoved();
}

simulated function OnCancel()
{
	if( UIAfterAction(Movie.Stack.GetScreen(class'UIAfterAction')) != none || 
		class'XComGameState_HeadquartersXCom'.static.IsObjectiveCompleted('T0_M2_WelcomeToArmory') )
	{
		super.OnCancel();
	}
}

//==============================================================================

simulated function AS_SetTitle(string Image, string TitleText, string LeftTitle, string RightRitle, string ClassTitle)
{
	MC.BeginFunctionOp("setPromotionTitle");
	MC.QueueString(Image);
	MC.QueueString(TitleText);
	MC.QueueString(class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS(LeftTitle));
	MC.QueueString(class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS(RightRitle));
	MC.QueueString(ClassTitle);
	MC.EndOp();
}

simulated static function bool CanCycleTo(XComGameState_Unit Unit)
{
	return Unit.IsSoldier() && !Unit.IsDead() && !Unit.IsOnCovertAction() && (Unit.GetRank() >= 1 || Unit.CanRankUpSoldier());
}

//==============================================================================

defaultproperties
{
	LibID = "PromotionScreenMC";
	bHideOnLoseFocus = false;
	bAutoSelectFirstNavigable = false;
	DisplayTag = "UIBlueprint_Promotion";
	CameraTag = "UIBlueprint_Promotion";
	previousSelectedIndexOnFocusLost = -1;
	SelectedAbilityIndex = 1;

	PropagandaMinRank = 5;
	bShowExtendedHeaderData = true;
}