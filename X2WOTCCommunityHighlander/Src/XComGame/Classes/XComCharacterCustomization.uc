//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    XComCharacterCustomization.uc
//  AUTHOR:  Brit Steiner 9/15/2014
//  PURPOSE: Container of static helper functions for customizing character screens 
//			 and visual updates. 
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class XComCharacterCustomization extends Object
	dependson(XComOnlineProfileSettingsDataBlob)
	config(UI);

const FIRST_NAME_MAX_CHARS      = 11;
const NICKNAME_NAME_MAX_CHARS   = 11;
const LAST_NAME_MAX_CHARS       = 15;

var const config name StandingStillAnimName;
var const config float UIColorBrightnessAdjust;

enum EUICustomizeCategory
{
	eUICustomizeCat_FirstName,
	eUICustomizeCat_LastName,
	eUICustomizeCat_NickName,
	eUICustomizeCat_WeaponName,
	eUICustomizeCat_Torso,
	eUICustomizeCat_Arms,
	eUICustomizeCat_Legs,
	eUICustomizeCat_Skin,
	eUICustomizeCat_Face,
	eUICustomizeCat_EyeColor,
	eUICustomizeCat_Hairstyle,
	eUICustomizeCat_HairColor,
	eUICustomizeCat_FaceDecorationUpper,
	eUICustomizeCat_FaceDecorationLower,
	eUICustomizeCat_FacialHair,
	eUICustomizeCat_Personality,
	eUICustomizeCat_Country,
	eUICustomizeCat_Voice,
	eUICustomizeCat_Gender,
	eUICustomizeCat_Race,
	eUICustomizeCat_Helmet,
	eUICustomizeCat_PrimaryArmorColor,
	eUICustomizeCat_SecondaryArmorColor,
	eUICustomizeCat_WeaponColor,
	eUICustomizeCat_ArmorPatterns,
	eUICustomizeCat_WeaponPatterns,
	eUICustomizeCat_LeftArmTattoos,
	eUICustomizeCat_RightArmTattoos,
	eUICustomizeCat_TattooColor,
	eUICustomizeCat_Scars,
	eUICustomizeCat_Class,
	eUICustomizeCat_ViewClass,
	eUICustomizeCat_AllowTypeSoldier,
	eUICustomizeCat_AllowTypeVIP,
	eUICustomizeCat_AllowTypeDarkVIP,
	eUICustomizeCat_FacePaint,
	eUICustomizeCat_DEV1,
	eUICustomizeCat_DEV2,
	eUICustomizeCat_LeftArm,
	eUICustomizeCat_RightArm,
	eUICustomizeCat_LeftArmDeco,
	eUICustomizeCat_RightArmDeco,
	eUICustomizeCat_LeftForearm,
	eUICustomizeCat_RightForearm,
	eUICustomizeCat_Thighs,
	eUICustomizeCat_Shins,
	eUICustomizeCat_TorsoDeco,
};
enum ENameCustomizationOptions
{
	eCustomizeName_First,
	eCustomizeName_Last,
	eCustomizeName_Nick,
};

var name LastSetCameraTag; //Let the system avoid resetting the currently set tag
var protectedwrite Actor ActorPawn;
var protectedwrite name PawnLocationTag;
var protectedwrite name RegularCameraTag;
var protectedwrite name RegularDisplayTag;
var protectedwrite name HeadCameraTag;
var protectedwrite name HeadDisplayTag;
var protectedwrite name LegsCameraTag;
var protectedwrite name LegsDisplayTag;

var protectedwrite float LargeUnitScale;

var private XComGameStateHistory History;
var private XComGameState CheckGameState;
var private X2BodyPartTemplateManager PartManager;
var protected X2SimpleBodyPartFilter BodyPartFilter;

var privatewrite StateObjectReference UnitRef;
var privatewrite XComGameState_Unit Unit;
var privatewrite XComGameState_Unit UpdatedUnitState;
// Start Issue #1089, unprivate
var /*privatewrite*/ XComGameState_Item PrimaryWeapon; 
var /*privatewrite*/ XComGameState_Item SecondaryWeapon;
var /*privatewrite*/ XComGameState_Item TertiaryWeapon;
// End Issue #1089
var privatewrite XComUnitPawn CosmeticUnit;

var privatewrite XGCharacterGenerator CharacterGenerator;

var privatewrite int m_iCustomizeNameType;

var localized string Gender_Male;
var localized string Gender_Female;
var localized string CustomizeFirstName;
var localized string CustomizeLastName;
var localized string CustomizeNickName;
var localized string CustomizeWeaponName;
var localized string RandomClass;
var localized string SoldierClass;

var XComOnlineProfileSettings m_kProfileSettings;

var array< delegate<GetIconsForBodyPartCallback> >  arrGetIconsForBodyPartDelegates;

delegate string GetIconsForBodyPartCallback(X2BodyPartTemplate BodyPart);

simulated function Init(XComGameState_Unit _Unit, optional Actor RequestedActorPawn = none, optional XComGameState gameState = none)
{
	History = `XCOMHISTORY;

	CheckGameState = gameState;

	Unit = _Unit;
	UpdatedUnitState = Unit;
	UnitRef = UpdatedUnitState.GetReference();
	
	PrimaryWeapon = XComGameState_Item(History.GetGameStateForObjectID(Unit.GetItemInSlot(eInvSlot_PrimaryWeapon).ObjectID));
	SecondaryWeapon = XComGameState_Item(History.GetGameStateForObjectID(Unit.GetItemInSlot(eInvSlot_SecondaryWeapon).ObjectID));
	TertiaryWeapon = XComGameState_Item(History.GetGameStateForObjectID(Unit.GetItemInSlot(eInvSlot_TertiaryWeapon).ObjectID));

	PartManager = class'X2BodyPartTemplateManager'.static.GetBodyPartTemplateManager();

	CharacterGenerator = `XCOMGAME.spawn( Unit.GetMyTemplate().CharacterGeneratorClass );

	BodyPartFilter = `XCOMGAME.SharedBodyPartFilter;
	
	ReCreatePawnVisuals(RequestedActorPawn);

	if (PartManager.DisablePostProcessWhenCustomizing)
	{
		class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController().ConsoleCommand("show postprocess");
	}

	m_kProfileSettings = `XPROFILESETTINGS;
	ConvertOldProfileCategoryAlerts();
}

simulated function Refresh(XComGameState_Unit PreviousUnit, XComGameState_Unit NewUnit)
{
	local Rotator UseRotation;

	//Commit changes to the previous unit
	if(PreviousUnit == Unit)
	{
		CommitChanges();
	}

	Unit = NewUnit;
	UpdatedUnitState = Unit;
	UnitRef = UpdatedUnitState.GetReference(); 

	UpdateBodyPartFilterForNewUnit(Unit);	

	PrimaryWeapon = XComGameState_Item(History.GetGameStateForObjectID(Unit.GetItemInSlot(eInvSlot_PrimaryWeapon).ObjectID));
	SecondaryWeapon = XComGameState_Item(History.GetGameStateForObjectID(Unit.GetItemInSlot(eInvSlot_SecondaryWeapon).ObjectID));
	TertiaryWeapon = XComGameState_Item(History.GetGameStateForObjectID(Unit.GetItemInSlot(eInvSlot_TertiaryWeapon).ObjectID));

	if(ActorPawn != None)
	{
		UseRotation = ActorPawn.Rotation;
	}
	else
	{
		UseRotation.Yaw = -16384;
	}

	XComPresentationLayerBase(Outer).GetUIPawnMgr().ReleasePawn(XComPresentationLayerBase(Outer), PreviousUnit.ObjectID, true);
	CreatePawnVisuals(UseRotation);
}

simulated function bool InShell()
{
	return XComShellPresentationLayer(Outer) != none;
}

function UpdateBodyPartFilterForNewUnit(XComGameState_Unit NewUnit)
{
	BodyPartFilter.Set(EGender(Unit.kAppearance.iGender), ECharacterRace(Unit.kAppearance.iRace), Unit.kAppearance.nmTorso, !Unit.IsSoldier(), Unit.IsVeteran() || InShell());
	BodyPartFilter.AddCharacterFilter(NewUnit.GetMyTemplateName(), NewUnit.GetMyTemplate().bHasCharacterExclusiveAppearance);
}

//BodyPartFilter.FilterAny
function bool HasPartsForPartType(string PartType, delegate<X2BodyPartFilter.FilterCallback> CallbackFn)
{
	local array<X2BodyPartTemplate> Templates;

	PartManager.GetFilteredUberTemplates(PartType, BodyPartFilter, CallbackFn, Templates);

	return Templates.Length > 0;
}

function bool HasMultiplePartsForPartType(string PartType, delegate<X2BodyPartFilter.FilterCallback> CallbackFn)
{
	local array<X2BodyPartTemplate> Templates;
	local int i;

	PartManager.GetFilteredUberTemplates(PartType, BodyPartFilter, CallbackFn, Templates);

	`log("BFL HasMultiplePartsForPartType : part type =" @ PartType @ ", num parts =" @ Templates.Length);

	for(i = 0; i < Templates.Length; i++)
	{
		`log("  template" @ i @ "=" @ Templates[i].DisplayName);
	}

	return Templates.Length > 1;
}

//==============================================================================
simulated function ReCreatePawnVisuals(optional Actor RequestedActorPawn, optional bool bForce)
{
	local Rotator UseRotation;

	if (RequestedActorPawn != none)
	{
		UseRotation = RequestedActorPawn.Rotation;
	}
	else if(ActorPawn != None)
	{
		UseRotation = ActorPawn.Rotation;
	}
	else
	{
		UseRotation.Yaw = -16384;
	}

	XComPresentationLayerBase(Outer).GetUIPawnMgr().ReleasePawn(XComPresentationLayerBase(Outer), UnitRef.ObjectID, bForce);
	CreatePawnVisuals(UseRotation);
}


