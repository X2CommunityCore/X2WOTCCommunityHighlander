//-----------------------------------------------------------
//	Class:	JsonConfig_TaggedConfigProperty
//	Author: Musashi
//	Defines a config entry for a config value with meta information for automatic localization tags
//-----------------------------------------------------------

class JsonConfig_TaggedConfigProperty extends Object dependson(JsonConfig_Manager);

var JsonConfig_Manager ManagerInstance;
var protected string Value;
var protectedwrite JsonConfig_Vector VectorValue;
var protectedwrite JsonConfig_Array ArrayValue;
var protectedwrite JsonConfig_WeaponDamageValue DamageValue;

var protected string Namespace;
var protected string TagFunction;
var protected string TagParam;
var protected string TagPrefix;
var protected string TagSuffix;

var protectedwrite bool bIsVector;
var protectedwrite bool bIsArray;
var protectedwrite bool bIsDamageValue;

public function string GetTagParam()
{
	local string PropertyRefValue;

	// Check if the tag param is referencing another property value
	if (ManagerInstance.static.HasConfigProperty(TagParam))
	{
		PropertyRefValue = ManagerInstance.static.GetConfigStringValue(TagParam);

		if (PropertyRefValue != "")
		{
			return PropertyRefValue;
		}
	}

	return TagParam;
}

public function string GetValue(optional string TagFunctionIn)
{
	if (TagFunctionIn != "")
	{
		return GetTagValueModifiedByTagFunction(TagFunctionIn);
	}

	return Value;
}

public function SetValue(string ValueParam)
{
	bIsVector = false;
	bIsArray = false;
	bIsDamageValue = false;
	Value = ValueParam;
}

public function vector GetVectorValue()
{
	return VectorValue.GetVectorValue();
}

public function SetVectorValue(vector VectorParam)
{
	bIsVector = true;
	bIsArray = false;
	bIsDamageValue = false;
	VectorValue.SetVectorValue(VectorParam);
}

public function array<string> GetArrayValue()
{
	return ArrayValue.GetArrayValue();
}

public function SetArrayValue(array<string> ArrayValueParam)
{
	bIsVector = false;
	bIsArray = true;
	bIsDamageValue = false;
	ArrayValue.SetArrayValue(ArrayValueParam);
}

public function WeaponDamageValue GetDamageValue()
{
	return DamageValue.GetDamageValue();
}

public function SetDamageValue(WeaponDamageValue DamageValueParam)
{
	bIsVector = false;
	bIsArray = false;
	bIsDamageValue = true;
	DamageValue.SetDamageValue(DamageValueParam);
}

public function string GetTagFunctionValue()
{
	return TagFunction;
}

public function SetTagFunctionValue(string TagFunctionParam)
{
	TagFunction = TagFunctionParam;
}

public function SetTagParamValue(string TagParamParam)
{
	TagParam = TagParamParam;
}

public function string GetTagParamValue()
{
	return TagParam;
}

public function string GetTagValue()
{
	local string TagValue;

	if (bIsVector)
	{
		TagValue = VectorValue.ToString();
	}
	else if (bIsArray)
	{
		TagValue = ArrayValue.ToString();
	}
	else if (bIsDamageValue)
	{
		DamageValue.ToString();
	}
	else
	{
		TagValue = Value;
	}

	if (!bIsVector &&
		TagFunction != "")
	{
		TagValue = GetTagValueModifiedByTagFunction(TagFunction);
	}

	return TagPrefix $ TagValue $ TagSuffix;
}

