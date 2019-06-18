class JsonConfig_Manager extends JsonConfig config(GameData) abstract;

struct ConfigPropertyMapEntry
{
	var string PropertyName;
	var JsonConfig_TaggedConfigProperty ConfigProperty;
};

var config array<string> ConfigProperties;
var protectedwrite array<ConfigPropertyMapEntry> DeserialzedConfigPropertyMap;
var array< Delegate<TagFunctionDelegate> > OnTagFunctions;
var string DefaultConfigManagerClassName;
var JsonConfig_Manager DefaultConfigManager;

delegate bool TagFunctionDelegate(name TagFunctionName, JsonConfig_TaggedConfigProperty ConfigProperty, out string TagValue);

//
// override in subclasses
//
function bool OnTagFunction(name TagFunctionName, JsonConfig_TaggedConfigProperty ConfigProperty, out string TagValue);

public static function JsonConfig_Manager GetConfigManager(optional string ClassNameParam)
{
	local JsonConfig_Manager ConfigManager;

	if (ClassNameParam == "")
	{
		ClassNameParam = string(default.class);
	}

	ConfigManager = JsonConfig_Manager(class'Engine'.static.FindClassDefaultObject(ClassNameParam));
	
	if (ConfigManager.DeserialzedConfigPropertyMap.Length == 0)
	{
		ConfigManager.DeserializeConfig();
		if (ConfigManager.OnTagFunctions.Find(OnTagFunction) == Index_None)
		{
			ConfigManager.OnTagFunctions.AddItem(OnTagFunction);
		}
	}

	return ConfigManager;
}

public static function JsonConfig_Manager GetDefaultConfigManager()
{
	local JsonConfig_Manager ConfigManager;

	ConfigManager = GetConfigManager();
	return ConfigManager.DefaultConfigManager;
}

public static function SerializeAndSaveConfig()
{
	local JsonConfig_Manager ConfigManager;

	ConfigManager = GetConfigManager();
	ConfigManager.SerializeConfig();
	ConfigManager.SaveConfig();
}

private function DeserializeConfig()
{
	local ConfigPropertyMapEntry MapEntry;
	local JSonObject JSonObject, JSonObjectProperty;
	local JsonConfig_TaggedConfigProperty ConfigProperty;
	local string SerializedConfigProperty, PropertyName;

	`LOG(default.class @ GetFuncName() @ "found entries:" @ default.ConfigProperties.Length,, 'RPG');

	foreach default.ConfigProperties(SerializedConfigProperty)
	{
		PropertyName = GetObjectKey(SanitizeJson(SerializedConfigProperty));
		JSonObject = class'JSonObject'.static.DecodeJson(SanitizeJson(SerializedConfigProperty));

		if (JSonObject != none && PropertyName != "")
		{
			JSonObjectProperty = JSonObject.GetObject(PropertyName);

			if (JSonObjectProperty != none &&
				DeserialzedConfigPropertyMap.Find('PropertyName', PropertyName) == INDEX_NONE)
			{
				ConfigProperty = new class'JsonConfig_TaggedConfigProperty';
				ConfigProperty.ManagerInstance = self;
				ConfigProperty.Deserialize(JSonObjectProperty);
				MapEntry.PropertyName = PropertyName;
				MapEntry.ConfigProperty = ConfigProperty;
				DeserialzedConfigPropertyMap.AddItem(MapEntry);
			}
		}
	}
}

private function SerializeConfig()
{
	local ConfigPropertyMapEntry MapEntry;
	local JSonObject JSonObject;

	ConfigProperties.Length = 0;

	foreach DeserialzedConfigPropertyMap(MapEntry)
	{
		JSonObject = new () class'JsonObject';
		JSonObject.SetObject(MapEntry.PropertyName, MapEntry.ConfigProperty.Serialize());
		ConfigProperties.AddItem(class'JSonObject'.static.EncodeJson(JSonObject));
	}
}

static public function bool HasConfigProperty(coerce string PropertyName, optional string Namespace)
{
	PropertyName = GetPropertyName(PropertyName, Namespace);

	return GetConfigManager().DeserialzedConfigPropertyMap.Find('PropertyName', PropertyName) != INDEX_NONE;
}

static public function SetConfigString(string PropertyName, coerce string Value)
{
	local JsonConfig_Manager ConfigManager;
	local JsonConfig_TaggedConfigProperty ConfigProperty;
	local ConfigPropertyMapEntry MapEntry;

	ConfigManager = GetConfigManager();

	if (ConfigManager.static.HasConfigProperty(PropertyName))
	{
		ConfigProperty = ConfigManager.static.GetConfigProperty(PropertyName);
		ConfigProperty.SetValue(Value);
	}
	else
	{
		ConfigProperty = new class'JsonConfig_TaggedConfigProperty';
		ConfigProperty.ManagerInstance = ConfigManager;
		ConfigProperty.SetValue(Value);

		MapEntry.PropertyName = PropertyName;
		MapEntry.ConfigProperty = ConfigProperty;

		ConfigManager.DeserialzedConfigPropertyMap.AddItem(MapEntry);
	}
}

static public function int GetConfigIntValue(coerce string PropertyName, optional string TagFunction, optional string Namespace)
{
	return int(GetConfigStringValue(PropertyName, TagFunction, Namespace));
}

static public function float GetConfigFloatValue(coerce string PropertyName, optional string TagFunction, optional string Namespace)
{
	return float(GetConfigStringValue(PropertyName, TagFunction, Namespace));
}

static public function name GetConfigNameValue(coerce string PropertyName, optional string TagFunction, optional string Namespace)
{
	return name(GetConfigStringValue(PropertyName, TagFunction, Namespace));
}

static public function int GetConfigByteValue(coerce string PropertyName, optional string TagFunction, optional string Namespace)
{
	return byte(GetConfigStringValue(PropertyName, TagFunction, Namespace));
}

static public function bool GetConfigBoolValue(coerce string PropertyName, optional string TagFunction, optional string Namespace)
{
	return bool(GetConfigStringValue(PropertyName, TagFunction, Namespace));
}

static public function array<int> GetConfigIntArray(coerce string PropertyName, optional string TagFunction, optional string Namespace)
{
	local array<string> StringArray;
	local string Value;
	local array<int> IntArray;

	StringArray = GetConfigStringArray(PropertyName, TagFunction, Namespace);

	foreach StringArray(Value)
	{
		IntArray.AddItem(int(Value));
	}

	return IntArray;
}

static public function array<float> GetConfigFloatArray(coerce string PropertyName, optional string TagFunction, optional string Namespace)
{
	local array<string> StringArray;
	local string Value;
	local array<float> FloatArray;

	StringArray = GetConfigStringArray(PropertyName, TagFunction, Namespace);

	foreach StringArray(Value)
	{
		FloatArray.AddItem(float(Value));
	}

	return FloatArray;
}

static public function array<name> GetConfigNameArray(coerce string PropertyName, optional string TagFunction, optional string Namespace)
{
	local array<string> StringArray;
	local string Value;
	local array<name> NameArray;

	StringArray = GetConfigStringArray(PropertyName, TagFunction, Namespace);

	foreach StringArray(Value)
	{
		NameArray.AddItem(name(Value));
	}

	return NameArray;
}

static public function vector GetConfigVectorValue(coerce string PropertyName, optional string TagFunction, optional string Namespace)
{
	local JsonConfig_TaggedConfigProperty ConfigProperty;

	ConfigProperty = GetConfigProperty(PropertyName);

	if (ConfigProperty != none)
	{
		//`LOG(default.class @ GetFuncName() @ `ShowVar(PropertyName) @ "Value:" @ ConfigProperty.VectorValue.ToString() @ `ShowVar(Namespace),, 'RPG');
		return ConfigProperty.GetVectorValue();
	}

	return vect(0, 0, 0);
}