simulated function OnPawnVisualsCreated(XComUnitPawn inPawn)
{
	local XComGameState_Item ItemState;
	local XComGameState TempGameState;
	local XComGameStateContext_ChangeContainer TempContainer;
	local XComLWTuple OverrideTuple; //for issue #229
	local float CustomScale; // issue #229
	
	ActorPawn = inPawn;

	ActorPawn.GotoState('CharacterCustomization');

	ItemState = UpdatedUnitState.GetItemInSlot(eInvSlot_PrimaryWeapon, CheckGameState);
	if (ItemState == none)
	{
		//This logic runs in the character pool - where the unit does not actually have a real load out. So we need to make one temporarily that the weapon visualization logic can use.
		TempContainer = class'XComGameStateContext_ChangeContainer'.static.CreateEmptyChangeContainer("Fake Loadout");
		TempGameState = History.CreateNewGameState(true, TempContainer);

		//Give the unit a loadout
		UpdatedUnitState.ApplyInventoryLoadout(TempGameState);

		//Add the state to the history so that the visualization functions can operate correctly
		History.AddGameStateToHistory(TempGameState);

		//Save off the weapon states so we can use them later
		PrimaryWeapon = UpdatedUnitState.GetItemInSlot(eInvSlot_PrimaryWeapon, TempGameState);
		SecondaryWeapon = UpdatedUnitState.GetItemInSlot(eInvSlot_SecondaryWeapon, TempGameState);
		TertiaryWeapon = UpdatedUnitState.GetItemInSlot(eInvSlot_TertiaryWeapon, TempGameState);

		//Create the visuals for the weapons, using the temp game state
		XComUnitPawn(ActorPawn).CreateVisualInventoryAttachments(XComPresentationLayerBase(Outer).GetUIPawnMgr(), UpdatedUnitState, TempGameState);

		//Manually set the secondary weapon to have the same appearance as the primary
		// Disabled this on 3-31-17 since some xpack secondary weapons need to derive color from the armor. This should be handled in XGWeapon. - jweinhoffer
		//XGWeapon(SecondaryWeapon.GetVisualizer()).SetAppearance(PrimaryWeapon.WeaponAppearance);

		//Destroy the temporary game state change that granted the unit a load out
		History.ObliterateGameStatesFromHistory(1);

		//Now clear the items from the unit so we don't accidentally save them
		UpdatedUnitState.EmptyInventoryItems();
	}
	else
	{
		PrimaryWeapon = ItemState;
		SecondaryWeapon = UpdatedUnitState.GetItemInSlot(eInvSlot_SecondaryWeapon, CheckGameState);
		TertiaryWeapon = UpdatedUnitState.GetItemInSlot(eInvSlot_TertiaryWeapon, CheckGameState);
		XComUnitPawn(ActorPawn).CreateVisualInventoryAttachments(XComPresentationLayerBase(Outer).GetUIPawnMgr(), UpdatedUnitState, CheckGameState);
	}

		//start issue #229: instead of boolean check, always trigger event to check if we should use custom unit scale.
	CustomScale = UpdatedUnitState.UseLargeArmoryScale() ? LargeUnitScale : 1.0f;
 	//set up a Tuple for return value
	OverrideTuple = new class'XComLWTuple';
	OverrideTuple.Id = 'OverrideCharCustomizationScale';
	OverrideTuple.Data.Add(3);
	OverrideTuple.Data[0].kind = XComLWTVBool;
	OverrideTuple.Data[0].b = false;
	OverrideTuple.Data[1].kind = XComLWTVFloat;
	OverrideTuple.Data[1].f = CustomScale;
	OverrideTuple.Data[2].kind = XComLWTVObject;
	OverrideTuple.Data[2].o = UpdatedUnitState;
	`XEVENTMGR.TriggerEvent('OverrideCharCustomizationScale', OverrideTuple, UpdatedUnitState, none);
	
	//if the unit should use the large armory scale by default, then either they'll use the default scale
	//or a custom one given by a mod according to their character template
	if(OverrideTuple.Data[0].b || UpdatedUnitState.UseLargeArmoryScale()) 
	{
		CustomScale = OverrideTuple.Data[1].f;
		XComUnitPawn(ActorPawn).Mesh.SetScale(CustomScale);
	}
	//end issue #229
	
}

simulated function CreatePawnVisuals(Rotator UseRotation)
{	
	local Vector SpawnPawnLocation;
	local name LocationName;
	local PointInSpace PlacementActor;

	LocationName = 'UIPawnLocation_Armory';
	foreach XComPresentationLayerBase(Outer).WorldInfo.AllActors(class'PointInSpace', PlacementActor)
	{
		if (PlacementActor != none && PlacementActor.Tag == LocationName)
			break;
	}

	SpawnPawnLocation = PlacementActor.Location;

	ActorPawn = XComPresentationLayerBase(Outer).GetUIPawnMgr().RequestPawnByState(XComPresentationLayerBase(Outer), UpdatedUnitState, SpawnPawnLocation, UseRotation, OnPawnVisualsCreated);	
}
//==============================================================================

simulated function EditText(int iType)
{
	local string NameToShow; 

	switch(iType)
	{
	case eUICustomizeCat_FirstName:
		NameToShow = UpdatedUnitState.GetFirstName(); 
		OpenNameInputBox(iType, CustomizeFirstName, NameToShow, FIRST_NAME_MAX_CHARS);
		break;
	case eUICustomizeCat_LastName:
		NameToShow = UpdatedUnitState.GetLastName(); 
		OpenNameInputBox(iType, CustomizeLastName, NameToShow, LAST_NAME_MAX_CHARS);
		break;
	case eUICustomizeCat_NickName:
		NameToShow = UpdatedUnitState.GetNickName(true); 
		OpenNameInputBox(iType, CustomizeNickName, NameToShow, NICKNAME_NAME_MAX_CHARS);
		break;
	case eUICustomizeCat_WeaponName:
		NameToShow = UpdatedUnitState.GetItemInSlot(eInvSlot_PrimaryWeapon, CheckGameState).Nickname; 
		OpenNameInputBox(iType, CustomizeWeaponName, NameToShow, NICKNAME_NAME_MAX_CHARS);
		break;
	}
}

simulated function OpenNameInputBox(int optionIndex, string title, string text, int maxCharacters)
{
	local TInputDialogData kData;

	m_iCustomizeNameType = optionIndex;

	//if(!`GAMECORE.WorldInfo.IsConsoleBuild() || `ISCONTROLLERACTIVE )
	//{
		kData.strTitle = title;
		kData.iMaxChars = maxCharacters;
		kData.strInputBoxText = text;
		kData.fnCallback = OnNameInputBoxClosed;

		XComPresentationLayerBase(Outer).UIInputDialog(kData);
/*	}
	else
	{
		XComPresentationLayerBase(Outer).UIKeyboard( title, 
			text, 
			VirtualKeyboard_OnNameInputBoxAccepted, 
			VirtualKeyboard_OnNameInputBoxCancelled,
			false, 
			maxCharacters
		);
	}*/
}

// TEXT INPUT BOX (PC)
function OnNameInputBoxClosed(string text)
{
	local UICustomize CustomizeScreen;

	if(text != "" || m_iCustomizeNameType == eCustomizeName_Nick)
	{
		switch(m_iCustomizeNameType)
		{
		case eCustomizeName_First:
			UpdatedUnitState.SetUnitName(text, UpdatedUnitState.GetLastName(), UpdatedUnitState.GetNickName(true));
			break;
		case eCustomizeName_Last:
			UpdatedUnitState.SetUnitName(UpdatedUnitState.GetFirstName(), text, UpdatedUnitState.GetNickName(true));
			break;
		case eCustomizeName_Nick:
			UpdatedUnitState.SetUnitName(UpdatedUnitState.GetFirstName(), UpdatedUnitState.GetLastName(), text);
			break;
		case eUICustomizeCat_WeaponName:
			// TODO: Implement functionality
			`RedScreen("Weapon naming functionality not yet implemented");
			break;
		}

		//If we are in the strategy game...
		if(`GAME != none)
		{
			`ONLINEEVENTMGR.EvalName(UpdatedUnitState);
		}
	}

	m_iCustomizeNameType = -1; 

	// Update the soldier header on the current screen - sbatista
	CustomizeScreen = UICustomize(`SCREENSTACK.GetFirstInstanceOf(class'UICustomize'));
	if(CustomizeScreen != none)
		CustomizeScreen.Header.PopulateData(UpdatedUnitState);
}
function VirtualKeyboard_OnNameInputBoxAccepted(string text, bool bWasSuccessful)
{
	OnNameInputBoxClosed(bWasSuccessful ? text : "");
}

function VirtualKeyboard_OnNameInputBoxCancelled()
{
	OnNameInputBoxClosed("");
}
//==============================================================================

simulated function int DevNextIndex(int index, int direction, out array<X2BodyPartTemplate> ArmorParts)
{
	if (ArmorParts.Length == 0)
		return INDEX_NONE;

	return WrapIndex(index + direction, 0, ArmorParts.Length);
}

simulated function int DevPartIndex( name PartName, array<X2DataTemplate> Parts)
{
	local int PartIndex;

	for( PartIndex = 0; PartIndex < Parts.Length; ++PartIndex )
	{
		if( PartName == Parts[PartIndex].DataName )
		{
			break;
		}
	}

	return PartIndex;
}

//==============================================================================

function UpdateCategory( string BodyPartType, int direction, delegate<X2BodyPartFilter.FilterCallback> FilterFn, out name Part, optional int specificIndex = -1)
{
	local int categoryValue;
	local int newIndex;
	local array<X2BodyPartTemplate> BodyParts;

	PartManager.GetFilteredUberTemplates(BodyPartType, BodyPartFilter, FilterFn, BodyParts);

	if( specificIndex != -1 ) 
	{
		newIndex = WrapIndex(specificIndex, 0, BodyParts.Length);
	}
	else
	{
		categoryValue = DevPartIndex(Part, BodyParts);
		newIndex = DevNextIndex(categoryValue, direction, BodyParts);
	}
	Part = BodyParts[newIndex].DataName;

	XComHumanPawn(ActorPawn).SetAppearance(UpdatedUnitState.kAppearance);
	UpdatedUnitState.StoreAppearance();
}

function UpdateCategorySimple( string BodyPartType, int direction, delegate<X2BodyPartFilter.FilterCallback> FilterFn, out name Part, optional int specificIndex = -1)
{
	CyclePartSimple(BodyPartType, direction, FilterFn, Part, specificIndex);
	XComHumanPawn(ActorPawn).SetAppearance(UpdatedUnitState.kAppearance);
	UpdatedUnitState.StoreAppearance();
}

function CyclePartSimple( string BodyPartType, int direction, delegate<X2BodyPartFilter.FilterCallback> FilterFn, out name Part, optional int specificIndex = -1)
{
	local int categoryValue;
	local int newIndex;
	local array<X2BodyPartTemplate> BodyParts;

	PartManager.GetFilteredUberTemplates(BodyPartType, self, FilterFn, BodyParts);

	if( specificIndex != -1 ) 
	{
		newIndex = WrapIndex(specificIndex, 0, BodyParts.Length);
	}
	else
	{
		categoryValue = DevPartIndex(Part, BodyParts);
		newIndex = WrapIndex(categoryValue + direction, 0, BodyParts.Length);
	}
	Part = BodyParts[newIndex].DataName;
}

//==============================================================================

//This method will check whether a given part selection is valid given the current torso.
function bool ValidatePartSelection(string PartType, name PartSelection)
{
	local array<X2BodyPartTemplate> BodyParts;
	local int Index;	

	//Retrieve a list of valid parts for the specified part type
	BodyPartFilter.Set(EGender(UpdatedUnitState.kAppearance.iGender), ECharacterRace(UpdatedUnitState.kAppearance.iRace), UpdatedUnitState.kAppearance.nmTorso, !UpdatedUnitState.IsSoldier(), UpdatedUnitState.IsVeteran() || InShell());
	PartManager.GetFilteredUberTemplates(PartType, BodyPartFilter, BodyPartFilter.FilterByTorsoAndArmorMatch, BodyParts);

	//See if the part selection is in the list of filtered templates. If it is, the part selection is valid.
	for(Index = 0; Index < BodyParts.Length; ++Index)
	{
		if(BodyParts[Index].DataName == PartSelection)
		{
			return true;
		}
	}
	
	return false;
}

// Start Issue #350, Enhanced version of above which also makes valid if possible. Less CopyPasta code then!
// Return indicates if it managed to make the part valid.
function bool MakePartValid(string PartType, out name PartSelection, optional bool BlankValid=true)
{
	local X2BodyPartTemplate BodyPart;

	if (!(PartSelection == '' && BlankValid || ValidatePartSelection(PartType, PartSelection)))
	{
		BodyPart = class'X2BodyPartTemplateManager'.static.GetBodyPartTemplateManager().GetRandomUberTemplate(PartType, BodyPartFilter, BodyPartFilter.FilterByTorsoAndArmorMatch);
		if(BodyPart != none)
		{
			PartSelection = BodyPart.DataName;
		}
		else
		{
			return false;
		}
	}
	return true;
}
// End Issue #350

// direction will either be -1 (left arrow), or 1 (right arrow)xcom
simulated function OnCategoryValueChange(int categoryIndex, int direction, optional int specificIndex = -1)
{	
	local int categoryValue;	
	local TSoldier NewSoldier;
	local TWeaponAppearance WeaponAppearance;	
	local TAppearance Appearance;
	local name RequestTemplate;
	local XComUnitPawn CosmeticUnitPawn;
	local X2BodyPartTemplate BodyPart;
	
	// player has moused out of list dont change current selection
	if (specificIndex == -1)
		return;

	//Set the body part filter with latest data so that the filters can operate	
	BodyPartFilter.Set(EGender(UpdatedUnitState.kAppearance.iGender), ECharacterRace(UpdatedUnitState.kAppearance.iRace), UpdatedUnitState.kAppearance.nmTorso, !UpdatedUnitState.IsSoldier(), UpdatedUnitState.IsVeteran() || InShell());

	switch(categoryIndex)
	{
	case eUICustomizeCat_Torso:       
		UpdateCategory("Torso", direction, BodyPartFilter.FilterByTorsoAndArmorMatch, UpdatedUnitState.kAppearance.nmTorso, specificIndex);
		// Start Issue #350
		MakePartValid("LeftArmDeco", UpdatedUnitState.kAppearance.nmLeftArmDeco); 
		MakePartValid("RightArmDeco", UpdatedUnitState.kAppearance.nmRightArmDeco); 
		MakePartValid("LeftForearm", UpdatedUnitState.kAppearance.nmLeftForearm); 
		MakePartValid("RightForearm", UpdatedUnitState.kAppearance.nmRightForearm); 
		MakePartValid("Legs", UpdatedUnitState.kAppearance.nmLegs, false); 
		MakePartValid("Thighs", UpdatedUnitState.kAppearance.nmThighs); 
		MakePartValid("Shins", UpdatedUnitState.kAppearance.nmShins); 
		MakePartValid("TorsoDeco", UpdatedUnitState.kAppearance.nmTorsoDeco); 
		if(UpdatedUnitState.kAppearance.nmArms != '')
		{
			if (!MakePartValid("Arms", UpdatedUnitState.kAppearance.nmArms, false))
			{
				if(MakePartValid("LeftArm", UpdatedUnitState.kAppearance.nmLeftArm, false) && MakePartValid("RightArm", UpdatedUnitState.kAppearance.nmRightArm, false))
				{
					UpdatedUnitState.kAppearance.nmArms = '';
				}
				else
				{
					// #350 It's possible it got a valid LeftArm but failed on the RightArm...
					UpdatedUnitState.kAppearance.nmLeftArm = '';
				}
			}
		}
		else
		{
			if (!(MakePartValid("LeftArm", UpdatedUnitState.kAppearance.nmLeftArm, false) && MakePartValid("RightArm", UpdatedUnitState.kAppearance.nmRightArm, false)))
			{
				if(MakePartValid("Arms", UpdatedUnitState.kAppearance.nmArms, false))
				{
					UpdatedUnitState.kAppearance.nmLeftArm = '';
					UpdatedUnitState.kAppearance.nmRightArm = '';
					// Start Issue #659, need the UI to blank out the ArmDecos since not hidden in Pawn again
					UpdatedUnitState.kAppearance.nmLeftArmDeco = '';
					UpdatedUnitState.kAppearance.nmRightArmDeco = '';
					// End Issue #659
				}
			}
			
		}
		// End Issue #350
		XComHumanPawn(ActorPawn).SetAppearance(UpdatedUnitState.kAppearance);
		UpdatedUnitState.StoreAppearance();
		break;
	case eUICustomizeCat_Arms:
		UpdateCategory("Arms", direction, BodyPartFilter.FilterByTorsoAndArmorMatch, UpdatedUnitState.kAppearance.nmArms, specificIndex);

		//Set individual arm options to none when setting dual arms
		UpdatedUnitState.kAppearance.nmLeftArm = '';
		UpdatedUnitState.kAppearance.nmRightArm = '';
		// Start Issue #350
		// Start Issue #659, need the UI to blank out the ArmDecos again
		UpdatedUnitState.kAppearance.nmLeftArmDeco = '';
		UpdatedUnitState.kAppearance.nmRightArmDeco = '';
		// End Issue #659
		//UpdatedUnitState.kAppearance.nmLeftForearm = '';
		//UpdatedUnitState.kAppearance.nmRightForearm = '';
		// End Issue #350
		XComHumanPawn(ActorPawn).SetAppearance(UpdatedUnitState.kAppearance);
		break;
	case eUICustomizeCat_LeftArm:
		UpdateCategory("LeftArm", direction, BodyPartFilter.FilterByTorsoAndArmorMatch, UpdatedUnitState.kAppearance.nmLeftArm, specificIndex);
		if(UpdatedUnitState.kAppearance.nmRightArm == '')
		{
			BodyPart = class'X2BodyPartTemplateManager'.static.GetBodyPartTemplateManager().GetRandomUberTemplate("RightArm", BodyPartFilter, BodyPartFilter.FilterByTorsoAndArmorMatch);
			if(BodyPart != none)
			{
				UpdatedUnitState.kAppearance.nmRightArm = BodyPart.DataName;
			}
		}		
		UpdatedUnitState.kAppearance.nmArms = ''; //Clear dual arms selection
		XComHumanPawn(ActorPawn).SetAppearance(UpdatedUnitState.kAppearance);
		UpdatedUnitState.StoreAppearance();
		break;
	case eUICustomizeCat_RightArm:
		UpdateCategory("RightArm", direction, BodyPartFilter.FilterByTorsoAndArmorMatch, UpdatedUnitState.kAppearance.nmRightArm, specificIndex);
		if(UpdatedUnitState.kAppearance.nmLeftArm == '')
		{
			BodyPart = class'X2BodyPartTemplateManager'.static.GetBodyPartTemplateManager().GetRandomUberTemplate("LeftArm", BodyPartFilter, BodyPartFilter.FilterByTorsoAndArmorMatch);
			if(BodyPart != none)
			{
				UpdatedUnitState.kAppearance.nmLeftArm = BodyPart.DataName;
			}
		}
		UpdatedUnitState.kAppearance.nmArms = ''; //Clear dual arms selection
		XComHumanPawn(ActorPawn).SetAppearance(UpdatedUnitState.kAppearance);
		UpdatedUnitState.StoreAppearance();
		break;
	case eUICustomizeCat_LeftArmDeco:
		UpdateCategory("LeftArmDeco", direction, BodyPartFilter.FilterByTorsoAndArmorMatch, UpdatedUnitState.kAppearance.nmLeftArmDeco, specificIndex);
		break;
	case eUICustomizeCat_RightArmDeco:
		UpdateCategory("RightArmDeco", direction, BodyPartFilter.FilterByTorsoAndArmorMatch, UpdatedUnitState.kAppearance.nmRightArmDeco, specificIndex);
		break;
	case eUICustomizeCat_LeftForearm:
		UpdateCategory("LeftForearm", direction, BodyPartFilter.FilterByTorsoAndArmorMatch, UpdatedUnitState.kAppearance.nmLeftForearm, specificIndex);
		break;
	case eUICustomizeCat_RightForearm:
		UpdateCategory("RightForearm", direction, BodyPartFilter.FilterByTorsoAndArmorMatch, UpdatedUnitState.kAppearance.nmRightForearm, specificIndex);
		break;
	case eUICustomizeCat_Legs:                  
		UpdateCategory("Legs", direction, BodyPartFilter.FilterByTorsoAndArmorMatch, UpdatedUnitState.kAppearance.nmLegs, specificIndex);
		break;
	case eUICustomizeCat_Thighs:
		UpdateCategory("Thighs", direction, BodyPartFilter.FilterByTorsoAndArmorMatch, UpdatedUnitState.kAppearance.nmThighs, specificIndex);
		break;
	case eUICustomizeCat_Shins:
		UpdateCategory("Shins", direction, BodyPartFilter.FilterByTorsoAndArmorMatch, UpdatedUnitState.kAppearance.nmShins, specificIndex);
		break;
	case eUICustomizeCat_TorsoDeco:
		UpdateCategory("TorsoDeco", direction, BodyPartFilter.FilterByTorsoAndArmorMatch, UpdatedUnitState.kAppearance.nmTorsoDeco, specificIndex);
		break;
	case eUICustomizeCat_Skin:
		UpdatedUnitState.kAppearance.iSkinColor = WrapIndex(specificIndex, 0, XComHumanPawn(ActorPawn).NumPossibleSkinColors);		
		XComHumanPawn(ActorPawn).SetAppearance(UpdatedUnitState.kAppearance);
		UpdatedUnitState.StoreAppearance();
		break;
	case eUICustomizeCat_Face:		
		UpdateCategorySimple("Head", direction, BodyPartFilter.FilterByGenderAndRaceAndCharacterAndClass, UpdatedUnitState.kAppearance.nmHead, specificIndex);
		break;
	case eUICustomizeCat_EyeColor:			
		UpdatedUnitState.kAppearance.iEyeColor = WrapIndex(specificIndex, 0, `CONTENT.GetColorPalette(ePalette_EyeColor).Entries.length);
		XComHumanPawn(ActorPawn).SetAppearance(UpdatedUnitState.kAppearance);
		UpdatedUnitState.StoreAppearance();
		break;
	case eUICustomizeCat_DEV1:				break; // TODO: update game data
	case eUICustomizeCat_DEV2:				break; // TODO: update game data
	case eUICustomizeCat_Hairstyle:	
		UpdateCategorySimple("Hair", direction, BodyPartFilter.FilterByGenderAndNonSpecialized, UpdatedUnitState.kAppearance.nmHaircut, specificIndex);
		break;
	case eUICustomizeCat_HairColor:	
		UpdatedUnitState.kAppearance.iHairColor = WrapIndex(specificIndex, 0, XComHumanPawn(ActorPawn).NumPossibleHairColors);	
		XComHumanPawn(ActorPawn).SetAppearance(UpdatedUnitState.kAppearance);
		UpdatedUnitState.StoreAppearance();
		break; 
	case eUICustomizeCat_FaceDecorationUpper:
		UpdateCategorySimple("FacePropsUpper", direction, BodyPartFilter.FilterByGenderAndNonSpecialized, UpdatedUnitState.kAppearance.nmFacePropUpper, specificIndex);
		break;
	case eUICustomizeCat_FaceDecorationLower:
		UpdateCategorySimple("FacePropsLower", direction, BodyPartFilter.FilterByGenderAndNonSpecialized, UpdatedUnitState.kAppearance.nmFacePropLower, specificIndex);
		break;
	case eUICustomizeCat_FacialHair:				 
		UpdateCategorySimple("Beards", direction, BodyPartFilter.FilterByGenderAndNonSpecialized, UpdatedUnitState.kAppearance.nmBeard, specificIndex);
		break;
	case eUICustomizeCat_Personality:				 
		if(specificIndex > -1)
		{
			UpdatedUnitState.kAppearance.iAttitude = specificIndex;
			UpdatedUnitState.UpdatePersonalityTemplate();
			XComHumanPawn(ActorPawn).PlayHQIdleAnim(, , true);
			UpdatedUnitState.StoreAppearance();
		}
		break;
	case eUICustomizeCat_Country:
		UpdateCountry(specificIndex);
		break;
	case eUICustomizeCat_Voice:
		UpdateCategorySimple("Voice", direction, BodyPartFilter.FilterByGenderAndCharacterAndNonSpecialized, UpdatedUnitState.kAppearance.nmVoice, specificIndex);
		XComHumanPawn(ActorPawn).SetVoice(UpdatedUnitState.kAppearance.nmVoice);
		UpdatedUnitState.StoreAppearance();
		break;
	case eUICustomizeCat_Gender:					 
		categoryValue = UpdatedUnitState.kAppearance.iGender;

		UpdatedUnitState.StoreAppearance();

		UpdatedUnitState.kAppearance.iGender = (EGender(specificIndex + 1) == eGender_Male )? eGender_Male : eGender_Female;

		// only update if the gender actually changed
		if (UpdatedUnitState.kAppearance.iGender != categoryValue)
		{
			//Weirdism of the CreateTSoldier interface: don't request a soldier template
			RequestTemplate = '';
			if( !UpdatedUnitState.IsSoldier() )
			{
				RequestTemplate = UpdatedUnitState.GetMyTemplateName();
			}

			//Gender re-assignment requires lots of changes...		
			NewSoldier = CharacterGenerator.CreateTSoldier(RequestTemplate, EGender(UpdatedUnitState.kAppearance.iGender), UpdatedUnitState.GetCountryTemplate().DataName, -1, UpdatedUnitState.GetItemInSlot(eInvSlot_Armor).GetMyTemplateName());

			// If the selected armor has a specific matching helmet, add it to the appearance
			BodyPartFilter.Set(EGender(NewSoldier.kAppearance.iGender), ECharacterRace(NewSoldier.kAppearance.iRace), NewSoldier.kAppearance.nmTorso, !UpdatedUnitState.IsSoldier(), UpdatedUnitState.IsVeteran() || InShell());
			BodyPart = class'X2BodyPartTemplateManager'.static.GetBodyPartTemplateManager().GetRandomUberTemplate("Helmets", BodyPartFilter, BodyPartFilter.FilterByTorsoAndArmorMatch);
			if (BodyPart != none)
			{
				NewSoldier.kAppearance.nmHelmet = BodyPart.DataName;
			}

			if (UpdatedUnitState.HasStoredAppearance(UpdatedUnitState.kAppearance.iGender))
			{
				UpdatedUnitState.GetStoredAppearance(NewSoldier.kAppearance, UpdatedUnitState.kAppearance.iGender);
			}

			UpdatedUnitState.SetTAppearance(NewSoldier.kAppearance);
		
			//Gender changes everything, so re-get all the pieces
			ReCreatePawnVisuals(ActorPawn, true);
		}

		//TODO category.SetValue(string(UpdatedUnitState.kAppearance.iGender));
		break;
	case eUICustomizeCat_Race:					     
		categoryValue = UpdatedUnitState.kAppearance.iRace;

		if(specificIndex != -1)
			UpdatedUnitState.kAppearance.iRace = specificIndex;
		else
			UpdatedUnitState.kAppearance.iRace = WrapIndex(categoryValue + direction, 0, eRace_MAX);
		
		BodyPartFilter.Set(EGender(UpdatedUnitState.kAppearance.iGender), ECharacterRace(UpdatedUnitState.kAppearance.iRace), UpdatedUnitState.kAppearance.nmTorso);
		UpdateCategorySimple("Head", direction, BodyPartFilter.FilterByGenderAndRaceAndCharacterAndClass, UpdatedUnitState.kAppearance.nmHead);

		XComHumanPawn(ActorPawn).SetAppearance(UpdatedUnitState.kAppearance);
		UpdatedUnitState.StoreAppearance();
		//TODO category.SetValue(string(UpdatedUnitState.kAppearance.iRace));
		break;
	case eUICustomizeCat_Helmet:  
		UpdateCategory("Helmets", direction, BodyPartFilter.FilterByGenderAndNonSpecializedAndClassAndTechAndArmor, UpdatedUnitState.kAppearance.nmHelmet, specificIndex);
		break;
	case eUICustomizeCat_PrimaryArmorColor:		
		UpdatedUnitState.kAppearance.iArmorTint = WrapIndex(specificIndex, 0, XComHumanPawn(ActorPawn).NumPossibleArmorTints);	
		XComHumanPawn(ActorPawn).SetAppearance(UpdatedUnitState.kAppearance);
		UpdatedUnitState.StoreAppearance();

		// Check for any weapons which are supposed to copy the armor tint and apply the change
		WeaponAppearance = PrimaryWeapon.WeaponAppearance;
		WeaponAppearance.iWeaponTint = UpdatedUnitState.kAppearance.iArmorTint;
		UpdateWeaponAppearances(WeaponAppearance, true, false, true);
		break; 
	case eUICustomizeCat_SecondaryArmorColor:
		UpdatedUnitState.kAppearance.iArmorTintSecondary = WrapIndex(specificIndex, 0, XComHumanPawn(ActorPawn).NumPossibleArmorTints);
		XComHumanPawn(ActorPawn).SetAppearance(UpdatedUnitState.kAppearance);
		// Start Issue #380
		CosmeticUnitPawn = XComPresentationLayerBase(Outer).GetUIPawnMgr().GetCosmeticPawn(eInvSlot_SecondaryWeapon, UpdatedUnitState.ObjectID);
		if (CosmeticUnitPawn != none)
		{
			Appearance.nmPatterns = PrimaryWeapon.WeaponAppearance.nmWeaponPattern;
			Appearance.iArmorTint = PrimaryWeapon.WeaponAppearance.iWeaponTint;
			Appearance.iArmorTintSecondary = UpdatedUnitState.kAppearance.iArmorTintSecondary;
			CosmeticUnitPawn.SetAppearance(Appearance, true);
		}
		// End Issue #380
		UpdatedUnitState.StoreAppearance();
		break; 
	case eUICustomizeCat_WeaponColor:		
		WeaponAppearance = PrimaryWeapon.WeaponAppearance;
		if( specificIndex == -1 ) //default tint is -1 when no tint was ever selected. Keep it -1, else it will push select another tint in the list when player never selected a tint. 
			WeaponAppearance.iWeaponTint = -1;
		else
			WeaponAppearance.iWeaponTint = WrapIndex(specificIndex, 0, XComHumanPawn(ActorPawn).NumPossibleArmorTints);
		
		UpdatedUnitState.kAppearance.iWeaponTint = WeaponAppearance.iWeaponTint;
		
		UpdateWeaponAppearances(WeaponAppearance, true, false);

		//Alter the appearance of an attached cosmetic unit pawn ( such as the gremlin )
		CosmeticUnitPawn = XComPresentationLayerBase(Outer).GetUIPawnMgr().GetCosmeticPawn(eInvSlot_SecondaryWeapon, UpdatedUnitState.ObjectID);
		if (CosmeticUnitPawn != none)
		{
			Appearance.nmPatterns = WeaponAppearance.nmWeaponPattern;
			Appearance.iArmorTint = WeaponAppearance.iWeaponTint;
			// Single line for Issue #380
			Appearance.iArmorTintSecondary = UpdatedUnitState.kAppearance.iArmorTintSecondary;
			CosmeticUnitPawn.SetAppearance(Appearance, true);
		}
		UpdatedUnitState.StoreAppearance();
		break;
	case eUICustomizeCat_ArmorPatterns:
		UpdateCategorySimple("Patterns", direction, BodyPartFilter.FilterAny, UpdatedUnitState.kAppearance.nmPatterns, specificIndex);
		
		WeaponAppearance = PrimaryWeapon.WeaponAppearance;
		WeaponAppearance.nmWeaponPattern = UpdatedUnitState.kAppearance.nmPatterns;
		UpdateWeaponAppearances(WeaponAppearance, false, true, true);
		break;
	case eUICustomizeCat_WeaponPatterns:
		WeaponAppearance = PrimaryWeapon.WeaponAppearance;
		CyclePartSimple("Patterns", direction, BodyPartFilter.FilterAny, WeaponAppearance.nmWeaponPattern, specificIndex);
		UpdatedUnitState.kAppearance.nmWeaponPattern = WeaponAppearance.nmWeaponPattern;
		
		UpdateWeaponAppearances(WeaponAppearance, false, true);

		//Alter the appearance of an attached cosmetic unit pawn ( such as the gremlin )
		CosmeticUnitPawn = XComPresentationLayerBase(Outer).GetUIPawnMgr().GetCosmeticPawn(eInvSlot_SecondaryWeapon, UpdatedUnitState.ObjectID);
		if (CosmeticUnitPawn != none)
		{
			Appearance.nmPatterns = WeaponAppearance.nmWeaponPattern;
			Appearance.iArmorTint = WeaponAppearance.iWeaponTint;
			// Single line for Issue #380
			Appearance.iArmorTintSecondary = UpdatedUnitState.kAppearance.iArmorTintSecondary;
			CosmeticUnitPawn.SetAppearance(Appearance, true);
		}
		UpdatedUnitState.StoreAppearance();
		break;
	case eUICustomizeCat_FacePaint:
		UpdateCategorySimple("Facepaint", direction, BodyPartFilter.FilterAny, UpdatedUnitState.kAppearance.nmFacePaint, specificIndex);
		break;
	case eUICustomizeCat_LeftArmTattoos:
		UpdateCategorySimple("Tattoos", direction, BodyPartFilter.FilterAny, UpdatedUnitState.kAppearance.nmTattoo_LeftArm, specificIndex);
		break;
	case eUICustomizeCat_RightArmTattoos:
		UpdateCategorySimple("Tattoos", direction, BodyPartFilter.FilterAny, UpdatedUnitState.kAppearance.nmTattoo_RightArm, specificIndex);
		break;
	case eUICustomizeCat_TattooColor:
		UpdatedUnitState.kAppearance.iTattooTint = WrapIndex(specificIndex, 0, XComHumanPawn(ActorPawn).NumPossibleArmorTints);
		XComHumanPawn(ActorPawn).SetAppearance(UpdatedUnitState.kAppearance);
		UpdatedUnitState.StoreAppearance();
		break;
	case eUICustomizeCat_Scars:
		UpdateCategorySimple("Scars", direction, BodyPartFilter.FilterByCharacter, UpdatedUnitState.kAppearance.nmScars, specificIndex);
		break;
	case eUICustomizeCat_Class:
		UpdateClass(specificIndex);
		break;
	case eUICustomizeCat_ViewClass:
		ViewClass(specificIndex);
		break;
	case eUICustomizeCat_AllowTypeSoldier:
		UpdateAllowedTypeSoldier(specificIndex);
		break;
	case eUICustomizeCat_AllowTypeVIP:
		UpdateAllowedTypeVIP(specificIndex);
		break;
	case eUICustomizeCat_AllowTypeDarkVIP:
		UpdateAllowedTypeDarkVIP(specificIndex);
		break;

	}

	// Only update the camera when editing a unit, not when customizing weapons
	if(`SCREENSTACK.HasInstanceOf(class'UICustomize'))
		UpdateCamera(categoryIndex);

	AccessedCategoryCheckDLC(EUICustomizeCategory(categoryIndex));
}

function UpdateCamera(optional int categoryIndex = -1)
{
	local name CameraTag;
	local name AnimName;
	local XComHQPresentationLayer HQPres;
	local XComShellPresentationLayer ShellPres;
	local XComBaseCamera HQCamera;
	local UIDisplay_LevelActor DisplayActor;
	local bool bCosmeticPawnOnscreen;
	local bool bExecuteCameraChange;

	switch(categoryIndex)
	{
	case eUICustomizeCat_Face:
	case eUICustomizeCat_EyeColor:
	case eUICustomizeCat_Hairstyle:
	case eUICustomizeCat_HairColor:
	case eUICustomizeCat_FaceDecorationUpper:
	case eUICustomizeCat_FaceDecorationLower:
	case eUICustomizeCat_FacialHair:
	case eUICustomizeCat_Helmet:
	case eUICustomizeCat_Scars:
	case eUICustomizeCat_FacePaint:
	case eUICustomizeCat_Skin:
	case eUICustomizeCat_Race:
		CameraTag = HeadCameraTag;
		AnimName = StandingStillAnimName; // play by the book anim when looking at face
		bCosmeticPawnOnscreen = false;
		
		break;
	case eUICustomizeCat_Legs:
	case eUICustomizeCat_Thighs:
	case eUICustomizeCat_Shins:
		CameraTag = LegsCameraTag;
		bCosmeticPawnOnscreen = true;		
		break;
	default:
		CameraTag = RegularCameraTag;
		bCosmeticPawnOnscreen = true;
	break;
	}

	HQPres = `HQPRES;
	ShellPres = XComShellPresentationLayer(`PRESBASE);
	if(HQPres != none)
	{
		HQCamera = HQPres.GetCamera();
	}
	
	// the locked display will follow with the camera, so that as the user switches between customizing
	// different things, the camera doesn't jump all over
	// find the current active ui display
	foreach HQCamera.AllActors(class'UIDisplay_LevelActor', DisplayActor)
	{
		if(DisplayActor.m_kMovie != none)
		{
			DisplayActor.SetLockedToCamera(true);
			break;
		}
	}
	
	
	//bHasOldCameraState means we are still blending from the previous camera
	if(HQCamera.bHasOldCameraState)
	{
		if(LastSetCameraTag != CameraTag)
		{
			bExecuteCameraChange = true;			
		}
	}
	else
	{
		bExecuteCameraChange = true;		
	}

	if(bExecuteCameraChange)
	{
		if(bCosmeticPawnOnscreen)
		{
			MoveCosmeticPawnOnscreen();
		}
		else
		{
			MoveCosmeticPawnOffscreen();
		}

		if(HQPres != none)
		{
			HQPres.CAMLookAtNamedLocation(string(CameraTag), `HQINTERPTIME);
		}
		else
		{
			ShellPres.CAMLookAtNamedLocation(string(CameraTag), `HQINTERPTIME);
		}

		XComHumanPawn(ActorPawn).PlayHQIdleAnim(AnimName, , true);
	}

	LastSetCameraTag = CameraTag;
}

function MoveCosmeticPawnOnscreen()
{
	local XComHumanPawn UnitPawn;
	local XComUnitPawn CosmeticPawn;
	local UIPawnMgr PawnMgr;

	PawnMgr = XComPresentationLayerBase(Outer).GetUIPawnMgr();

	UnitPawn = XComHumanPawn(ActorPawn);
	if (UnitPawn == none)
		return;

	CosmeticPawn = PawnMgr.GetCosmeticPawn(eInvSlot_SecondaryWeapon, UnitRef.ObjectID);
	if (CosmeticPawn == none)
		return;

	if (CosmeticPawn.IsInState('Onscreen'))
		return;

	if (CosmeticPawn.IsInState('Offscreen'))
	{
		CosmeticPawn.GotoState('StartOnscreenMove');
	}
	else
	{
		CosmeticPawn.GotoState('FinishOnscreenMove');
	}
}

private function MoveCosmeticPawnOffscreen()
{
	local XComHumanPawn UnitPawn;
	local XComUnitPawn CosmeticPawn;
	local UIPawnMgr PawnMgr;

	PawnMgr = XComPresentationLayerBase(Outer).GetUIPawnMgr();

	UnitPawn = XComHumanPawn(ActorPawn);
	if (UnitPawn == none)
		return;

	CosmeticPawn = PawnMgr.GetCosmeticPawn(eInvSlot_SecondaryWeapon, UnitRef.ObjectID);
	if (CosmeticPawn == none)
		return;

	if (CosmeticPawn.IsInState('Offscreen'))
		return;

	CosmeticPawn.GotoState('MoveOffscreen');
}

function int GetCategoryValue( string BodyPart, name PartToMatch, delegate<X2BodyPartFilter.FilterCallback> FilterFn )
{
	local array<X2BodyPartTemplate> BodyParts;
	local int PartIndex;
	local int categoryValue;

	PartManager.GetFilteredUberTemplates(BodyPart, self, FilterFn, BodyParts);
	for( PartIndex = 0; PartIndex < BodyParts.Length; ++PartIndex )
	{
		if( PartToMatch == BodyParts[PartIndex].DataName )
		{
			categoryValue = PartIndex;
			break;
		}
	}

	return categoryValue;
}

function string GetCategoryDisplayName( string BodyPart, name PartToMatch, delegate<X2BodyPartFilter.FilterCallback> FilterFn )
{
	local int PartIndex;
	local name DefaultTemplateName;
	local array<X2BodyPartTemplate> BodyParts;
	//Variable for Issue #329
	local string DisplayName;

	PartManager.GetFilteredUberTemplates(BodyPart, self, FilterFn, BodyParts);
	for( PartIndex = 0; PartIndex < BodyParts.Length; ++PartIndex )
	{
		if( PartToMatch == BodyParts[PartIndex].DataName )
		{
			//Begin Issue #328
			/// HL-Docs: ref:BodyPartTemplateNames
			DisplayName = BodyParts[PartIndex].DisplayName;
			if (DisplayName == "")
			{
				return string(GetCategoryValue(BodyPart, PartToMatch, BodyPartFilter.FilterByTorsoAndArmorMatch));
			}
			return DisplayName;
			//End Issue #328
		}
	}

	switch(BodyPart)
	{
		case "Patterns": DefaultTemplateName = 'Pat_Nothing'; break;
		case "Helmets": DefaultTemplateName = 'Helmet_0_NoHelmet_M'; break;
		case "Scars": DefaultTemplateName = 'Scars_BLANK'; break;
		case "Facepaint": DefaultTemplateName = 'Facepaint_BLANK'; break;
	}

	return PartManager.FindUberTemplate(BodyPart, DefaultTemplateName).DisplayName;
}

simulated function string GetCategoryDisplay(int catType)
{
	local string Result;
	local X2SoldierPersonalityTemplate PersonalityTemplate;
	local array<X2StrategyElementTemplate> PersonalityTemplateList;
	local X2WeaponTemplate WeaponTemplate;

	switch(catType)
	{
	case eUICustomizeCat_FirstName:
		Result = UpdatedUnitState.GetFirstName();
		break;
	case eUICustomizeCat_LastName:
		Result = UpdatedUnitState.GetLastName(); 
		break;
	case eUICustomizeCat_NickName:
		Result = UpdatedUnitState.GetNickName();
		break;
	case eUICustomizeCat_WeaponName:
		Result = UpdatedUnitState.GetItemInSlot(eInvSlot_PrimaryWeapon, CheckGameState).Nickname;
		break;
	case eUICustomizeCat_Torso:  
		//Singeline Change for Issue #328        
		Result = GetCategoryDisplayName("Torso", UpdatedUnitState.kAppearance.nmTorso, BodyPartFilter.FilterByTorsoAndArmorMatch);
		break;
	case eUICustomizeCat_Arms:              
		//Begin Issue #328        
		Result = GetCategoryDisplayName("Arms", UpdatedUnitState.kAppearance.nmArms, BodyPartFilter.FilterByTorsoAndArmorMatch);
		//End Issue #328        
		break;
	case eUICustomizeCat_LeftArm:
		Result = GetCategoryDisplayName("LeftArm", UpdatedUnitState.kAppearance.nmLeftArm, BodyPartFilter.FilterByTorsoAndArmorMatch);
		break;
	case eUICustomizeCat_RightArm:
		Result = GetCategoryDisplayName("RightArm", UpdatedUnitState.kAppearance.nmRightArm, BodyPartFilter.FilterByTorsoAndArmorMatch);
		break;
	case eUICustomizeCat_LeftArmDeco:
		Result = GetCategoryDisplayName("LeftArmDeco", UpdatedUnitState.kAppearance.nmLeftArmDeco, BodyPartFilter.FilterByTorsoAndArmorMatch);
		break;
	case eUICustomizeCat_RightArmDeco:
		Result = GetCategoryDisplayName("RightArmDeco", UpdatedUnitState.kAppearance.nmRightArmDeco, BodyPartFilter.FilterByTorsoAndArmorMatch);
		break;
	case eUICustomizeCat_LeftForearm:
		Result = GetCategoryDisplayName("LeftForearm", UpdatedUnitState.kAppearance.nmLeftForearm, BodyPartFilter.FilterByTorsoAndArmorMatch);
		break;
	case eUICustomizeCat_RightForearm:
		Result = GetCategoryDisplayName("RightForearm", UpdatedUnitState.kAppearance.nmRightForearm, BodyPartFilter.FilterByTorsoAndArmorMatch);
		break;
	case eUICustomizeCat_Legs:      
		//Singeline Change for Issue #328
		Result = GetCategoryDisplayName("Legs", UpdatedUnitState.kAppearance.nmLegs, BodyPartFilter.FilterByTorsoAndArmorMatch);
		break;
	case eUICustomizeCat_Thighs:
		Result = GetCategoryDisplayName("Thighs", UpdatedUnitState.kAppearance.nmThighs, BodyPartFilter.FilterByTorsoAndArmorMatch);
		break;
	case eUICustomizeCat_Shins:
		//Singeline Change for Issue #328
		Result = GetCategoryDisplayName("Shins", UpdatedUnitState.kAppearance.nmShins, BodyPartFilter.FilterByTorsoAndArmorMatch);
		break;
	case eUICustomizeCat_TorsoDeco:
		Result = GetCategoryDisplayName("TorsoDeco", UpdatedUnitState.kAppearance.nmTorsoDeco, BodyPartFilter.FilterByTorsoAndArmorMatch);
		break;
	case eUICustomizeCat_Skin:					 
		Result = string(UpdatedUnitState.kAppearance.iSkinColor);
		break;
	case eUICustomizeCat_Face:
		Result = GetCategoryDisplayName("Head", UpdatedUnitState.kAppearance.nmHead, BodyPartFilter.FilterByGenderAndRaceAndCharacterAndClass);
		break;
	case eUICustomizeCat_EyeColor:				
		Result = string(UpdatedUnitState.kAppearance.iEyeColor);
		break;
	case eUICustomizeCat_Hairstyle:		
		Result = GetCategoryDisplayName("Hair", UpdatedUnitState.kAppearance.nmHaircut, BodyPartFilter.FilterByGenderAndNonSpecialized);
		break;
	case eUICustomizeCat_HairColor:				
		Result = string(UpdatedUnitState.kAppearance.iHairColor);
		break;
	case eUICustomizeCat_FaceDecorationUpper:
		Result = GetCategoryDisplayName("FacePropsUpper", UpdatedUnitState.kAppearance.nmFacePropUpper, BodyPartFilter.FilterByGenderAndNonSpecialized);
		break;
	case eUICustomizeCat_FaceDecorationLower:
		Result = GetCategoryDisplayName("FacePropsLower", UpdatedUnitState.kAppearance.nmFacePropLower, BodyPartFilter.FilterByGenderAndNonSpecialized);
		break;
	case eUICustomizeCat_FacialHair:			 
		Result = GetCategoryDisplayName("Beards", UpdatedUnitState.kAppearance.nmBeard, BodyPartFilter.FilterByGenderAndNonSpecialized);
		break;
	case eUICustomizeCat_Personality:			 
		PersonalityTemplateList = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager().GetAllTemplatesOfClass(class'X2SoldierPersonalityTemplate');
		PersonalityTemplate = X2SoldierPersonalityTemplate(PersonalityTemplateList[UpdatedUnitState.kAppearance.iAttitude]);
		Result = PersonalityTemplate.FriendlyName;
		break;
	case eUICustomizeCat_Country:
		Result = UpdatedUnitState.GetCountryTemplate().DisplayName;
		break;
	case eUICustomizeCat_Voice:
		Result = GetCategoryDisplayName("Voice", UpdatedUnitState.kAppearance.nmVoice, BodyPartFilter.FilterByGenderAndCharacterAndNonSpecialized);
		break;
	case eUICustomizeCat_Gender:				 
		if( UpdatedUnitState.kAppearance.iGender == eGender_Male ) Result = Gender_Male;
		else if( UpdatedUnitState.kAppearance.iGender == eGender_Female ) Result = Gender_Female;
		break;
	case eUICustomizeCat_Race:
		Result = string(UpdatedUnitState.kAppearance.iRace);
		break;
	case eUICustomizeCat_Helmet:              
		Result = GetCategoryDisplayName("Helmets", UpdatedUnitState.kAppearance.nmHelmet, BodyPartFilter.FilterByGenderAndNonSpecializedAndClassAndTechAndArmor);
		break;
	case eUICustomizeCat_PrimaryArmorColor:   
		Result = string(UpdatedUnitState.kAppearance.iArmorTint);
		break;
	case eUICustomizeCat_SecondaryArmorColor: 
		Result = string(UpdatedUnitState.kAppearance.iArmorTintSecondary);
		break;
	case eUICustomizeCat_WeaponColor:
		WeaponTemplate = X2WeaponTemplate(PrimaryWeapon.GetMyTemplate());
		if(WeaponTemplate == None || !WeaponTemplate.bUseArmorAppearance)
			Result = string(PrimaryWeapon.WeaponAppearance.iWeaponTint);
		else
			Result = string(SecondaryWeapon.WeaponAppearance.iWeaponTint);
		break;
	case eUICustomizeCat_ArmorPatterns:       
		Result = GetCategoryDisplayName("Patterns", UpdatedUnitState.kAppearance.nmPatterns, BodyPartFilter.FilterAny);
		break;
	case eUICustomizeCat_WeaponPatterns:
		WeaponTemplate = X2WeaponTemplate(PrimaryWeapon.GetMyTemplate());
		if (WeaponTemplate == None || !WeaponTemplate.bUseArmorAppearance)
			Result = GetCategoryDisplayName("Patterns", PrimaryWeapon.WeaponAppearance.nmWeaponPattern, BodyPartFilter.FilterAny);
		else
			Result = GetCategoryDisplayName("Patterns", SecondaryWeapon.WeaponAppearance.nmWeaponPattern, BodyPartFilter.FilterAny);		
		break;
	case eUICustomizeCat_FacePaint:
		Result = GetCategoryDisplayName("Facepaint", UpdatedUnitState.kAppearance.nmFacePaint, BodyPartFilter.FilterAny);
		break;
	case eUICustomizeCat_LeftArmTattoos:
		Result = GetCategoryDisplayName("Tattoos", UpdatedUnitState.kAppearance.nmTattoo_LeftArm, BodyPartFilter.FilterAny);
		break;
	case eUICustomizeCat_RightArmTattoos:
		Result = GetCategoryDisplayName("Tattoos", UpdatedUnitState.kAppearance.nmTattoo_RightArm, BodyPartFilter.FilterAny);
		break;
	case eUICustomizeCat_TattooColor:
		Result = string(UpdatedUnitState.kAppearance.iTattooTint);
		break;
	case eUICustomizeCat_Scars:
		Result = GetCategoryDisplayName("Scars", UpdatedUnitState.kAppearance.nmScars, BodyPartFilter.FilterByCharacter);
		break;
	case eUICustomizeCat_Class:
		Result = UpdatedUnitState.GetMyTemplate().strCharacterName;
		break;
	case eUICustomizeCat_ViewClass:
		Result = UpdatedUnitState.GetSoldierClassTemplate().DisplayName;
		break;
	}

	return Result;
}

private function int GetCategoryValueGeneric( string BodyPart, name PartToMatch, delegate<X2BodyPartFilter.FilterCallback> FilterFn )
{
	local int PartIndex;
	local array<X2BodyPartTemplate> BodyParts;

	PartManager.GetFilteredUberTemplates(BodyPart, self, FilterFn, BodyParts);
	for( PartIndex = 0; PartIndex < BodyParts.Length; ++PartIndex )
	{
		if( PartToMatch == BodyParts[PartIndex].DataName )
		{
			return PartIndex;
		}
	}

	return -1;
}

simulated function string FormatCategoryDisplay(int catType, optional EUIState ColorState = eUIState_Normal, optional int FontSize = -1)
{
	return class'UIUtilities_Text'.static.GetSizedText(GetCategoryDisplay(catType), FontSize);
	//return class'UIUtilities_Text'.static.GetColoredText(GetCategoryDisplay(catType), ColorState, FontSize);
}

//==============================================================================

reliable client function array<string> GetCategoryList( int categoryIndex )
{
	local int i;
	local array<string> Items;
	local array<name> TemplateNames;
	local X2StrategyElementTemplateManager StratMgr;
	local array<X2StrategyElementTemplate> CountryTemplates;
	local X2SoldierClassTemplateManager TemplateMan;
	local X2SoldierClassTemplate SoldierClassTemplate;
	local array<X2StrategyElementTemplate> PersonalityTemplateList;
	local X2SoldierPersonalityTemplate PersonalityTemplate;
	local X2CountryTemplate CountryTemplate;

	local XComOnlineProfileSettings ProfileSettings;
	local int BronzeScore, HighScore;

	switch(categoryIndex)
	{
	case eUICustomizeCat_Face:
		GetGenericCategoryList(Items, "Head", BodyPartFilter.FilterByGenderAndRaceAndCharacterAndClass, class'UICustomize_Head'.default.m_strFace);
		return Items;
	case eUICustomizeCat_Hairstyle: 
		GetGenericCategoryList(Items, "Hair", BodyPartFilter.FilterByGenderAndNonSpecialized, class'UICustomize_Head'.default.m_strHair);
		return Items;
	case eUICustomizeCat_FacialHair: 
		GetGenericCategoryList(Items, "Beards", BodyPartFilter.FilterByGenderAndNonSpecialized, class'UICustomize_Head'.default.m_strFacialHair);
		return Items;
	case eUICustomizeCat_Race:
		for(i = 0; i < eRace_MAX; ++i)
		{
			Items.AddItem(class'UICustomize_Head'.default.m_strRace @ string(i));
		}
		return Items;
	case eUICustomizeCat_Voice:
		GetGenericCategoryList(Items, "Voice", BodyPartFilter.FilterByGenderAndCharacterAndNonSpecialized, class'UICustomize_Info'.default.m_strVoice);
		return Items;
	case eUICustomizeCat_Helmet:
		GetGenericCategoryList(Items, "Helmets", BodyPartFilter.FilterByGenderAndNonSpecializedAndClassAndTechAndArmor, class'UICustomize_Head'.default.m_strHelmet);
		return Items;
	case eUICustomizeCat_ArmorPatterns:
		GetGenericCategoryList(Items, "Patterns", BodyPartFilter.FilterAny, class'UICustomize_Body'.default.m_strArmorPattern);
		return Items;
	case eUICustomizeCat_WeaponPatterns:
		GetGenericCategoryList(Items, "Patterns", BodyPartFilter.FilterAny, class'UICustomize_Weapon'.default.m_strWeaponPattern);
		return Items;
	case eUICustomizeCat_FacePaint:
		GetGenericCategoryList(Items, "Facepaint", BodyPartFilter.FilterAny, class'UICustomize_Head'.default.m_strFacePaint);
		return Items;
	case eUICustomizeCat_LeftArmTattoos:
		GetGenericCategoryList(Items, "Tattoos", BodyPartFilter.FilterAny, class'UICustomize_Body'.default.m_strTattoosLeft);
		return Items;
	case eUICustomizeCat_RightArmTattoos:
		GetGenericCategoryList(Items, "Tattoos", BodyPartFilter.FilterAny, class'UICustomize_Body'.default.m_strTattoosRight);
		return Items;
	case eUICustomizeCat_Scars:
		GetGenericCategoryList(Items, "Scars", BodyPartFilter.FilterByCharacter, class'UICustomize_Head'.default.m_strScars);
		return Items;
	case eUICustomizeCat_Arms:
		GetGenericCategoryList(Items, "Arms", BodyPartFilter.FilterByTorsoAndArmorMatch, class'UICustomize_Body'.default.m_strArms);
		return Items;
	case eUICustomizeCat_LeftArm:
		GetGenericCategoryList(Items, "LeftArm", BodyPartFilter.FilterByTorsoAndArmorMatch, class'UICustomize_Body'.default.m_strLeftArm);
		return Items;		
	case eUICustomizeCat_RightArm:
		GetGenericCategoryList(Items, "RightArm", BodyPartFilter.FilterByTorsoAndArmorMatch, class'UICustomize_Body'.default.m_strRightArm);
		return Items;
	case eUICustomizeCat_LeftArmDeco:
		GetGenericCategoryList(Items, "LeftArmDeco", BodyPartFilter.FilterByTorsoAndArmorMatch, class'UICustomize_Body'.default.m_strLeftArmDeco);
		return Items;		
	case eUICustomizeCat_RightArmDeco:
		GetGenericCategoryList(Items, "RightArmDeco", BodyPartFilter.FilterByTorsoAndArmorMatch, class'UICustomize_Body'.default.m_strRightArmDeco);
		return Items;
	case eUICustomizeCat_LeftForearm:
		GetGenericCategoryList(Items, "LeftForearm", BodyPartFilter.FilterByTorsoAndArmorMatch, class'UICustomize_Body'.default.m_strLeftForearm);
		return Items;
	case eUICustomizeCat_RightForearm:
		GetGenericCategoryList(Items, "RightForearm", BodyPartFilter.FilterByTorsoAndArmorMatch, class'UICustomize_Body'.default.m_strRightForearm);
		return Items;
	case eUICustomizeCat_Torso:
		GetGenericCategoryList(Items, "Torso", BodyPartFilter.FilterByTorsoAndArmorMatch, class'UICustomize_Body'.default.m_strTorso);
		return Items;
	case eUICustomizeCat_TorsoDeco:
		GetGenericCategoryList(Items, "TorsoDeco", BodyPartFilter.FilterByTorsoAndArmorMatch, class'UICustomize_Body'.default.m_strTorsoDeco);
		return Items;
	case eUICustomizeCat_Legs:
		GetGenericCategoryList(Items, "Legs", BodyPartFilter.FilterByTorsoAndArmorMatch, class'UICustomize_Body'.default.m_strLegs);
		return Items;
	case eUICustomizeCat_Thighs:
		GetGenericCategoryList(Items, "Thighs", BodyPartFilter.FilterByTorsoAndArmorMatch, class'UICustomize_Body'.default.m_strThighs);
		return Items;
	case eUICustomizeCat_Shins:
		GetGenericCategoryList(Items, "Shins", BodyPartFilter.FilterByTorsoAndArmorMatch, class'UICustomize_Body'.default.m_strShins);
		return Items;
	case eUICustomizeCat_FaceDecorationUpper:
		GetGenericCategoryList(Items, "FacePropsUpper", BodyPartFilter.FilterByGenderAndNonSpecialized, class'UICustomize_Head'.default.m_strUpperFaceProps);
		return Items;
	case eUICustomizeCat_FaceDecorationLower:
		GetGenericCategoryList(Items, "FacePropsLower", BodyPartFilter.FilterByGenderAndNonSpecialized, class'UICustomize_Head'.default.m_strLowerFaceProps);
		return Items;
	case eUICustomizeCat_Personality: 
		ProfileSettings = `XPROFILESETTINGS;
		BronzeScore = class'XComGameState_LadderProgress'.static.GetLadderMedalThreshold( 4, 0 );
		HighScore = ProfileSettings.Data.GetLadderHighScore( 4 );

		PersonalityTemplateList = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager().GetAllTemplatesOfClass(class'X2SoldierPersonalityTemplate');
		for(i = 0; i < PersonalityTemplateList.Length; i++)
		{
			PersonalityTemplate = X2SoldierPersonalityTemplate(PersonalityTemplateList[i]);

			// skip TLE attitudes unless ladder 4 has been completed to BronzeMedal
			if ((PersonalityTemplate.ClassThatCreatedUs.Name == 'X2StrategyElement_TLESoldierPersonalities') && (BronzeScore > HighScore))
				continue;

			Items.AddItem(PersonalityTemplate.FriendlyName);
		}
		return Items;

	case eUICustomizeCat_Gender:
		Items.AddItem(Gender_Male);
		Items.AddItem(Gender_Female);
		return Items;
	case eUICustomizeCat_Country: 
		StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
		CountryTemplates = StratMgr.GetAllTemplatesOfClass(class'X2CountryTemplate');
		CountryTemplates.Sort(SortCountryTemplates);
		for( i = 0; i < CountryTemplates.Length; i++ )
		{
			CountryTemplate = X2CountryTemplate(CountryTemplates[i]);
			if (!CountryTemplate.bHideInCustomization)
			{
				Items.AddItem(X2CountryTemplate(CountryTemplates[i]).DisplayName);
			}
		}
		return Items;
	case eUICustomizeCat_Class:
		TemplateMan = class'X2SoldierClassTemplateManager'.static.GetSoldierClassTemplateManager();
		TemplateMan.GetTemplateNames(TemplateNames);

		Items.AddItem(SoldierClass); // Add the base game soldier class

		for( i = 0; i < TemplateNames.Length; i++ )
		{
			SoldierClassTemplate = TemplateMan.FindSoldierClassTemplate(TemplateNames[i]);

			if(!SoldierClassTemplate.bMultiplayerOnly && !SoldierClassTemplate.bHideInCharacterPool && SoldierClassTemplate.RequiredCharacterClass != '')
			{
				Items.AddItem(SoldierClassTemplate.DisplayName);
			}			
		}
		return Items;
	case eUICustomizeCat_ViewClass:
		TemplateMan = class'X2SoldierClassTemplateManager'.static.GetSoldierClassTemplateManager();
		TemplateMan.GetTemplateNames(TemplateNames);

		for (i = 0; i < TemplateNames.Length; i++)
		{
			SoldierClassTemplate = TemplateMan.FindSoldierClassTemplate(TemplateNames[i]);

			if (!SoldierClassTemplate.bMultiplayerOnly && !SoldierClassTemplate.bHideInCharacterPool && SoldierClassTemplate.RequiredCharacterClass == '')
			{
				Items.AddItem(SoldierClassTemplate.DisplayName);
			}
		}

		Items.AddItem(RandomClass);
		return Items;
	}
	//Else return empty:
	Items.Length = 0;
	return Items; 
}

