class X2WOTCCommunityHighlander_MCMScreen extends Object config(UI);

struct BuilderInstance
{
	var int PageId;
	var JsonConfig_MCM_Builder Builder;
};

var config int VERSION_CFG;
var config array<string> MCMBuilderClasses;

var array<BuilderInstance> BuilderInstances;

`include(X2WOTCCommunityHighlander/Src/ModConfigMenuAPI/MCM_API_Includes.uci)
`include(X2WOTCCommunityHighlander/Src/ModConfigMenuAPI/MCM_API_CfgHelpers.uci)

event OnInit(UIScreen Screen)
{
	`MCM_API_Register(Screen, ClientModCallback);
}

simulated function ClientModCallback(MCM_API_Instance ConfigAPI, int GameMode)
{
	local string BuilderClassName;

	foreach default.MCMBuilderClasses(BuilderClassName)
	{
		BuildMCM(
			BuilderClassName,
			ConfigAPI,
			GameMode
		);
	}
}

simulated function BuildMCM(
	string BuilderClassName,
	MCM_API_Instance ConfigAPI,
	int GameMode
)
{
	//local JsonConfig_MCM_Builder Builder;
	local BuilderInstance Instance;
	local MCMConfigMapEntry MapEntry;
	local JsonConfig_MCM_Page MCMPageConfig;
	local JsonConfig_MCM_Group MCMGroupConfig;
	local JsonConfig_MCM_Element MCMElementConfig;
	local JsonConfig_Manager SaveConfigManager;
	local MCM_API_SettingsPage Page;
	local MCM_API_SettingsGroup Group;
	local name SetttingName;
	
	Instance.Builder = class'JsonConfig_MCM_Builder'.static.GetMCMBuilder(BuilderClassName);

	foreach Instance.Builder.DeserialzedPagesMap(MapEntry)
	{
		MCMPageConfig = MapEntry.MCMConfigPage;
		Page = ConfigAPI.NewSettingsPage(MCMPageConfig.GetPageTitle());
		Page.SetPageTitle(MCMPageConfig.GetTabLabel());

		if (MCMPageConfig.ShouldEnableResetButton())
		{
			Page.EnableResetButton(ResetButtonClicked);
		}

		MCMPageConfig.MCMPageId = Page.GetPageId();
		Instance.PageId = Page.GetPageId();
		BuilderInstances.AddItem(Instance);

		foreach MCMPageConfig.Groups(MCMGroupConfig)
		{
			SaveConfigManager = GetConfigManager(MCMPageConfig, MCMGroupConfig);
			
			Group = Page.AddGroup(name(MCMGroupConfig.GetGroupName()), MCMGroupConfig.GetGroupLabel());

			foreach MCMGroupConfig.Elements(MCMElementConfig)
			{
				SetttingName = name(Caps(MCMElementConfig.SettingName));
				
				switch (MCMElementConfig.Type)
				{
					case "Label":
						Group.AddLabel(
							SetttingName,
							MCMElementConfig.GetLabel(),
							MCMElementConfig.GetTooltip()
						);
						break;
					case "Button":
						Group.AddButton(
							SetttingName,
							MCMElementConfig.GetLabel(),
							MCMElementConfig.GetTooltip(),
							MCMElementConfig.ButtonLabel,
							ButtonClickHandler
						);
						break;
					case "Checkbox":
						Group.AddCheckbox(
							SetttingName,
							MCMElementConfig.GetLabel(),
							MCMElementConfig.GetTooltip(),
							SaveConfigManager.GetConfigBoolValue(MCMElementConfig.SettingName),
							BoolSaveHandler,
							BoolChangeHandler
						);
						break;
					case "Slider":
						Group.AddSlider(
							SetttingName,
							MCMElementConfig.GetLabel(),
							MCMElementConfig.GetTooltip(),
							float(MCMElementConfig.SliderMin),
							float(MCMElementConfig.SliderMax),
							float(MCMElementConfig.SliderStep),
							SaveConfigManager.GetConfigFloatValue(MCMElementConfig.SettingName),
							FloatSaveHandler,
							FloatChangeHandler
						);
						break;
					case "Spinner":
						Group.AddSpinner(
							SetttingName,
							MCMElementConfig.GetLabel(),
							MCMElementConfig.GetTooltip(),
							MCMElementConfig.Options.GetArrayValue(),
							SaveConfigManager.GetConfigStringValue(MCMElementConfig.SettingName),
							StringSaveHandler,
							StringChangeHandler
						);
						break;
					case "Dropdown":
						Group.AddDropdown(
							SetttingName,
							MCMElementConfig.GetLabel(),
							MCMElementConfig.GetTooltip(),
							MCMElementConfig.Options.GetArrayValue(),
							SaveConfigManager.GetConfigStringValue(MCMElementConfig.SettingName),
							StringSaveHandler,
							StringChangeHandler
						);
						break;
					default:
						`LOG(default.class @ GetFuncName() @ "unknown MCM element type" @ MCMElementConfig.Type);
						break;
				}
			}
		}
		
		Page.ShowSettings();
		Page.SetSaveHandler(SaveButtonClicked);
	}
}

