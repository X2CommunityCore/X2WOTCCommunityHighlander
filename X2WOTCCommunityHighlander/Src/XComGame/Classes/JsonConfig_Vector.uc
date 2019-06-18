//-----------------------------------------------------------
//	Class:	JsonConfig_Vector
//	Author: Muasshi
//	
//-----------------------------------------------------------
class JsonConfig_Vector extends Object implements(JsonConfig_Interface);

var protectedwrite vector VectorValue;

public function SetVectorValue(vector VectorParam)
{
	VectorValue = VectorParam;
}

public function vector GetVectorValue()
{
	return VectorValue;
}

public function string ToString()
{
	return VectorValue.X $ "," $ VectorValue.Y $ "," $ VectorValue.Z;
}

public function Serialize(out JsonObject JsonObject, string PropertyName)
{
	local JsonObject JsonSubObject;

	JsonSubObject = new () class'JsonObject';
	JsonSubObject.SetIntValue("X", VectorValue.X);
	JsonSubObject.SetIntValue("Y", VectorValue.X);
	JsonSubObject.SetIntValue("Z", VectorValue.X);

	JSonObject.SetObject(PropertyName, JsonSubObject);
}

public function bool Deserialize(JSonObject Data, string PropertyName)
{
	local JSonObject VectorJson;

	VectorJson = Data.GetObject(PropertyName);
	if (VectorJson != none)
	{
		VectorValue.X = VectorJson.GetIntValue("X");
		VectorValue.Y = VectorJson.GetIntValue("Y");
		VectorValue.Z = VectorJson.GetIntValue("Z");
		return true;
	}

	VectorValue.X = 0;
	VectorValue.Y = 0;
	VectorValue.Z = 0;

	return false;
}