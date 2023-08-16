class XGCharacterGenerator extends Actor
	dependson(X2StrategyGameRulesetDataStructures) config(NameList);

// American
var localized array<string> m_arrAmMFirstNames;
var localized array<string> m_arrAmFFirstNames;
var localized array<string> m_arrAmLastNames;
// Arab
var localized array<string> m_arrAbMFirstNames;
var localized array<string> m_arrAbFFirstNames;
var localized array<string> m_arrAbLastNames;
// Israel
var localized array<string> m_arrIsMFirstNames;
var localized array<string> m_arrIsFFirstNames;
var localized array<string> m_arrIsLastNames;
// Russia
var localized array<string> m_arrRsMFirstNames;
var localized array<string> m_arrRsFFirstNames;
var localized array<string> m_arrRsMLastNames;
var localized array<string> m_arrRsFLastnames;
// England
var localized array<string> m_arrEnMFirstNames;
var localized array<string> m_arrEnFFirstNames;
var localized array<string> m_arrEnLastNames;
// French
var localized array<string> m_arrFrMFirstNames;
var localized array<string> m_arrFrFFirstNames;
var localized array<string> m_arrFrLastNames;
// African
var localized array<string> m_arrAfMFirstNames;
var localized array<string> m_arrAfFFirstNames;
var localized array<string> m_arrAfLastNames;
// Japanese
var localized array<string> m_arrJpMFirstNames;
var localized array<string> m_arrJpFFirstNames;
var localized array<string> m_arrJpLastNames;
// Chinese
var localized array<string> m_arrChMFirstNames;
var localized array<string> m_arrChFFirstNames;
var localized array<string> m_arrChLastNames;
// Indian
var localized array<string> m_arrInMFirstNames;
var localized array<string> m_arrInFFirstNames;
var localized array<string> m_arrInLastNames;
// German
var localized array<string> m_arrGmMFirstNames;
var localized array<string> m_arrGmFFirstNames;
var localized array<string> m_arrGmLastNames;
// Italian
var localized array<string> m_arrItMFirstNames;
var localized array<string> m_arrItFFirstNames;
var localized array<string> m_arrItLastNames;
// Mexican
var localized array<string> m_arrMxMFirstNames;
var localized array<string> m_arrMxFFirstNames;
var localized array<string> m_arrMxLastNames;
// Australian
var localized array<string> m_arrAuMFirstNames;
var localized array<string> m_arrAuFFirstNames;
var localized array<string> m_arrAuLastNames;
// Spanish
var localized array<string> m_arrEsMFirstNames;
var localized array<string> m_arrEsFFirstNames;
var localized array<string> m_arrEsLastNames;
// Greece
var localized array<string> m_arrGrMFirstNames;
var localized array<string> m_arrGrFFirstNames;
var localized array<string> m_arrGrLastNames;
// Norway
var localized array<string> m_arrNwMFirstNames;
var localized array<string> m_arrNwFFirstNames;
var localized array<string> m_arrNwLastNames;
// Ireland
var localized array<string> m_arrIrMFirstNames;
var localized array<string> m_arrIrFFirstNames;
var localized array<string> m_arrIrLastNames;
// South Korea
var localized array<string> m_arrSkMFirstNames;
var localized array<string> m_arrSkFFirstNames;
var localized array<string> m_arrSkLastNames;
// The Netherlands
var localized array<string> m_arrDuMFirstNames;
var localized array<string> m_arrDuFFirstNames;
var localized array<string> m_arrDuLastNames;
// Scotland
var localized array<string> m_arrScMFirstNames;
var localized array<string> m_arrScFFirstNames;
var localized array<string> m_arrScLastNames;
// Belgium
var localized array<string> m_arrBgMFirstNames;
var localized array<string> m_arrBgFFirstNames;
var localized array<string> m_arrBgLastNames;
// Poland
var localized array<string> m_arrPlMFirstNames;
var localized array<string> m_arrPlMLastnames;
var localized array<string> m_arrPlFFirstNames;
var localized array<string> m_arrPlFLastNames;

struct LocToSoldierLanguageElement
{
	var string LocString;
	var string GameLanguage;
};

var config array<LocToSoldierLanguageElement> LocToSoldierLanguage; //Allows the game to map the Loc string to an in-game language when picking soldiers

var config float NewSoldier_HatChance;
var config float NewSoldier_UpperFacePropChance;
var config float NewSoldier_LowerFacePropChance;
var config float NewSoldier_BeardChance;
var config bool  NewSoldier_ForceColors; //Forces units to use color selections 0-6 when being spawned

var config float NewCivlian_HatChance;
var config float NewCivlian_UpperFacePropChance;
var config float NewCivlian_LowerFacePropChance;
var config float NewCivlian_BeardChance;

var config float DLCPartPackDefaultChance;

// Temporary variable for uniquely randomized hair so artists
// can see potentially all hair types in a squad.
var int m_iHairType;

// temporary variable for soldier creation, used by TemplateMgr filter functions
// Start unprotect variables for issue #783
var /*protected*/ TSoldier kSoldier;
var /*protected*/ X2BodyPartTemplate kTorsoTemplate;
var /*protected*/ name MatchCharacterTemplateForTorso;
var /*protected*/ name MatchArmorTemplateForTorso;
var /*protected*/ array<name> DLCNames; //List of DLC packs to pull parts from for the currently generating soldier.
// End unprotect variables for issue #783

// Store a country name to be use in bios for soldiers that force a unique country
var name BioCountryName;

// Character groups that use soldier voices
var const config array<name> SoldierVoiceCharacterGroups;
// Variable for Issue #384
var X2CharacterTemplate m_CharTemplate;

// New variable for issue #397
var config(Content) int iDefaultWeaponTint;

// Start issue #783
var XComGameState_Unit GenerateAppearanceForUnitState;
var XComGameState GenerateAppearanceForGameState;
// End issue #783

