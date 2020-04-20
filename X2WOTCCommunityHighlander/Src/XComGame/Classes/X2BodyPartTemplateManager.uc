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
			// Begin issue #328 - Check if the TemplateName indentifies the Part Type.
			/// HL-Docs: feature:BodyPartTemplateNames; issue:328; tags:customization
			/// Allows Torso, Arms and Legs customization pieces to be uniquely localized.
			///
			/// For templates, localization (i.e. providing strings for in-game display like names
			/// or descriptions) is handled using the object name that is the same as the template name.
			/// For example, given a template name of `'Female_LongStraight'`, the template is created
			/// by giving the `X2BodyPartTemplate` that name:
			///
			/// ```unrealscript
			/// // Object name -------vvvvvvvvvvvvvvvvvvv
			/// Template = new(None, "Female_LongStraight") class'X2BodyPartTemplate';
			/// Template.SetTemplateName('Female_LongStraight');
			/// // Template name ---------^^^^^^^^^^^^^^^^^^^
			/// ```
			///
			/// On the localization side, the object name is used to localize the `DisplayName`:
			///
			/// ```ini
			/// ;vvvvvvvvvvvvvvvvvvv--- Object name
			/// [Female_LongStraight X2BodyPartTemplate]
			/// DisplayName="Long Straight"
			/// ```
			///
			/// Body part templates are different from normal templates in that templates for different
			/// customization categories are allowed to have the same name. In vanilla, there are collisions
			/// for `Torso`, `Arms` and `Legs` so there is a Conventional Medium Male Torso, an Arms piece,
			/// and a Legs piece with the name `CnvMed_Std_A_M`.
			/// However, in order for localization to work, there must be no object name collisions.
			/// As a result, the game opts to not assign any object name to Torsos, Arms, and Legs, and instead
			/// simply shows them as "Torso 1", "Torso 2" and so on.
			///
			/// Because mods may want to localize their pieces, this Highlander change gives all armor pieces a unique object name.
			/// This happens using the following algorithm for every `BodyPartTemplateConfig` entry:
			///
			/// 1. If the `PartType` is not `"Torso"`, `"Arms"`, `"Legs"`, the object name and the template name are
			///    taken from `TemplateName` in the config entry (vanilla behavior).
			/// 2. If the `PartType` is `"Torso"`, `"Arms"`, or `"Legs"`:
			///     1. If `TemplateName` contains that part type, then the object name and the template name are
			///         taken from `TemplateName` in the config entry.
			///     2. If `TemplateName` does not contain that part type, then the template name is taken from
			///         `TemplateName`, and the object name is created by appending an underscore and the part type
			///         to the template name.
			///
			/// Additionally, the UI is changed to use the `DisplayName` for Torso/Arms/Legs, and fall back to numbered vanilla display
			/// if no `DisplayName` is provided.
			///
			/// A table with some examples:
			///
			/// | Config `PartType`  | Config `TemplateName` | Resulting Template Name | Resulting Object Name    |
			/// | ------------------ | --------------------- | ----------------------- | ------------------------ |
			/// | `"Torso"`          | `"CnvMed_Std_A_M"`    | `'CnvMed_Std_A_M'`      | `"CnvMed_Std_A_M_Torso"` |
			/// | `"Helmets"`        | `"Reaper_Hood_A_M"`   | `'Reaper_Hood_A_M'`     | `"Reaper_Hood_A_M"`      |
			/// | `"Torso"`          | `"DLC_30_Torso_M"`    | `'DLC_30_Torso_M'`      | `"DLC_30_Torso_M"`       |
			if(InStr(PartInfo.TemplateName, PartInfo.PartType,, true)==INDEX_NONE)
			{
				// Instead of giving up, decorate TemplateName to get unique Object Name
				Template = new(None, string(PartInfo.TemplateName) $ "_" $ PartInfo.PartType) class'X2BodyPartTemplate';
				break;
			}
			// End issue #328 - Fall through to default case if template name indenties the part type
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