protected function GetGenericCategoryList(out array<string> Items,  string BodyPart, delegate<X2BodyPartFilter.FilterCallback> FilterFn, optional string PrefixLocText )
{
	local int i, iDel;
	local array<X2BodyPartTemplate> BodyParts;
	local string Label;
	local delegate< GetIconsForBodyPartCallback > dCallback;

	PartManager.GetFilteredUberTemplates(BodyPart, self, FilterFn, BodyParts);
	for( i = 0; i < BodyParts.Length; ++i )
	{
		if(BodyParts[i].DisplayName != "")
			Label = BodyParts[i].DisplayName;
		else if(PrefixLocText != "")
			Label = PrefixLocText @ i;
		else
			Label = string(i);

		for( iDel = 0; iDel < arrGetIconsForBodyPartDelegates.Length; iDel++ )
		{
			dCallback = arrGetIconsForBodyPartDelegates[iDel];

			if( dCallback != none )
				Label = dCallback(Bodyparts[i]) $ Label;
		}

		Items.AddItem(Label);
	}
}


simulated function SubscribeToGetIconsForBodyPart(delegate<GetIconsForBodyPartCallback> fCallback)
{
	local int foundIndex;

	foundIndex = arrGetIconsForBodyPartDelegates.Find(fCallback);

	if( foundIndex == -1 )
		arrGetIconsForBodyPartDelegates.AddItem(fCallback);
	else
		`log("Can not SubscribeToGetIconsForBodyPart callback ("$fCallback$"); already found at arrGetIconsForBodyPartDelegates["$foundIndex$"].", , 'uixcom');
}

simulated function UnsubscribeToGetIconsForBodyPart(delegate<GetIconsForBodyPartCallback> fCallback)
{
	local int foundIndex;

	foundIndex = arrGetIconsForBodyPartDelegates.Find(fCallback);

	if( foundIndex == -1 )
		`log("Can not UnsubscribeToGetIconsForBodyPart callback ("$fCallback$"); not found in arrGetIconsForBodyPartDelegates", , 'uixcom');
	else
		arrGetIconsForBodyPartDelegates.RemoveItem(fCallback);
}

