//-----------------------------------------------------------
//	Class:	JsonConfig_WeaponDamageValue
//	Author: Musashi
//	
//-----------------------------------------------------------
class JsonConfig_WeaponDamageValue extends Object implements (JsonConfig_Interface);

var protectedwrite WeaponDamageValue DamageValue;

public function SetDamageValue(WeaponDamageValue DamageValueParam)
{
	DamageValue = DamageValueParam;
}

public function WeaponDamageValue GetDamageValue()
{
	return DamageValue;
}

public function string ToString()
{
	// @TODO make proper damage preview function
	return  (DamageValue.Damage - DamageValue.Spread) $ "-" $ (DamageValue.Damage + DamageValue.Spread);
}

public function Serialize(out JsonObject JsonObject, string PropertyName)
{
	local JsonObject JsonSubObject;

	JsonSubObject = new () class'JsonObject';
	JsonSubObject.SetIntValue("Damage",  DamageValue.Damage);
	JsonSubObject.SetIntValue("Spread",  DamageValue.Spread);
	JsonSubObject.SetIntValue("PlusOne",  DamageValue.PlusOne);
	JsonSubObject.SetIntValue("Crit",  DamageValue.Crit);
	JsonSubObject.SetIntValue("Pierce",  DamageValue.Pierce);
	JsonSubObject.SetIntValue("Rupture",  DamageValue.Rupture);
	JsonSubObject.SetIntValue("Shred",  DamageValue.Shred);
	JsonSubObject.SetStringValue("Tag",  string(DamageValue.Tag));
	JsonSubObject.SetStringValue("DamageType", string(DamageValue.DamageType));

	JSonObject.SetObject(PropertyName, JsonSubObject);
}

public function bool Deserialize(JSonObject Data, string PropertyName)
{
	local JsonObject DamageValueJson;

	DamageValueJson = Data.GetObject(PropertyName);
	if (DamageValueJson != none)
	{
		DamageValue.Damage = DamageValueJson.GetIntValue("Damage");
		DamageValue.Spread = DamageValueJson.GetIntValue("Spread");
		DamageValue.PlusOne = DamageValueJson.GetIntValue("PlusOne");
		DamageValue.Crit = DamageValueJson.GetIntValue("Crit");
		DamageValue.Pierce = DamageValueJson.GetIntValue("Pierce");
		DamageValue.Rupture = DamageValueJson.GetIntValue("Rupture");
		DamageValue.Shred = DamageValueJson.GetIntValue("Shred");
		DamageValue.Tag = name(DamageValueJson.GetStringValue("Tag"));
		DamageValue.DamageType = name(DamageValueJson.GetStringValue("DamageType"));
		return true;
	}

	DamageValue.Damage = 0;
	DamageValue.Spread = 0;
	DamageValue.PlusOne = 0;
	DamageValue.Crit = 0;
	DamageValue.Pierce = 0;
	DamageValue.Rupture = 0;
	DamageValue.Shred = 0;
	DamageValue.Tag = '';
	DamageValue.DamageType = '';

	return false;
}