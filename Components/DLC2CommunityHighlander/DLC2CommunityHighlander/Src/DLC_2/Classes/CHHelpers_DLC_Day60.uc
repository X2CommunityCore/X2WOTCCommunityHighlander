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

// On a BEST-EFFORT BASIS, attempt to add the ruler `RulerTemplateName` to existing encounter buckets.
// EncounterListName will be used to add to the bucket, defaulting to `LIST_RULER_<RulerTemplateName>`.
// It is recommended that this be called once for your custom ruler in `OnPostTemplatesCreated`.
static function TryAddToExistingRulerEncounterBuckets(name RulerTemplateName, optional name EncounterListName = '')
{
	local int i, pos;
	local ConditionalEncounter Encounter;

	i = class'XComGameState_AlienRulerManager'.default.AlienRulerTemplates.Find('AlienRulerTemplateName', RulerTemplateName);

	if (i == INDEX_NONE)
	{
		`log("CHL_DLC_2: TryAddToExistingRulerEncounterBuckets -- Skipping " $ RulerTemplateName $ " as it is not a known ruler.");
		return;
	}

	if (EncounterListName == '')
	{
		EncounterListName = name("LIST_RULER_" $ RulerTemplateName);
	}

	Encounter.EncounterID = EncounterListName;
	Encounter.IncludeTacticalTag = class'XComGameState_AlienRulerManager'.default.AlienRulerTemplates[i].ActiveTacticalTag;
	Encounter.ExcludeTacticalTag = class'XComGameState_AlienRulerManager'.default.AlienRulerTemplates[i].DeadTacticalTag;

	for (i = 0; i < class'XComTacticalMissionManager'.default.EncounterBuckets.Length; i++)
	{
		pos = MatchAlienRulerBucket(class'XComTacticalMissionManager'.default.EncounterBuckets[i]);

		if (pos != INDEX_NONE)
		{
			class'XComTacticalMissionManager'.default.EncounterBuckets[i].EncounterIDs.InsertItem(pos, Encounter);
			`log("CHL_DLC_2: TryAddToExistingRulerEncounterBuckets -- inserted "$ Encounter.EncounterID $ " at position " $ pos $ " into bucket " $ class'XComTacticalMissionManager'.default.EncounterBuckets[i].EncounterBucketID);
		}
	}
}

// Identify an alien ruler bucket. This function recognizes an alien ruler bucket by
// matching a positive number of ruler list encounters (with an IncludeTacticalTag and an ExcludeTacticalTag)
// and any number of arbitrary encounters after that. Returns INDEX_NONE if this bucket is not an alien ruler
// bucket, otherwise returns the desired insertion position.
static function int MatchAlienRulerBucket(const EncounterBucket Bucket)
{
	local int idx, j;

	for (idx = 0; idx < Bucket.EncounterIDs.Length; idx++)
	{
		// Test whether this bucket references an Alien Ruler with its Dead/Alive tags.
		j = class'XComGameState_AlienRulerManager'.default.AlienRulerTemplates.Find('ActiveTacticalTag', Bucket.EncounterIDs[idx].IncludeTacticalTag);
		if (j == INDEX_NONE ||  class'XComGameState_AlienRulerManager'.default.AlienRulerTemplates[j].DeadTacticalTag != Bucket.EncounterIDs[idx].ExcludeTacticalTag)
		{
			// If not, break, we're done here.
			break;
		}
	}

	// idx now is the index where the encounters stopped referencing rulers.
	// If idx == 0, there were no rulers
	return (idx == 0) ? INDEX_NONE : idx;
}

// Issue #335 End
