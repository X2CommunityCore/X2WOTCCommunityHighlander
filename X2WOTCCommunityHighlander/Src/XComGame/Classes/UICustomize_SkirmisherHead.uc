//---------------------------------------------------------------------------------------
//  FILE:    UICustomize_SkirmisherHead.uc
//  PURPOSE: Skirmisher head options list. 
//---------------------------------------------------------------------------------------
//  Copyright (c) 2017 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class UICustomize_SkirmisherHead extends UICustomize_Head;

//----------------------------------------------------------------------------
// FUNCTIONS

simulated function CreateDataListItems()
{
	local EUIState ColorState;
	local bool bIsObstructed;
	local bool bIsSuppressed; // Issue #219, bIsSuppressed => bIsObstructed (implication)
	local int i;

	// Start Issue #219
	if (CustomizeManager.HasMultipleCustomizationOptions(eUICustomizeCat_Face))
	{
		// FACE
		//-----------------------------------------------------------------------------------------
		ColorState = bIsSuperSoldier ? eUIState_Disabled : eUIState_Normal;
		GetListItem(i++)
			.UpdateDataValue(CustomizeManager.CheckForAttentionIcon(eUICustomizeCat_Face)$ m_strFace, CustomizeManager.FormatCategoryDisplay(eUICustomizeCat_Face, ColorState, FontSize), CustomizeFace)
			.SetDisabled(bIsSuperSoldier, m_strIsSuperSoldier);
	}
	// End Issue #219

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

	// LOWER FACE PROPS
	//-----------------------------------------------------------------------------------------
	bIsObstructed = XComHumanPawn(CustomizeManager.ActorPawn).SuppressLowerFaceProp(); // Issue #219
	bIsSuppressed = class'CHHelpers'.default.HeadSuppressesLowerFaceProp.Find(XComHumanPawn(CustomizeManager.ActorPawn).HeadContent.Name) > INDEX_NONE; // Issue #219
	ColorState = bIsObstructed ? eUIState_Disabled : eUIState_Normal;

	GetListItem(i++, bIsObstructed, bIsSuppressed ? m_strChangeFace : m_strRemoveHelmet).UpdateDataValue(CustomizeManager.CheckForAttentionIcon(eUICustomizeCat_FaceDecorationLower) $ m_strLowerFaceProps, // Issue #219
		CustomizeManager.FormatCategoryDisplay(eUICustomizeCat_FaceDecorationLower, ColorState, FontSize), CustomizeLowerFaceProps);

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
}