function GenerateName( int iGender, name CountryName, out string strFirst, out string strLast, optional int iRace = -1 )
{
	local X2StrategyElementTemplateManager StratMgr;
	local X2CountryTemplate CountryTemplate;
	local array<CountryNames> AllNames, GeneralNames, RaceSpecificNames;
	local int idx, iRoll;

	strFirst = "";
	strLast = "";
	StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
	CountryTemplate = X2CountryTemplate(StratMgr.FindStrategyElementTemplate(CountryName));

	for(idx = 0; idx < CountryTemplate.Names.Length; idx++)
	{
		// Add to list of all names
		AllNames.AddItem(CountryTemplate.Names[idx]);

		if(!CountryTemplate.Names[idx].bRaceSpecific)
		{
			// Add to general list of names
			GeneralNames.AddItem(CountryTemplate.Names[idx]);
		}
		else if(CountryTemplate.Names[idx].bRaceSpecific && CountryTemplate.Names[idx].Race == iRace)
		{
			// Add to list of applicable race specific names
			RaceSpecificNames.AddItem(CountryTemplate.Names[idx]);
		}
	}

	// Roll for race specific name
	iRoll = `SYNC_RAND(100);
	while(RaceSpecificNames.Length > 0 && (strFirst == "" || strLast == ""))
	{
		if(RaceSpecificNames.Length == 1 || iRoll < RaceSpecificNames[0].PercentChance)
		{
			if(iGender == eGender_Female)
			{
				strFirst = RaceSpecificNames[0].FemaleNames[`SYNC_RAND(RaceSpecificNames[0].FemaleNames.Length)];
				strLast = RaceSpecificNames[0].FemaleLastNames[`SYNC_RAND(RaceSpecificNames[0].FemaleLastNames.Length)];
			}
			else
			{
				strFirst = RaceSpecificNames[0].MaleNames[`SYNC_RAND(RaceSpecificNames[0].MaleNames.Length)];
				strLast = RaceSpecificNames[0].MaleLastNames[`SYNC_RAND(RaceSpecificNames[0].MaleLastNames.Length)];
			}
		}
		else
		{
			iRoll -= RaceSpecificNames[0].PercentChance;
			RaceSpecificNames.Remove(0, 1);
		}
	}

	// Roll for general name
	iRoll = `SYNC_RAND(100);
	while(GeneralNames.Length > 0 && (strFirst == "" || strLast == ""))
	{
		if(GeneralNames.Length == 1 || iRoll < GeneralNames[0].PercentChance)
		{
			if(iGender == eGender_Female)
			{
				strFirst = GeneralNames[0].FemaleNames[`SYNC_RAND(GeneralNames[0].FemaleNames.Length)];
				strLast = GeneralNames[0].FemaleLastNames[`SYNC_RAND(GeneralNames[0].FemaleLastNames.Length)];
			}
			else
			{
				strFirst = GeneralNames[0].MaleNames[`SYNC_RAND(GeneralNames[0].MaleNames.Length)];
				strLast = GeneralNames[0].MaleLastNames[`SYNC_RAND(GeneralNames[0].MaleLastNames.Length)];
			}	
		}
		else
		{
			iRoll -= GeneralNames[0].PercentChance;
			GeneralNames.Remove(0, 1);
		}
	}

	// Roll on all names (could happen if only race specific names were configured for the country, and input race doesn't match)
	iRoll = `SYNC_RAND(100);
	while(AllNames.Length > 0 && (strFirst == "" || strLast == ""))
	{
		if(AllNames.Length == 1 || iRoll < AllNames[0].PercentChance)
		{
			if(iGender == eGender_Female)
			{
				strFirst = AllNames[0].FemaleNames[`SYNC_RAND(AllNames[0].FemaleNames.Length)];
				strLast = AllNames[0].FemaleLastNames[`SYNC_RAND(AllNames[0].FemaleLastNames.Length)];
			}
			else
			{
				strFirst = AllNames[0].MaleNames[`SYNC_RAND(AllNames[0].MaleNames.Length)];
				strLast = AllNames[0].MaleLastNames[`SYNC_RAND(AllNames[0].MaleLastNames.Length)];
			}		
		}
		else
		{
			iRoll -= AllNames[0].PercentChance;
			AllNames.Remove(0, 1);
		}
	}

	// Fall through case
	if(strFirst == "" || strLast == "")
	{
		if(iGender == eGender_Female)
		{
			strFirst = m_arrAmFFirstNames[`SYNC_RAND(m_arrAmFFirstNames.Length)];
		}
		else
		{
			strFirst = m_arrAmMFirstNames[`SYNC_RAND(m_arrAmMFirstNames.Length)];
		}

		strLast = m_arrAmLastNames[`SYNC_RAND(m_arrAmLastNames.Length)];
	}
}