simulated function ButtonClickHandler(MCM_API_Setting Setting)
{
	`XEVENTMGR.TriggerEvent('MCM_ButtonClick', Setting, GetBuilder(Setting.GetParentGroup().GetParentPage().GetPageId()), none);
}

simulated function BoolChangeHandler(MCM_API_Setting Setting, bool SettingValue)
{
	ElementChangeHandler(Setting, SettingValue);
}

simulated function BoolSaveHandler(MCM_API_Setting Setting, bool SettingValue)
{
	ElementSaveHandler(Setting, SettingValue);
}

simulated function FloatChangeHandler(MCM_API_Setting Setting, float SettingValue)
{
	ElementChangeHandler(Setting, SettingValue);
}

simulated function FloatSaveHandler(MCM_API_Setting Setting, float SettingValue)
{
	ElementSaveHandler(Setting, SettingValue);
}

simulated function StringChangeHandler(MCM_API_Setting Setting, string SettingValue)
{
	ElementChangeHandler(Setting, SettingValue);
}

simulated function StringSaveHandler(MCM_API_Setting Setting, string SettingValue)
{
	ElementSaveHandler(Setting, SettingValue);
}

simulated function ElementChangeHandler(MCM_API_Setting Setting, coerce string SettingValue)
{
	local XComLWTuple Tuple;

	Tuple = new class'XComLWTuple';
	Tuple.Id = 'MCM_ChangeHandler';
	Tuple.Data.Add(2);

	Tuple.Data[0].kind = XComLWTVObject;
	Tuple.Data[0].o = GetBuilder(Setting.GetParentGroup().GetParentPage().GetPageId());
	Tuple.Data[1].kind = XComLWTVString;
	Tuple.Data[1].s = SettingValue;

	`XEVENTMGR.TriggerEvent('MCM_ChangeHandler', Setting, Tuple, none);
}