function string CheckForAttentionIcon(int catType)
{	
	local bool bNeedsAttention;
	local bool bHasDLC, bCategoryHasDLC; 

	// Per Jake, 4/28/2017: Turning off the attention icon for the customization pools in general. -bsteiner
	return "";


	if( m_kProfileSettings == none ) return "";

	switch( catType )
	{
	case eUICustomizeCat_FirstName: // Info group 

		if( !bNeedsAttention && !bHasDLC )
		{

			bCategoryHasDLC = DoesCategoryHaveDLC(eUICustomizeCat_Country);
			if( bCategoryHasDLC )
			{
				bHasDLC = bCategoryHasDLC;
				bNeedsAttention = DoesCategoryNeedDLCAttention(eUICustomizeCat_Country);
			}
		}
		if( !bNeedsAttention && !bHasDLC )
		{

			bCategoryHasDLC = DoesCategoryHaveDLC(eUICustomizeCat_Gender);
			if( bCategoryHasDLC )
			{
				bHasDLC = bCategoryHasDLC;
				bNeedsAttention = DoesCategoryNeedDLCAttention(eUICustomizeCat_Gender);
			}
		}
		break; 
	case eUICustomizeCat_NickName: //Props group 

		if( !bNeedsAttention && !bHasDLC )
		{
			bCategoryHasDLC = DoesCategoryHaveDLC(eUICustomizeCat_Helmet);
			if( bCategoryHasDLC )
			{
				bHasDLC = bCategoryHasDLC;
				bNeedsAttention = DoesCategoryNeedDLCAttention(eUICustomizeCat_Helmet);
			}
		}
		if( !bNeedsAttention && !bHasDLC )
		{
			bCategoryHasDLC = DoesCategoryHaveDLC(eUICustomizeCat_Arms);
			if( bCategoryHasDLC )
			{
				bHasDLC = bCategoryHasDLC;
				bNeedsAttention = DoesCategoryNeedDLCAttention(eUICustomizeCat_Arms);
			}
		}
		if( !bNeedsAttention && !bHasDLC )
		{
			bCategoryHasDLC = DoesCategoryHaveDLC(eUICustomizeCat_LeftArm);
			if( bCategoryHasDLC )
			{
				bHasDLC = bCategoryHasDLC;
				bNeedsAttention = DoesCategoryNeedDLCAttention(eUICustomizeCat_LeftArm);
			}
		}
		if( !bNeedsAttention && !bHasDLC )
		{
			bCategoryHasDLC = DoesCategoryHaveDLC(eUICustomizeCat_RightArm);
			if( bCategoryHasDLC )
			{
				bHasDLC = bCategoryHasDLC;
				bNeedsAttention = DoesCategoryNeedDLCAttention(eUICustomizeCat_RightArm);
			}
		}
		if( !bNeedsAttention && !bHasDLC )
		{
			bCategoryHasDLC = DoesCategoryHaveDLC(eUICustomizeCat_Legs);
			if( bCategoryHasDLC )
			{
				bHasDLC = bCategoryHasDLC;
				bNeedsAttention = DoesCategoryNeedDLCAttention(eUICustomizeCat_Legs);
			}
		}
		if( !bNeedsAttention && !bHasDLC )
		{
			bCategoryHasDLC = DoesCategoryHaveDLC(eUICustomizeCat_Torso);
			if( bCategoryHasDLC )
			{
				bHasDLC = bCategoryHasDLC;
				bNeedsAttention = DoesCategoryNeedDLCAttention(eUICustomizeCat_Torso);
			}
		}
		if( !bNeedsAttention && !bHasDLC )
		{
			bCategoryHasDLC = DoesCategoryHaveDLC(eUICustomizeCat_FaceDecorationUpper);
			if( bCategoryHasDLC )
			{
				bHasDLC = bCategoryHasDLC;
				bNeedsAttention = DoesCategoryNeedDLCAttention(eUICustomizeCat_FaceDecorationUpper);
			}
		}
		if( !bNeedsAttention && !bHasDLC )
		{
			bCategoryHasDLC = DoesCategoryHaveDLC(eUICustomizeCat_FaceDecorationLower);
			if( bCategoryHasDLC )
			{
				bHasDLC = bCategoryHasDLC;
				bNeedsAttention = DoesCategoryNeedDLCAttention(eUICustomizeCat_FaceDecorationLower);
			}
		}
		if( !bNeedsAttention && !bHasDLC )
		{
			bCategoryHasDLC = DoesCategoryHaveDLC(eUICustomizeCat_ArmorPatterns);
			if( bCategoryHasDLC )
			{
				bHasDLC = bCategoryHasDLC;
				bNeedsAttention = DoesCategoryNeedDLCAttention(eUICustomizeCat_ArmorPatterns);
			}
		}
		if( !bNeedsAttention && !bHasDLC )
		{
			bCategoryHasDLC = DoesCategoryHaveDLC(eUICustomizeCat_WeaponPatterns);
			if( bCategoryHasDLC )
			{
				bHasDLC = bCategoryHasDLC;
				bNeedsAttention = DoesCategoryNeedDLCAttention(eUICustomizeCat_WeaponPatterns);
			}
		}
		if( !bNeedsAttention && !bHasDLC )
		{
			bCategoryHasDLC = DoesCategoryHaveDLC(eUICustomizeCat_FacePaint);
			if( bCategoryHasDLC )
			{
				bHasDLC = bCategoryHasDLC;
				bNeedsAttention = DoesCategoryNeedDLCAttention(eUICustomizeCat_FacePaint);
			}
		}
		if( !bNeedsAttention && !bHasDLC )
		{
			bCategoryHasDLC = DoesCategoryHaveDLC(eUICustomizeCat_LeftArmTattoos);
			if( bCategoryHasDLC )
			{
				bHasDLC = bCategoryHasDLC;
				bNeedsAttention = DoesCategoryNeedDLCAttention(eUICustomizeCat_LeftArmTattoos);
			}
		}
		if( !bNeedsAttention && !bHasDLC )
		{
			bCategoryHasDLC = DoesCategoryHaveDLC(eUICustomizeCat_RightArmTattoos);
			if( bCategoryHasDLC )
			{
				bHasDLC = bCategoryHasDLC;
				bNeedsAttention = DoesCategoryNeedDLCAttention(eUICustomizeCat_RightArmTattoos);
			}
		}
		if( !bNeedsAttention && !bHasDLC )
		{
			bCategoryHasDLC = DoesCategoryHaveDLC(eUICustomizeCat_TattooColor);
			if( bCategoryHasDLC )
			{
				bHasDLC = bCategoryHasDLC;
				bNeedsAttention = DoesCategoryNeedDLCAttention(eUICustomizeCat_TattooColor);
			}
		}
		if( !bNeedsAttention && !bHasDLC )
		{
			bCategoryHasDLC = DoesCategoryHaveDLC(eUICustomizeCat_Scars);
			if( bCategoryHasDLC )
			{
				bHasDLC = bCategoryHasDLC;
				bNeedsAttention = DoesCategoryNeedDLCAttention(eUICustomizeCat_Scars);
			}
		}
		break; 

	case eUICustomizeCat_WeaponName:
	case eUICustomizeCat_Torso:
	case eUICustomizeCat_Arms:
	case eUICustomizeCat_Legs:
	case eUICustomizeCat_Skin:
	case eUICustomizeCat_Face:
	case eUICustomizeCat_EyeColor:
	case eUICustomizeCat_Hairstyle:
	case eUICustomizeCat_HairColor:
	case eUICustomizeCat_FaceDecorationUpper:
	case eUICustomizeCat_FaceDecorationLower:
	case eUICustomizeCat_FacialHair:
	case eUICustomizeCat_Personality:
	case eUICustomizeCat_Country:
	case eUICustomizeCat_Voice:
	case eUICustomizeCat_Gender:
	case eUICustomizeCat_Race:
	case eUICustomizeCat_Helmet:
	case eUICustomizeCat_PrimaryArmorColor:
	case eUICustomizeCat_SecondaryArmorColor:
	case eUICustomizeCat_WeaponColor:
	case eUICustomizeCat_ArmorPatterns:
	case eUICustomizeCat_WeaponPatterns:
	case eUICustomizeCat_LeftArmTattoos:
	case eUICustomizeCat_RightArmTattoos:
	case eUICustomizeCat_TattooColor:
	case eUICustomizeCat_Scars:
	case eUICustomizeCat_Class:
	case eUICustomizeCat_ViewClass:
	case eUICustomizeCat_AllowTypeSoldier:
	case eUICustomizeCat_AllowTypeVIP:
	case eUICustomizeCat_AllowTypeDarkVIP:
	case eUICustomizeCat_FacePaint:
	case eUICustomizeCat_DEV1:
	case eUICustomizeCat_DEV2:
	case eUICustomizeCat_LeftArm:
	case eUICustomizeCat_RightArm:
	case eUICustomizeCat_LeftArmDeco:
	case eUICustomizeCat_RightArmDeco:
	case eUICustomizeCat_LeftForearm:
	case eUICustomizeCat_RightForearm:
	case eUICustomizeCat_Thighs:
	case eUICustomizeCat_Shins:
	case eUICustomizeCat_TorsoDeco:

		bCategoryHasDLC = DoesCategoryHaveDLC(catType); 
		if( bCategoryHasDLC )
		{
			bHasDLC = bCategoryHasDLC;
			bNeedsAttention = DoesCategoryNeedDLCAttention(catType);
		}
		break;
	}


	if( bNeedsAttention && bHasDLC )
		return class'UIUtilities_Text'.static.InjectImage(class'UIUtilities_Image'.const.HTML_AttentionIcon, 26, 26, -4) $ " ";
	else
		return "";
}