static public function array<string> GetConfigStringArray(coerce string PropertyName, optional string TagFunction, optional string Namespace)
{
	local JsonConfig_TaggedConfigProperty ConfigProperty;
	local array<string> EmptyArray;

	ConfigProperty = GetConfigProperty(PropertyName, Namespace);

	if (ConfigProperty != none)
	{
		//`LOG(default.class @ GetFuncName() @ `ShowVar(PropertyName) @ "Value:" @ ConfigProperty.ArrayValue.ToString() @ `ShowVar(Namespace),, 'RPG');
		return ConfigProperty.GetArrayValue();
	}

	EmptyArray.Length = 0; // Prevent unassigned warning

	return EmptyArray;
}

static public function WeaponDamageValue GetConfigDamageValue(coerce string PropertyName, optional string Namespace)
{
	local JsonConfig_TaggedConfigProperty ConfigProperty;
	local WeaponDamageValue Value;

	ConfigProperty = GetConfigProperty(PropertyName, Namespace);

	if (ConfigProperty != none)
	{
		Value =  ConfigProperty.GetDamageValue();
		//`LOG(default.class @ GetFuncName() @ `ShowVar(PropertyName) @ "Value:" @ ConfigProperty.DamageValue.ToString() @ `ShowVar(Namespace),, 'RPG');
	}

	return Value;
}

static public function string GetConfigStringValue(coerce string PropertyName, optional string TagFunction, optional string Namespace)
{
	local JsonConfig_TaggedConfigProperty ConfigProperty;
	local string Value;

	ConfigProperty = GetConfigProperty(PropertyName, Namespace);

	if (ConfigProperty != none)
	{
		Value =  ConfigProperty.GetValue(TagFunction);
		//`LOG(default.class @ GetFuncName() @ `ShowVar(PropertyName) @ `ShowVar(Value) @ `ShowVar(TagFunction) @ `ShowVar(Namespace),, 'RPG');
	}

	return Value;
}

static public function string GetConfigTagValue(coerce string PropertyName, optional string Namespace)
{
	local JsonConfig_TaggedConfigProperty ConfigProperty;

	ConfigProperty = GetConfigProperty(PropertyName, Namespace);

	if (ConfigProperty != none)
	{
		return ConfigProperty.GetTagValue();
	}

	return  "";
}


static public function JsonConfig_TaggedConfigProperty GetConfigProperty(
	coerce string PropertyName,
	optional string Namespace
)
{
	local JsonConfig_Manager ConfigManager;
	local int Index;

	ConfigManager = GetConfigManager();

	PropertyName = GetPropertyName(PropertyName, Namespace);

	Index = ConfigManager.DeserialzedConfigPropertyMap.Find('PropertyName', PropertyName);
	if (Index != INDEX_NONE)
	{
		return ConfigManager.DeserialzedConfigPropertyMap[Index].ConfigProperty;
	}

	if (ConfigManager.DefaultConfigManager != none)
	{
		return ConfigManager.DefaultConfigManager.GetConfigProperty(PropertyName, Namespace);
	}

	`LOG(default.class @ GetFuncName() @ "could not find config property for" @ PropertyName,, 'RPG');

	return none;
}
