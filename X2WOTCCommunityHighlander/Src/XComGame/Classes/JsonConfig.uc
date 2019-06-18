//-----------------------------------------------------------
//	Class:	JsonConfiguc
//	Author: Musashi
//	
//-----------------------------------------------------------
class JsonConfig extends JsonObject;

struct ObjectKey
{
	var string Key;
	var string ParentKey;
};

static public final function string GetPropertyName(coerce string PropertyName, optional string Namespace)
{
	if (Namespace != "")
	{
		PropertyName $= ":" $ Namespace;
	}

	return PropertyName;
}

static public function string SanitizeJson(string Json)
{
	local string Buffer;
	local int CountBracketsOpen, CountBracketsClose, CountDoubleQuotes;

	Buffer = Repl(Repl(Repl(Json, "\n", ""), " ", ""), "	", "");
	
	CountBracketsOpen  = CountCharacters(Buffer, "{");
	CountBracketsClose = CountCharacters(Buffer, "}");
	CountDoubleQuotes = CountCharacters(Buffer, "\"");

	if (CountBracketsOpen != CountBracketsClose ||
		InStr(Buffer, "\"{") != INDEX_NONE ||
		CountDoubleQuotes % 2 != 0)
	{
		`LOG(default.class @ GetFuncName() @ "Warning: invalid json" @ Buffer,, 'RPG');
		return "";
	}

	Buffer = LTrimToFirstBracket(Buffer);
	Buffer = RTrimToFirstBracket(Buffer);

	return Buffer;
}

static public final function int CountCharacters(coerce string S, string Character)
{
	local int Count, Index, Max;
	local string copy;

	copy = S;

	Max = Len(copy);

	for (Index = 0; Index < Max; Index++)
	{
		if (Left(copy, 1) == Character)
		{
			Count++;
		}
		copy = Right(copy, Len(copy) - 1);
	}

	return Count;
}

static public final function string LTrimToFirstBracket(coerce string S)
{
	while (Left(S, 1) != "{" && Len(S) > 0)
	{
		S = Right(S, Len(S) - 1);
	}
	return S;
}
static public final function string RTrimToFirstBracket(coerce string S)
{
	while (Right(S, 1) != "}" && Len(S) > 0)
	{
		S = Left(S, Len(S) - 1);
	}
	return S;
}

static public final function array<ObjectKey> GetAllObjectKeys(coerce string Str)
{
	local array<string> Chunks;
	local string Chunk, ParentKey, GrandParentKey;
	local array<ObjectKey> Keys;
	local ObjectKey ObjKey, EmptyKey;

	ParentKey = "";
	GrandParentKey = "";

	Str = Repl(Str, "\":{", "$$$\":{");
	Str = Repl(Str, "\"}}", "}\"}");
	Str = Repl(Str, "},", "}\"");

	Chunks = SplitString(Str, "\"", true);

	foreach Chunks(Chunk)
	{
		if (InStr(Chunk, "$$$") != INDEX_NONE)
		{
			ObjKey = EmptyKey;
			ObjKey.ParentKey = ParentKey;
			ObjKey.Key = Repl(Chunk, "$$$", "");
			Keys.AddItem(ObjKey);
		}

		if (InStr(Chunk, "{") != INDEX_NONE)
		{
			if (ParentKey != "")
			{
				GrandParentKey = ParentKey;
			}
			ParentKey = ObjKey.Key;
		}

		// Last level
		if (InStr(Chunk, "}") != INDEX_NONE && ObjKey.Key == ParentKey)
		{
			ParentKey = GrandParentKey;
			GrandParentKey = "";
			ObjKey = EmptyKey;
		}
		else if (InStr(Chunk, "}") != INDEX_NONE && ParentKey != "")
		{
			ParentKey = Keys[Keys.Find('Key', ParentKey)].ParentKey;
			ObjKey = EmptyKey;
		}
	}

	return Keys;
}

static public final function string GetObjectKey(coerce string S)
{
	local int Index, Max, DoubleQuoteUnicode;
	local string Key;
	local bool bStart;

	Max = Len(S);
	DoubleQuoteUnicode = 34;

	for (Index = 0; Index < Max; Index++)
	{
		if (Asc(Left(S, 1)) == DoubleQuoteUnicode)
		{
			if (bStart)
				break;
			if (!bStart)
				bStart = true;
		}

		if (bStart && Asc(Left(S, 1)) != DoubleQuoteUnicode)
		{
			Key $= Left(S, 1);
		}

		S = Right(S, Len(S) - 1);
	}

	return Key;
}