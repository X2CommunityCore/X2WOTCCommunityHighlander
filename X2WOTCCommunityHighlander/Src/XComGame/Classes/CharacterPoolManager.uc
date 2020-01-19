//---------------------------------------------------------------------------------------
//  FILE:    CharacterPoolManager.uc
//  AUTHOR:  Ned Way --  9/17/2014
//  PURPOSE: Edit the soldier's name and nationality. 
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class CharacterPoolManager 
	extends Object 
	native(Core)
	dependson(XGTacticalGameCoreNativeBase, XGCharacterGenerator)
	config(Game);


enum ECharacterPoolSelectionMode
{
	eCPSM_None,
	eCPSM_PoolOnly,
	eCPSM_Mixed,
	eCPSM_RandomOnly,
};

//Used to serialize data into / out of the character bool bin file
struct native CharacterPoolDataElement
{
	var string strFirstName;
	var string strLastName;
	var string strNickName;
	var name m_SoldierClassTemplateName;
	var name CharacterTemplateName;
	var TAppearance kAppearance;
	var name Country;
	var bool AllowedTypeSoldier;
	var bool AllowedTypeVIP;
	var bool AllowedTypeDarkVIP;
	var string PoolTimestamp;
	var string BackgroundText;
};

var ECharacterPoolSelectionMode SelectionMode;

var array<XComGameState_Unit> CharacterPool;

var string PoolFileName;

var CharacterPoolDataElement CharacterPoolSerializeHelper; //temp to use for serializing data

var int GenderHelper; //temp storage for Gender Comparison

var string ImportDirectoryName;

var config array<name> CanConvertToVIPTemplateNames;

native static function EnumerateImportablePools(out array<string> FriendlyNames, out array<string> FileNames);

function native LoadCharacterPool();
function native LoadBaseGameCharacterPool();
function native SaveCharacterPool();
function native DeleteCharacterPool();

function native string GetBaseGameCharacterPoolName();

event XComGameState_Unit CreateSoldier(name DataTemplateName)
{
	local XComGameState					SoldierContainerState;
	local XComGameState_Unit			NewSoldierState;	

	// Create the new soldiers
	local X2CharacterTemplateManager    CharTemplateMgr;	
	local X2CharacterTemplate           CharacterTemplate;
	local TSoldier                      CharacterGeneratorResult;
	local XGCharacterGenerator          CharacterGenerator;

	local XComGameStateHistory			History;

	local XComGameStateContext_ChangeContainer ChangeContainer;


	//Create a new game state that will form the start state for the tactical battle. Use this helper method to set up the basics and
	//get a reference to the battle data object
	//NewStartState = class'XComGameStateContext_TacticalGameRule'.static.CreateDefaultTacticalStartState_Singleplayer(BattleData);

	History = `XCOMHISTORY;
	
	//Create a game state to use for creating a unit
	ChangeContainer = class'XComGameStateContext_ChangeContainer'.static.CreateEmptyChangeContainer("Character Pool Manager");
	SoldierContainerState = History.CreateNewGameState(true, ChangeContainer);

	CharTemplateMgr = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager();
	`assert(CharTemplateMgr != none);

	CharacterTemplate = CharTemplateMgr.FindCharacterTemplate(DataTemplateName);	

	if (CharacterTemplate != none)
	{
		CharacterGenerator = `XCOMGAME.Spawn(CharacterTemplate.CharacterGeneratorClass);
		`assert(CharacterGenerator != none);

		NewSoldierState = CharacterTemplate.CreateInstanceFromTemplate(SoldierContainerState);
		NewSoldierState.RandomizeStats();

		NewSoldierState.bAllowedTypeSoldier = true;

		CharacterGeneratorResult = CharacterGenerator.CreateTSoldier(DataTemplateName);
		NewSoldierState.SetTAppearance(CharacterGeneratorResult.kAppearance);
		NewSoldierState.SetCharacterName(CharacterGeneratorResult.strFirstName, CharacterGeneratorResult.strLastName, CharacterGeneratorResult.strNickName);
		NewSoldierState.SetCountry(CharacterGeneratorResult.nmCountry);
		class'XComGameState_Unit'.static.NameCheck(CharacterGenerator, NewSoldierState, eNameType_Full);

		NewSoldierState.GenerateBackground(, CharacterGenerator.BioCountryName);
	}
	
	//Tell the history that we don't actually want this game state
	History.CleanupPendingGameState(SoldierContainerState);

	return NewSoldierState;
}

