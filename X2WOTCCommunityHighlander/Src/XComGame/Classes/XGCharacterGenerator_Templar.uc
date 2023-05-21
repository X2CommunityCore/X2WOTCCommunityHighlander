class XGCharacterGenerator_Templar extends XGCharacterGenerator
	dependson(X2StrategyGameRulesetDataStructures) config(NameList);

var config array<int> PrimaryArmorColors;
var config array<int> SecondaryArmorColors;
var config array<name> MaleHeads;
var config array<Name> FemaleHeads;
var config array<name> MaleHelmets;
var config array<name> FemaleHelmets;

function bool IsSoldier(name CharacterTemplateName)
{
	return true;
}

function X2CharacterTemplate SetCharacterTemplate(name CharacterTemplateName, name ArmorName)
{
	MatchArmorTemplateForTorso = (ArmorName == '') ? 'TemplarArmor' : ArmorName;
	MatchCharacterTemplateForTorso = 'NoCharacterTemplateName'; //Force the selector to use the armor type to filter torsos

	return class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager().FindCharacterTemplate(CharacterTemplateName);
}

function TSoldier CreateTSoldier(optional name CharacterTemplateName, optional EGender eForceGender, optional name nmCountry = '', optional int iRace = -1, optional name ArmorName)
{
	local X2SoldierClassTemplateManager ClassMgr;
	local X2SoldierClassTemplate ClassTemplate;

	kSoldier = super.CreateTSoldier('TemplarSoldier', eForceGender, nmCountry, iRace, ArmorName);
	SetCountry('Country_Templar');
	ClassMgr = class'X2SoldierClassTemplateManager'.static.GetSoldierClassTemplateManager();
	ClassTemplate = ClassMgr.FindSoldierClassTemplate('Templar');
	kSoldier.strNickName = GenerateNickname(ClassTemplate, kSoldier.kAppearance.iGender);

	// Start issue #783
	ModifyGeneratedUnitAppearance(CharacterTemplateName, eForceGender, nmCountry, iRace, ArmorName);
	// End issue #783

	return kSoldier;
}

function SetRace(int iRace)
{
	kSoldier.kAppearance.iRace = eRace_Hispanic;
}

function SetHead(X2SimpleBodyPartFilter BodyPartFilter, X2CharacterTemplate CharacterTemplate)
{
	super.SetHead(BodyPartFilter, CharacterTemplate);

	if (kSoldier.kAppearance.iGender == eGender_Male)
	{
		kSoldier.kAppearance.nmHead = default.MaleHeads[`SYNC_RAND(default.MaleHeads.Length)];
	}
	else
	{
		kSoldier.kAppearance.nmHead = default.FemaleHeads[`SYNC_RAND(default.FemaleHeads.Length)];
	}
}

function SetAccessories(X2SimpleBodyPartFilter BodyPartFilter, name CharacterTemplateName)
{
	super.SetAccessories(BodyPartFilter, CharacterTemplateName);

	if (kSoldier.kAppearance.iGender == eGender_Male)
	{
		kSoldier.kAppearance.nmHelmet = default.MaleHelmets[`SYNC_RAND(default.MaleHelmets.Length)];
	}
	else
	{
		kSoldier.kAppearance.nmHelmet = default.FemaleHelmets[`SYNC_RAND(default.FemaleHelmets.Length)];
	}
}

function SetArmorTints(X2CharacterTemplate CharacterTemplate)
{
	super.SetArmorTints(CharacterTemplate);

	kSoldier.kAppearance.iArmorTint = default.PrimaryArmorColors[`SYNC_RAND(default.PrimaryArmorColors.Length)];
	kSoldier.kAppearance.iArmorTintSecondary = default.SecondaryArmorColors[`SYNC_RAND(default.SecondaryArmorColors.Length)];
}

function SetVoice(name CharacterTemplateName, name CountryName)
{
	if (IsSoldier(CharacterTemplateName))
	{
		kSoldier.kAppearance.nmVoice = GetVoiceFromCountryAndGenderAndCharacter(CountryName, kSoldier.kAppearance.iGender, CharacterTemplateName);
		
		if (kSoldier.kAppearance.nmVoice == '')
		{
			if (kSoldier.kAppearance.iGender == eGender_Male)
			{
				kSoldier.kAppearance.nmVoice = 'TemplarMaleVoice1_Localized';
			}
			else
			{
				kSoldier.kAppearance.nmVoice = 'TemplarFemaleVoice1_Localized';
			}
		}
	}
}

function SetAttitude()
{
	kSoldier.kAppearance.iAttitude = 0; // Should correspond with Personality_ByTheBook
}