// CH Helper class for DLC_2
class CHHelpers_DLC_Day60 extends Object;

// Issue #335 Start
// Returns true if the list contains any of the active tags specified in
// `class'XComGameState_AlienRulerManager'.default.AlienRulerTemplates`
static function bool ContainsRulerActiveTag(const out array<name> Tags)
{
	local int i, j;

	if (Tags.Length == 0)
	{
		return false;
	}

	for (i = 0; i < class'XComGameState_AlienRulerManager'.default.AlienRulerTemplates.Length; i++)
	{
		if (Tags.Find(class'XComGameState_AlienRulerManager'.default.AlienRulerTemplates[i].ActiveTacticalTag) != INDEX_NONE)
		{
			return true;
		}

		for (j = 0; j < class'XComGameState_AlienRulerManager'.default.AlienRulerTemplates[i].AdditionalTags.Length; j++)
		{
			if (Tags.Find(class'XComGameState_AlienRulerManager'.default.AlienRulerTemplates[i].AdditionalTags[j].TacticalTag) != INDEX_NONE)
			{
				return true;
			}
		}
	}

	return false;
}
// Issue #335 End
