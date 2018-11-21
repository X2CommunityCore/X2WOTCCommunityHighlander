//---------------------------------------------------------------------------------------
//  FILE:    UICustomize_Head.uc
//  PURPOSE: Soldier gear options list. 
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class UICustomize_Body extends UICustomize;

var localized string m_strTitle;
var localized string m_strArms;
var localized string m_strTorso;
var localized string m_strLegs;
var localized string m_strArmorPattern;
var localized string m_strTattoosLeft;
var localized string m_strTattoosRight;
var localized string m_strTattooColor;
var localized string m_strMainColor;
var localized string m_strSecondaryColor;

//Left arm / right arm selection
var localized string m_strLeftArm;
var localized string m_strRightArm;
var localized string m_strLeftArmDeco;
var localized string m_strRightArmDeco;

// XPack Hero deco selection
var localized string m_strLeftForearm;
var localized string m_strRightForearm;
var localized string m_strThighs;
var localized string m_strShins;
var localized string m_strTorsoDeco;

//----------------------------------------------------------------------------
// FUNCTIONS

function ResetMechaListItems()
{
	local UIMechaListItem CustomizeItem;
	local int i;

	for (i = 0; i < List.ItemCount; i++)
	{
		CustomizeItem = GetListItem(i++);
		CustomizeItem.SetDisabled(false);
		CustomizeItem.OnLoseFocus();
		CustomizeItem.Hide();
		CustomizeItem.BG.RemoveTooltip();
		CustomizeItem.DisableNavigation();
	}
	List.SetSelectedIndex(-1);
}