function UpdateWeaponAppearances(TWeaponAppearance WeaponAppearance, bool bUpdateTint, bool bUpdatePattern, optional bool bArmorUpdate)
{
	local array<XComGameState_Item> Items;
	local int Index;

	Items = UpdatedUnitState.GetAllInventoryItems();
	if (Items.Length > 0)
	{
		for (Index = 0; Index < Items.Length; ++Index)
		{
			if (XGWeapon(Items[Index].GetVisualizer()) != none)
			{
				switch (Items[Index].InventorySlot)
				{
				case eInvSlot_PrimaryWeapon:
					SetWeaponAppearance(PrimaryWeapon, WeaponAppearance, bUpdateTint, bUpdatePattern, bArmorUpdate);
					break;
				case eInvSlot_SecondaryWeapon:
					SetWeaponAppearance(SecondaryWeapon, WeaponAppearance, bUpdateTint, bUpdatePattern, bArmorUpdate);
					break;
				case eInvSlot_TertiaryWeapon:
					SetWeaponAppearance(TertiaryWeapon, WeaponAppearance, bUpdateTint, bUpdatePattern, bArmorUpdate);
					break;
				case eInvSlot_QuaternaryWeapon:
				case eInvSlot_QuinaryWeapon:
				case eInvSlot_SenaryWeapon:
				case eInvSlot_SeptenaryWeapon:
					XGWeapon(Items[Index].GetVisualizer()).SetAppearance(WeaponAppearance);
					break;
				}
			}
		}
	}
	else // Handles character pool case when no items in inventory
	{
		SetWeaponAppearance(PrimaryWeapon, WeaponAppearance, bUpdateTint, bUpdatePattern, bArmorUpdate);
		SetWeaponAppearance(SecondaryWeapon, WeaponAppearance, bUpdateTint, bUpdatePattern, bArmorUpdate);

		if (TertiaryWeapon != none)
		{
			SetWeaponAppearance(TertiaryWeapon, WeaponAppearance, bUpdateTint, bUpdatePattern, bArmorUpdate);
		}
	}
}