//Used as part of serialization - this event is called when saving the character pool data out
event FillCharacterPoolData(XComGameState_Unit Unit)
{	
	CharacterPoolSerializeHelper.strFirstName = Unit.GetFirstName();
	CharacterPoolSerializeHelper.strLastName = Unit.GetLastName();
	CharacterPoolSerializeHelper.strNickName = Unit.GetNickName();	
	CharacterPoolSerializeHelper.m_SoldierClassTemplateName = Unit.GetSoldierClassTemplate().DataName;
	CharacterPoolSerializeHelper.CharacterTemplateName = Unit.GetMyTemplate().DataName;
	CharacterPoolSerializeHelper.kAppearance = Unit.kAppearance;
	CharacterPoolSerializeHelper.Country = Unit.GetCountry();
	CharacterPoolSerializeHelper.AllowedTypeSoldier = Unit.bAllowedTypeSoldier;
	CharacterPoolSerializeHelper.AllowedTypeVIP = Unit.bAllowedTypeVIP;
	CharacterPoolSerializeHelper.AllowedTypeDarkVIP = Unit.bAllowedTypeDarkVIP;
	CharacterPoolSerializeHelper.PoolTimestamp = Unit.PoolTimestamp;
	CharacterPoolSerializeHelper.BackgroundText = Unit.GetBackground();
}

event InitSoldier( XComGameState_Unit Unit, const out CharacterPoolDataElement CharacterPoolData )
{
	local XGCharacterGenerator CharacterGenerator;
	local TSoldier             CharacterGeneratorResult;

	Unit.SetSoldierClassTemplate(CharacterPoolData.m_SoldierClassTemplateName);
	Unit.SetCharacterName(CharacterPoolData.strFirstName, CharacterPoolData.strLastName, CharacterPoolData.strNickName);
	Unit.SetTAppearance(CharacterPoolData.kAppearance);
	Unit.SetCountry(CharacterPoolData.Country);
	Unit.SetBackground(CharacterPoolData.BackgroundText);

	Unit.bAllowedTypeSoldier = CharacterPoolData.AllowedTypeSoldier;
	Unit.bAllowedTypeVIP = CharacterPoolData.AllowedTypeVIP;
	Unit.bAllowedTypeDarkVIP = CharacterPoolData.AllowedTypeDarkVIP;

	Unit.PoolTimestamp = CharacterPoolData.PoolTimestamp;

	if (!(Unit.bAllowedTypeSoldier || Unit.bAllowedTypeVIP || Unit.bAllowedTypeDarkVIP))
		Unit.bAllowedTypeSoldier = true;

	//No longer re-creates the entire character, just set the invalid attributes to the first element
	//if (!ValidateAppearance(CharacterPoolData.kAppearance))
	if (!FixAppearanceOfInvalidAttributes(Unit.kAppearance))
	{
		//This should't fail now that we attempt to fix invalid attributes
		CharacterGenerator = `XCOMGRI.Spawn(Unit.GetMyTemplate().CharacterGeneratorClass);
		`assert(CharacterGenerator != none);
		CharacterGeneratorResult = CharacterGenerator.CreateTSoldierFromUnit(Unit, none);
		Unit.SetTAppearance(CharacterGeneratorResult.kAppearance);
	}
}

