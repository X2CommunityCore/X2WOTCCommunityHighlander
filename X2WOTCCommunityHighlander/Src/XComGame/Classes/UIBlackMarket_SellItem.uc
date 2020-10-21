//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIExhange_TradingPostItem.uc
//  AUTHOR:  Samuel Batista
//  PURPOSE: UIPanel representing a list entry on Trading Post screen.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class UIBlackMarket_SellItem extends UIPanel;

var UIBGBox BG;

var UIButton Add;
var UIButton Remove;
var UIPanel  PlusIcon;
var UIPanel  MinusIcon;

var int NumSelling;
var StateObjectReference ItemRef;
var X2ItemTemplate ItemTemplate;
var int Price;
var BlackMarketItemPrice ItemPrice;

simulated function InitListItem(BlackMarketItemPrice BuyPrice)
{
	InitPanel();

	if( `ISCONTROLLERACTIVE == false )
	{
		Navigator.HorizontalNavigation = true;

		BG = Spawn(class'UIBGBox', self);
		BG.bIsNavigable = false; 
		BG.InitBG('theButton', 0, 0, 695, 40);
		BG.ProcessMouseEvents(OnChildMouseEvent);
	}

	Remove = Spawn(class'UIButton', self);
	Remove.bIsNavigable = false;
	Remove.InitButton('InventoryRemoveButton');
	Remove.ProcessMouseEvents(OnButtonMouseEvent);

	Add = Spawn(class'UIButton', self);
	Add.bIsNavigable = false;
	Add.InitButton('InventoryAddButton');
	Add.ProcessMouseEvents(OnButtonMouseEvent);

	if(`ISCONTROLLERACTIVE)
	{
		Add.Hide();
		Remove.Hide();

		PlusIcon = Spawn(class'UIPanel', self);
		PlusIcon.bIsNavigable = false;
		PlusIcon.InitPanel('plusMC');

		MinusIcon = Spawn(class'UIPanel', self);
		MinusIcon.bIsNavigable = false;
		MinusIcon.InitPanel('minusMC');

		PlusIcon.Hide();
		MinusIcon.Hide();
	}
	
	PopulateData(BuyPrice);
}

simulated function PopulateData(BlackMarketItemPrice BuyPrice)
{
	local XComGameState_Item Item;
	local string ItemName, InventoryQuantity, SellQuantity, TotalValue, ItemValue;
	local int ItemCost;

	ItemPrice = BuyPrice;
	ItemRef = BuyPrice.ItemRef;
	Price = BuyPrice.Price + BuyPrice.Price * (class'UIUtilities_Strategy'.static.GetBlackMarket().BuyPricePercentIncrease / 100.0f);
	Item = GetItem();
	ItemTemplate = Item.GetMyTemplate();
	
	ItemCost = class'UIUtilities_Strategy'.static.GetCostQuantity(ItemTemplate.Cost, 'Supplies');
	if (ItemCost > 0) // Ensure that the sell price of the item is not more than its cost from engineering
	{
		Price = Min(Price, ItemCost);
	}

	ItemName = class'UIUtilities_Text'.static.GetColoredText(ItemTemplate.GetItemFriendlyName(), eUIState_Normal, 24);
	InventoryQuantity = class'UIUtilities_Text'.static.GetColoredText(string(Item.Quantity - NumSelling), eUIState_Normal, 24);
	ItemValue = class'UIUtilities_Text'.static.GetColoredText(class'UIUtilities_Strategy'.default.m_strCreditsPrefix $ string(Price), eUIState_Cash, 24);

	if(NumSelling > 0)
	{
		SellQuantity = class'UIUtilities_Text'.static.GetColoredText(string(NumSelling), eUIState_Normal, 24);
		TotalValue = class'UIUtilities_Text'.static.GetColoredText(class'UIUtilities_Strategy'.default.m_strCreditsPrefix $ string(Price * NumSelling), eUIState_Cash, 24);
	}
	else
	{
		SellQuantity = class'UIUtilities_Text'.static.GetColoredText("-", eUIState_Normal, 24);
		TotalValue = "";
	}

	MC.BeginFunctionOp("populateData");
	MC.QueueString(ItemName);
	MC.QueueString(InventoryQuantity);
	MC.QueueString(ItemValue);
	MC.QueueString(SellQuantity);
	MC.QueueString(TotalValue);
	MC.EndOp();

}

simulated function OnChildMouseEvent(UIPanel control, int cmd)
{
	UIBlackMarket_Sell(screen).List.OnChildMouseEvent(self, cmd);

	if( cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_IN )
	{
		UIBlackMarket_Sell(screen).PopulateItemCard(ItemTemplate, ItemRef, string(Price));
	}
}

simulated function ChangeQuantity(int amt)
{
	local XComGameState_Item Item;
	local int NewNumSelling;

	NewNumSelling = NumSelling + amt;
	Item = GetItem();

	if (amt == 0 || NewNumSelling > Item.Quantity || NewNumSelling < 0)
		return;

	NumSelling = NewNumSelling;
	
	UIBlackMarket_Sell(screen).UpdateTotalValue(amt < 0 ? -Price : Price);
	UIBlackMarket_Sell(screen).PopulateItemCard(ItemTemplate, ItemRef, string(Price));
	PopulateData(ItemPrice);
}

simulated function OnButtonMouseEvent(UIPanel Button, int cmd)
{
	if(cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_UP)
	{
		if(Button == Add)
			ChangeQuantity(1);
		else if(Button == Remove)
			ChangeQuantity(-1);
	}
	else if( cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_IN )
	{
		Button.OnReceiveFocus();
		if(Button == Add)
			mc.FunctionBool("highlightAdd", true);
		else if(Button == Remove)
			mc.FunctionBool("highlightRemove", true);
	}
	else if( cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_OUT )
	{
		Button.OnLoseFocus();
		if(Button == Add)
			mc.FunctionBool("highlightAdd", false);
		else if(Button == Remove)
			mc.FunctionBool("highlightRemove", false);
	}
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
	case class'UIUtilities_Input'.const.FXS_ARROW_LEFT:
	case class'UIUtilities_Input'.const.FXS_DPAD_LEFT:
	case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_LEFT:
	case class'UIUtilities_Input'.const.FXS_BUTTON_LBUMPER:
		`SOUNDMGR.PlaySoundEvent("Generic_Mouse_Click");
		ChangeQuantity(-1);
		break;

	case class'UIUtilities_Input'.const.FXS_ARROW_RIGHT:
	case class'UIUtilities_Input'.const.FXS_DPAD_RIGHT:
	case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_RIGHT:
	case class'UIUtilities_Input'.const.FXS_BUTTON_RBUMPER:
		`SOUNDMGR.PlaySoundEvent("Generic_Mouse_Click");
		ChangeQuantity(1);
		break;

	default:
		bHandled = false;
		break;
	}

	return bHandled || super.OnUnrealCommand(cmd, arg);
}

simulated function XComGameState_Item GetItem()
{
	return XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(ItemRef.ObjectID));
}

defaultproperties
{
	bIsNavigable = true;
	bCascadeFocus = false;
	LibID = "BlackMarketItem";
	width = 700;
	height = 45;
}