function name PickOriginCountry()
{
	local X2StrategyElementTemplateManager StratMgr;
	local array<X2StrategyElementTemplate> CountryTemplates;
	local array<name> arrCountries;
	local int idx, i;

	StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
	CountryTemplates = StratMgr.GetAllTemplatesOfClass(class'X2CountryTemplate');

	for(idx = 0; idx < CountryTemplates.Length; idx++)
	{
		for(i = 0; i < X2CountryTemplate(CountryTemplates[idx]).UnitWeight; i++)
		{
			arrCountries.AddItem(CountryTemplates[idx].DataName);
		}
	}

	if(arrCountries.Length > 0)
	{
		return arrCountries[`SYNC_RAND(arrCountries.Length)];
	}
	
	return 'Country_USA';
}

function name DefaultGetRandomUberTemplate_WarnAboutFilter(string PartType)
{
	`log("WARNING:"@ `ShowVar(self) $": Unable to find a GetRandomUberTemplate for '"$PartType$"' given Torso '"$kSoldier.kAppearance.nmTorso$"' Armor '"$MatchArmorTemplateForTorso$"' Character '"$MatchCharacterTemplateForTorso$"'", ,'XCom_Templates');
	return '';
}

//In some cases we already have unit that we want to just want to randomize the appearance of. This method is used for that purpose. UsedGameState is the game state
//that contains Unit
function TSoldier CreateTSoldierFromUnit( XComGameState_Unit Unit, XComGameState UseGameState )
{
	local XComGameState_Item ArmorItem;
	local name ArmorName;
	// Variable for issue #783
	local TSoldier CreatedTSoldier;

	ArmorItem = Unit.GetItemInSlot(eInvSlot_Armor, UseGameState, true);
	ArmorName = ArmorItem == none ? '' : ArmorItem.GetMyTemplateName();	

	// Start issue #783
	GenerateAppearanceForUnitState = Unit;
	GenerateAppearanceForGameState = UseGameState;
	
	CreatedTSoldier = CreateTSoldier( Unit.GetMyTemplateName(), EGender(Unit.kAppearance.iGender), Unit.kAppearance.nmFlag, Unit.kAppearance.iRace, ArmorName );

	// Blank the properties just in case this instance of the Character Generator will be used to also call CreateTSoldier() separately, 
	// which would trigger the 'PostUnitAppearanceGenerated' event another time, but it would still pass the same Unit State and Game State from the time CreateTSoldierFromUnit()
	// was called. So we blank them out to make sure we're not passing irrelevant information with the event.
	GenerateAppearanceForUnitState = none;
	GenerateAppearanceForGameState = none;

	return CreatedTSoldier;
	// End issue #783
}

delegate bool FilterCallback(X2BodyPartTemplate Template);
function X2BodyPartTemplate SetBodyPartToFirstInArray(X2BodyPartTemplateManager PartTemplateManager, out name DataName, string PartTypeName, delegate<FilterCallback> CallbackFn)
{
	local array<X2BodyPartTemplate> listPartTemplate;
	PartTemplateManager.GetFilteredUberTemplates(PartTypeName, `XCOMGAME.SharedBodyPartFilter, CallbackFn, listPartTemplate);
	DataName = (listPartTemplate.length > 0) ? listPartTemplate[0].DataName : DefaultGetRandomUberTemplate_WarnAboutFilter(PartTypeName);
	return (listPartTemplate.length > 0) ? listPartTemplate[0] : none;
}
function X2BodyPartTemplate RandomizeSetBodyPart(X2BodyPartTemplateManager PartTemplateManager, out name DataName, string PartTypeName, delegate<FilterCallback> CallbackFn, optional bool bCanBeEmpty = false)
{
	local X2BodyPartTemplate RandomPart;

	//Clear the template name if it is allowed to be empty
	if(bCanBeEmpty)
	{
		DataName = '';
	}

	RandomPart = PartTemplateManager.GetRandomUberTemplate(PartTypeName, `XCOMGAME.SharedBodyPartFilter, CallbackFn);
	if(!bCanBeEmpty || (RandomPart != none))
	{
		DataName = (RandomPart != none) ? RandomPart.DataName : DefaultGetRandomUberTemplate_WarnAboutFilter(PartTypeName);
	}
	return RandomPart;
}

function UpdateDLCPackFilters()
{
	// Issue #155 follow-up Start
	DLCNames = class'CHHelpers'.static.GetAcceptablePartPacks();
	// Issue #155 End
}

function TSoldier CreateTSoldier( optional name CharacterTemplateName, optional EGender eForceGender, optional name nmCountry = '', optional int iRace = -1, optional name ArmorName )
{
	local XComLinearColorPalette HairPalette;
	local X2SimpleBodyPartFilter BodyPartFilter;
	local X2CharacterTemplate CharacterTemplate;
	local TAppearance DefaultAppearance;

	kSoldier.kAppearance = DefaultAppearance;	
	
	CharacterTemplate = SetCharacterTemplate(CharacterTemplateName, ArmorName);
	// Single Line for Issue #384
	m_CharTemplate = CharacterTemplate;

	if (nmCountry == '')
		nmCountry = PickOriginCountry();
	
	SetCountry(nmCountry);
	SetRace(iRace);
	SetGender(eForceGender);
	kSoldier.iRank = 0;
	
	BodyPartFilter = `XCOMGAME.SharedBodyPartFilter;

	//When generating new characters, consider the DLC pack filters.
	//Use the player's settings from Options->Game Options to pick which DLC / Mod packs this generated soldier should draw from
	UpdateDLCPackFilters();
	
	SetTorso(BodyPartFilter, CharacterTemplateName);
	SetArmsLegsAndDeco(BodyPartFilter);
	SetHead(BodyPartFilter, CharacterTemplate);
	SetAccessories(BodyPartFilter, CharacterTemplateName);
	SetUnderlay(BodyPartFilter);
	SetArmorTints(CharacterTemplate);
	
	HairPalette = `CONTENT.GetColorPalette(ePalette_HairColor);
	kSoldier.kAppearance.iHairColor = ChooseHairColor(kSoldier.kAppearance, HairPalette.BaseOptions); // Only generate with base options
	kSoldier.kAppearance.iEyeColor = 0; //right now initialized to the first one, todo when we decides which are the base colors for the different races.
		
	// SHIP HACK: There are at least 5 base options for every palette. I am not proud. -- jboswell
	kSoldier.kAppearance.iSkinColor = Rand(5);

	SetVoice(CharacterTemplateName, nmCountry);
	SetAttitude();
	GenerateName( kSoldier.kAppearance.iGender, kSoldier.nmCountry, kSoldier.strFirstName, kSoldier.strLastName, kSoldier.kAppearance.iRace );

	BioCountryName = kSoldier.nmCountry;

	// Start issue #783
	ModifyGeneratedUnitAppearance(CharacterTemplateName, eForceGender, nmCountry, iRace, ArmorName);
	// End issue #783

	return kSoldier;
}

// Start issue #783
final protected function ModifyGeneratedUnitAppearance(optional name CharacterTemplateName, optional EGender eForceGender, optional name nmCountry = '', optional int iRace = -1, optional name ArmorName)
{
	local array<X2DownloadableContentInfo> DLCInfos;
	local int i;
	
	/// HL-Docs: ref:ModifyGeneratedUnitAppearance
	DLCInfos = `ONLINEEVENTMGR.GetDLCInfos(false);
	for (i = 0; i < DLCInfos.Length; i++)
	{
		DLCInfos[i].ModifyGeneratedUnitAppearance(self, CharacterTemplateName, eForceGender, nmCountry, iRace, ArmorName, GenerateAppearanceForUnitState, GenerateAppearanceForGameState);
	}
}
// End issue #783

static function Name GetLanguageByString(optional string strLanguage="")
{
	if (len(strLanguage) == 0)
		strLanguage = GetLanguage();

	switch (strLanguage)
	{
	case "DEU":
		return 'german';
	case "ESN":
		return 'spanish';
	case "FRA":
		return 'french';
	case "ITA":
		return 'italian';	
	}

	return 'english';
}

function Name GetLanguageByCountry(name CountryName)
{
	local X2StrategyElementTemplateManager StratMgr;
	local X2CountryTemplate CountryTemplate;
	local name LanguageName;
	local string LanguageString;
	local string LocString;	
	local int Index;
	local bool bWantsForeignLanguages;
	local XComOnlineProfileSettings ProfileSettings;

	StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
	CountryTemplate = X2CountryTemplate(StratMgr.FindStrategyElementTemplate(CountryName));
	if(CountryTemplate != none)
	{
		LanguageName = CountryTemplate.Language;
	}
	
	ProfileSettings = `XPROFILESETTINGS;
	bWantsForeignLanguages = ProfileSettings != none && ProfileSettings.Data != none && ProfileSettings.Data.m_bForeignLanguages;
	//Try to get a language from the LOC settings if the player has an option set to do so or something is wrong with the country settings
	if(!bWantsForeignLanguages || LanguageName == '') 
	{
		LocString = GetLanguage(); //Get the three letter code for our language
		for(Index = 0; Index < LocToSoldierLanguage.Length; ++Index)
		{
			if(LocString == LocToSoldierLanguage[Index].LocString)
			{				
				LanguageString = string(LanguageName);

				//Do str in str check so that we can match language accents, ie english matching englishUK
				if(InStr(LanguageString, LocToSoldierLanguage[Index].GameLanguage) == -1)
				{
					//The country language did not match our loc settings, change it
					LanguageName = name(LocToSoldierLanguage[Index].GameLanguage);
				}
			}
		}
	}

	//If we STILL don't have a language, pick english
	if(LanguageName == '')
	{
		LanguageName = 'english';
	}
	
	return LanguageName;
}

function name GetVoiceFromCountryAndGender(name CountryName, int iGender)
{
	local name nmLanguage;

	local X2BodyPartTemplateManager PartTemplateManager;
	local X2BodyPartTemplate SelectedVoiceTemplate;

	local array<X2BodyPartTemplate> AllVoiceTemplates;
	local array<X2BodyPartTemplate> FilteredVoiceTemplates;
	local X2BodyPartTemplate VoiceTemplate;
	local X2SimpleBodyPartFilter BodyPartFilter;	

	local int iRoll;
	
	// Get a language spoken in the given country. If the player doesn't want foreign languages, will return a language that matches their loc settings
	nmLanguage = GetLanguageName(CountryName);

	// Get all the Voice body part templates
	PartTemplateManager = class'X2BodyPartTemplateManager'.static.GetBodyPartTemplateManager();
	PartTemplateManager.GetUberTemplates("Voice", AllVoiceTemplates);
	
	// Filter Voice templates, selecting ones that match the determined language and given gender.
	foreach AllVoiceTemplates(VoiceTemplate)
	{
		if (VoiceTemplate.Gender == iGender && VoiceTemplate.Language == nmLanguage && !VoiceTemplate.SpecializedType)
			FilteredVoiceTemplates.AddItem(VoiceTemplate);
	}

	// From the filtered list, select and return a random template.
	if (FilteredVoiceTemplates.Length > 0)
	{
		iRoll = `SYNC_RAND( FilteredVoiceTemplates.Length );
		SelectedVoiceTemplate = FilteredVoiceTemplates[iRoll];

		if (SelectedVoiceTemplate != none)
			return SelectedVoiceTemplate.DataName;
	}

	BodyPartFilter = `XCOMGAME.SharedBodyPartFilter;
	BodyPartFilter.Set(EGender(iGender), ECharacterRace(0), ''); //Just picking voice, only need gender
	VoiceTemplate = PartTemplateManager.GetRandomUberTemplate("Voice", BodyPartFilter, BodyPartFilter.FilterByGenderAndCharacterAndNonSpecialized);

	return VoiceTemplate.DataName;
}

function name GetVoiceFromCountryAndGenderAndCharacter(name CountryName, int Gender, name CharacterTemplateName)
{
	local X2BodyPartTemplateManager PartTemplateManager;
	local array<X2BodyPartTemplate> AllVoiceTemplates;
	local array<X2BodyPartTemplate> FilteredVoiceTemplates;
	local X2BodyPartTemplate VoiceTemplate;
	local name nmLanguage;

	// Get a language spoken in the given country. If the player doesn't want foreign languages, will return a language that matches their loc settings
	nmLanguage = GetLanguageName(CountryName);

	// Get all the Voice body part templates
	PartTemplateManager = class'X2BodyPartTemplateManager'.static.GetBodyPartTemplateManager();
	PartTemplateManager.GetUberTemplates("Voice", AllVoiceTemplates);

	// Filter Voice templates, selecting ones that match the determined language, gender, and character.
	foreach AllVoiceTemplates(VoiceTemplate)
	{
		if (VoiceTemplate.Gender == kSoldier.kAppearance.iGender && VoiceTemplate.Language == nmLanguage && VoiceTemplate.CharacterTemplate == CharacterTemplateName)
		{
			FilteredVoiceTemplates.AddItem(VoiceTemplate);
		}
	}

	// From the filtered list, select and return a random template.
	if (FilteredVoiceTemplates.Length > 0)
	{
		VoiceTemplate = FilteredVoiceTemplates[`SYNC_RAND( FilteredVoiceTemplates.Length )];
	}	

	return VoiceTemplate.DataName;
}