function bool FixAppearanceOfInvalidAttributes_FixSingle(string PartsType, out name PartsName, optional bool ArmorTorsoFilter)
{
	local X2BodyPartTemplateManager PartTemplateManager;
	local array<X2BodyPartTemplate> listPartTemplate;
	local X2SimpleBodyPartFilter BodyPartFilter;

	BodyPartFilter = `XCOMGAME.SharedBodyPartFilter;

	PartTemplateManager = class'X2BodyPartTemplateManager'.static.GetBodyPartTemplateManager();
	if (!(PartTemplateManager.FindUberTemplate(PartsType, PartsName) != none))
	{
		if(PartsType == "Torso")
		{
			BodyPartFilter.Set(BodyPartFilter.Gender, BodyPartFilter.Race, '');
			BodyPartFilter.SetTorsoSelection('NoCharacterTemplateName', 'KevlarArmor');
			PartTemplateManager.GetFilteredUberTemplates(PartsType, BodyPartFilter,
														 BodyPartFilter.FilterTorso, listPartTemplate);
		}
		else
		{
			PartTemplateManager.GetFilteredUberTemplates(PartsType, BodyPartFilter,
														 ArmorTorsoFilter ? BodyPartFilter.FilterByTorsoAndArmorMatch : BodyPartFilter.FilterByGenderAndCharacterAndNonSpecializedAndTech, listPartTemplate);
		}
		
		PartsName = (listPartTemplate.length > 0) ? listPartTemplate[0].DataName : '';
		if (len(PartsName) <= 0)
			return false;
	}
	return true;
}

function bool FixUnderlay(out TAppearance Appearance)
{
	local X2BodyPartTemplateManager PartTemplateManager;
	local X2SimpleBodyPartFilter BodyPartFilter;

	BodyPartFilter = `XCOMGAME.SharedBodyPartFilter;
	PartTemplateManager = class'X2BodyPartTemplateManager'.static.GetBodyPartTemplateManager();

	if(!(PartTemplateManager.FindUberTemplate("Torso", Appearance.nmTorso_Underlay) != none))
	{
		BodyPartFilter.Set(EGender(Appearance.iGender), ECharacterRace(Appearance.iRace), '');
		BodyPartFilter.SetTorsoSelection('NoCharacterTemplate', 'Underlay'); //Force underlay selection
		Appearance.nmTorso_Underlay = PartTemplateManager.GetRandomUberTemplate("Torso", BodyPartFilter, BodyPartFilter.FilterTorso).DataName;

		BodyPartFilter.Set(EGender(Appearance.iGender), ECharacterRace(Appearance.iRace), Appearance.nmTorso_Underlay);
		Appearance.nmLegs_Underlay = PartTemplateManager.GetRandomUberTemplate("Legs", BodyPartFilter, BodyPartFilter.FilterByTorsoAndArmorMatch).DataName;
		Appearance.nmArms_Underlay = PartTemplateManager.GetRandomUberTemplate("Arms", BodyPartFilter, BodyPartFilter.FilterByTorsoAndArmorMatch).DataName;
	}
	
	return Appearance.nmTorso_Underlay != '';
}