function SetWeaponAppearance(out XComGameState_Item ItemState, TWeaponAppearance WeaponAppearance, bool bUpdateTint, bool bUpdatePattern, optional bool bArmorUpdate)
{
	local X2WeaponTemplate WeaponTemplate;

	WeaponTemplate = X2WeaponTemplate(ItemState.GetMyTemplate());
	if (WeaponTemplate == None || (bArmorUpdate && WeaponTemplate.bUseArmorAppearance) || (!bArmorUpdate && !WeaponTemplate.bUseArmorAppearance))
	{
		if (bUpdateTint)
			ItemState.WeaponAppearance.iWeaponTint = WeaponAppearance.iWeaponTint;
		if (bUpdatePattern)
			ItemState.WeaponAppearance.nmWeaponPattern = WeaponAppearance.nmWeaponPattern;

		XGWeapon(ItemState.GetVisualizer()).SetAppearance(ItemState.WeaponAppearance);
	}
}

function bool DoesCategoryNeedDLCAttention(int catType)
{
	local array<name> DLCNames; 
	local array<CustomizationAlertInfo> Info;
	local array<CustomizationAlertInfo> ParsedInfo;
	local int i; 
	local name DLCName;
		
	Info = m_kProfileSettings.Data.m_arrCharacterCustomizationCategoriesInfo;

	DLCNames = GetCategoryDLCNames(catType); 

	// Get a smaller array of items for this category 	
	for( i = 0; i < Info.length; i++ )
	{
		if( Info[i].Category == catType )
			ParsedInfo.AddItem(Info[i]);
	}
	
	foreach DLCNames(DLCName)
	{
		if( DoesCategoryHaveDLC(catType, DLCName) )
		{
			//Checking the array of info for *only this category*, we need attention if we have not stored that DLC name for it.
			if( ParsedInfo.Find('DLCName', DLCName) == -1 )
				return true;
		}
	}

	return false; 
}

function AccessedCategoryCheckDLC(int catType)
{
	local array<name> DLCNames;
	local name DLCName;
	local CustomizationAlertInfo AlertInfo; 

	if( m_kProfileSettings == none ) return;
	if( !DoesCategoryHaveDLC(catType) ) return;

	AlertInfo.Category = catType;

	DLCNames = GetCategoryDLCNames(catType);

	foreach DLCNames(DLCName)
	{
		AlertInfo.DLCName = DLCName;
		if( !HasStoredThisCategory(catType, DLCName) )
		{
			m_kProfileSettings.Data.m_arrCharacterCustomizationCategoriesInfo.AddItem(AlertInfo);
		}
	}

	`ONLINEEVENTMGR.SaveProfileSettings(true);
}

function bool HasStoredThisCategory( int catType, name DLCName  )
{
	local  array<CustomizationAlertInfo> Info;
	local int i;

	Info = m_kProfileSettings.Data.m_arrCharacterCustomizationCategoriesInfo;

	for( i = 0; i < Info.length; i++ )
	{
		if( Info[i].Category == catType && Info[i].DLCName == DLCName )
			return true;

	}
	return false;
}

function array<name> GetCategoryDLCNames(int catType)
{
	local array<X2BodyPartTemplate> BodyParts;
	local int Index;
	local string PartType;
	local array<name> DLCNames; 


	switch( catType )
	{
	case eUICustomizeCat_Torso:					PartType = "Torso"; break;
	case eUICustomizeCat_Arms:					PartType = "Arms"; break;
	case eUICustomizeCat_Legs:					PartType = "Legs"; break;
	case eUICustomizeCat_Skin:					PartType = ""; break;
	case eUICustomizeCat_Face:					PartType = ""; break;
	case eUICustomizeCat_EyeColor:				PartType = ""; break;
	case eUICustomizeCat_Hairstyle:				PartType = "Hair"; break;
	case eUICustomizeCat_HairColor:				PartType = ""; break;
	case eUICustomizeCat_FaceDecorationUpper:	PartType = "FacePropsUpper"; break;
	case eUICustomizeCat_FaceDecorationLower:	PartType = "FacePropsLower"; break;
	case eUICustomizeCat_FacialHair:			PartType = "Beards"; break;
	case eUICustomizeCat_Personality:			PartType = ""; break;
	case eUICustomizeCat_Country:				PartType = ""; break;
	case eUICustomizeCat_Voice:					PartType = "Voice"; break;
	case eUICustomizeCat_Gender:				PartType = ""; break;
	case eUICustomizeCat_Race:					PartType = ""; break;
	case eUICustomizeCat_Helmet:				PartType = ""; break;
	case eUICustomizeCat_PrimaryArmorColor:		PartType = ""; break;
	case eUICustomizeCat_SecondaryArmorColor:	PartType = ""; break;
	case eUICustomizeCat_WeaponColor:			PartType = ""; break;
	case eUICustomizeCat_ArmorPatterns:			PartType = ""; break;
	case eUICustomizeCat_WeaponPatterns:		PartType = ""; break;
	case eUICustomizeCat_LeftArmTattoos:		PartType = "Tattoos"; break;
	case eUICustomizeCat_RightArmTattoos:		PartType = "Tattoos"; break;
	case eUICustomizeCat_TattooColor:			PartType = ""; break;
	case eUICustomizeCat_Scars:					PartType = "Scars"; break;
	case eUICustomizeCat_Class:					PartType = ""; break;
	case eUICustomizeCat_ViewClass:				PartType = ""; break;
	case eUICustomizeCat_FacePaint:				PartType = "Facepaint"; break;
	case eUICustomizeCat_LeftArm:				PartType = "LeftArm"; break;
	case eUICustomizeCat_RightArm:				PartType = "RightArm"; break;
	case eUICustomizeCat_LeftArmDeco:			PartType = "LeftArmDeco"; break;
	case eUICustomizeCat_RightArmDeco:			PartType = "RightArmDeco"; break;
	case eUICustomizeCat_LeftForearm:			PartType = "LeftForearm"; break;
	case eUICustomizeCat_RightForearm:			PartType = "RightForearm"; break;
	case eUICustomizeCat_Thighs:				PartType = "Thighs"; break;
	case eUICustomizeCat_Shins:					PartType = "Shins"; break;
	case eUICustomizeCat_TorsoDeco:				PartType = "TorsoDeco"; break;

		break;
	default:
		PartType = "";
	}

	if( PartType != "" )
	{
		//Retrieve a list of valid parts for the specified part type
		BodyPartFilter.Set(EGender(UpdatedUnitState.kAppearance.iGender), ECharacterRace(UpdatedUnitState.kAppearance.iRace), UpdatedUnitState.kAppearance.nmTorso, !UpdatedUnitState.IsSoldier(), UpdatedUnitState.IsVeteran() || InShell());
		PartManager.GetFilteredUberTemplates(PartType, BodyPartFilter, BodyPartFilter.FilterAny, BodyParts);

		//See if the part has a DLC identified. 
		for( Index = 0; Index < BodyParts.Length; ++Index )
		{
			if( BodyParts[Index].DLCName != '' )
			{
				DLCNames.AddItem(BodyParts[Index].DLCName);
			}
		}
	}

	return DLCNames;
}

// This takes the old data and moves it forward in to the new system. 
function ConvertOldProfileCategoryAlerts()
{
	local  array<int> AttentionCategories;
	local int i;

	AttentionCategories = m_kProfileSettings.Data.m_arrCharacterCustomizationCategoriesClearedAttention;
	if( AttentionCategories.length == 0 ) return;

	for( i = 0; i < AttentionCategories.length; i++ )
	{
		AccessedCategoryCheckDLC(AttentionCategories[i]);
	}

	m_kProfileSettings.Data.m_arrCharacterCustomizationCategoriesClearedAttention.length = 0;

	`ONLINEEVENTMGR.SaveProfileSettings(true);

}


function bool DoesCategoryHaveDLC( int catType, optional name DLCName = '')
{
	local array<X2BodyPartTemplate> BodyParts;
	local int Index;
	local string PartType; 


	switch( catType )
	{
	case eUICustomizeCat_Torso:					PartType = "Torso"; break;
	case eUICustomizeCat_Arms:					PartType = "Arms"; break;
	case eUICustomizeCat_Legs:					PartType = "Legs"; break;
	case eUICustomizeCat_Skin:					PartType = ""; break;
	case eUICustomizeCat_Face:					PartType = ""; break;
	case eUICustomizeCat_EyeColor:				PartType = ""; break;
	case eUICustomizeCat_Hairstyle:				PartType = "Hair"; break;
	case eUICustomizeCat_HairColor:				PartType = ""; break;
	case eUICustomizeCat_FaceDecorationUpper:	PartType = "FacePropsUpper"; break;
	case eUICustomizeCat_FaceDecorationLower:	PartType = "FacePropsLower"; break;
	case eUICustomizeCat_FacialHair:			PartType = "Beards"; break;
	case eUICustomizeCat_Personality:			PartType = ""; break;
	case eUICustomizeCat_Country:				PartType = ""; break;
	case eUICustomizeCat_Voice:					PartType = "Voice"; break;
	case eUICustomizeCat_Gender:				PartType = ""; break;
	case eUICustomizeCat_Race:					PartType = ""; break;
	case eUICustomizeCat_Helmet:				PartType = ""; break;
	case eUICustomizeCat_PrimaryArmorColor:		PartType = ""; break;
	case eUICustomizeCat_SecondaryArmorColor:	PartType = ""; break;
	case eUICustomizeCat_WeaponColor:			PartType = ""; break;
	case eUICustomizeCat_ArmorPatterns:			PartType = ""; break;
	case eUICustomizeCat_WeaponPatterns:		PartType = ""; break;
	case eUICustomizeCat_LeftArmTattoos:		PartType = "Tattoos"; break;
	case eUICustomizeCat_RightArmTattoos:		PartType = "Tattoos"; break;
	case eUICustomizeCat_TattooColor:			PartType = ""; break;
	case eUICustomizeCat_Scars:					PartType = "Scars"; break;
	case eUICustomizeCat_Class:					PartType = ""; break;
	case eUICustomizeCat_ViewClass:				PartType = ""; break;
	case eUICustomizeCat_FacePaint:				PartType = "Facepaint"; break;
	case eUICustomizeCat_LeftArm:				PartType = "LeftArm"; break;
	case eUICustomizeCat_RightArm:				PartType = "RightArm"; break;
	case eUICustomizeCat_LeftArmDeco:			PartType = "LeftArmDeco"; break;
	case eUICustomizeCat_RightArmDeco:			PartType = "RightArmDeco"; break;

		break;
	default:
		PartType = ""; 
	}
	
	if( PartType != "" )
	{
		//Retrieve a list of valid parts for the specified part type
		BodyPartFilter.Set(EGender(UpdatedUnitState.kAppearance.iGender), ECharacterRace(UpdatedUnitState.kAppearance.iRace), UpdatedUnitState.kAppearance.nmTorso, !UpdatedUnitState.IsSoldier(), UpdatedUnitState.IsVeteran() || InShell());
		PartManager.GetFilteredUberTemplates(PartType, BodyPartFilter, BodyPartFilter.FilterAny, BodyParts);

		//See if the part has a DLC identified. 
		for( Index = 0; Index < BodyParts.Length; ++Index )
		{
			if( DLCName != '' && BodyParts[Index].DLCName == DLCName)
			{
				return true;
			}
			else if( BodyParts[Index].DLCName != '' )
			{
				return true;
			}
		}
	}

	return false;
}