function int ChooseHairColor( const out TAppearance kAppearance, int iNumBaseOptions )
{
	local int iHairChoice;
	local array<int> arrChoices;

	switch( kAppearance.iRace )
	{
	case eRace_African:
		arrChoices.AddItem(11);
		arrChoices.AddItem(12);
		arrChoices.AddItem(13);
		iHairChoice = arrChoices[Rand(arrChoices.Length)];
		break;
	case eRace_Hispanic:
		arrChoices.AddItem(11);
		arrChoices.AddItem(12);
		arrChoices.AddItem(13);
		iHairChoice = arrChoices[Rand(arrChoices.Length)];
		break;
	case eRace_Asian:
		arrChoices.AddItem(11);
		arrChoices.AddItem(12);
		arrChoices.AddItem(13);
		iHairChoice = arrChoices[Rand(arrChoices.Length)];
		break;
	default:
		iHairChoice = Rand(iNumBaseOptions);
		break;
	}

	if( iHairChoice >= iNumBaseOptions )
		iHairChoice = Rand(iNumBaseOptions);

	return iHairChoice;
}

function int ChooseFacialHair( const out TAppearance kAppearance, name nmOrigin, int iNumBaseOptions )
{
	local int iHairChoice;

	if( Rand(4) == 0 )
		iHairChoice = Rand(iNumBaseOptions);
	else
		iHairChoice = 0;

	return iHairChoice;
}