function bool FixAppearanceOfInvalidAttributes(out TAppearance Appearance)
{
	local bool bSuccess;
	bSuccess = true;	
	GenderHelper = Appearance.iGender;
	`XCOMGAME.SharedBodyPartFilter.Set(EGender(Appearance.iGender), ECharacterRace(Appearance.iRace), Appearance.nmTorso, false, true);
	bSuccess = bSuccess && FixAppearanceOfInvalidAttributes_FixSingle("Torso", Appearance.nmTorso, true);
	bSuccess = bSuccess && FixAppearanceOfInvalidAttributes_FixSingle("Head", Appearance.nmHead);
	`XCOMGAME.SharedBodyPartFilter.Set(EGender(Appearance.iGender), ECharacterRace(Appearance.iRace), Appearance.nmTorso, false, true);
	bSuccess = bSuccess && FixAppearanceOfInvalidAttributes_FixSingle("Legs", Appearance.nmLegs, true);
	bSuccess = bSuccess && FixAppearanceOfInvalidAttributes_FixSingle("Arms", Appearance.nmArms, true);
	bSuccess = bSuccess && FixAppearanceOfInvalidAttributes_FixSingle("Hair", Appearance.nmHaircut);
	bSuccess = bSuccess && FixAppearanceOfInvalidAttributes_FixSingle("Eyes", Appearance.nmEye);
	bSuccess = bSuccess && FixAppearanceOfInvalidAttributes_FixSingle("Teeth", Appearance.nmTeeth);
	//currently decokit assets are only male, can be commented out when there are female assets 
	//bSuccess = bSuccess && FixAppearanceOfInvalidAttributes_FixSingle("DecoKits", Appearance.nmDecoKit);
	bSuccess = bSuccess && FixAppearanceOfInvalidAttributes_FixSingle("Helmets", Appearance.nmHelmet);
	bSuccess = bSuccess && FixAppearanceOfInvalidAttributes_FixSingle("Patterns", Appearance.nmPatterns);
	bSuccess = bSuccess && FixAppearanceOfInvalidAttributes_FixSingle("Patterns", Appearance.nmWeaponPattern);
	bSuccess = bSuccess && FixAppearanceOfInvalidAttributes_FixSingle("Tattoos", Appearance.nmTattoo_LeftArm);
	bSuccess = bSuccess && FixAppearanceOfInvalidAttributes_FixSingle("Tattoos", Appearance.nmTattoo_RightArm);
	bSuccess = bSuccess && FixAppearanceOfInvalidAttributes_FixSingle("Scars", Appearance.nmScars);
	bSuccess = bSuccess && FixAppearanceOfInvalidAttributes_FixSingle("Voice", Appearance.nmVoice);

	//Underlay special case
	bSuccess = bSuccess && FixUnderlay(Appearance);

	return bSuccess;
}

function bool ValidateAppearance(const out TAppearance Appearance)
{
	local X2BodyPartTemplateManager PartTemplateManager;
	local bool bValid;

	PartTemplateManager = class'X2BodyPartTemplateManager'.static.GetBodyPartTemplateManager();

	bValid = true;
	bValid = bValid && PartTemplateManager.FindUberTemplate("Torso", Appearance.nmTorso) != none;
	bValid = bValid && PartTemplateManager.FindUberTemplate("Head", Appearance.nmHead) != none;
	bValid = bValid && PartTemplateManager.FindUberTemplate("Legs", Appearance.nmLegs) != none;

	//Check for dual arm as well as individual arm selections
	if(PartTemplateManager.FindUberTemplate("Arms", Appearance.nmArms) == none &&
	   PartTemplateManager.FindUberTemplate("LeftArm", Appearance.nmLeftArm) == none)
	{
		bValid = false;
	}

	bValid = bValid && PartTemplateManager.FindUberTemplate("Arms", Appearance.nmArms) != none;
	bValid = bValid && PartTemplateManager.FindUberTemplate("Hair", Appearance.nmHaircut) != none;
	bValid = bValid && PartTemplateManager.FindUberTemplate("Eyes", Appearance.nmEye) != none;
	bValid = bValid && PartTemplateManager.FindUberTemplate("Teeth", Appearance.nmTeeth) != none;	
	bValid = bValid && PartTemplateManager.FindUberTemplate("Helmets", Appearance.nmHelmet) != none;
	bValid = bValid && PartTemplateManager.FindUberTemplate("Patterns", Appearance.nmPatterns) != none;
	bValid = bValid && PartTemplateManager.FindUberTemplate("Tattoos", Appearance.nmTattoo_LeftArm) != none;
	bValid = bValid && PartTemplateManager.FindUberTemplate("Tattoos", Appearance.nmTattoo_RightArm) != none;
	bValid = bValid && PartTemplateManager.FindUberTemplate("Scars", Appearance.nmScars) != none;
	bValid = bValid && PartTemplateManager.FindUberTemplate("Patterns", Appearance.nmWeaponPattern) != none;

	return bValid;
}

function OnCharacterModified(XComGameState_Unit Character)
{
	SaveCharacterPool();
}

function RemoveUnit( XComGameState_Unit Character )
{
	CharacterPool.RemoveItem(Character);
}

