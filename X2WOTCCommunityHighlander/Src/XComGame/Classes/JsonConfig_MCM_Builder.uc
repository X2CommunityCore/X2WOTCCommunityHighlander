class JsonConfig_MCM_Builder extends JsonConfig config(UI) abstract;

struct MCMConfigMapEntry
{
	var string PageID;
	var JsonConfig_MCM_Page MCMConfigPage;
};

var config array<string> MCMPages;
var protectedwrite array<MCMConfigMapEntry> DeserialzedPagesMap;
var string BuilderClassName;
var array<ObjectKey> ObjectKeys;

static public function JsonConfig_MCM_Builder GetMCMBuilder(optional string BuilderClassNameParam)
{
	local JsonConfig_MCM_Builder MCMBuilder;

	if (BuilderClassNameParam == "")
	{
		BuilderClassNameParam = string(default.class);
	}


	MCMBuilder = JsonConfig_MCM_Builder(class'Engine'.static.FindClassDefaultObject(BuilderClassNameParam));

	if (MCMBuilder.DeserialzedPagesMap.Length == 0)
	{
		MCMBuilder.DeserializeConfig();
		MCMBuilder.BuilderClassName = BuilderClassNameParam;
	}

	return MCMBuilder;
}

function string LocalizeItem(string Key)
{
	local string Locale, Path;
	
	Path = string(GetPackageName()) $ "." $ BuilderClassName $ "." $ Key;
	Locale =  ParseLocalizedPropertyPath(Path);

	if (Locale == "")
	{
		`LOG(default.class @ GetFuncName() @ "Warning localization not found:" @ Path,, 'RPG');
	}
	
	return Locale;
}

public static function SerializeAndSaveBuilderConfig()
{
	local JsonConfig_MCM_Builder Builder;

	Builder = GetMCMBuilder();
	Builder.SerializeConfig();
	Builder.SaveConfig();
}

private function DeserializeConfig()
{
	local MCMConfigMapEntry MapEntry;
	local JSonObject JSonObject;
	local JsonConfig_MCM_Page MCMPage;
	local ObjectKey ObjKey;
	local string SanitizedJsonString, SerializedMCMPage;

	`LOG(default.class @ GetFuncName() @ "found entries:" @ default.MCMPages.Length,, 'RPG');

	foreach default.MCMPages(SerializedMCMPage)
	{
		SanitizedJsonString = SanitizeJson(SerializedMCMPage);

		if (SanitizedJsonString != "")
		{
			ObjectKeys = GetAllObjectKeys(SanitizedJsonString);
			JSonObject = class'JSonObject'.static.DecodeJson(SanitizedJsonString);
	
			foreach ObjectKeys(ObjKey)
			{
				if (JSonObject != none && ObjKey.ParentKey == "")
				{
					if (DeserialzedPagesMap.Find('PageID', ObjKey.Key) == INDEX_NONE)
					{
						MCMPage = new class'JsonConfig_MCM_Page';
						if (MCMPage.Deserialize(JSonObject, ObjKey.Key, self))
						{
							MapEntry.PageID = ObjKey.Key;
							MapEntry.MCMConfigPage = MCMPage;
							DeserialzedPagesMap.AddItem(MapEntry);
						}
					}
				}
			}
		}
	}
}

private function SerializeConfig()
{
	local MCMConfigMapEntry MapEntry;
	local JSonObject JSonObject;

	MCMPages.Length = 0;

	foreach DeserialzedPagesMap(MapEntry)
	{
		JSonObject = new () class'JsonObject';
		MapEntry.MCMConfigPage.Serialize(JSonObject, MapEntry.PageID);
		MCMPages.AddItem(class'JSonObject'.static.EncodeJson(JSonObject));
	}
}
