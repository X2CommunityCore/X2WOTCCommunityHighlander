//-----------------------------------------------------------
//	Class:	JsonConfig_MCM_Page
//	Author: Musashi
//	
//-----------------------------------------------------------
class JsonConfig_MCM_Page extends Object;

var JsonConfig_MCM_Builder Builder;
var int MCMPageId;
var string ConfigKey;
var string PageTitle;
var string TabLabel;
var string EnableResetButton;
var string SaveConfigManager;
var array<JsonConfig_MCM_Group> Groups;

public function bool ShouldEnableResetButton()
{
	return bool(EnableResetButton);
}

public function SetPageTitle(string PageTitleParam)
{
	PageTitle = PageTitleParam;
}

public function string GetPageTitle()
{
	if (PageTitle != "")
	{
		return PageTitle;
	}

	return Builder.LocalizeItem(ConfigKey $ "_TITLE");
}

public function SetTabLabel(string TabLabelParam)
{
	TabLabel = TabLabelParam;
}

public function string GetTabLabel()
{
	if (TabLabel != "")
	{
		return TabLabel;
	}

	return Builder.LocalizeItem(ConfigKey $ "_LABEL");
}

public function Serialize(out JsonObject JsonObject, string PropertyName)
{
	local JsonObject JsonSubObject;

	ConfigKey = PropertyName;

	JsonSubObject = new () class'JsonObject';
	JsonSubObject.SetStringValue("PageTitle", PageTitle);
	JsonSubObject.SetStringValue("TabLabel", TabLabel);
	JsonSubObject.SetStringValue("EnableResetButton", EnableResetButton);
	JsonSubObject.SetStringValue("SaveConfigManager", SaveConfigManager);

	JSonObject.SetObject(PropertyName, JsonSubObject);
}

public function bool Deserialize(JSonObject Data, string PropertyName, JsonConfig_MCM_Builder BuilderParam)
{
	local JsonObject PageJson;

	ConfigKey = PropertyName;

	PageJson = Data.GetObject(PropertyName);
	if (PageJson != none)
	{
		PageTitle = PageJson.GetStringValue("PageTitle");
		TabLabel = PageJson.GetStringValue("TabLabel");
		EnableResetButton = PageJson.GetStringValue("EnableResetButton");
		SaveConfigManager = PageJson.GetStringValue("SaveConfigManager");
		Builder = BuilderParam;

		DeserializeGroups(PageJson);
		
		return true;
	}

	return false;
}

private function DeserializeGroups(JsonObject PageJson)
{
	local JsonConfig_MCM_Group Group;
	local ObjectKey ObjKey;

	foreach Builder.ObjectKeys(ObjKey)
	{
		if (ObjKey.ParentKey == ConfigKey)
		{
			Group = new class'JsonConfig_MCM_Group';
			if(Group.Deserialize(PageJson, ObjKey.Key, Builder))
			{
				Groups.AddItem(Group);
			}
		}
	}
}