function bool IsSoldier(name CharacterTemplateName)
{
	return (CharacterTemplateName == 'Soldier' || CharacterTemplateName == '');
}

function Name GetLanguageName(name CountryName)
{
	return GetLanguageByCountry(CountryName);
}

function X2CharacterTemplate SetCharacterTemplate(name CharacterTemplateName, name ArmorName)
{
	local X2CharacterTemplate CharacterTemplate;

	if (IsSoldier(CharacterTemplateName))
	{
		MatchArmorTemplateForTorso = (ArmorName == '') ? 'KevlarArmor' : ArmorName;
		MatchCharacterTemplateForTorso = 'NoCharacterTemplateName'; //Force the selector to use the armor type to filter torsos
	}
	else
	{
		MatchArmorTemplateForTorso = 'NoArmor'; //Default armor match value
		MatchCharacterTemplateForTorso = CharacterTemplateName;
	}

	CharacterTemplate = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager().FindCharacterTemplate(CharacterTemplateName);
	if (CharacterTemplate == None)
	{
		CharacterTemplate = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager().FindCharacterTemplate('Soldier');
	}

	return CharacterTemplate;
}

function SetCountry(name nmCountry)
{
	kSoldier.nmCountry = nmCountry;
	kSoldier.kAppearance.nmFlag = kSoldier.nmCountry; // needs to be copied here for pawns -- jboswell
}

function SetRace(int iRace)
{
	if (iRace == -1)
		kSoldier.kAppearance.iRace = GetRandomRaceByCountry(kSoldier.nmCountry);
	else
		kSoldier.kAppearance.iRace = iRace;
}

function SetGender(EGender eForceGender)
{
	if (eForceGender != eGender_None)
		kSoldier.kAppearance.iGender = eForceGender;
	else
		kSoldier.kAppearance.iGender = (Rand(2) == 0) ? eGender_Female : eGender_Male;
}

function SetTorso(out X2SimpleBodyPartFilter BodyPartFilter, name CharacterTemplateName)
{
	local X2BodyPartTemplateManager PartTemplateManager;

	PartTemplateManager = class'X2BodyPartTemplateManager'.static.GetBodyPartTemplateManager();
	
	//Set up for the torso selection
	BodyPartFilter.Set(EGender(kSoldier.kAppearance.iGender), ECharacterRace(kSoldier.kAppearance.iRace), '', , , DLCNames); //Don't have a torso yet	
	BodyPartFilter.SetTorsoSelection(MatchCharacterTemplateForTorso, MatchArmorTemplateForTorso);
	kTorsoTemplate = RandomizeSetBodyPart(PartTemplateManager, kSoldier.kAppearance.nmTorso, "Torso", BodyPartFilter.FilterTorso);

	//Set again now that we have picked our torso
	BodyPartFilter.Set(EGender(kSoldier.kAppearance.iGender), ECharacterRace(kSoldier.kAppearance.iRace), kSoldier.kAppearance.nmTorso, !IsSoldier(CharacterTemplateName), , DLCNames);
}

