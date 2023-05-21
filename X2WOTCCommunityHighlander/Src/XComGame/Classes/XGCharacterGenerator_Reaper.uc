class XGCharacterGenerator_Reaper extends XGCharacterGenerator
	dependson(X2StrategyGameRulesetDataStructures) config(NameList);

var config array<int> PrimaryArmorColors;
var config array<int> SecondaryArmorColors;
var config array<name> MaleHeads;
var config array<Name> FemaleHeads;
var config array<name> MaleHelmets;
var config array<name> FemaleHelmets;
var config array<name> MaleLeftArms;
var config array<name> MaleRightArms;
var config array<name> FemaleLeftArms;
var config array<name> FemaleRightArms;


function bool IsSoldier(name CharacterTemplateName)
{
	return true;
}

function X2CharacterTemplate SetCharacterTemplate(name CharacterTemplateName, name ArmorName)
{
	MatchArmorTemplateForTorso = (ArmorName == '') ? 'ReaperArmor' : ArmorName;
	MatchCharacterTemplateForTorso = 'NoCharacterTemplateName'; //Force the selector to use the armor type to filter torsos

	return class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager().FindCharacterTemplate('ReaperSoldier');
}

function TSoldier CreateTSoldier(optional name CharacterTemplateName, optional EGender eForceGender, optional name nmCountry = '', optional int iRace = -1, optional name ArmorName)
{
	local X2SoldierClassTemplateManager ClassMgr;
	local X2SoldierClassTemplate ClassTemplate;

	kSoldier = super.CreateTSoldier('ReaperSoldier', eForceGender, nmCountry, iRace, ArmorName);
	SetCountry('Country_Reaper');
	ClassMgr = class'X2SoldierClassTemplateManager'.static.GetSoldierClassTemplateManager();
	ClassTemplate = ClassMgr.FindSoldierClassTemplate('Reaper');
	kSoldier.strNickName = GenerateNickname(ClassTemplate, kSoldier.kAppearance.iGender);

	// Start issue #783
	ModifyGeneratedUnitAppearance(CharacterTemplateName, eForceGender, nmCountry, iRace, ArmorName);
	// End issue #783

	return kSoldier;
}

function SetRace(int iRace)
{
	kSoldier.kAppearance.iRace = eRace_Caucasian;
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

function SetArmsLegsAndDeco(X2SimpleBodyPartFilter BodyPartFilter)
{
	super.SetArmsLegsAndDeco(BodyPartFilter);

	if(kSoldier.kAppearance.iGender == eGender_Male)
	{
		kSoldier.kAppearance.nmLeftArm = default.MaleLeftArms[`SYNC_RAND(default.MaleLeftArms.Length)];
		kSoldier.kAppearance.nmRightArm = default.MaleRightArms[`SYNC_RAND(default.MaleRightArms.Length)];
	}
	else
	{
		kSoldier.kAppearance.nmLeftArm = default.FemaleLeftArms[`SYNC_RAND(default.FemaleLeftArms.Length)];
		kSoldier.kAppearance.nmRightArm = default.FemaleRightArms[`SYNC_RAND(default.FemaleRightArms.Length)];
	}
}

function SetAccessories(X2SimpleBodyPartFilter BodyPartFilter, name CharacterTemplateName)
{
	super.SetAccessories(BodyPartFilter, CharacterTemplateName);

	if(kSoldier.kAppearance.iGender == eGender_Male)
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
				kSoldier.kAppearance.nmVoice = 'ReaperMaleVoice1_Localized';
			}
			else
			{
				kSoldier.kAppearance.nmVoice = 'ReaperFemaleVoice1_Localized';
			}
		}
	}
}