function string GetTagValueModifiedByTagFunction(string TagFunctionIn)
{
	local int OutValue;
	local string DelegateValue;
	local array<string> LocalArrayValue;
	local delegate<JsonConfig_Manager.TagFunctionDelegate> TagFunctionCB;

	foreach ManagerInstance.OnTagFunctions(TagFunctionCB)
	{
		if (TagFunctionCB(name(TagFunctionIn), self, DelegateValue))
		{
			return DelegateValue;
		}
	}

	switch (name(TagFunctionIn))
	{
		case 'TagValueToPercent':
			OutValue = int(float(Value) * 100);
			break;
		case 'TagValueToPercentMinusHundred':
			OutValue = int(float(Value) * 100 - 100);
			break;
		case 'TagValueMetersToTiles':
			OutValue = int(float(Value) * class'XComWorldData'.const.WORLD_METERS_TO_UNITS_MULTIPLIER / class'XComWorldData'.const.WORLD_StepSize);
			break;
		case 'TagValueTilesToMeters':
			OutValue = int(float(Value) * class'XComWorldData'.const.WORLD_StepSize / class'XComWorldData'.const.WORLD_METERS_TO_UNITS_MULTIPLIER);
			break;
		case 'TagValueTilesToUnits':
			OutValue = int(float(Value) * class'XComWorldData'.const.WORLD_StepSize);
			break;
		case 'TagValueParamAddition':
			 OutValue = int(float(Value) + float(GetTagParam()));
			 break;
		case 'TagValueParamMultiplication':
			 OutValue = int(float(Value) * float(GetTagParam()));
			 break;
		case 'TagArrayValue':
			LocalArrayValue = GetArrayValue();
			return  LocalArrayValue[int(GetTagParam())];
			break;
		default:
			break;
	}

	return string(OutValue);
}


function JSonObject Serialize()
{
	local JsonObject JsonObject;

	JSonObject = new () class'JsonObject';

	if (bIsArray)
	{
		ArrayValue.Serialize(JSonObject, "ArrayValue");
	}
	else if (bIsVector)
	{
		VectorValue.Serialize(JSonObject, "VectorValue");
	}
	else if (bIsDamageValue)
	{
		DamageValue.Serialize(JSonObject, "DamageValue");
	}
	else
	{
		JSonObject.SetStringValue("Value", Value);
	}

	if (Namespace != "")
	{
		JSonObject.SetStringValue("Namespace", Namespace);
	}
	if (TagFunction != "")
	{
		JSonObject.SetStringValue("TagFunction", TagFunction);
	}
	if (TagParam != "")
	{
		JSonObject.SetStringValue("TagParam", TagParam);
	}
	if (TagPrefix != "")
	{
		JSonObject.SetStringValue("TagPrefix", TagPrefix);
	}
	if (TagSuffix != "")
	{
		JSonObject.SetStringValue("TagSuffix", TagSuffix);
	}

	return JSonObject;
}

function Deserialize(JSonObject Data)
{
	VectorValue = new class'JsonConfig_Vector';
	ArrayValue = new class'JsonConfig_Array';
	DamageValue = new class'JsonConfig_WeaponDamageValue';

	bIsVector = VectorValue.Deserialize(Data, "VectorValue");
	bIsArray = ArrayValue.Deserialize(Data, "ArrayValue");
	bIsDamageValue = DamageValue.Deserialize(Data, "DamageValue");

	Value = Data.GetStringValue("Value");

	Namespace = Data.GetStringValue("Namespace");
	TagFunction = Data.GetStringValue("TagFunction");
	TagParam = Data.GetStringValue("TagParam");
	TagPrefix = Data.GetStringValue("TagPrefix");
	TagSuffix = Data.GetStringValue("TagSuffix");
}

defaultproperties
{
	Begin Object Class=JsonConfig_Vector Name=TaggedDefaultJsonConfig_Vector
	End Object
	VectorValue = TaggedDefaultJsonConfig_Vector;

	Begin Object Class=JsonConfig_Array Name=TaggedDefaultJsonConfig_Array
	End Object
	ArrayValue = TaggedDefaultJsonConfig_Array;

	Begin Object Class=JsonConfig_WeaponDamageValue Name=TaggedDefaultJsonConfig_WeaponDamageValue
	End Object
	DamageValue = TaggedDefaultJsonConfig_WeaponDamageValue;
}