simulated function bool HasMultipleCustomizationOptions(int catType)
{
	local array<string> CustomizationOptions;
	CustomizationOptions = GetCategoryList(catType);
	return CustomizationOptions.Length > 1;
}

simulated function bool HasBeard()
{
	return UpdatedUnitState.kAppearance.nmBeard != 'MaleBeard_Blank' && UpdatedUnitState.kAppearance.nmBeard != 'Central_StratBeard';
}

simulated function int GetCategoryIndex(int catType)
{
	local int i, Result, country;
	local name UnitCountryTemplate;
	local X2StrategyElementTemplateManager StratMgr;
	local array<X2StrategyElementTemplate> CountryTemplates;
	local X2WeaponTemplate WeaponTemplate;
	local X2SoldierClassTemplateManager TemplateMan;
	local X2SoldierClassTemplate SoldierClassTemplate;
	local array<name> TemplateNames;
	local int idx;

	Result = -1;

	switch(catType)
	{
	case eUICustomizeCat_Torso:  
		Result = GetCategoryValue("Torso", UpdatedUnitState.kAppearance.nmTorso, BodyPartFilter.FilterByTorsoAndArmorMatch);
		break;
	case eUICustomizeCat_TorsoDeco:
		Result = GetCategoryValue("TorsoDeco", UpdatedUnitState.kAppearance.nmTorsoDeco, BodyPartFilter.FilterByTorsoAndArmorMatch);
		break;
	case eUICustomizeCat_Arms:              
		Result = GetCategoryValue("Arms", UpdatedUnitState.kAppearance.nmArms, BodyPartFilter.FilterByTorsoAndArmorMatch);
		break;
	case eUICustomizeCat_LeftArm:
		Result = GetCategoryValue("LeftArm", UpdatedUnitState.kAppearance.nmLeftArm, BodyPartFilter.FilterByTorsoAndArmorMatch);
		break;		
	case eUICustomizeCat_RightArm:
		Result = GetCategoryValue("RightArm", UpdatedUnitState.kAppearance.nmRightArm, BodyPartFilter.FilterByTorsoAndArmorMatch);
		break;
	case eUICustomizeCat_LeftArmDeco:
		Result = GetCategoryValue("LeftArmDeco", UpdatedUnitState.kAppearance.nmLeftArmDeco, BodyPartFilter.FilterByTorsoAndArmorMatch);
		break;
	case eUICustomizeCat_RightArmDeco:
		Result = GetCategoryValue("RightArmDeco", UpdatedUnitState.kAppearance.nmRightArmDeco, BodyPartFilter.FilterByTorsoAndArmorMatch);
		break;
	case eUICustomizeCat_LeftForearm:
		Result = GetCategoryValue("LeftForearm", UpdatedUnitState.kAppearance.nmLeftForearm, BodyPartFilter.FilterByTorsoAndArmorMatch);
		break;
	case eUICustomizeCat_RightForearm:
		Result = GetCategoryValue("RightForearm", UpdatedUnitState.kAppearance.nmRightForearm, BodyPartFilter.FilterByTorsoAndArmorMatch);
		break;
	case eUICustomizeCat_Legs:              
		Result = GetCategoryValue("Legs", UpdatedUnitState.kAppearance.nmLegs, BodyPartFilter.FilterByTorsoAndArmorMatch);
		break;
	case eUICustomizeCat_Thighs:
		Result = GetCategoryValue("Thighs", UpdatedUnitState.kAppearance.nmThighs, BodyPartFilter.FilterByTorsoAndArmorMatch);
		break;
	case eUICustomizeCat_Shins:
		Result = GetCategoryValue("Shins", UpdatedUnitState.kAppearance.nmShins, BodyPartFilter.FilterByTorsoAndArmorMatch);
		break;
	case eUICustomizeCat_Skin:					 
		Result = UpdatedUnitState.kAppearance.iSkinColor;
		break;
	case eUICustomizeCat_Face:
		Result = GetCategoryValue("Head", UpdatedUnitState.kAppearance.nmHead, BodyPartFilter.FilterByGenderAndRaceAndCharacterAndClass);
		break;
	case eUICustomizeCat_EyeColor:				
		Result = UpdatedUnitState.kAppearance.iEyeColor;
		break;
	case eUICustomizeCat_Hairstyle:		
		Result = GetCategoryValue("Hair", UpdatedUnitState.kAppearance.nmHaircut, BodyPartFilter.FilterByGenderAndNonSpecialized);
		break;
	case eUICustomizeCat_HairColor:				
		Result = UpdatedUnitState.kAppearance.iHairColor;
		break;
	case eUICustomizeCat_FaceDecorationUpper:
		Result = GetCategoryValue("FacePropsUpper", UpdatedUnitState.kAppearance.nmFacePropUpper, BodyPartFilter.FilterByGenderAndNonSpecialized);
		break;
	case eUICustomizeCat_FaceDecorationLower:
		Result = GetCategoryValue("FacePropsLower", UpdatedUnitState.kAppearance.nmFacePropLower, BodyPartFilter.FilterByGenderAndNonSpecialized);
		break;
	case eUICustomizeCat_FacialHair:			 
		Result = GetCategoryValue("Beards", UpdatedUnitState.kAppearance.nmBeard, BodyPartFilter.FilterByGenderAndNonSpecialized);
		break;
	case eUICustomizeCat_Personality:			 
		Result = UpdatedUnitState.kAppearance.iAttitude;
		break;
	case eUICustomizeCat_Voice:
		Result = GetCategoryValue("Voice", UpdatedUnitState.kAppearance.nmVoice, BodyPartFilter.FilterByGenderAndCharacterAndNonSpecialized);
		break;
	case eUICustomizeCat_Gender:				 
		Result = UpdatedUnitState.kAppearance.iGender-1;
		break;
	case eUICustomizeCat_Race:					 
		Result = UpdatedUnitState.kAppearance.iRace;
		break;
	case eUICustomizeCat_Helmet:              
		Result = GetCategoryValue("Helmets", UpdatedUnitState.kAppearance.nmHelmet, BodyPartFilter.FilterByGenderAndNonSpecializedAndClassAndTechAndArmor);
		break;
	case eUICustomizeCat_PrimaryArmorColor:   
		Result = UpdatedUnitState.kAppearance.iArmorTint;
		break;
	case eUICustomizeCat_SecondaryArmorColor: 
		Result = UpdatedUnitState.kAppearance.iArmorTintSecondary;
		break;
	case eUICustomizeCat_WeaponColor:
		WeaponTemplate = X2WeaponTemplate(PrimaryWeapon.GetMyTemplate());
		if (WeaponTemplate == None || !WeaponTemplate.bUseArmorAppearance)
			Result = XGWeapon(PrimaryWeapon.GetVisualizer()).m_kAppearance.iWeaponTint;
		else
			Result = XGWeapon(SecondaryWeapon.GetVisualizer()).m_kAppearance.iWeaponTint;
		break;
	case eUICustomizeCat_ArmorPatterns:       
		Result = GetCategoryValue("Patterns", UpdatedUnitState.kAppearance.nmPatterns, BodyPartFilter.FilterAny);
		break;
	case eUICustomizeCat_WeaponPatterns:
		Result = GetCategoryValue("Patterns", XGWeapon(PrimaryWeapon.GetVisualizer()).m_kAppearance.nmWeaponPattern, BodyPartFilter.FilterAny);
		break;
	case eUICustomizeCat_FacePaint:
		Result = GetCategoryValue("Facepaint", UpdatedUnitState.kAppearance.nmFacePaint, BodyPartFilter.FilterAny);
		break;
	case eUICustomizeCat_LeftArmTattoos:
		Result = GetCategoryValue("Tattoos", UpdatedUnitState.kAppearance.nmTattoo_LeftArm, BodyPartFilter.FilterAny);
		break;
	case eUICustomizeCat_RightArmTattoos:
		Result = GetCategoryValue("Tattoos", UpdatedUnitState.kAppearance.nmTattoo_RightArm, BodyPartFilter.FilterAny);
		break;
	case eUICustomizeCat_TattooColor:
		Result = UpdatedUnitState.kAppearance.iTattooTint;
		break;
	case eUICustomizeCat_Scars:
		Result = GetCategoryValue("Scars", UpdatedUnitState.kAppearance.nmScars, BodyPartFilter.FilterByCharacter);
		break;
	case eUICustomizeCat_Class:

		TemplateMan = class'X2SoldierClassTemplateManager'.static.GetSoldierClassTemplateManager();
		TemplateMan.GetTemplateNames(TemplateNames);

		for (idx = 0; idx < TemplateNames.Length; idx++)
		{
			SoldierClassTemplate = TemplateMan.FindSoldierClassTemplate(TemplateNames[idx]);

			if (SoldierClassTemplate.bHideInCharacterPool || SoldierClassTemplate.bMultiplayerOnly || SoldierClassTemplate.RequiredCharacterClass == '')
			{
				TemplateNames.Remove(idx, 1);
				idx--;
			}
		}

		Result = TemplateNames.Find(UpdatedUnitState.GetSoldierClassTemplateName());
		break;
	case eUICustomizeCat_ViewClass:

		TemplateMan = class'X2SoldierClassTemplateManager'.static.GetSoldierClassTemplateManager();
		TemplateMan.GetTemplateNames(TemplateNames);

		for (idx = 0; idx < TemplateNames.Length; idx++)
		{
			SoldierClassTemplate = TemplateMan.FindSoldierClassTemplate(TemplateNames[idx]);

			if (SoldierClassTemplate.bHideInCharacterPool || SoldierClassTemplate.bMultiplayerOnly || SoldierClassTemplate.RequiredCharacterClass != '')
			{
				TemplateNames.Remove(idx, 1);
				idx--;
			}
		}

		Result = TemplateNames.Find(UpdatedUnitState.GetSoldierClassTemplateName());
		break;
	case eUICustomizeCat_Country:
		country = 0;
		StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
		CountryTemplates = StratMgr.GetAllTemplatesOfClass(class'X2CountryTemplate');
		CountryTemplates.Sort(SortCountryTemplates);
		UnitCountryTemplate = UpdatedUnitState.GetCountryTemplate().DataName;
		for(i = 0; i < CountryTemplates.Length; ++i)
		{
			if(UnitCountryTemplate == CountryTemplates[i].DataName)
			{
				Result = country;
				break;
			}

			if(X2CountryTemplate(CountryTemplates[i]).bHideInCustomization == false)
				country++;
		}
		break;
	}

	return Result;
}

simulated function array<string> GetColorList( int catType )
{
	local XComLinearColorPalette Palette;
	local array<string> Colors; 
	local int i; 

	switch (catType)
	{
	case eUICustomizeCat_Skin:	
		Palette = `CONTENT.GetColorPalette(XComHumanPawn(ActorPawn).HeadContent.SkinPalette);
		for( i = 0; i < Palette.Entries.length; i++ )
		{
			Colors.AddItem( class'UIUtilities_Colors'.static.LinearColorToFlashHex( Palette.Entries[i].Primary, UIColorBrightnessAdjust ) );
		}
		break;
	case eUICustomizeCat_HairColor:	
		Palette = `CONTENT.GetColorPalette(ePalette_HairColor);
		for( i = 0; i < Palette.Entries.length; i++ )
		{
			Colors.AddItem( class'UIUtilities_Colors'.static.LinearColorToFlashHex( Palette.Entries[i].Primary, UIColorBrightnessAdjust ) );
		}
		break;
	case eUICustomizeCat_EyeColor:	
		Palette = `CONTENT.GetColorPalette(ePalette_EyeColor);
		for( i = 0; i < Palette.Entries.length; i++ )
		{
			Colors.AddItem( class'UIUtilities_Colors'.static.LinearColorToFlashHex( Palette.Entries[i].Primary, UIColorBrightnessAdjust ) );
		}
		break;
	case eUICustomizeCat_PrimaryArmorColor:	
		Palette = `CONTENT.GetColorPalette(ePalette_ArmorTint);
		for( i = 0; i < Palette.Entries.length; i++ )
		{
			Colors.AddItem( class'UIUtilities_Colors'.static.LinearColorToFlashHex( Palette.Entries[i].Primary, UIColorBrightnessAdjust ) );
		}
		break;
	case eUICustomizeCat_SecondaryArmorColor:	
		Palette = `CONTENT.GetColorPalette(ePalette_ArmorTint);
		for( i = 0; i < Palette.Entries.length; i++ )
		{
			Colors.AddItem( class'UIUtilities_Colors'.static.LinearColorToFlashHex( Palette.Entries[i].Secondary, UIColorBrightnessAdjust ) );
		}
		break;
	case eUICustomizeCat_WeaponColor:
		Palette = `CONTENT.GetColorPalette(ePalette_ArmorTint);
		for(i = 0; i < Palette.Entries.length; i++)
		{
			Colors.AddItem(class'UIUtilities_Colors'.static.LinearColorToFlashHex(Palette.Entries[i].Primary, UIColorBrightnessAdjust));
		}
		break;
	case eUICustomizeCat_TattooColor:
		Palette = `CONTENT.GetColorPalette(ePalette_ArmorTint);
		for(i = 0; i < Palette.Entries.length; i++)
		{
			Colors.AddItem(class'UIUtilities_Colors'.static.LinearColorToFlashHex(Palette.Entries[i].Primary, UIColorBrightnessAdjust));
		}
		break;
	default:
		break;
	}

	return Colors;
}

simulated function string GetCurrentDisplayColorHTML( int catType )
{	
	local XComLinearColorPalette Palette;
	local X2WeaponTemplate WeaponTemplate;
	local int ColorIndex;

	switch (catType)
	{
	case eUICustomizeCat_Skin:	
		Palette = `CONTENT.GetColorPalette(XComHumanPawn(ActorPawn).HeadContent.SkinPalette);
		ColorIndex = UpdatedUnitState.kAppearance.iSkinColor;
		break;
	case eUICustomizeCat_HairColor:	
		Palette = `CONTENT.GetColorPalette(ePalette_HairColor);
		ColorIndex = UpdatedUnitState.kAppearance.iHairColor;
		break;
	case eUICustomizeCat_EyeColor:	
		Palette = `CONTENT.GetColorPalette(ePalette_EyeColor);
		ColorIndex = UpdatedUnitState.kAppearance.iEyeColor;
		break;
	case eUICustomizeCat_PrimaryArmorColor:	
		Palette = `CONTENT.GetColorPalette(ePalette_ArmorTint);
		ColorIndex = UpdatedUnitState.kAppearance.iArmorTint;
		break;
	case eUICustomizeCat_SecondaryArmorColor:	
		Palette = `CONTENT.GetColorPalette(ePalette_ArmorTint);
		ColorIndex = UpdatedUnitState.kAppearance.iArmorTintSecondary;
		break;
	case eUICustomizeCat_WeaponColor:
		Palette = `CONTENT.GetColorPalette(ePalette_ArmorTint);
		WeaponTemplate = X2WeaponTemplate(PrimaryWeapon.GetMyTemplate());
		if (WeaponTemplate == None || !WeaponTemplate.bUseArmorAppearance)
			ColorIndex = PrimaryWeapon.WeaponAppearance.iWeaponTint;
		else
			ColorIndex = SecondaryWeapon.WeaponAppearance.iWeaponTint;
		break;
	case eUICustomizeCat_TattooColor:
		Palette = `CONTENT.GetColorPalette(ePalette_ArmorTint);
		ColorIndex = UpdatedUnitState.kAppearance.iTattooTint;
		break;
	default:
		ColorIndex = -1;
		break;
	}

	if ((ColorIndex >= 0) && (Palette != none))
	{
		if(catType == eUICustomizeCat_SecondaryArmorColor)
			return class'UIUtilities_Colors'.static.LinearColorToFlashHex(Palette.Entries[ColorIndex].Secondary, UIColorBrightnessAdjust);

		return class'UIUtilities_Colors'.static.LinearColorToFlashHex(Palette.Entries[ColorIndex].Primary, UIColorBrightnessAdjust);
	}

	return "";
}

