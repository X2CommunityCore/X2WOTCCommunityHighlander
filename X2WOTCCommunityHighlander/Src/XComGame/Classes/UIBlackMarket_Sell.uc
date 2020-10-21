//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIBlackMarket_Sell.uc
//  AUTHOR:  Samuel Batista
//  PURPOSE: Screen where players can exchange items for supplies.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class UIBlackMarket_Sell extends UIScreen;

var int SaleAmount;
//var UIText TotalValue;
var StateObjectReference BlackMarketReference;
var UIButton ConfirmButton;

var localized string m_strConfirmButtonLabel;
var localized string m_strInventoryLabel;
var localized string m_strSellLabel;
var localized string m_strTotalLabel;
var localized string m_strCostLabel;
var localized string m_strInterestedLabel;
var localized string m_strQuantityLabel;
var localized String	m_strSellConfirmTitle;
var localized String	m_strSellConfirmText;
var localized string m_strAddRemoveItems;

var UIList List;
var UIPanel ListBG;

var XComGameStateHistory History;
var XComGameState_HeadquartersXCom XComHQ;


simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	super.InitScreen(InitController, InitMovie, InitName);

	History = `XCOMHISTORY;
	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();

	BuildScreen();
	MC.FunctionVoid("AnimateIn");
	Show();
}

simulated function BuildScreen()
{
	History = `XCOMHISTORY;
	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();

	ListBG = Spawn(class'UIPanel', self);
	ListBG.InitPanel('InventoryListBG');
	ListBG.Show();

	List = Spawn(class'UIList', self).InitList('inventoryListMC');
	List.bStickyHighlight = true;
	List.OnSelectionChanged = SelectedItemChanged;

	Navigator.SetSelected(List);

	// send mouse scroll events to the list
	ListBG.ProcessMouseEvents(List.OnChildMouseEvent);

	UpdateNavHelp();

	MC.BeginFunctionOp("SetGreeble");
	MC.QueueString(class'UIAlert'.default.m_strBlackMarketFooterLeft);
	MC.QueueString(class'UIAlert'.default.m_strBlackMarketFooterRight);
	MC.QueueString(class'UIAlert'.default.m_strBlackMarketLogoString);
	MC.EndOp();

	//---------------------
	
	// Move and resize list to accommodate label
	List.SetHeight(class'UIBlackMarket_SellItem'.default.Height * 16);

	UpdateSellInfo();

	ConfirmButton = Spawn(class'UIButton', self).InitButton('ConfirmButton', m_strConfirmButtonLabel, OnConfirmButtonClicked, eUIButtonStyle_HOTLINK_BUTTON);
	ConfirmButton.SetGamepadIcon(class'UIUtilities_Input'.static.GetGamepadIconPrefix() $ class'UIUtilities_Input'.const.ICON_X_SQUARE);

	PopulateData();
	UpdateTotalValue();
	List.SetSelectedIndex(0, true);
}