function SetArmsLegsAndDeco(X2SimpleBodyPartFilter BodyPartFilter)
{
	local X2BodyPartTemplateManager PartTemplateManager;

	PartTemplateManager = class'X2BodyPartTemplateManager'.static.GetBodyPartTemplateManager();

	RandomizeSetBodyPart(PartTemplateManager, kSoldier.kAppearance.nmLegs, "Legs", BodyPartFilter.FilterByTorsoAndArmorMatch);
	RandomizeSetBodyPart(PartTemplateManager, kSoldier.kAppearance.nmArms, "Arms", BodyPartFilter.FilterByTorsoAndArmorMatch, true);

	//If no arm selection, check the left / right arms
	if (kSoldier.kAppearance.nmArms == '')
	{
		RandomizeSetBodyPart(PartTemplateManager, kSoldier.kAppearance.nmLeftArm, "LeftArm", BodyPartFilter.FilterByTorsoAndArmorMatch);
		RandomizeSetBodyPart(PartTemplateManager, kSoldier.kAppearance.nmRightArm, "RightArm", BodyPartFilter.FilterByTorsoAndArmorMatch);
		RandomizeSetBodyPart(PartTemplateManager, kSoldier.kAppearance.nmLeftArmDeco, "LeftArmDeco", BodyPartFilter.FilterByTorsoAndArmorMatch);
		RandomizeSetBodyPart(PartTemplateManager, kSoldier.kAppearance.nmRightArmDeco, "RightArmDeco", BodyPartFilter.FilterByTorsoAndArmorMatch);
	}

	// Start Issue #384
	/// HL-Docs: ref:Bugfixes; issue:384
	/// Randomize deco slots only if the character template is not using `bForceAppearance`.
	// XPack Hero Deco
	if (!m_CharTemplate.bForceAppearance)
	{
		// Start Issue #359
		RandomizeSetBodyPart(PartTemplateManager, kSoldier.kAppearance.nmLeftForearm, "LeftForearm", BodyPartFilter.FilterByTorsoAndArmorMatch);
		RandomizeSetBodyPart(PartTemplateManager, kSoldier.kAppearance.nmRightForearm, "RightForearm", BodyPartFilter.FilterByTorsoAndArmorMatch);
		// End Issue #359
		RandomizeSetBodyPart(PartTemplateManager, kSoldier.kAppearance.nmThighs, "Thighs", BodyPartFilter.FilterByTorsoAndArmorMatch);
		RandomizeSetBodyPart(PartTemplateManager, kSoldier.kAppearance.nmShins, "Shins", BodyPartFilter.FilterByTorsoAndArmorMatch);
		RandomizeSetBodyPart(PartTemplateManager, kSoldier.kAppearance.nmTorsoDeco, "TorsoDeco", BodyPartFilter.FilterByTorsoAndArmorMatch);
	}
	// End Issue #384
}

function SetHead(X2SimpleBodyPartFilter BodyPartFilter, X2CharacterTemplate CharacterTemplate)
{
	local X2BodyPartTemplateManager PartTemplateManager;

	PartTemplateManager = class'X2BodyPartTemplateManager'.static.GetBodyPartTemplateManager();

	if (IsSoldier(CharacterTemplate.DataName))
	{
		RandomizeSetBodyPart(PartTemplateManager, kSoldier.kAppearance.nmHaircut, "Hair", BodyPartFilter.FilterByGenderAndNonSpecialized);
	}
	else
	{
		RandomizeSetBodyPart(PartTemplateManager, kSoldier.kAppearance.nmHaircut, "Hair", BodyPartFilter.FilterByGenderAndNonSpecializedCivilian);
	}

	BodyPartFilter.AddCharacterFilter(CharacterTemplate.DataName, CharacterTemplate.bHasCharacterExclusiveAppearance); // Make sure heads get filtered properly
	RandomizeSetBodyPart(PartTemplateManager, kSoldier.kAppearance.nmHead, "Head", BodyPartFilter.FilterByGenderAndRaceAndCharacterAndClass);
	RandomizeSetBodyPart(PartTemplateManager, kSoldier.kAppearance.nmEye, "Eyes", BodyPartFilter.FilterAny);
	RandomizeSetBodyPart(PartTemplateManager, kSoldier.kAppearance.nmTeeth, "Teeth", BodyPartFilter.FilterAny);
}

function SetAccessories(X2SimpleBodyPartFilter BodyPartFilter, name CharacterTemplateName)
{
	local X2BodyPartTemplateManager PartTemplateManager;

	PartTemplateManager = class'X2BodyPartTemplateManager'.static.GetBodyPartTemplateManager();

	//Custom settings depending on whether the unit is a soldier or not
	SetBodyPartToFirstInArray(PartTemplateManager, kSoldier.kAppearance.nmPatterns, "Patterns", BodyPartFilter.FilterAny);
	SetBodyPartToFirstInArray(PartTemplateManager, kSoldier.kAppearance.nmWeaponPattern, "Patterns", BodyPartFilter.FilterAny);
	SetBodyPartToFirstInArray(PartTemplateManager, kSoldier.kAppearance.nmTattoo_LeftArm, "Tattoos", BodyPartFilter.FilterAny);
	SetBodyPartToFirstInArray(PartTemplateManager, kSoldier.kAppearance.nmTattoo_RightArm, "Tattoos", BodyPartFilter.FilterAny);
	
	if (IsSoldier(CharacterTemplateName))
	{
		if (`SYNC_FRAND() < NewSoldier_BeardChance )
		{
		RandomizeSetBodyPart(PartTemplateManager, kSoldier.kAppearance.nmBeard, "Beards", BodyPartFilter.FilterByGenderAndNonSpecialized);
		}
		else
		{
			SetBodyPartToFirstInArray(PartTemplateManager, kSoldier.kAppearance.nmBeard, "Beards", BodyPartFilter.FilterAny);
		}


		if (`SYNC_FRAND() < NewSoldier_HatChance )
		{
		RandomizeSetBodyPart(PartTemplateManager, kSoldier.kAppearance.nmHelmet, "Helmets", BodyPartFilter.FilterByGenderAndNonSpecializedAndClassAndTechAndArmor);
		}
		else
		{
			SetBodyPartToFirstInArray(PartTemplateManager, kSoldier.kAppearance.nmHelmet, "Helmets", BodyPartFilter.FilterAny);
		}

		if (`SYNC_FRAND() < NewSoldier_LowerFacePropChance )
		{
		RandomizeSetBodyPart(PartTemplateManager, kSoldier.kAppearance.nmFacePropLower, "FacePropsLower", BodyPartFilter.FilterByGenderAndNonSpecialized);
		}
		else
		{
			SetBodyPartToFirstInArray(PartTemplateManager, kSoldier.kAppearance.nmFacePropLower, "FacePropsLower", BodyPartFilter.FilterAny);
		}

		if (`SYNC_FRAND() < NewSoldier_UpperFacePropChance )
		{
		RandomizeSetBodyPart(PartTemplateManager, kSoldier.kAppearance.nmFacePropUpper, "FacePropsUpper", BodyPartFilter.FilterByGenderAndNonSpecialized);
		}
		else
		{
			SetBodyPartToFirstInArray(PartTemplateManager, kSoldier.kAppearance.nmFacePropUpper, "FacePropsUpper", BodyPartFilter.FilterAny);
		}
	}
	else
	{
		if (`SYNC_FRAND() < NewCivlian_BeardChance )
		{
		RandomizeSetBodyPart(PartTemplateManager, kSoldier.kAppearance.nmBeard, "Beards", BodyPartFilter.FilterByGenderAndNonSpecialized);
		}
		else
		{
			SetBodyPartToFirstInArray(PartTemplateManager, kSoldier.kAppearance.nmBeard, "Beards", BodyPartFilter.FilterAny);
		}

		if (`SYNC_FRAND() < NewCivlian_HatChance )
		{
		RandomizeSetBodyPart(PartTemplateManager, kSoldier.kAppearance.nmHelmet, "Helmets", BodyPartFilter.FilterByGenderAndNonSpecializedAndTechAndArmor);
		}
		else
		{
			SetBodyPartToFirstInArray(PartTemplateManager, kSoldier.kAppearance.nmHelmet, "Helmets", BodyPartFilter.FilterAny);
		}

		if (`SYNC_FRAND() < NewCivlian_LowerFacePropChance )
		{
		RandomizeSetBodyPart(PartTemplateManager, kSoldier.kAppearance.nmFacePropLower, "FacePropsLower", BodyPartFilter.FilterByGenderAndNonSpecializedCivilian);
		}
		else
		{
			SetBodyPartToFirstInArray(PartTemplateManager, kSoldier.kAppearance.nmFacePropLower, "FacePropsLower", BodyPartFilter.FilterAny);
		}

		if (`SYNC_FRAND() < NewCivlian_UpperFacePropChance )
		{
		RandomizeSetBodyPart(PartTemplateManager, kSoldier.kAppearance.nmFacePropUpper, "FacePropsUpper", BodyPartFilter.FilterByGenderAndNonSpecializedCivilian);
		}
		else
		{
			SetBodyPartToFirstInArray(PartTemplateManager, kSoldier.kAppearance.nmFacePropUpper, "FacePropsUpper", BodyPartFilter.FilterAny);
		}
	}
}