simulated function string GetCurrentSoldierFullDisplayName()
{
	local string soldierName; 
	if( Unit.GetNickName() != "" )
		soldierName = Unit.GetFirstName() @ Unit.GetNickName() @ Unit.GetLastName();
	else
		soldierName = Unit.GetFirstName() @ Unit.GetLastName();

	return soldierName; 
}

function bool ShowMaleOnlyOptions()
{
	return (UpdatedUnitState.kAppearance.iGender == eGender_Male);
}

function bool IsFacialHairDisabled()
{
	return XComHumanPawn(ActorPawn).SuppressBeard(); // Issue #219, consistency
}

simulated function bool IsArmorPatternSelected()
{
	return (0 != GetCategoryValue("Patterns", UpdatedUnitState.kAppearance.nmPatterns, BodyPartFilter.FilterByGenderAndNonSpecialized));
}

simulated function ViewClass(int iSpecificIndex)
{
	local X2SoldierClassTemplateManager TemplateMan;
	local X2SoldierClassTemplate SoldierClassTemplate;
	local array<name> TemplateNames;
	local name TemplateName;
	local int iRandomIndex, idx;
	local Rotator CachedRotation;

	TemplateMan = class'X2SoldierClassTemplateManager'.static.GetSoldierClassTemplateManager();
	TemplateMan.GetTemplateNames(TemplateNames);

	for (idx = 0; idx < TemplateNames.Length; idx++)
	{
		SoldierClassTemplate = TemplateMan.FindSoldierClassTemplate(TemplateNames[idx]);

		if (SoldierClassTemplate.bHideInCharacterPool || SoldierClassTemplate.bMultiplayerOnly || SoldierClassTemplate.RequiredCharacterClass != '')
		{
			TemplateNames.Remove(idx, 1);
			idx--;
		}
	}

	if (iSpecificIndex < TemplateNames.Length && iSpecificIndex > -1)
	{
		TemplateName = TemplateNames[iSpecificIndex];
	}
	else
	{
		iRandomIndex = `SYNC_RAND(TemplateNames.Length);
		TemplateName = TemplateNames[iRandomIndex];
	}

	UpdatedUnitState.SetSoldierClassTemplate(TemplateName);
	if (ActorPawn != none)
	{
		CachedRotation = ActorPawn.Rotation;
		XComPresentationLayerBase(Outer).GetUIPawnMgr().ReleasePawn(XComPresentationLayerBase(Outer), UnitRef.ObjectID);

		CreatePawnVisuals(CachedRotation);
	}
}

simulated function UpdateClass( int iSpecificIndex )
{
	local X2SoldierClassTemplateManager TemplateMan;
	local X2SoldierClassTemplate SoldierClassTemplate;
	local X2CharacterTemplateManager CharTemplateMgr;
	local X2CharacterTemplate CharacterTemplate;
	local array<name> TemplateNames;
	local name TemplateName, CharacterClassName; 
	local int idx;
	local Rotator CachedRotation;
	local TSoldier CharacterGeneratorResult;
	local TAppearance SavedAppearance, NewAppearance;
	local bool bAllowHeadTransfer;

	TemplateMan = class'X2SoldierClassTemplateManager'.static.GetSoldierClassTemplateManager();
	TemplateMan.GetTemplateNames(TemplateNames);
	
	if (iSpecificIndex == 0)
	{
		TemplateName = 'Rookie';
	}
	else
	{
		for (idx = 0; idx < TemplateNames.Length; idx++)
		{
			SoldierClassTemplate = TemplateMan.FindSoldierClassTemplate(TemplateNames[idx]);

			if (SoldierClassTemplate.bHideInCharacterPool || SoldierClassTemplate.bMultiplayerOnly || SoldierClassTemplate.RequiredCharacterClass == '')
			{
				TemplateNames.Remove(idx, 1);
				idx--;
			}
		}

		if ((iSpecificIndex - 1) < TemplateNames.Length && iSpecificIndex > -1)
		{
			// Subtract 1 from the index, since the base game soldier option will always be first
			TemplateName = TemplateNames[iSpecificIndex - 1];
		}
	}

	UpdatedUnitState.SetSoldierClassTemplate( TemplateName );

	SoldierClassTemplate = TemplateMan.FindSoldierClassTemplate(TemplateName);
	CharacterClassName = (SoldierClassTemplate.RequiredCharacterClass != '') ? SoldierClassTemplate.RequiredCharacterClass : 'Soldier';
	if (CharacterClassName != UpdatedUnitState.GetMyTemplateName())
	{
		// Get the new character template based on the soldier class requirement
		CharTemplateMgr = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager();
		CharacterTemplate = CharTemplateMgr.FindCharacterTemplate(CharacterClassName);

		SavedAppearance = UpdatedUnitState.kAppearance;

		// Check to see if head appearance options can be transferred between the character templates
		bAllowHeadTransfer = true;
		if (CharacterTemplate.bHasCharacterExclusiveAppearance || UpdatedUnitState.GetMyTemplate().bHasCharacterExclusiveAppearance)
		{
			bAllowHeadTransfer = false;
			UpdatedUnitState.bAllowedTypeSoldier = true;
			UpdatedUnitState.bAllowedTypeVIP = false;
			UpdatedUnitState.bAllowedTypeDarkVIP = false;
		}

		// Regenerate the unit with their new character template, then generate a new appearance for them
		UpdatedUnitState.OnCreation(CharacterTemplate);
		CharacterGenerator = `XCOMGAME.Spawn(CharacterTemplate.CharacterGeneratorClass);
		CharacterGeneratorResult = CharacterGenerator.CreateTSoldier(, EGender(UpdatedUnitState.kAppearance.iGender));
		NewAppearance = CharacterGeneratorResult.kAppearance;

		// Transfer appearance data that will be the same no matter the class
		NewAppearance.iArmorTint = SavedAppearance.iArmorTint;
		NewAppearance.iArmorTintSecondary = SavedAppearance.iArmorTintSecondary;
		NewAppearance.nmPatterns = SavedAppearance.nmPatterns;
		NewAppearance.iWeaponTint = SavedAppearance.iWeaponTint;
		NewAppearance.nmWeaponPattern = SavedAppearance.nmWeaponPattern;
		NewAppearance.iTattooTint = SavedAppearance.iTattooTint;
		NewAppearance.nmTattoo_LeftArm = SavedAppearance.nmTattoo_LeftArm;
		NewAppearance.nmTattoo_RightArm = SavedAppearance.nmTattoo_RightArm;
		NewAppearance.iEyeColor = SavedAppearance.iEyeColor;
		NewAppearance.iFacialHair = SavedAppearance.iFacialHair;
		NewAppearance.iHairColor = SavedAppearance.iHairColor;
		NewAppearance.iSkinColor = SavedAppearance.iSkinColor;
		NewAppearance.nmFacePaint = SavedAppearance.nmFacePaint;

		if (bAllowHeadTransfer)
		{
			NewAppearance.iRace = SavedAppearance.iRace;
			NewAppearance.nmHead = SavedAppearance.nmHead;
			NewAppearance.nmHaircut = SavedAppearance.nmHaircut;
			NewAppearance.nmBeard = SavedAppearance.nmBeard;
			NewAppearance.nmHelmet = SavedAppearance.nmHelmet;
			NewAppearance.nmFacePropLower = SavedAppearance.nmFacePropLower;
			NewAppearance.nmFacePropUpper = SavedAppearance.nmFacePropUpper;
		}
		else
		{
			UpdatedUnitState.SetUnitName(CharacterGeneratorResult.strFirstName, CharacterGeneratorResult.strLastName, UpdatedUnitState.GetNickName());
		}

		// Now overwrite the unit state with the modified appearance data
		UpdatedUnitState.SetTAppearance(NewAppearance);
		UpdatedUnitState.SetCountry(CharacterGeneratorResult.nmCountry);
		UpdatedUnitState.UpdatePersonalityTemplate(); // Grab the personality based on the one set in kAppearance

		ReCreatePawnVisuals(ActorPawn);
	}
	else if (ActorPawn != none)
	{
		CachedRotation = ActorPawn.Rotation;
		XComPresentationLayerBase(Outer).GetUIPawnMgr().ReleasePawn(XComPresentationLayerBase(Outer), UnitRef.ObjectID);

		CreatePawnVisuals(CachedRotation);
	}
}

simulated function UpdateAllowedTypeSoldier(int iSpecificIndex)
{
	UpdatedUnitState.bAllowedTypeSoldier = (iSpecificIndex != 0 ? true : false);
}
simulated function UpdateAllowedTypeVIP(int iSpecificIndex)
{
	UpdatedUnitState.bAllowedTypeVIP = (iSpecificIndex != 0 ? true : false);
}
simulated function UpdateAllowedTypeDarkVIP(int iSpecificIndex)
{
	UpdatedUnitState.bAllowedTypeDarkVIP = (iSpecificIndex != 0 ? true : false);
}

simulated function UpdateCountry(int iSpecificIndex)
{
	local X2StrategyElementTemplateManager StratMgr;
	local array<X2StrategyElementTemplate> CountryTemplates;
	local X2CountryTemplate CountryTemplate;
	local name TemplateName;
	local int idx;

	StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
	CountryTemplates = StratMgr.GetAllTemplatesOfClass(class'X2CountryTemplate');
	CountryTemplates.Sort(SortCountryTemplates);

	// Remove any country templates that shouldn't be available for customization
	for (idx = 0; idx < CountryTemplates.Length; idx++)
	{
		CountryTemplate = X2CountryTemplate(CountryTemplates[idx]);
		if (CountryTemplate.bHideInCustomization)
		{
			CountryTemplates.RemoveItem(CountryTemplate);
			idx--;
		}
	}

	if(iSpecificIndex < CountryTemplates.Length && iSpecificIndex > -1)
	{
		TemplateName = CountryTemplates[iSpecificIndex].DataName;
	}
	else
	{
		//TODO: @nway or @gameplay: how do we store a real random/any country for the pool to load in? 
		TemplateName = CountryTemplates[0].DataName;
	}

	UpdatedUnitState.SetCountry(TemplateName);

	//Country changes the flag on the unit, so remake the unit
	XComHumanPawn(ActorPawn).SetAppearance(UpdatedUnitState.kAppearance);
}

simulated function int SortCountryTemplates(X2StrategyElementTemplate A, X2StrategyElementTemplate B)
{
	local X2CountryTemplate CountryA, CountryB;
	CountryA = X2CountryTemplate(A);
	CountryB = X2CountryTemplate(B);
	if (CountryA.DisplayName < CountryB.DisplayName)
		return 1;
	else if (CountryA.DisplayName > CountryB.DisplayName)
		return -1;
	return 0;
}

//==============================================================================

function CommitChanges()
{
	local CharacterPoolManager cpm;

	if(Unit != none)
	{
		SubmitUnitCustomizationChanges();

		cpm = CharacterPoolManager(`XENGINE.GetCharacterPoolManager());
		cpm.SaveCharacterPool();

		if(`GAME != none)
		{
			`GAME.GetGeoscape().m_kBase.m_kCrewMgr.TakeCrewPhotobgraph(Unit.GetReference(), true);
		}		
	}

	if(PrimaryWeapon != None &&
	   UpdatedUnitState.GetPrimaryWeapon() == PrimaryWeapon) //Only do this if we are in the avenger, and not the character pool
	{
		SubmitWeaponCustomizationChanges();
	}
		
}

simulated function OnDeactivate( bool bAcceptChanges )
{
	if( bAcceptChanges )
	{
		CommitChanges();
	}

	XComPresentationLayerBase(Outer).GetUIPawnMgr().ReleasePawn(XComPresentationLayerBase(Outer), UnitRef.ObjectID);

	if( CharacterGenerator != None )
	{
		CharacterGenerator.Destroy();
	}

	if (PartManager.DisablePostProcessWhenCustomizing)
	{
		class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController().ConsoleCommand("show postprocess");
	}

	//Clear out any delegates that may be around.
	arrGetIconsForBodyPartDelegates.length = 0;
}

simulated function SubmitUnitCustomizationChanges()
{
	local XComGameState_Unit OriginalUnit;
	local XComGameState NewGameState;
	local bool bIsUnitInHistory;

	bIsUnitInHistory = (History.GetGameStateForObjectID(Unit.ObjectID) != none);
	OriginalUnit = bIsUnitInHistory ? XComGameState_Unit(Unit.GetPreviousVersion()) : none;

	// Make sure that the Unit is in the history at some point, so we know we aren't in the character pool
	// Then submit a modified version of the unit to the history if its customization has changed
	if (bIsUnitInHistory && (OriginalUnit == none || HasUnitAppearanceChanged(OriginalUnit)))
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Unit Customize");
		Unit = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', Unit.ObjectID));
		Unit.SetSoldierClassTemplate(Unit.GetSoldierClassTemplate().DataName);
		Unit.SetTAppearance(UpdatedUnitState.kAppearance);
		Unit.SetCharacterName(UpdatedUnitState.SafeGetCharacterFirstName(), UpdatedUnitState.SafeGetCharacterLastName(), UpdatedUnitState.SafeGetCharacterNickName());
		Unit.SetCountry(UpdatedUnitState.GetCountry());
		`GAMERULES.SubmitGameState(NewGameState);
	}
}

simulated function bool HasUnitAppearanceChanged(XComGameState_Unit OriginalUnit)
{
	if (OriginalUnit.kAppearance != UpdatedUnitState.kAppearance)
	{
		return true;
	}

	if (OriginalUnit.SafeGetCharacterFirstName() != UpdatedUnitState.SafeGetCharacterFirstName() ||
		OriginalUnit.SafeGetCharacterLastName() != UpdatedUnitState.SafeGetCharacterLastName() ||
		OriginalUnit.SafeGetCharacterNickName() != UpdatedUnitState.SafeGetCharacterNickName())
	{
		return true;
	}	

	if (OriginalUnit.GetCountry() != UpdatedUnitState.GetCountry())
	{
		return true;
	}

	return false;
}

simulated function SubmitWeaponCustomizationChanges()
{
	local XComGameState WeaponCustomizationState;
	local XComGameState_Item UpdatedWeapon;
	local XComGameStateContext_ChangeContainer ChangeContainer;

	if(HasWeaponAppearanceChanged()) 
	{
		ChangeContainer = class'XComGameStateContext_ChangeContainer'.static.CreateEmptyChangeContainer("Weapon Customize");
		WeaponCustomizationState = History.CreateNewGameState(true, ChangeContainer);
		UpdatedWeapon = XComGameState_Item(WeaponCustomizationState.ModifyStateObject(class'XComGameState_Item', PrimaryWeapon.ObjectID));
		UpdatedWeapon.WeaponAppearance = XGWeapon(PrimaryWeapon.GetVisualizer()).m_kAppearance;
		`GAMERULES.SubmitGameState(WeaponCustomizationState);
	}
}

simulated function bool HasWeaponAppearanceChanged()
{
	local XComGameState_Item PrevState;
	local TWeaponAppearance WeaponAppearance;

	PrevState = XComGameState_Item(History.GetGameStateForObjectID(PrimaryWeapon.ObjectID));
	WeaponAppearance = PrimaryWeapon.WeaponAppearance;

	return PrevState.WeaponAppearance != WeaponAppearance;
}


//==============================================================================

defaultproperties
{
	RegularCameraTag="UIBlueprint_CustomizeMenu"
	RegularDisplayTag="UIBlueprint_CustomizeMenu"
	HeadCameraTag="UIBlueprint_CustomizeHead"
	HeadDisplayTag="UIBlueprint_CustomizeHead"
	LegsCameraTag="UIBlueprint_CustomizeLegs"
	LegsDisplayTag="UIBlueprint_CustomizeLegs"

	LargeUnitScale = 0.84
}