simulated function PopulateData()
{
	local XComGameState NewGameState;
	local BlackMarketItemPrice Item;
	local XComGameState_Item InventoryItem;
	local array<BlackMarketItemPrice> Items;
	local XComGameState_BlackMarket BlackMarketState;
	local UIBlackMarket_SellItem ListItem;
	local BlackMarketItemPrice PrevItem;

	ListItem = UIBlackMarket_SellItem(List.GetSelectedItem());
	if(ListItem != None)
		PrevItem = ListItem.ItemPrice;

	// override behavior in child classes
	List.ClearItems();

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Update Black Market Price List");
	BlackMarketState = XComGameState_BlackMarket(`XCOMHISTORY.GetGameStateForObjectID(BlackMarketReference.ObjectID));

	// Update Black Markets prices if we need to
	BlackMarketState = XComGameState_BlackMarket(NewGameState.ModifyStateObject(class'XComGameState_BlackMarket', BlackMarketState.ObjectID));
	if(BlackMarketState.UpdateBuyPrices())
	{
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
	else
	{
		NewGameState.PurgeGameStateForObjectID(BlackMarketState.ObjectID);
		`XCOMHISTORY.CleanupPendingGameState(NewGameState);
	}

	BlackMarketState = XComGameState_BlackMarket(`XCOMHISTORY.GetGameStateForObjectID(BlackMarketReference.ObjectID));
	Items = BlackMarketState.BuyPrices;
	Items.Sort(SortByInterest);
	
	foreach Items(Item)
	{
		// Don't display if none in your inventory to sell
		InventoryItem = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(Item.ItemRef.ObjectID));
		if( InventoryItem.Quantity > 0 )
		{
			Spawn(class'UIBlackMarket_SellItem', List.itemContainer).InitListItem(Item);
			if(Item == PrevItem)
				List.SetSelectedIndex(List.GetItemCount() - 1);
		}
	}

	if(List.ItemCount > 0)
	{
		ListItem = UIBlackMarket_SellItem(List.GetItem(0));
		PopulateItemCard(ListItem.ItemTemplate, ListItem.ItemRef, string(ListItem.Price));
		if(List.SelectedIndex < 0)
			List.SetSelectedIndex(0);
	}
	else
	{
		ClearItemCard();
	}

	if (List.ItemCount <= 0)
		CloseScreen(); //bsg-crobinson (5.22.17): Force player out if they run out of items to sell
}

function int SortByInterest(BlackMarketItemPrice BuyPriceA, BlackMarketItemPrice BuyPriceB)
{
	local XComGameState_BlackMarket BlackMarketState;
	local XComGameState_Item ItemA, ItemB;

	History = `XCOMHISTORY;
	BlackMarketState = XComGameState_BlackMarket(History.GetGameStateForObjectID(BlackMarketReference.ObjectID));
	ItemA = XComGameState_Item(History.GetGameStateForObjectID(BuyPriceA.ItemRef.ObjectID));
	ItemB = XComGameState_Item(History.GetGameStateForObjectID(BuyPriceB.ItemRef.ObjectID));

	if(BlackMarketState.InterestTemplates.Find(ItemB.GetMyTemplateName()) != INDEX_NONE &&
	   BlackMarketState.InterestTemplates.Find(ItemA.GetMyTemplateName()) == INDEX_NONE)
	{
		return -1;
	}
	
	return 0;
}

simulated function UpdateTotalValue(optional int Delta = 0)
{
	SaleAmount += Delta;

	ConfirmButton.SetDisabled(SaleAmount == 0);

	MC.BeginFunctionOp("UpdateSellTotal");
	MC.QueueString(class'UIUtilities_Strategy'.default.m_strCreditsPrefix  $ string(SaleAmount));
	MC.EndOp();
	UpdateNavHelp();
}

simulated function OnConfirmButtonClicked(UIButton Button)
{
	local int i;
	local XComGameState NewGameState;
	local XComGameState_BlackMarket BlackMarketState;
	local UIBlackMarket_SellItem UIItem;
	local bool bSold;

	if(ConfirmButton.isDisabled)
	{
		Movie.Pres.PlayUISound(eSUISound_MenuClose);
		return;
	}

	BlackMarketState = XComGameState_BlackMarket(`XCOMHISTORY.GetGameStateForObjectID(BlackMarketReference.ObjectID));
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Trading Post Exchange");
	bSold = false;

	for(i = 0; i < List.itemCount; ++i)
	{
		UIItem = UIBlackMarket_SellItem(List.GetItem(i));
		
		if(UIItem.NumSelling > 0)
		{
			bSold = true;
			BlackMarketState = XComGameState_BlackMarket(NewGameState.GetGameStateForObjectID(BlackMarketReference.ObjectID));
			
			if(BlackMarketState == none)
			{
				BlackMarketState = XComGameState_BlackMarket(NewGameState.ModifyStateObject(class'XComGameState_BlackMarket', BlackMarketReference.ObjectID));
			}

			class'X2StrategyGameRulesetDataStructures'.static.TradingPostTransaction(NewGameState, BlackMarketState, UIItem.GetItem(), UIItem.Price, UIItem.NumSelling);
		}
	}

	if(bSold)
	{
		`XEVENTMGR.TriggerEvent('BlackMarketGoodsSold', , , NewGameState);
		`XSTRATEGYSOUNDMGR.PlaySoundEvent("StrategyUI_Sell_Item");
	}

	if(NewGameState.GetNumGameStateObjects() > 0)
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	else
		`XCOMHISTORY.CleanupPendingGameState(NewGameState);
	
	`HQPRES.m_kAvengerHUD.UpdateResources();

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();

	SaleAmount = 0;
	PopulateData();
	UpdateTotalValue();

	Movie.Pres.PlayUISound(eSUISound_MenuSelect);
}

simulated function UpdateSellInfo()
{
	MC.BeginFunctionOp("UpdateSellInfo");
	MC.QueueString(m_strInventoryLabel);
	MC.QueueString(m_strSellLabel);
	MC.QueueString(m_strTotalLabel);
	MC.QueueString(m_strConfirmButtonLabel);
	MC.QueueString(m_strQuantityLabel);
	MC.EndOp();
}

simulated function SelectedItemChanged(UIList ContainerList, int ItemIndex)
{
	local UIBlackMarket_SellItem ListItem;

	ListItem = UIBlackMarket_SellItem(ContainerList.GetItem(ItemIndex));
	if( ListItem.ItemTemplate != none )
	{
		PopulateItemCard(ListItem.ItemTemplate, ListItem.ItemRef, string(ListItem.Price));
	}
}

simulated function PopulateItemCard(X2ItemTemplate ItemTemplate, StateObjectReference ItemRef, optional string ItemPrice = "")
{
	local string strImage, strTitle, strInterest;

	if( ItemTemplate.strImage != "" )
		strImage = ItemTemplate.strImage;
	else
		strImage = "img:///UILibrary_StrategyImages.GeneMods.GeneMods_MimeticSkin"; //Temp cool image

	strTitle = class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS(ItemTemplate.GetItemFriendlyName());
	
	strInterest = IsInterested(ItemTemplate) ? m_strInterestedLabel : "";

	MC.BeginFunctionOp("UpdateItemCard");
	MC.QueueString(strImage);
	MC.QueueString(strTitle);
	MC.QueueString(m_strCostLabel);
	MC.QueueString(ItemPrice);
	MC.QueueString(strInterest);
	MC.QueueString(""); // TODO: what warning string goes here? 
	MC.QueueString(ItemTemplate.GetItemBriefSummary(ItemRef.ObjectID));
	MC.EndOp(); 

}

simulated function ClearItemCard()
{
	MC.BeginFunctionOp("UpdateItemCard");
	MC.QueueString("");
	MC.QueueString("");
	MC.QueueString("");
	MC.QueueString("");
	MC.QueueString("");
	MC.QueueString(""); 
	MC.QueueString("");
	MC.EndOp();
}

simulated function bool IsInterested(X2ItemTemplate ItemTemplate)
{
	local array<XComGameState_Item> Interests;
	local int i;

	Interests = class'UIUtilities_Strategy'.static.GetBlackMarket().GetInterests();

	for( i = 0; i < Interests.Length; i++ )
	{
		if( Interests[i].GetMyTemplate() == ItemTemplate )
			return true;
	}
	return false;
}

simulated function UpdateNavHelp()
{
	`HQPRES.m_kAvengerHUD.NavHelp.ClearButtonHelp();
	`HQPRES.m_kAvengerHUD.NavHelp.AddBackButton(CloseScreen);

	if(`ISCONTROLLERACTIVE && List.ItemCount > 0) //Only show this if theres a controller and theres available items to sell
	{
		`HQPRES.m_kAvengerHUD.NavHelp.AddLeftHelp(m_strAddRemoveItems, class'UIUtilities_Input'.const.ICON_DPAD_HORIZONTAL);
	}

	/*if(List.ItemCount > 0)
		`HQPRES.m_kAvengerHUD.NavHelp.AddLeftHelp(class'UIUtilities_Text'.default.m_strGenericNavigate, class'UIUtilities_Input'.const.ICON_DPAD_HORIZONTAL);
		//USE THIS IF WE SWITCH TO BUMPER NAVIGATION - JTA 2016/2/12
		//`HQPRES.m_kAvengerHUD.NavHelp.AddLeftHelp(
		//	class'UIUtilities_Text'.static.InjectImage(class'UIUtilities_Input'.static.GetGamepadIconPrefix() $class'UIUtilities_Input'.const.Icon_LB_L1,38,26,-10) $
		//	class'UIUtilities_Text'.static.InjectImage(class'UIUtilities_Input'.static.GetGamepadIconPrefix() $class'UIUtilities_Input'.const.Icon_RB_R1,34,26,-10) @
		//	class'UIUtilities_Text'.default.m_strGenericNavigate);
	if(SaleAmount > 0)
		`HQPRES.m_kAvengerHUD.NavHelp.AddLeftHelp(m_strSellLabel, class'UIUtilities_Input'.static.GetGamepadIconPrefix() $ class'UIUtilities_Input'.const.ICON_X_SQUARE);
		*/
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	local bool bHandled;

	// Only pay attention to presses or repeats; ignoring other input types
	// NOTE: Ensure repeats only occur with arrow keys
	if( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg) )
		return false;

	bHandled = true;
	switch( cmd )
	{
	case class'UIUtilities_Input'.const.FXS_KEY_ENTER:
	case class'UIUtilities_Input'.const.FXS_KEY_SPACEBAR:
		OnConfirmButtonClicked(ConfirmButton);
		break;
	case class'UIUtilities_Input'.const.FXS_BUTTON_X:
		if(List.ItemCount > 0) //bsg-crobinson (5.3.17): Be sure we have items to sell before we pop up this dialouge box
			DisplayConfirmSellDialog();
		break;
	case class'UIUtilities_Input'.const.FXS_BUTTON_B:
	case class'UIUtilities_Input'.const.FXS_KEY_ESCAPE:
	case class'UIUtilities_Input'.const.FXS_R_MOUSE_DOWN:
		CloseScreen();
		break;
	case class'UIUtilities_Input'.const.FXS_BUTTON_START:
		`HQPRES.UIPauseMenu(, true);
		break;
	default:
		bHandled = false;
		break;
	}

	return bHandled || super.OnUnrealCommand(cmd, arg);
}

function DisplayConfirmSellDialog()
{
	local TDialogueBoxData kConfirmData;

	kConfirmData.eType = eDialog_Warning;
	kConfirmData.strTitle = m_strSellConfirmTitle;
	kConfirmData.strText = Repl(m_strSellConfirmText,"<amount>",class'UIUtilities_Strategy'.default.m_strCreditsPrefix  $ string(SaleAmount));
	kConfirmData.strAccept = class'UIUtilities_Text'.default.m_strGenericConfirm;
	kConfirmData.strCancel = class'UIUtilities_Text'.default.m_strGenericCancel;

	kConfirmData.fnCallback = OnDisplayConfirmSellDialogAction;

	Movie.Pres.UIRaiseDialog(kConfirmData);
}

//bsg-crobinson (5.4.17): Be sure to clear/update navhelp on receive/lose focus
simulated function OnReceiveFocus()
{
	super.OnReceiveFocus();
	UpdateNavHelp();
}

simulated function OnLoseFocus()
{
	super.OnLoseFocus();
	`HQPRES.m_kAvengerHUD.NavHelp.ClearButtonHelp();
	
}
//bsg-crobinson (5.4.17): end

function OnDisplayConfirmSellDialogAction(Name eAction)
{
	if (eAction == 'eUIAction_Accept')
	{
		OnConfirmButtonClicked(ConfirmButton);
	}
}
defaultproperties
{
	Package = "/ package/gfxBlackMarket/BlackMarket";
	bConsumeMouseEvents = true;
}