function ECharacterPoolSelectionMode GetSelectionMode(ECharacterPoolSelectionMode OverrideMode)
{

	if( OverrideMode != eCPSM_None && OverrideMode != eCPSM_Mixed )
		return OverrideMode;

	// check for mixed, 50-50 chance of random/pool
	if( OverrideMode == eCPSM_Mixed || SelectionMode == eCPSM_Mixed )
	{
		if( `SYNC_RAND(2) == 1 )
			return eCPSM_PoolOnly;
		else
			return eCPSM_RandomOnly;

	}

	return SelectionMode;
}

function XComGameState_Unit CreateCharacter(XComGameState StartState, optional ECharacterPoolSelectionMode SelectionModeOverride = eCPSM_None, optional name CharacterTemplateName, optional name ForceCountry, optional string UnitName )
{
	local array<int> Indices;
	local int i;

	local X2CharacterTemplateManager CharTemplateMgr;	
	local X2CharacterTemplate CharacterTemplate;
	local XGCharacterGenerator CharacterGenerator;
	local TSoldier CharacterGeneratorResult;

	local XComGameState_Unit SoldierState;
	local XComGameState_Unit Unit;
	local XComGameState_Unit SelectedUnit;
	local int RemoveValue;

	local int SelectedIndex;

	local ECharacterPoolSelectionMode Mode;

	Mode = GetSelectionMode(SelectionModeOverride);

	if( CharacterPool.Length == 0 )
		Mode = eCPSM_RandomOnly;

	// by this point, we should have either pool or random as our mode
	`assert( Mode != eCPSM_None && Mode != eCPSM_Mixed);

	// pool only can still fall through and do random if there's no pool characters unused or available
	if( Mode == eCPSM_PoolOnly )
	{

		for( i=0; i<CharacterPool.Length; i++ )
		{
			if(UnitName == "" || CharacterPool[i].GetFullName() == UnitName)
			{
				Indices.AddItem(i);
			}
		}

		if( Indices.Length != 0 )
		{

			// this may need to be sped up with a map and a hash
			foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Unit', Unit )
			{
				RemoveValue = -1;

				for( i=0; i<Indices.Length; i++ )
				{
					if( CharacterPool[Indices[i]].GetFirstName() == Unit.GetFirstName() &&
						CharacterPool[Indices[i]].GetLastName() == Unit.GetLastName() &&
					    UnitName == "")
					{
						RemoveValue = Indices[i];
					}

					if( RemoveValue != -1 )
					{
						Indices.RemoveItem( RemoveValue );
						RemoveValue = -1; //Reset the search.
						i--;
					}
				}
			}

			// Avoid duplicates by removing character pool units which have already been created and added to the start state
			foreach StartState.IterateByClassType(class'XComGameState_Unit', Unit)
			{
				RemoveValue = -1;

				for (i = 0; i < Indices.Length; i++)
				{
					if (CharacterPool[Indices[i]].GetFirstName() == Unit.GetFirstName() &&
						CharacterPool[Indices[i]].GetLastName() == Unit.GetLastName() &&
						UnitName == "")
					{
						RemoveValue = Indices[i];
					}

					if (RemoveValue != -1)
					{
						Indices.RemoveItem(RemoveValue);
						RemoveValue = -1; //Reset the search.
						i--;
					}
				}
			}
		}
	}

	CharTemplateMgr = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager();
	`assert(CharTemplateMgr != none);

	if(CharacterTemplateName == '')
	{
		CharacterTemplateName = 'Soldier';
	}
	CharacterTemplate = CharTemplateMgr.FindCharacterTemplate(CharacterTemplateName);
	SoldierState = CharacterTemplate.CreateInstanceFromTemplate(StartState);

	//Filter the character pool possibilities by their allowed types
	if (!(CharacterTemplate.bUsePoolVIPs || CharacterTemplate.bUsePoolSoldiers || CharacterTemplate.bUsePoolDarkVIPs))
		`log("Character template requested from pool, but doesn't want any types:" @ CharacterTemplate.Name);

	for (i = 0; i < Indices.Length; i++)
	{
		if (!TypeFilterPassed(CharacterPool[Indices[i]], CharacterTemplate))
		{
			Indices.RemoveItem(Indices[i]);
			i--;
		}
	}
	

	// Indices.Length will be 0 if no characters left in pool or doing a random selection...
	if( Indices.Length != 0 )
	{
		SelectedIndex = `SYNC_RAND( Indices.Length ); 
		
		SelectedUnit = CharacterPool[ Indices[ SelectedIndex ] ];

		SoldierState.SetTAppearance( SelectedUnit.kAppearance );
		SoldierState.SetCharacterName(SelectedUnit.GetFirstName(), SelectedUnit.GetLastName(), SelectedUnit.GetNickName(false));
		SoldierState.SetCountry(SelectedUnit.GetCountry());
		SoldierState.SetBackground(SelectedUnit.GetBackground());
	}
	else
	{

		CharacterGenerator = `XCOMGRI.Spawn(CharacterTemplate.CharacterGeneratorClass);
		`assert(CharacterGenerator != none);

		// Single Line for Issue #70
		/// HL-Docs: ref:Bugfixes; issue:70
		/// `CharacterPoolManager:CreateCharacter` now honors ForceCountry
		CharacterGeneratorResult = CharacterGenerator.CreateTSoldier(CharacterTemplateName, , ForceCountry);

		SoldierState.SetTAppearance(CharacterGeneratorResult.kAppearance);
		SoldierState.SetCharacterName(CharacterGeneratorResult.strFirstName, CharacterGeneratorResult.strLastName, CharacterGeneratorResult.strNickName);
		SoldierState.SetCountry(CharacterGeneratorResult.nmCountry);
		if(!SoldierState.HasBackground())
			SoldierState.GenerateBackground( , CharacterGenerator.BioCountryName);
		class'XComGameState_Unit'.static.NameCheck(CharacterGenerator, SoldierState, eNameType_Full);
	}

	SoldierState.StoreAppearance(); // Save the soldiers appearance so char pool customizations are correct if you swap armors
	return SoldierState;

}

//Returns true if the character CharacterFromPool can be used as a unit of type CharacterTemplate.
function bool TypeFilterPassed(XComGameState_Unit CharacterFromPool, X2CharacterTemplate CharacterTemplate)
{
	if((CharacterTemplate.bUsePoolVIPs && CharacterFromPool.bAllowedTypeVIP) || 
		(CharacterTemplate.bUsePoolDarkVIPs && CharacterFromPool.bAllowedTypeDarkVIP))
	{
		if(CharacterFromPool.GetMyTemplateName() == CharacterTemplate.DataName ||
		   CanConvertToVIPTemplateNames.Find(CharacterFromPool.GetMyTemplateName()) != INDEX_NONE)
		{
			return true;
		}

		return false;
	}

	// First make sure that the character template of the pool unit matches the filter
	if (CharacterFromPool.GetMyTemplateName() != CharacterTemplate.DataName)
		return false;

	if (CharacterTemplate.bUsePoolSoldiers && CharacterFromPool.bAllowedTypeSoldier)
		return true;

	if (!(CharacterFromPool.bAllowedTypeDarkVIP || CharacterFromPool.bAllowedTypeSoldier || CharacterFromPool.bAllowedTypeVIP))
		`log("Character in pool had no allowed types:" @ CharacterFromPool.GetFullName());

	return false;
}

//The expected format for CharacterName is "firstname lastname"
function XComGameState_Unit GetCharacter(string CharacterName)
{
	local int Index;	

	for(Index = 0; Index < CharacterPool.Length; ++Index)
	{
		if(CharacterName == CharacterPool[Index].GetFullName())
		{
			return CharacterPool[Index];
		}
	}

	return none;
}

cpptext
{
	virtual void Serialize(FArchive &Ar);
};

defaultproperties
{
	PoolFileName = "CharacterPool\\DefaultCharacterPool.bin";

	ImportDirectoryName = "CharacterPool\\Importable";

	SelectionMode = eCPSM_Mixed;
}