simulated function ElementSaveHandler(MCM_API_Setting Setting, coerce string SettingValue)
{
	local JsonConfig_MCM_Page Page;
	local JsonConfig_MCM_Group Group;
	local JsonConfig_Manager SaveConfigManager;
	local XComLWTuple Tuple;
	local bool bOverrideDefaultHandler;
	
	bOverrideDefaultHandler = false;

	Tuple = new class'XComLWTuple';
	Tuple.Id = 'MCM_SaveHandler';
	Tuple.Data.Add(3);

	Tuple.Data[0].kind = XComLWTVObject;
	Tuple.Data[0].o = GetBuilder(Setting.GetParentGroup().GetParentPage().GetPageId());
	Tuple.Data[1].kind = XComLWTVString;
	Tuple.Data[1].s = SettingValue;
	Tuple.Data[2].kind = XComLWTVBool;
	Tuple.Data[2].b = bOverrideDefaultHandler;

	`XEVENTMGR.TriggerEvent('MCM_SaveHandler', Setting, Tuple, none);

	if (!Tuple.Data[2].b)
	{
		
		Page = GetPage(Setting.GetParentGroup().GetParentPage().GetPageId());
		Group = GetGroup(
			Setting.GetParentGroup().GetParentPage().GetPageId(),
			Setting.GetParentGroup().GetName()
		);
		SaveConfigManager = GetConfigManager(Page, Group);
		SaveConfigManager.static.SetConfigString(Caps(string(Setting.GetName())), SettingValue);
	}
}

simulated function SaveButtonClicked(MCM_API_SettingsPage Page)
{
	local JsonConfig_MCM_Page ConfigPage;
	local JsonConfig_MCM_Group ConfigGroup;
	local JsonConfig_Manager SaveConfigManager;
	local XComLWTuple Tuple;
	local bool bOverrideDefaultHandler;
	local int Index;

	bOverrideDefaultHandler = false;
		
	Tuple = new class'XComLWTuple';
	Tuple.Id = 'MCM_SaveButtonClicked';
	Tuple.Data.Add(2);

	Tuple.Data[0].kind = XComLWTVObject;
	Tuple.Data[0].o = GetBuilder(Page.GetPageId());
	Tuple.Data[1].kind = XComLWTVBool;
	Tuple.Data[1].b = bOverrideDefaultHandler;

	`XEVENTMGR.TriggerEvent('MCM_SaveButtonClicked', Page, Tuple, none);
	if (!Tuple.Data[1].b)
	{
		for (Index = 0; Index < Page.GetGroupCount(); Index++)
		{
			ConfigGroup = GetGroup(
				Page.GetPageId(),
				Page.GetGroupByIndex(Index).GetName()
			);
			if (ConfigGroup.SaveConfigManager != "")
			{
				SaveConfigManager = class'JsonConfig_Manager'.static.GetConfigManager(ConfigGroup.SaveConfigManager);
				SaveConfigManager.static.SerializeAndSaveConfig();
			}
		}

		ConfigPage = GetPage(Page.GetPageId());
		SaveConfigManager = class'JsonConfig_Manager'.static.GetConfigManager(ConfigPage.SaveConfigManager);
		SaveConfigManager.static.SerializeAndSaveConfig();
		
		`XEVENTMGR.TriggerEvent('MCM_ConfigSaved', Page, GetBuilder(Page.GetPageId()), none);
	}
}

simulated function ResetButtonClicked(MCM_API_SettingsPage Page)
{
	local JsonConfig_MCM_Page ConfigPage;
	local JsonConfig_MCM_Group ConfigGroup;
	local JsonConfig_Manager SaveConfigManager, DefaultConfigManager;
	local int Index;
	local int SettingIndex;
	local MCM_API_SettingsGroup Group;
	local MCM_API_Setting Setting;
	local MCM_API_Checkbox Checkbox;
	local MCM_API_Slider Slider;
	local MCM_API_Spinner Spinner;
	local MCM_API_Dropdown Dropdown;
	local XComLWTuple Tuple;
	local bool bOverrideDefaultHandler;

	bOverrideDefaultHandler = false;
		
	Tuple = new class'XComLWTuple';
	Tuple.Id = 'ResetButtonClicked';
	Tuple.Data.Add(2);

	Tuple.Data[0].kind = XComLWTVObject;
	Tuple.Data[0].o = GetBuilder(Page.GetPageId());
	Tuple.Data[1].kind = XComLWTVBool;
	Tuple.Data[1].b = bOverrideDefaultHandler;

	`XEVENTMGR.TriggerEvent('ResetButtonClicked', Page, Tuple, none);
	if (!Tuple.Data[1].b)
	{
		ConfigPage = GetPage(Page.GetPageId());
		
		for (Index = 0; Index < Page.GetGroupCount(); Index++)
		{
			Group = Page.GetGroupByIndex(Index);

			ConfigGroup = GetGroup(
				Page.GetPageId(),
				Page.GetGroupByIndex(Index).GetName()
			);
			SaveConfigManager = GetConfigManager(ConfigPage, ConfigGroup);
			DefaultConfigManager = SaveConfigManager.GetDefaultConfigManager();

			for (SettingIndex = 0; SettingIndex < Group.GetNumberOfSettings(); SettingIndex++)
			{
				Setting = Group.GetSettingByIndex(SettingIndex);
			
				switch (Setting.GetSettingType())
				{
					case eSettingType_Checkbox:
						Checkbox = MCM_API_Checkbox(Setting);
						Checkbox.SetValue(DefaultConfigManager.static.GetConfigBoolValue(Checkbox.GetName()), true);
						break;
					case eSettingType_Slider:
						Slider = MCM_API_Slider(Setting);
						Slider.SetValue(DefaultConfigManager.static.GetConfigFloatValue(Slider.GetName()), true);
						break;
					case eSettingType_Dropdown:
						Dropdown = MCM_API_Dropdown(Setting);
						Dropdown.SetValue(DefaultConfigManager.static.GetConfigStringValue(Dropdown.GetName()), true);
						break;
					case eSettingType_Spinner:
						Spinner = MCM_API_Spinner(Setting);
						Spinner.SetValue(DefaultConfigManager.static.GetConfigStringValue(Spinner.GetName()), true);
						break;
				}
			}
		}

		`XEVENTMGR.TriggerEvent('MCM_ConfigResetted', Page, GetBuilder(Page.GetPageId()), none);
	}
}

function JsonConfig_Manager GetConfigManager(JsonConfig_MCM_Page Page, JsonConfig_MCM_Group Group)
{
	if (Group.SaveConfigManager != "")
	{
		return class'JsonConfig_Manager'.static.GetConfigManager(Group.SaveConfigManager);
	}
	else
	{
		return class'JsonConfig_Manager'.static.GetConfigManager(Page.SaveConfigManager);
	}
}

simulated public function JsonConfig_MCM_Page GetPage(int PageID)
{
	local JsonConfig_MCM_Builder Builder;
	local MCMConfigMapEntry MCMConfig;
	local JsonConfig_MCM_Page Page;


	Builder = GetBuilder(PageID);

	if (Builder != none)
	{
		foreach Builder.DeserialzedPagesMap(MCMConfig)
		{
			Page = MCMConfig.MCMConfigPage;

			if (Page.MCMPageId == PageID)
			{
				return Page;
			}
		}
	}

	`LOG(default.class @ GetFuncName() @ Builder @ "could not find MCMConfigPage for" @ PageID,, 'RPG');

	return none;
}

simulated public function JsonConfig_MCM_Group GetGroup(int PageID, name GroupName)
{
	local JsonConfig_MCM_Page Page;
	local JsonConfig_MCM_Group Group;

	Page = GetPage(PageID);

	foreach Page.Groups(Group)
	{
		if (name(Group.GetGroupName()) == GroupName)
		{
			return Group;
		}
	}

	`LOG(default.class @ GetFuncName() @ "could not find JsonConfig_MCM_Group for" @ PageID @ GroupName,, 'RPG');

	return none;
}

simulated public function JsonConfig_MCM_Element GetElement(int PageID, name GroupName, name SettingName)
{
	local JsonConfig_MCM_Group Group;
	local JsonConfig_MCM_Element Element;

	Group = GetGroup(PageID, GroupName);

	foreach Group.Elements(Element)
	{
		if (name(Element.SettingName) == SettingName)
		{
			return Element;
		}
	}

	`LOG(default.class @ GetFuncName() @ "could not find JsonConfig_MCM_Element for" @ PageID @ GroupName @ SettingName,, 'RPG');

	return none;
}

simulated function JsonConfig_MCM_Builder GetBuilder(int PageID)
{
	return BuilderInstances[BuilderInstances.Find('PageId', PageID)].Builder;
}