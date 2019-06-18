//-----------------------------------------------------------
//	Class:	JsonConfig_MCM_Element
//	Author: Musashi
//	
//-----------------------------------------------------------
class JsonConfig_MCM_Element extends Object;

var string ConfigKey;
var JsonConfig_MCM_Builder Builder;
var string SettingName;
var string Type;
var string Label;
var string Tooltip;
var string SliderMin;
var string SliderMax;
var string SliderStep;
var string ButtonLabel;
var JsonConfig_Array Options;

public function string GetLabel()
{
	if (Label != "")
	{
		return Label;
	}

	return Builder.LocalizeItem(SettingName $ "_LABEL");
}

public function string GetTooltip()
{
	if (Tooltip != "")
	{
		return Tooltip;
	}

	return Builder.LocalizeItem(SettingName $ "_TOOLTIP");
}

public function Serialize(out JsonObject JsonObject, string PropertyName)
{
	local JsonObject JsonSubObject;

	ConfigKey = PropertyName;

	JsonSubObject = new () class'JsonObject';
	JsonSubObject.SetStringValue("SettingName", ConfigKey);
	JsonSubObject.SetStringValue("Type", Type);
	JsonSubObject.SetStringValue("Label", Label);
	JsonSubObject.SetStringValue("Tooltip", Tooltip);
	JsonSubObject.SetStringValue("SliderMin", SliderMin);
	JsonSubObject.SetStringValue("SliderMax", SliderMax);
	JsonSubObject.SetStringValue("SliderStep", SliderStep);
	JsonSubObject.SetStringValue("ButtonLabel", ButtonLabel);
	Options.Serialize(JsonSubObject, "Options");

	JSonObject.SetObject(PropertyName, JsonSubObject);
}

public function bool Deserialize(JSonObject Data, string PropertyName, JsonConfig_MCM_Builder BuilderParam)
{
	local JsonObject ElementJson;

	ConfigKey = PropertyName;

	Options = new class'JsonConfig_Array';

	ElementJson = Data.GetObject(PropertyName);
	if (ElementJson != none)
	{
		Builder = BuilderParam;
		SettingName = ConfigKey;
		Type = ElementJson.GetStringValue("Type");
		Label = ElementJson.GetStringValue("Label");
		Tooltip = ElementJson.GetStringValue("Tooltip");
		SliderMin = ElementJson.GetStringValue("SliderMin");
		SliderMax = ElementJson.GetStringValue("SliderMax");
		SliderStep = ElementJson.GetStringValue("SliderStep");
		ButtonLabel = ElementJson.GetStringValue("ButtonLabel");
		Options.Deserialize(ElementJson, "Options");

		return (Type != "");
	}
	return false;
}


defaultproperties
{
	Begin Object Class=JsonConfig_Array Name=DefaultJsonConfig_Array
	End Object
	Options = DefaultJsonConfig_Array;
}