simulated function UpdateData()
{
	local int i;
	local bool bHasOptions;
	local EUIState ColorState;	
	local int currentSel;
	local bool bCanSelectArmDeco;
	local bool bCanSelectForearmDeco;
	local bool bCanSelectDualArms;
	currentSel = List.SelectedIndex;
	
	ResetMechaListItems();

	super.UpdateData();

	// ARMOR PRIMARY COLOR
	//-----------------------------------------------------------------------------------------
	GetListItem(i++).UpdateDataColorChip(CustomizeManager.CheckForAttentionIcon(eUICustomizeCat_PrimaryArmorColor)$ m_strMainColor,
		CustomizeManager.GetCurrentDisplayColorHTML(eUICustomizeCat_PrimaryArmorColor), PrimaryArmorColorSelector);

	// ARMOR SECONDARY COLOR
	//-----------------------------------------------------------------------------------------
	GetListItem(i++).UpdateDataColorChip(CustomizeManager.CheckForAttentionIcon(eUICustomizeCat_SecondaryArmorColor)$ m_strSecondaryColor,
		CustomizeManager.GetCurrentDisplayColorHTML(eUICustomizeCat_SecondaryArmorColor), SecondaryArmorColorSelector);

	ColorState = bIsSuperSoldier ? eUIState_Disabled : eUIState_Normal;
	
	// ARMOR PATTERN (VETERAN ONLY)
	//-----------------------------------------------------------------------------------------
	GetListItem(i++, bDisableVeteranOptions).UpdateDataValue(CustomizeManager.CheckForAttentionIcon(eUICustomizeCat_ArmorPatterns) $ m_strArmorPattern,
		CustomizeManager.FormatCategoryDisplay(eUICustomizeCat_ArmorPatterns, ColorState, FontSize), CustomizeArmorPattern);

	// ARMS
	//-----------------------------------------------------------------------------------------
	bCanSelectDualArms = CustomizeManager.HasPartsForPartType("Arms", `XCOMGAME.SharedBodyPartFilter.FilterByTorsoAndArmorMatch);
	if (CustomizeManager.HasMultiplePartsForPartType("Arms", `XCOMGAME.SharedBodyPartFilter.FilterByTorsoAndArmorMatch))
	{
		GetListItem(i++, !bCanSelectDualArms, m_strIncompatibleStatus).UpdateDataValue(CustomizeManager.CheckForAttentionIcon(eUICustomizeCat_Arms) $ m_strArms,
			CustomizeManager.FormatCategoryDisplay(eUICustomizeCat_Arms, bCanSelectDualArms ? eUIState_Normal : eUIState_Disabled, FontSize), CustomizeArms, true);
	}

	if (CustomizeManager.HasPartsForPartType("LeftArm", `XCOMGAME.SharedBodyPartFilter.FilterByTorsoAndArmorMatch))
	{
		//If they have parts for left arm, we assume that right arm parts are available too.
		if (CustomizeManager.HasMultiplePartsForPartType("LeftArm", `XCOMGAME.SharedBodyPartFilter.FilterByTorsoAndArmorMatch))
		{
			GetListItem(i++).UpdateDataValue(CustomizeManager.CheckForAttentionIcon(eUICustomizeCat_LeftArm) $ m_strLeftArm,
				CustomizeManager.FormatCategoryDisplay(eUICustomizeCat_LeftArm, , FontSize), CustomizeLeftArm, true);
		}

		if (CustomizeManager.HasMultiplePartsForPartType("RightArm", `XCOMGAME.SharedBodyPartFilter.FilterByTorsoAndArmorMatch))
		{
			GetListItem(i++).UpdateDataValue(CustomizeManager.CheckForAttentionIcon(eUICustomizeCat_RightArm) $ m_strRightArm,
				CustomizeManager.FormatCategoryDisplay(eUICustomizeCat_RightArm, , FontSize), CustomizeRightArm, true);
		}

		//Only show these options if there is no dual arm selection
		bCanSelectArmDeco = Unit.kAppearance.nmArms == '' && CustomizeManager.HasPartsForPartType("LeftArmDeco", `XCOMGAME.SharedBodyPartFilter.FilterByTorsoAndArmorMatch);
		if (CustomizeManager.HasMultiplePartsForPartType("LeftArmDeco", `XCOMGAME.SharedBodyPartFilter.FilterByTorsoAndArmorMatch))
		{
			GetListItem(i++, !bCanSelectArmDeco, m_strIncompatibleStatus).UpdateDataValue(CustomizeManager.CheckForAttentionIcon(eUICustomizeCat_LeftArmDeco) $ m_strLeftArmDeco,
				CustomizeManager.FormatCategoryDisplay(eUICustomizeCat_LeftArmDeco, bCanSelectArmDeco ? eUIState_Normal : eUIState_Disabled, FontSize), CustomizeLeftArmDeco, true);
		}
	
		bCanSelectArmDeco = Unit.kAppearance.nmArms == '' && CustomizeManager.HasPartsForPartType("RightArmDeco", `XCOMGAME.SharedBodyPartFilter.FilterByTorsoAndArmorMatch);
		if (CustomizeManager.HasMultiplePartsForPartType("RightArmDeco", `XCOMGAME.SharedBodyPartFilter.FilterByTorsoAndArmorMatch))
		{
			GetListItem(i++, !bCanSelectArmDeco, m_strIncompatibleStatus).UpdateDataValue(CustomizeManager.CheckForAttentionIcon(eUICustomizeCat_RightArmDeco) $ m_strRightArmDeco,
				CustomizeManager.FormatCategoryDisplay(eUICustomizeCat_RightArmDeco, bCanSelectArmDeco ? eUIState_Normal : eUIState_Disabled, FontSize), CustomizeRightArmDeco, true);
		}

		
		bCanSelectForearmDeco = (Unit.kAppearance.nmArms == '' && CustomizeManager.HasPartsForPartType("LeftForearm", `XCOMGAME.SharedBodyPartFilter.FilterByTorsoAndArmorMatch) &&
			!XComHumanPawn(CustomizeManager.ActorPawn).LeftArmContent.bHideForearms);
		if (CustomizeManager.HasMultiplePartsForPartType("LeftForearm", `XCOMGAME.SharedBodyPartFilter.FilterByTorsoAndArmorMatch))
		{
			GetListItem(i++, !bCanSelectForearmDeco, m_strIncompatibleStatus).UpdateDataValue(CustomizeManager.CheckForAttentionIcon(eUICustomizeCat_LeftForearm) $ m_strLeftForearm,
				CustomizeManager.FormatCategoryDisplay(eUICustomizeCat_LeftForearm, bCanSelectForearmDeco ? eUIState_Normal : eUIState_Disabled, FontSize), CustomizeLeftForearm, true);
		}
		
		bCanSelectForearmDeco = (Unit.kAppearance.nmArms == '' && CustomizeManager.HasPartsForPartType("RightForearm", `XCOMGAME.SharedBodyPartFilter.FilterByTorsoAndArmorMatch) &&
			!XComHumanPawn(CustomizeManager.ActorPawn).RightArmContent.bHideForearms);
		if (CustomizeManager.HasMultiplePartsForPartType("RightForearm", `XCOMGAME.SharedBodyPartFilter.FilterByTorsoAndArmorMatch))
		{
			GetListItem(i++, !bCanSelectForearmDeco, m_strIncompatibleStatus).UpdateDataValue(CustomizeManager.CheckForAttentionIcon(eUICustomizeCat_RightForearm) $ m_strRightForearm,
				CustomizeManager.FormatCategoryDisplay(eUICustomizeCat_RightForearm, bCanSelectForearmDeco ? eUIState_Normal : eUIState_Disabled, FontSize), CustomizeRightForearm, true);
		}
	}

	// TORSO
	//-----------------------------------------------------------------------------------------
	bHasOptions = CustomizeManager.HasMultipleCustomizationOptions(eUICustomizeCat_Torso);
	ColorState = bHasOptions ? eUIState_Normal : eUIState_Disabled;

	if (CustomizeManager.HasMultiplePartsForPartType("Torso", `XCOMGAME.SharedBodyPartFilter.FilterByTorsoAndArmorMatch))
	{
		GetListItem(i++, !bHasOptions, m_strNoVariations).UpdateDataValue(CustomizeManager.CheckForAttentionIcon(eUICustomizeCat_Torso) $ m_strTorso,
			CustomizeManager.FormatCategoryDisplay(eUICustomizeCat_Torso, ColorState, FontSize), CustomizeTorso);
	}

	// TORSO DECO
	//-----------------------------------------------------------------------------------------
	if (CustomizeManager.HasMultiplePartsForPartType("TorsoDeco", `XCOMGAME.SharedBodyPartFilter.FilterByTorsoAndArmorMatch))
	{
		GetListItem(i++).UpdateDataValue(CustomizeManager.CheckForAttentionIcon(eUICustomizeCat_TorsoDeco) $ m_strTorsoDeco,
			CustomizeManager.FormatCategoryDisplay(eUICustomizeCat_TorsoDeco, , FontSize), CustomizeTorsoDeco);
	}

	// LEGS
	//-----------------------------------------------------------------------------------------
	if (CustomizeManager.HasMultiplePartsForPartType("Legs", `XCOMGAME.SharedBodyPartFilter.FilterByTorsoAndArmorMatch))
	{
		GetListItem(i++).UpdateDataValue(CustomizeManager.CheckForAttentionIcon(eUICustomizeCat_Legs) $ m_strLegs,
			CustomizeManager.FormatCategoryDisplay(eUICustomizeCat_Legs, , FontSize), CustomizeLegs);
	}

	// THIGHS
	//-----------------------------------------------------------------------------------------
	if (CustomizeManager.HasMultiplePartsForPartType("Thighs", `XCOMGAME.SharedBodyPartFilter.FilterByTorsoAndArmorMatch))
	{
		GetListItem(i++).UpdateDataValue(CustomizeManager.CheckForAttentionIcon(eUICustomizeCat_Thighs) $ m_strThighs,
			CustomizeManager.FormatCategoryDisplay(eUICustomizeCat_Thighs, , FontSize), CustomizeThighs);
	}

	// SHINS
	//-----------------------------------------------------------------------------------------
	if (CustomizeManager.HasMultiplePartsForPartType("Shins", `XCOMGAME.SharedBodyPartFilter.FilterByTorsoAndArmorMatch))
	{
		GetListItem(i++).UpdateDataValue(CustomizeManager.CheckForAttentionIcon(eUICustomizeCat_Shins) $ m_strShins,
			CustomizeManager.FormatCategoryDisplay(eUICustomizeCat_Shins, , FontSize), CustomizeShins);
	}

	// TATOOS (VETERAN ONLY)
	//-----------------------------------------------------------------------------------------
	GetListItem(i++, bDisableVeteranOptions).UpdateDataValue(CustomizeManager.CheckForAttentionIcon(eUICustomizeCat_LeftArmTattoos) $ m_strTattoosLeft,
		CustomizeManager.FormatCategoryDisplay(eUICustomizeCat_LeftArmTattoos, ColorState, FontSize), CustomizeLeftArmTattoos);

	GetListItem(i++, bDisableVeteranOptions).UpdateDataValue(CustomizeManager.CheckForAttentionIcon(eUICustomizeCat_RightArmTattoos) $ m_strTattoosRight,
		CustomizeManager.FormatCategoryDisplay(eUICustomizeCat_RightArmTattoos, ColorState, FontSize), CustomizeRightArmTattoos);

	// TATTOO COLOR (VETERAN ONLY)
	//-----------------------------------------------------------------------------------------
	GetListItem(i++, bDisableVeteranOptions).UpdateDataColorChip(CustomizeManager.CheckForAttentionIcon(eUICustomizeCat_TattooColor) $ m_strTattooColor,
		CustomizeManager.GetCurrentDisplayColorHTML(eUICustomizeCat_TattooColor), TattooColorSelector);

	if (currentSel > -1 && currentSel < List.ItemCount)
	{
		List.Navigator.SetSelected(List.GetItem(currentSel));
	}
	else
	{
		List.Navigator.SetSelected(List.GetItem(0));
	}
}

// --------------------------------------------------------------------------
reliable client function PrimaryArmorColorSelector()
{
	CustomizeManager.UpdateCamera(eUICustomizeCat_PrimaryArmorColor);
	ColorSelector = GetColorSelector(CustomizeManager.GetColorList(eUICustomizeCat_PrimaryArmorColor),
		PreviewPrimaryArmorColor, SetPrimaryArmorColor, int(CustomizeManager.GetCategoryDisplay(eUICustomizeCat_PrimaryArmorColor)));

	CustomizeManager.AccessedCategoryCheckDLC(eUICustomizeCat_PrimaryArmorColor);
}
function PreviewPrimaryArmorColor(int iColorIndex)
{
	CustomizeManager.OnCategoryValueChange(eUICustomizeCat_PrimaryArmorColor, -1, iColorIndex);
}
function SetPrimaryArmorColor(int iColorIndex)
{
	CustomizeManager.OnCategoryValueChange(eUICustomizeCat_PrimaryArmorColor, -1, iColorIndex);
	UpdateData();
}
// --------------------------------------------------------------------------
reliable client function SecondaryArmorColorSelector()
{
	CustomizeManager.UpdateCamera(eUICustomizeCat_SecondaryArmorColor);
	ColorSelector = GetColorSelector(CustomizeManager.GetColorList(eUICustomizeCat_SecondaryArmorColor),
		PreviewSecondaryArmorColor, SetSecondaryArmorColor, int(CustomizeManager.GetCategoryDisplay(eUICustomizeCat_SecondaryArmorColor)));
}
function PreviewSecondaryArmorColor(int iColorIndex)
{
	CustomizeManager.OnCategoryValueChange(eUICustomizeCat_SecondaryArmorColor, -1, iColorIndex);
}
function SetSecondaryArmorColor(int iColorIndex)
{
	CustomizeManager.OnCategoryValueChange(eUICustomizeCat_SecondaryArmorColor, -1, iColorIndex);
	UpdateData();
}
// ------------------------------------------------------------------------
simulated function CustomizeArmorPattern()
{
	CustomizeManager.UpdateCamera();
	Movie.Pres.UICustomize_Trait(m_strArmorPattern, "", CustomizeManager.GetCategoryList(eUICustomizeCat_ArmorPatterns),
		ChangeArmorPattern, ChangeArmorPattern, CanCycleTo, CustomizeManager.GetCategoryIndex(eUICustomizeCat_ArmorPatterns));

}
simulated function ChangeArmorPattern(UIList _list, int itemIndex)
{
	CustomizeManager.OnCategoryValueChange(eUICustomizeCat_ArmorPatterns, 0, itemIndex);
}

// --------------------------------------------------------------------------
simulated function CustomizeTorso()
{
	CustomizeManager.UpdateCamera();
	Movie.Pres.UICustomize_Trait(m_strTorso, "", CustomizeManager.GetCategoryList(eUICustomizeCat_Torso),
		ChangeTorso, ChangeTorso, CanCycleTo, CustomizeManager.GetCategoryIndex(eUICustomizeCat_Torso));
}
simulated function ChangeTorso(UIList _list, int itemIndex)
{
	CustomizeManager.OnCategoryValueChange(eUICustomizeCat_Torso, 0, itemIndex);
}

// --------------------------------------------------------------------------
simulated function CustomizeTorsoDeco()
{
	CustomizeManager.UpdateCamera();
	Movie.Pres.UICustomize_Trait(m_strTorsoDeco, "", CustomizeManager.GetCategoryList(eUICustomizeCat_TorsoDeco),
		ChangeTorsoDeco, ChangeTorsoDeco, CanCycleTo, CustomizeManager.GetCategoryIndex(eUICustomizeCat_TorsoDeco));
}
simulated function ChangeTorsoDeco(UIList _list, int itemIndex)
{
	CustomizeManager.OnCategoryValueChange(eUICustomizeCat_TorsoDeco, 0, itemIndex);
}

// --------------------------------------------------------------------------
simulated function CustomizeLegs()
{
	CustomizeManager.UpdateCamera(eUICustomizeCat_Legs);
	Movie.Pres.UICustomize_Trait(m_strLegs, "", CustomizeManager.GetCategoryList(eUICustomizeCat_Legs),
		ChangeLegs, ChangeLegs, CanCycleTo, CustomizeManager.GetCategoryIndex(eUICustomizeCat_Legs));

	UICustomize_Trait(Movie.Pres.ScreenStack.GetCurrentScreen()).CameraTag = "UIBlueprint_CustomizeLegs";
	UICustomize_Trait(Movie.Pres.ScreenStack.GetCurrentScreen()).DisplayTag = 'UIBlueprint_CustomizeLegs';
}
simulated function ChangeLegs(UIList _list, int itemIndex)
{
	CustomizeManager.OnCategoryValueChange(eUICustomizeCat_Legs, 0, itemIndex);
}

// --------------------------------------------------------------------------
simulated function CustomizeThighs()
{
	CustomizeManager.UpdateCamera(eUICustomizeCat_Thighs);
	Movie.Pres.UICustomize_Trait(m_strThighs, "", CustomizeManager.GetCategoryList(eUICustomizeCat_Thighs),
		ChangeThighs, ChangeThighs, CanCycleTo, CustomizeManager.GetCategoryIndex(eUICustomizeCat_Thighs));

	UICustomize_Trait(Movie.Pres.ScreenStack.GetCurrentScreen()).CameraTag = "UIBlueprint_CustomizeLegs";
	UICustomize_Trait(Movie.Pres.ScreenStack.GetCurrentScreen()).DisplayTag = 'UIBlueprint_CustomizeLegs';
}
simulated function ChangeThighs(UIList _list, int itemIndex)
{
	CustomizeManager.OnCategoryValueChange(eUICustomizeCat_Thighs, 0, itemIndex);
}

// --------------------------------------------------------------------------
simulated function CustomizeShins()
{
	CustomizeManager.UpdateCamera(eUICustomizeCat_Shins);
	Movie.Pres.UICustomize_Trait(m_strShins, "", CustomizeManager.GetCategoryList(eUICustomizeCat_Shins),
		ChangeShins, ChangeShins, CanCycleTo, CustomizeManager.GetCategoryIndex(eUICustomizeCat_Shins));

	UICustomize_Trait(Movie.Pres.ScreenStack.GetCurrentScreen()).CameraTag = "UIBlueprint_CustomizeLegs";
	UICustomize_Trait(Movie.Pres.ScreenStack.GetCurrentScreen()).DisplayTag = 'UIBlueprint_CustomizeLegs';
}
simulated function ChangeShins(UIList _list, int itemIndex)
{
	CustomizeManager.OnCategoryValueChange(eUICustomizeCat_Shins, 0, itemIndex);
}
// --------------------------------------------------------------------------
simulated function CustomizeArms()
{
	CustomizeManager.UpdateCamera();
	Movie.Pres.UICustomize_Trait(m_strArms, "", CustomizeManager.GetCategoryList(eUICustomizeCat_Arms),
		ChangeArms, ChangeArms, CanCycleTo, CustomizeManager.GetCategoryIndex(eUICustomizeCat_Arms));
}
simulated function ChangeArms(UIList _list, int itemIndex)
{
	CustomizeManager.OnCategoryValueChange(eUICustomizeCat_Arms, 0, itemIndex);
}

simulated function CustomizeLeftArm()
{
	CustomizeManager.UpdateCamera();
	Movie.Pres.UICustomize_Trait(m_strLeftArm, "", CustomizeManager.GetCategoryList(eUICustomizeCat_LeftArm),
		ChangeLeftArm, ChangeLeftArm, CanCycleTo, CustomizeManager.GetCategoryIndex(eUICustomizeCat_LeftArm));
}
simulated function ChangeLeftArm(UIList _list, int itemIndex)
{
	CustomizeManager.OnCategoryValueChange(eUICustomizeCat_LeftArm, 0, itemIndex);
}

simulated function CustomizeRightArm()
{
	CustomizeManager.UpdateCamera();
	Movie.Pres.UICustomize_Trait(m_strRightArm, "", CustomizeManager.GetCategoryList(eUICustomizeCat_RightArm),
		ChangeRightArm, ChangeRightArm, CanCycleTo, CustomizeManager.GetCategoryIndex(eUICustomizeCat_RightArm));
}
simulated function ChangeRightArm(UIList _list, int itemIndex)
{
	CustomizeManager.OnCategoryValueChange(eUICustomizeCat_RightArm, 0, itemIndex);
}

simulated function CustomizeLeftArmDeco()
{
	CustomizeManager.UpdateCamera();
	Movie.Pres.UICustomize_Trait(m_strLeftArmDeco, "", CustomizeManager.GetCategoryList(eUICustomizeCat_LeftArmDeco),
		ChangeLeftArmDeco, ChangeLeftArmDeco, CanCycleTo, CustomizeManager.GetCategoryIndex(eUICustomizeCat_LeftArmDeco));
}
simulated function ChangeLeftArmDeco(UIList _list, int itemIndex)
{
	CustomizeManager.OnCategoryValueChange(eUICustomizeCat_LeftArmDeco, 0, itemIndex);
}

simulated function CustomizeRightArmDeco()
{
	CustomizeManager.UpdateCamera();
	Movie.Pres.UICustomize_Trait(m_strRightArmDeco, "", CustomizeManager.GetCategoryList(eUICustomizeCat_RightArmDeco),
		ChangeRightArmDeco, ChangeRightArmDeco, CanCycleTo, CustomizeManager.GetCategoryIndex(eUICustomizeCat_RightArmDeco));
}
simulated function ChangeRightArmDeco(UIList _list, int itemIndex)
{
	CustomizeManager.OnCategoryValueChange(eUICustomizeCat_RightArmDeco, 0, itemIndex);
}

simulated function CustomizeLeftForearm()
{
	CustomizeManager.UpdateCamera();
	Movie.Pres.UICustomize_Trait(m_strLeftForearm, "", CustomizeManager.GetCategoryList(eUICustomizeCat_LeftForearm),
		ChangeLeftForearm, ChangeLeftForearm, CanCycleTo, CustomizeManager.GetCategoryIndex(eUICustomizeCat_LeftForearm));
}
simulated function ChangeLeftForearm(UIList _list, int itemIndex)
{
	CustomizeManager.OnCategoryValueChange(eUICustomizeCat_LeftForearm, 0, itemIndex);
}

simulated function CustomizeRightForearm()
{
	CustomizeManager.UpdateCamera();
	Movie.Pres.UICustomize_Trait(m_strRightForearm, "", CustomizeManager.GetCategoryList(eUICustomizeCat_RightForearm),
		ChangeRightForearm, ChangeRightForearm, CanCycleTo, CustomizeManager.GetCategoryIndex(eUICustomizeCat_RightForearm));
}
simulated function ChangeRightForearm(UIList _list, int itemIndex)
{
	CustomizeManager.OnCategoryValueChange(eUICustomizeCat_RightForearm, 0, itemIndex);
}
// ------------------------------------------------------------------------
simulated function CustomizeLeftArmTattoos()
{
	CustomizeManager.UpdateCamera();
	Movie.Pres.UICustomize_Trait(m_strTattoosLeft, "", CustomizeManager.GetCategoryList(eUICustomizeCat_LeftArmTattoos),
		ChangeTattoosLeftArm, ChangeTattoosLeftArm, CanCycleTo, CustomizeManager.GetCategoryIndex(eUICustomizeCat_LeftArmTattoos));
}
simulated function ChangeTattoosLeftArm(UIList _list, int itemIndex)
{
	CustomizeManager.OnCategoryValueChange(eUICustomizeCat_LeftArmTattoos, 0, itemIndex);
}
// ------------------------------------------------------------------------
simulated function CustomizeRightArmTattoos()
{
	CustomizeManager.UpdateCamera();
	Movie.Pres.UICustomize_Trait(m_strTattoosRight, "", CustomizeManager.GetCategoryList(eUICustomizeCat_RightArmTattoos),
		ChangeTattoosRightArm, ChangeTattoosRightArm, CanCycleTo, CustomizeManager.GetCategoryIndex(eUICustomizeCat_RightArmTattoos));
}
simulated function ChangeTattoosRightArm(UIList _list, int itemIndex)
{
	CustomizeManager.OnCategoryValueChange(eUICustomizeCat_RightArmTattoos, 0, itemIndex);
}
// --------------------------------------------------------------------------
reliable client function TattooColorSelector()
{
	CustomizeManager.UpdateCamera(eUICustomizeCat_TattooColor);
	ColorSelector = GetColorSelector(CustomizeManager.GetColorList(eUICustomizeCat_TattooColor),
		PreviewTattooColor, SetTattooColor, int(CustomizeManager.GetCategoryDisplay(eUICustomizeCat_TattooColor)));
	CustomizeManager.AccessedCategoryCheckDLC(eUICustomizeCat_TattooColor);
}
function PreviewTattooColor(int iColorIndex)
{
	CustomizeManager.OnCategoryValueChange(eUICustomizeCat_TattooColor, -1, iColorIndex);
}
function SetTattooColor(int iColorIndex)
{
	CustomizeManager.OnCategoryValueChange(eUICustomizeCat_TattooColor, -1, iColorIndex);
	UpdateData();
}