function SetUnderlay(out X2SimpleBodyPartFilter BodyPartFilter)
{
	local X2BodyPartTemplateManager PartTemplateManager;

	PartTemplateManager = class'X2BodyPartTemplateManager'.static.GetBodyPartTemplateManager();
	
	//All character templates that use the character generator get an underlay definition, reset the filter for underlay part selection	
	BodyPartFilter.Set(EGender(kSoldier.kAppearance.iGender), ECharacterRace(kSoldier.kAppearance.iRace), '');
	BodyPartFilter.SetTorsoSelection(MatchCharacterTemplateForTorso, 'Underlay');
	RandomizeSetBodyPart(PartTemplateManager, kSoldier.kAppearance.nmTorso_Underlay, "Torso", BodyPartFilter.FilterTorso);
	BodyPartFilter.Set(EGender(kSoldier.kAppearance.iGender), ECharacterRace(kSoldier.kAppearance.iRace), kSoldier.kAppearance.nmTorso_Underlay);
	RandomizeSetBodyPart(PartTemplateManager, kSoldier.kAppearance.nmLegs_Underlay, "Legs", BodyPartFilter.FilterByTorsoAndArmorMatch);
	RandomizeSetBodyPart(PartTemplateManager, kSoldier.kAppearance.nmArms_Underlay, "Arms", BodyPartFilter.FilterByTorsoAndArmorMatch);
}

