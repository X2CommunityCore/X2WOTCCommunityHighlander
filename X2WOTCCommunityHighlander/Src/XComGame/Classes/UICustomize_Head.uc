//---------------------------------------------------------------------------------------
//  FILE:    UICustomize_Head.uc
//  PURPOSE: Soldier gear options list. 
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class UICustomize_Head extends UICustomize;

var localized string m_strTitle;
var localized string m_strUpperFaceProps;
var localized string m_strLowerFaceProps;
var localized string m_strHelmet;
var localized string m_strScars;
var localized string m_strClearButton;
var localized string m_strFacePaint;
var localized string m_strHair;
var localized string m_strHairColor;
var localized string m_strEyeColor;
var localized string m_strSkinColor;
var localized string m_strFacialHair;
var localized string m_strRace;
var localized string m_strFace;
var localized string m_strRemoveHelmetOrLowerProp;
var localized string m_strChangeFace; // Issue #219

var const config name StandingStillAnimName;
//----------------------------------------------------------------------------
// FUNCTIONS

simulated function UpdateData()
{
	local int currentSel;
	currentSel = List.SelectedIndex;
	
	super.UpdateData();

	CreateDataListItems();

	if (currentSel > -1 && currentSel < List.ItemCount)
	{
		List.Navigator.SetSelected(List.GetItem(currentSel));
	}
	else
	{
		List.Navigator.SetSelected(List.GetItem(0));
	}

	if (CustomizeManager.ActorPawn != none)
	{
		IdleAnimName = StandingStillAnimName;

		// Play the "By The Book" idle to minimize character overlap with UI elements
		XComHumanPawn(CustomizeManager.ActorPawn).PlayHQIdleAnim(IdleAnimName);

		// Cache desired animation in case the pawn hasn't loaded the customization animation set
		XComHumanPawn(CustomizeManager.ActorPawn).CustomizationIdleAnim = IdleAnimName;
	}
}

