//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    X2BodyPartTemplateManager.uc
//  AUTHOR:  Timothy Talley  --  11/04/2013
//---------------------------------------------------------------------------------------
//  Copyright (c) 2013 Firaxis Games Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class X2BodyPartTemplateManager extends X2DataTemplateManager
    native(Core)
	config(Content);

var protected config array<X2PartInfo> BodyPartTemplateConfig;
var protected config array<string> ValidPartTypes;
var config bool DisableCharacterVoices; //Allow unilateral disabling of character voices from INI at Jake's request.
var config bool DisablePostProcessWhenCustomizing;
var private bool bPartTypeInitDone;

var private native Map_Mirror   BodyPartTemplateCache{TMap<FName, TMap<FName, UX2BodyPartTemplate*> *>};




native static function X2BodyPartTemplateManager GetBodyPartTemplateManager();

native function InitPartTypes( array<string> PartTypes);
native function bool AddUberTemplate(string BodyPartType, X2BodyPartTemplate Template, bool ReplaceDuplicate = false);
native function X2BodyPartTemplate FindUberTemplate(string BodyPartType, name PartName);
native function GetUberTemplates(string BodyPartType,  out array<X2BodyPartTemplate> Templates );
native function GetFilteredUberTemplates(string BodyPartType,  Object CallbackObject, delegate<X2BodyPartFilter.FilterCallback> CallbackFn, out array<X2BodyPartTemplate> Templates );
native function X2BodyPartTemplate GetRandomUberTemplate(string BodyPartType, Object CallbackObject, delegate<X2BodyPartFilter.FilterCallback> CallbackFn);
native function array<name> GetPartPackNames();



//Returns true if ArmorTemplates, gender, pristine, etc. all match up between the two templates
native static function bool DoArmorPartsMatch(X2BodyPartTemplate TemplateA, X2BodyPartTemplate TemplateB);




native function InitTemplates();

protected event InitTemplatesInternal()
{
	local int i;
	local X2PartInfo PartInfo;
	local X2BodyPartTemplate Template;

	InitPartTypes(ValidPartTypes);

	//== General Parts
	for (i = 0; i < BodyPartTemplateConfig.Length; ++i)
	{
		PartInfo = BodyPartTemplateConfig[i];

		// HAX: Load 'Torso', 'Arms' and 'Legs' templates the old way to prevent template name collisions:
		// TODO: @rmcfall - make all body part template names unique so they can be individually localized
		switch(PartInfo.PartType)
		{
		case "Torso":
		case "Arms":
		case "Legs":
			Template = new class'X2BodyPartTemplate';
			break;
		default:
			// This is the "new", proper way of instantiating a template (requires unique TemplateName)
			Template = new(None, string(PartInfo.TemplateName)) class'X2BodyPartTemplate';
		}
		
		Template.PartType			= PartInfo.PartType;

		Template.Gender				= PartInfo.Gender;
		Template.Race				= PartInfo.Race;
		Template.ArchetypeName		= PartInfo.ArchetypeName;

		// Body template
		Template.Type				= PartInfo.CivilianType;

		// Hair template
		Template.bCanUseOnCivilian	= PartInfo.bCanUseOnCivilian;
		Template.bIsHelmet			= PartInfo.bIsHelmet;

		// Armor
		Template.bVeteran			= PartInfo.bVeteran;
		Template.bAnyArmor			= PartInfo.bAnyArmor;
		Template.ArmorTemplate		= PartInfo.ArmorTemplate;
		Template.CharacterTemplate  = PartInfo.CharacterTemplate;
		Template.SpecializedType	= PartInfo.SpecializedType;
		Template.Tech				= PartInfo.Tech;
		Template.ReqClass			= PartInfo.ReqClass;
		Template.SetNames			= PartInfo.SetNames;

		// Language
		Template.Language			= PartInfo.Language;

		// Which content pack this part belongs to, either DLC or Mod
		Template.DLCName			= name(PartInfo.DLCName);

		Template.bGhostPawn = PartInfo.bGhostPawn;

		Template.SetTemplateName(PartInfo.TemplateName);
		AddUberTemplate(Template.PartType, Template, true);

		`log(`location @ "Adding BodyPartTemplate: " @ `ShowVar(Template.DataName) @ `ShowVar(Template) @ `ShowVar(Template.PartType),,'XCom_Templates');
	}

}

function LoadAllContent()
{
	local array<X2BodyPartTemplate> TemplateList;
	local XComContentManager ContentMgr;	
	local int Index, TemplateListIndex;

	ContentMgr = `CONTENT;
	for(Index = 0; Index < ValidPartTypes.Length; ++Index)
	{
		GetUberTemplates(ValidPartTypes[Index], TemplateList);

		//Skip voices, those will still be loaded on demand - as they are numerous and memory intensive
		if(ValidPartTypes[Index] == "Voice")
		{
			continue;
		}

		for(TemplateListIndex = 0; TemplateListIndex < TemplateList.Length; ++TemplateListIndex)
		{
			ContentMgr.RequestGameArchetype(TemplateList[TemplateListIndex].ArchetypeName, none, none, true);
		}
	}
}

cpptext
{
	TMap<FName, UX2BodyPartTemplate*> *GetPartMap( const TCHAR *BodyPartType );

}

defaultproperties
{
}