function SetArmorTints(X2CharacterTemplate CharacterTemplate)
{
	local TAppearance DefaultAppearance;
	local XComLinearColorPalette ArmorPalette;
	local int DefaultColors, SkipColors;
	
	//Randomly select colors for new soldiers
	ArmorPalette = `CONTENT.GetColorPalette(ePalette_ArmorTint);
	SkipColors = 10; //The last colors in the palette are rainbow colors, so skip those
	DefaultColors = 7; //Military default colors are 0-7

	//Use the default defined by the character template if set
	if (CharacterTemplate.DefaultAppearance.iArmorTint != DefaultAppearance.iArmorTint)
	{
		kSoldier.kAppearance.iArmorTint = CharacterTemplate.DefaultAppearance.iArmorTint;
	}
	else
	{
		if (NewSoldier_ForceColors)
		{
			kSoldier.kAppearance.iArmorTint = `SYNC_RAND(DefaultColors);
		}
		else
		{
			kSoldier.kAppearance.iArmorTint = `SYNC_RAND(ArmorPalette.Entries.length - SkipColors);
		}
	}

	//Use the default defined by the character template if set
	if (CharacterTemplate.DefaultAppearance.iArmorTintSecondary != DefaultAppearance.iArmorTintSecondary)
	{
		kSoldier.kAppearance.iArmorTintSecondary = CharacterTemplate.DefaultAppearance.iArmorTintSecondary;
	}
	else
	{
		if (NewSoldier_ForceColors)
		{
			kSoldier.kAppearance.iArmorTintSecondary = `SYNC_RAND(DefaultColors);
		}
		else
		{
			kSoldier.kAppearance.iArmorTintSecondary = `SYNC_RAND(ArmorPalette.Entries.length - SkipColors);
		}
	}

	// Begin issue #397
	/// HL-Docs: feature:ChangeDefaultWeaponColor; issue:397; tags:customization
	/// Soldiers with randomly generated appearance get the beige weapon color by default
	/// (color number 20). This change moves the default weapon color number to `XComContent.ini`,
	///	where it can be changed by mods or by the player manually.
	/// ```ini
	/// [XComGame.XGCharacterGenerator]
	/// iDefaultWeaponTint = 20
	/// ```
	kSoldier.kAppearance.iWeaponTint = iDefaultWeaponTint;
	// End issue #397
	kSoldier.kAppearance.iTattooTint = `SYNC_RAND(ArmorPalette.Entries.length - SkipColors);
}

private function bool SetCivilianVoice(const name CharTemplateName)
{
	local X2CharacterTemplate CharTemplate;

	if (CharTemplateName == 'Civilian')
	{
		CharTemplate = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager().FindCharacterTemplate(CharTemplateName);
		if (CharTemplate != none)
		{
			kSoldier.kAppearance.nmVoice = CharTemplate.DefaultAppearance.nmVoice;
			return true;
		}
	}
	return false;
}

private function bool NeedsSoldierVoice(const name CharTemplateName)
{
	local X2CharacterTemplate CharTemplate;

	CharTemplate = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager().FindCharacterTemplate(CharTemplateName);
	return CharTemplate != none && SoldierVoiceCharacterGroups.Find(CharTemplate.CharacterGroupName) != INDEX_NONE;
}

function SetVoice(name CharacterTemplateName, name CountryName)
{
	local X2CharacterTemplate CharTemplate;

	// Determine voice
	// If a civilian is being generated, set its voice according to its editor setting to prevent it from using soldier voices.
	// Otherwise, only set voices for soldiers and specific character groups that use soldier voices.
	if (!SetCivilianVoice(CharacterTemplateName) && (IsSoldier(CharacterTemplateName) || NeedsSoldierVoice(CharacterTemplateName)))
	{
		kSoldier.kAppearance.nmVoice = GetVoiceFromCountryAndGender(CountryName, kSoldier.kAppearance.iGender);

		if (kSoldier.kAppearance.nmVoice == '')
		{
			if (kSoldier.kAppearance.iGender == eGender_Male)
			{
				kSoldier.kAppearance.nmVoice = 'MaleVoice1_English_US';
			}
			else
			{
				kSoldier.kAppearance.nmVoice = 'FemaleVoice1_English_US';
			}
		}
	}
	else
	{
		CharTemplate = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager().FindCharacterTemplate( CharacterTemplateName );
		if ((CharTemplate != none) && CharTemplate.DefaultAppearance.nmVoice != '')
		{
			kSoldier.kAppearance.nmVoice = CharTemplate.DefaultAppearance.nmVoice;
		}
	}
}

function SetAttitude()
{
	local array<X2StrategyElementTemplate> PersonalityTemplates;

	local XComOnlineProfileSettings ProfileSettings;
	local int BronzeScore, HighScore, Choice;

	// Give Random Personality
	PersonalityTemplates = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager().GetAllTemplatesOfClass(class'X2SoldierPersonalityTemplate');

	ProfileSettings = `XPROFILESETTINGS;
	BronzeScore = class'XComGameState_LadderProgress'.static.GetLadderMedalThreshold( 4, 0 );
	HighScore = ProfileSettings.Data.GetLadderHighScore( 4 );

	if (BronzeScore > HighScore)
	{
		do { // repick until we choose something not from TLE
			Choice = `SYNC_RAND(PersonalityTemplates.Length);
		} until (PersonalityTemplates[Choice].ClassThatCreatedUs.Name != 'X2StrategyElement_TLESoldierPersonalities');
	}
	else // anything will do
	{
		Choice = `SYNC_RAND(PersonalityTemplates.Length);
	}

	kSoldier.kAppearance.iAttitude = Choice;
}

function int GetRandomRaceByCountry(name CountryName)
{
	local X2StrategyElementTemplateManager StratMgr;
	local X2CountryTemplate CountryTemplate;
	local int iRoll;

	StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
	CountryTemplate = X2CountryTemplate(StratMgr.FindStrategyElementTemplate(CountryName));

	if(CountryTemplate != none)
	{
		iRoll = `SYNC_RAND(CountryTemplate.Races.iCaucasian + CountryTemplate.Races.iAfrican + 
			CountryTemplate.Races.iHispanic + CountryTemplate.Races.iAsian);

		if(CountryTemplate.Races.iCaucasian > 0 && iRoll < CountryTemplate.Races.iCaucasian)
			return eRace_Caucasian;
		else
			iRoll -= CountryTemplate.Races.iCaucasian;

		if(CountryTemplate.Races.iAfrican > 0 && iRoll < CountryTemplate.Races.iAfrican)
			return eRace_African;
		else
			iRoll -= CountryTemplate.Races.iAfrican;

		if(CountryTemplate.Races.iHispanic > 0 && iRoll < CountryTemplate.Races.iHispanic)
			return eRace_Hispanic;
		else
			iRoll -= CountryTemplate.Races.iHispanic;

		if(CountryTemplate.Races.iAsian > 0 && iRoll < CountryTemplate.Races.iAsian)
			return eRace_Asian;
		else
			iRoll -= CountryTemplate.Races.iAsian;
	}

	return eRace_Caucasian;
}

function string GenerateNickname(X2SoldierClassTemplate Template, int iGender)
{
	local int iNumChoices, iChoice;

	iNumChoices = Template.RandomNickNames.Length;

	if(iGender == eGender_Female)
	{
		iNumChoices += Template.RandomNickNames_Female.Length;
	}
	else if(iGender == eGender_Male)
	{
		iNumChoices += Template.RandomNickNames_Male.Length;
	}

	iChoice = `SYNC_RAND(iNumChoices);

	if(iChoice < Template.RandomNickNames.Length)
	{
		return Template.RandomNickNames[iChoice];
	}
	else
	{
		iChoice -= Template.RandomNickNames.Length;
	}

	if(iGender == eGender_Female)
	{
		return Template.RandomNickNames_Female[iChoice];
	}
	else if(iGender == eGender_Male)
	{
		return Template.RandomNickNames_Male[iChoice];
	}

	return "";
}