simulated function CreateDataListItems()
{
	local EUIState ColorState;
	local bool bIsObstructed;
	local bool bIsSuppressed; // Issue #219, bIsSuppressed => bIsObstructed (implication)
	local int i;

	// FACE
	//-----------------------------------------------------------------------------------------
	ColorState = bIsSuperSoldier ? eUIState_Disabled : eUIState_Normal;
	GetListItem(i++)
		.UpdateDataValue(CustomizeManager.CheckForAttentionIcon(eUICustomizeCat_Face)$ m_strFace, CustomizeManager.FormatCategoryDisplay(eUICustomizeCat_Face, ColorState, FontSize), CustomizeFace)
		.SetDisabled(bIsSuperSoldier, m_strIsSuperSoldier);

	// HAIRSTYLE
	//-----------------------------------------------------------------------------------------
	bIsObstructed = XComHumanPawn(CustomizeManager.ActorPawn).SuppressHairstyle(); // Issue #219
	bIsSuppressed = class'CHHelpers'.default.HeadSuppressesHair.Find(XComHumanPawn(CustomizeManager.ActorPawn).HeadContent.Name) > INDEX_NONE; // Issue #219
	ColorState = (bIsSuperSoldier || bIsObstructed) ? eUIState_Disabled : eUIState_Normal;

	GetListItem(i++)
		.UpdateDataValue(CustomizeManager.CheckForAttentionIcon(eUICustomizeCat_Hairstyle)$ m_strHair, CustomizeManager.FormatCategoryDisplay(eUICustomizeCat_Hairstyle, ColorState, FontSize), CustomizeHair)
		.SetDisabled(bIsSuperSoldier || bIsObstructed, bIsSuperSoldier ? m_strIsSuperSoldier : (bIsSuppressed ? m_strChangeFace : m_strRemoveHelmet)); // Issue #219

	// HAIR COLOR
	//----------------------------------------------------------------------------------------
	// Start Issue #219
	bIsObstructed = XComHumanPawn(CustomizeManager.ActorPawn).SuppressHairstyle() &&
		(CustomizeManager.UpdatedUnitState.kAppearance.iGender == eGender_Female || XComHumanPawn(CustomizeManager.ActorPawn).SuppressBeard());
	bIsSuppressed = class'CHHelpers'.default.HeadSuppressesHair.Find(XComHumanPawn(CustomizeManager.ActorPawn).HeadContent.Name) > INDEX_NONE &&
		(CustomizeManager.UpdatedUnitState.kAppearance.iGender == eGender_Female || class'CHHelpers'.default.HeadSuppressesBeard.Find(XComHumanPawn(CustomizeManager.ActorPawn).HeadContent.Name) > INDEX_NONE);
	// End Issue #219
	ColorState = bIsObstructed ? eUIState_Disabled : eUIState_Normal;

	GetListItem(i++)
		.UpdateDataColorChip(CustomizeManager.CheckForAttentionIcon(eUICustomizeCat_HairColor)$ m_strHairColor, CustomizeManager.GetCurrentDisplayColorHTML(eUICustomizeCat_HairColor), HairColorSelector)
		.SetDisabled(bIsSuperSoldier || bIsObstructed, bIsSuperSoldier ? m_strIsSuperSoldier : (bIsSuppressed ? m_strChangeFace : m_strRemoveHelmet)); // Issue #219

	ColorState = bIsSuperSoldier ? eUIState_Disabled : eUIState_Normal;

	// EYE COLOR
	//-----------------------------------------------------------------------------------------
	GetListItem(i++)
		.UpdateDataColorChip(CustomizeManager.CheckForAttentionIcon(eUICustomizeCat_EyeColor)$m_strEyeColor, CustomizeManager.GetCurrentDisplayColorHTML(eUICustomizeCat_EyeColor), EyeColorSelector)
		.SetDisabled(bIsSuperSoldier, m_strIsSuperSoldier);

	// RACE
	//-----------------------------------------------------------------------------------------
	GetListItem(i++)
		.UpdateDataValue(CustomizeManager.CheckForAttentionIcon(eUICustomizeCat_Race)$ m_strRace, CustomizeManager.FormatCategoryDisplay(eUICustomizeCat_Race, ColorState, FontSize), CustomizeRace)
		.SetDisabled(bIsSuperSoldier, m_strIsSuperSoldier);

	// SKIN COLOR
	//-----------------------------------------------------------------------------------------
	GetListItem(i++)
		.UpdateDataColorChip(CustomizeManager.CheckForAttentionIcon(eUICustomizeCat_Skin)$ m_strSkinColor, CustomizeManager.GetCurrentDisplayColorHTML(eUICustomizeCat_Skin), SkinColorSelector)
		.SetDisabled(bIsSuperSoldier, m_strIsSuperSoldier);

	// HELMET
	//-----------------------------------------------------------------------------------------
	bIsObstructed = XComHumanPawn(CustomizeManager.ActorPawn).SuppressHelmet(); // Issue #219
	GetListItem(i++)
		.UpdateDataValue(CustomizeManager.CheckForAttentionIcon(eUICustomizeCat_Helmet) $ m_strHelmet, CustomizeManager.FormatCategoryDisplay(eUICustomizeCat_Helmet, ColorState, FontSize), CustomizeHelmet)
		.SetDisabled(bIsSuperSoldier || bIsObstructed, bIsSuperSoldier ? m_strIsSuperSoldier : m_strChangeFace); // Issue #219

	// UPPER FACE PROPS
	//-----------------------------------------------------------------------------------------
	bIsObstructed = XComHumanPawn(CustomizeManager.ActorPawn).SuppressUpperFaceProp(); // Issue #219
	bIsSuppressed = class'CHHelpers'.default.HeadSuppressesUpperFaceProp.Find(XComHumanPawn(CustomizeManager.ActorPawn).HeadContent.Name) > INDEX_NONE; // Issue #219
	ColorState = bIsObstructed ? eUIState_Disabled : eUIState_Normal;

	GetListItem(i++, bIsObstructed, bIsSuppressed ? m_strChangeFace : m_strRemoveHelmet).UpdateDataValue(CustomizeManager.CheckForAttentionIcon(eUICustomizeCat_FaceDecorationUpper) $ m_strUpperFaceProps,
		CustomizeManager.FormatCategoryDisplay(eUICustomizeCat_FaceDecorationUpper, ColorState, FontSize), CustomizeUpperFaceProps); // Issue #219

	// LOWER FACE PROPS
	//-----------------------------------------------------------------------------------------
	bIsObstructed = XComHumanPawn(CustomizeManager.ActorPawn).SuppressLowerFaceProp(); // Issue #219
	bIsSuppressed = class'CHHelpers'.default.HeadSuppressesLowerFaceProp.Find(XComHumanPawn(CustomizeManager.ActorPawn).HeadContent.Name) > INDEX_NONE; // Issue #219
	ColorState = bIsObstructed ? eUIState_Disabled : eUIState_Normal;

	GetListItem(i++, bIsObstructed, bIsSuppressed ? m_strChangeFace : m_strRemoveHelmet).UpdateDataValue(CustomizeManager.CheckForAttentionIcon(eUICustomizeCat_FaceDecorationLower) $ m_strLowerFaceProps, // Issue #219
		CustomizeManager.FormatCategoryDisplay(eUICustomizeCat_FaceDecorationLower, ColorState, FontSize), CustomizeLowerFaceProps); 

	// FACIAL HAIR
	//-----------------------------------------------------------------------------------------
	if (CustomizeManager.ShowMaleOnlyOptions())
	{
		bIsObstructed = XComHumanPawn(CustomizeManager.ActorPawn).SuppressBeard(); // Issue #219
		bIsSuppressed = class'CHHelpers'.default.HeadSuppressesBeard.Find(XComHumanPawn(CustomizeManager.ActorPawn).HeadContent.Name) > INDEX_NONE; // Issue #219
		ColorState = (bIsSuperSoldier || bIsObstructed) ? eUIState_Disabled : eUIState_Normal;

		GetListItem(i++)
			.UpdateDataValue(CustomizeManager.CheckForAttentionIcon(eUICustomizeCat_FacialHair)$m_strFacialHair, CustomizeManager.FormatCategoryDisplay(eUICustomizeCat_FacialHair, ColorState, FontSize), CustomizeFacialHair)
			.SetDisabled(bIsSuperSoldier || bIsObstructed, bIsSuperSoldier ? m_strIsSuperSoldier : (bIsSuppressed ? m_strChangeFace : m_strRemoveHelmetOrLowerProp)); // Issue #219
	}

	// FACE PAINT
	//-----------------------------------------------------------------------------------------

	//Check whether any face paint is available...	
	if (CustomizeManager.HasPartsForPartType("Facepaint", `XCOMGAME.SharedBodyPartFilter.FilterAny))
	{
		GetListItem(i++).UpdateDataValue(CustomizeManager.CheckForAttentionIcon(eUICustomizeCat_FacePaint) $ m_strFacePaint,
			CustomizeManager.FormatCategoryDisplay(eUICustomizeCat_FacePaint, eUIState_Normal, FontSize), CustomizeFacePaint);
	}

	// SCARS (VETERAN ONLY)
	//-----------------------------------------------------------------------------------------
	GetListItem(i++, bDisableVeteranOptions).UpdateDataValue(CustomizeManager.CheckForAttentionIcon(eUICustomizeCat_Scars) $ m_strScars,
		CustomizeManager.FormatCategoryDisplay(eUICustomizeCat_Scars, ColorState, FontSize), CustomizeScars);

	if (!CustomizeManager.ShowMaleOnlyOptions())
	{
		//bsg-crobinson (5.23.17): If soldier is a female, remove an index to make up for the additional male index
		GetListItem(i--).Remove();
	}
}

// --------------------------------------------------------------------------
simulated function CustomizeFace()
{
	CustomizeManager.UpdateCamera(eUICustomizeCat_Face);
	Movie.Pres.UICustomize_Trait(m_strFace, "", CustomizeManager.GetCategoryList(eUICustomizeCat_Face),
		ChangeFace, ChangeFace, CanCycleTo, CustomizeManager.GetCategoryIndex(eUICustomizeCat_Face));

	UICustomize_Trait(Movie.Pres.ScreenStack.GetCurrentScreen()).bUsePersonalityAnim = false;

	UICustomize_Trait(Movie.Pres.ScreenStack.GetCurrentScreen()).CameraTag = "UIBlueprint_CustomizeHead";
	UICustomize_Trait(Movie.Pres.ScreenStack.GetCurrentScreen()).DisplayTag = 'UIBlueprint_CustomizeHead';
}
reliable client function ChangeFace(UIList _list, int itemIndex)
{
	CustomizeManager.OnCategoryValueChange(eUICustomizeCat_Face, 0, itemIndex);
}
// --------------------------------------------------------------------------
simulated function CustomizeHair()
{
	CustomizeManager.UpdateCamera(eUICustomizeCat_Hairstyle);
	Movie.Pres.UICustomize_Trait(m_strHair, "", CustomizeManager.GetCategoryList(eUICustomizeCat_Hairstyle),
		ChangeHair, ChangeHair, CanCycleTo, CustomizeManager.GetCategoryIndex(eUICustomizeCat_Hairstyle));

	UICustomize_Trait(Movie.Pres.ScreenStack.GetCurrentScreen()).bUsePersonalityAnim = false;

	UICustomize_Trait(Movie.Pres.ScreenStack.GetCurrentScreen()).CameraTag = "UIBlueprint_CustomizeHead";
	UICustomize_Trait(Movie.Pres.ScreenStack.GetCurrentScreen()).DisplayTag = 'UIBlueprint_CustomizeHead';
}
reliable client function ChangeHair(UIList _list, int itemIndex)
{
	CustomizeManager.OnCategoryValueChange(eUICustomizeCat_Hairstyle, 0, itemIndex);
}
// --------------------------------------------------------------------------
simulated function CustomizeFacialHair()
{
	CustomizeManager.UpdateCamera(eUICustomizeCat_FacialHair);
	Movie.Pres.UICustomize_Trait(m_strFacialHair, "", CustomizeManager.GetCategoryList(eUICustomizeCat_FacialHair),
		ChangeFacialHair, ChangeFacialHair, CanCycleTo, CustomizeManager.GetCategoryIndex(eUICustomizeCat_FacialHair));

	UICustomize_Trait(Movie.Pres.ScreenStack.GetCurrentScreen()).bUsePersonalityAnim = false;

	UICustomize_Trait(Movie.Pres.ScreenStack.GetCurrentScreen()).CameraTag = "UIBlueprint_CustomizeHead";
	UICustomize_Trait(Movie.Pres.ScreenStack.GetCurrentScreen()).DisplayTag = 'UIBlueprint_CustomizeHead';
}
reliable client function ChangeFacialHair(UIList _list, int itemIndex)
{
	CustomizeManager.OnCategoryValueChange(eUICustomizeCat_FacialHair, 0, itemIndex);
}
// --------------------------------------------------------------------------
simulated function CustomizeRace()
{
	CustomizeManager.UpdateCamera(eUICustomizeCat_Race);
	Movie.Pres.UICustomize_Trait(m_strRace, "", CustomizeManager.GetCategoryList(eUICustomizeCat_Race),
		ChangeRace, ChangeRace, CanCycleTo, CustomizeManager.GetCategoryIndex(eUICustomizeCat_Race));

	UICustomize_Trait(Movie.Pres.ScreenStack.GetCurrentScreen()).bUsePersonalityAnim = false;

	UICustomize_Trait(Movie.Pres.ScreenStack.GetCurrentScreen()).CameraTag = "UIBlueprint_CustomizeHead";
	UICustomize_Trait(Movie.Pres.ScreenStack.GetCurrentScreen()).DisplayTag = 'UIBlueprint_CustomizeHead';
}
reliable client function ChangeRace(UIList _list, int itemIndex)
{
	CustomizeManager.OnCategoryValueChange(eUICustomizeCat_Race, 0, itemIndex);
}
// ------------------------------------------------------------------------
reliable client function SkinColorSelector()
{
	CustomizeManager.UpdateCamera(eUICustomizeCat_Skin);
	ColorSelector = GetColorSelector(CustomizeManager.GetColorList(eUICustomizeCat_Skin),
		PreviewSkinColor, SetSkinColor, int(CustomizeManager.GetCategoryDisplay(eUICustomizeCat_Skin)));
}
function PreviewSkinColor(int iColorIndex)
{
	CustomizeManager.OnCategoryValueChange(eUICustomizeCat_Skin, -1, iColorIndex);
}
function SetSkinColor(int iColorIndex)
{
	CustomizeManager.OnCategoryValueChange(eUICustomizeCat_Skin, -1, iColorIndex);
	UpdateData();
}
// --------------------------------------------------------------------------
simulated function EyeColorSelector()
{
	CustomizeManager.UpdateCamera(eUICustomizeCat_EyeColor);
	ColorSelector = GetColorSelector(CustomizeManager.GetColorList(eUICustomizeCat_EyeColor),
		PreviewEyeColor, SetEyeColor, int(CustomizeManager.GetCategoryDisplay(eUICustomizeCat_EyeColor)));

	CustomizeManager.AccessedCategoryCheckDLC(eUICustomizeCat_EyeColor);
}
simulated function PreviewEyeColor(int iIndex)
{
	CustomizeManager.OnCategoryValueChange(eUICustomizeCat_EyeColor, -1, iIndex);
}
simulated function SetEyeColor(int iIndex)
{
	CustomizeManager.OnCategoryValueChange(eUICustomizeCat_EyeColor, -1, iIndex);
	UpdateData();
}
// --------------------------------------------------------------------------
reliable client function HairColorSelector()
{
	CustomizeManager.UpdateCamera(eUICustomizeCat_HairColor);
	ColorSelector = GetColorSelector(CustomizeManager.GetColorList(eUICustomizeCat_HairColor),
		PreviewHairColor, SetHairColor, int(CustomizeManager.GetCategoryDisplay(eUICustomizeCat_HairColor)));
}
function PreviewHairColor(int iColorIndex)
{
	CustomizeManager.OnCategoryValueChange(eUICustomizeCat_HairColor, -1, iColorIndex);
}
function SetHairColor(int iColorIndex)
{
	CustomizeManager.OnCategoryValueChange(eUICustomizeCat_HairColor, -1, iColorIndex);
	UpdateData();
}

// ------------------------------------------------------------------------
simulated function CustomizeHelmet()
{
	CustomizeManager.UpdateCamera(eUICustomizeCat_Helmet);
	Movie.Pres.UICustomize_Trait(m_strHelmet, "", CustomizeManager.GetCategoryList(eUICustomizeCat_Helmet),
		ChangeHelmet, ChangeHelmet, CanCycleTo, CustomizeManager.GetCategoryIndex(eUICustomizeCat_Helmet));

	UICustomize_Trait(Movie.Pres.ScreenStack.GetCurrentScreen()).bUsePersonalityAnim = false;

	UICustomize_Trait(Movie.Pres.ScreenStack.GetCurrentScreen()).CameraTag = "UIBlueprint_CustomizeHead";
	UICustomize_Trait(Movie.Pres.ScreenStack.GetCurrentScreen()).DisplayTag = 'UIBlueprint_CustomizeHead';
}

simulated function ChangeHelmet(UIList _list, int itemIndex)
{
	CustomizeManager.OnCategoryValueChange(eUICustomizeCat_Helmet, 0, itemIndex);
}
// ------------------------------------------------------------------------
simulated function CustomizeFacePaint()
{
	CustomizeManager.UpdateCamera(eUICustomizeCat_FacePaint);
	Movie.Pres.UICustomize_Trait(m_strFacePaint, "", CustomizeManager.GetCategoryList(eUICustomizeCat_FacePaint),
		ChangeFacePaint, ChangeFacePaint, CanCycleTo, CustomizeManager.GetCategoryIndex(eUICustomizeCat_FacePaint));

	UICustomize_Trait(Movie.Pres.ScreenStack.GetCurrentScreen()).bUsePersonalityAnim = false;

	UICustomize_Trait(Movie.Pres.ScreenStack.GetCurrentScreen()).CameraTag = "UIBlueprint_CustomizeHead";
	UICustomize_Trait(Movie.Pres.ScreenStack.GetCurrentScreen()).DisplayTag = 'UIBlueprint_CustomizeHead';
}
simulated function ChangeFacePaint(UIList _list, int itemIndex)
{
	CustomizeManager.OnCategoryValueChange(eUICustomizeCat_FacePaint, 0, itemIndex);
}
// ------------------------------------------------------------------------
simulated function CustomizeScars()
{
	CustomizeManager.UpdateCamera(eUICustomizeCat_Scars);
	Movie.Pres.UICustomize_Trait(m_strScars, "", CustomizeManager.GetCategoryList(eUICustomizeCat_Scars),
		ChangeScars, ChangeScars, CanCycleTo, CustomizeManager.GetCategoryIndex(eUICustomizeCat_Scars));

	UICustomize_Trait(Movie.Pres.ScreenStack.GetCurrentScreen()).bUsePersonalityAnim = false;

	UICustomize_Trait(Movie.Pres.ScreenStack.GetCurrentScreen()).CameraTag = "UIBlueprint_CustomizeHead";
	UICustomize_Trait(Movie.Pres.ScreenStack.GetCurrentScreen()).DisplayTag = 'UIBlueprint_CustomizeHead';
}
simulated function ChangeScars(UIList _list, int itemIndex)
{
	CustomizeManager.OnCategoryValueChange(eUICustomizeCat_Scars, 0, itemIndex);
}
// --------------------------------------------------------------------------
simulated function CustomizeUpperFaceProps()
{
	CustomizeManager.UpdateCamera(eUICustomizeCat_FaceDecorationUpper);
	Movie.Pres.UICustomize_Trait(m_strUpperFaceProps, "", CustomizeManager.GetCategoryList(eUICustomizeCat_FaceDecorationUpper),
		ChangeFaceUpperProps, ChangeFaceUpperProps, CanCycleTo, CustomizeManager.GetCategoryIndex(eUICustomizeCat_FaceDecorationUpper));

	UICustomize_Trait(Movie.Pres.ScreenStack.GetCurrentScreen()).bUsePersonalityAnim = false;
	UICustomize_Trait(Movie.Pres.ScreenStack.GetCurrentScreen()).CameraTag = "UIBlueprint_CustomizeHead";
	UICustomize_Trait(Movie.Pres.ScreenStack.GetCurrentScreen()).DisplayTag = 'UIBlueprint_CustomizeHead';
}
simulated function ChangeFaceUpperProps(UIList _list, int itemIndex)
{
	CustomizeManager.OnCategoryValueChange(eUICustomizeCat_FaceDecorationUpper, 0, itemIndex);
}
// --------------------------------------------------------------------------
simulated function CustomizeLowerFaceProps()
{
	CustomizeManager.UpdateCamera(eUICustomizeCat_FaceDecorationLower);
	Movie.Pres.UICustomize_Trait(m_strLowerFaceProps, "", CustomizeManager.GetCategoryList(eUICustomizeCat_FaceDecorationLower),
		ChangeFaceLowerProps, ChangeFaceLowerProps, CanCycleTo, CustomizeManager.GetCategoryIndex(eUICustomizeCat_FaceDecorationLower));

	UICustomize_Trait(Movie.Pres.ScreenStack.GetCurrentScreen()).CameraTag = "UIBlueprint_CustomizeHead";
	UICustomize_Trait(Movie.Pres.ScreenStack.GetCurrentScreen()).DisplayTag = 'UIBlueprint_CustomizeHead';
}
simulated function ChangeFaceLowerProps(UIList _list, int itemIndex)
{
	CustomizeManager.OnCategoryValueChange(eUICustomizeCat_FaceDecorationLower, 0, itemIndex);
}
//==============================================================================

defaultproperties
{
	CameraTag = "UIBlueprint_CustomizeHead";
	DisplayTag = "UIBlueprint_CustomizeHead";
	bUsePersonalityAnim = false;
}