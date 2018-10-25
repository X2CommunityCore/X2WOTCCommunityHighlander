// Issue #309, extra class so that we don't run into increasing circular class dependencies
// I would have liked to place this in CHHelpers, or call this class CHPhotoboothHelpers,
// but this wouldn't work due to UCC being picky about struct and enum compilation order.
// X2PhotoboothHelpers comes after X2Photobooth, so that's okay! Strategic class naming!
class X2PhotoboothHelpers extends Object config(Content);

struct SoldierClassEnums
{
	var name SoldierClass;
	var Photobooth_AnimationFilterType ClassFilter;
};

var config array<SoldierClassEnums> PhotoboothSoldierClassFilters;

// Soldier classes mentioned here cannot have poses with a ePAFT_SoldierRifle,
// or poses marked bExcludeFromTemplar.
var config array<name> TemplarLikeSoldierClasses;

// Character templates mentioned here will use the spark poses and have some
// extra space for themselves.
var config array<name> SparkLikeCharacterTemplates;

// Return the list of soldier class filters for this class, or, if there are none, return an array with a single
// ePAFT_None entry. The first entry is considered the "primary" filter for purposes of random rolls.
static function array<Photobooth_AnimationFilterType> GetClassFiltersForClass(name SoldierClassTemplateName)
{
	local int i;
	local array<Photobooth_AnimationFilterType> ClassFilters;

	for (i = 0; i < default.PhotoboothSoldierClassFilters.Length; i++)
	{
		if (default.PhotoboothSoldierClassFilters[i].SoldierClass == SoldierClassTemplateName)
		{
			ClassFilters.AddItem(default.PhotoboothSoldierClassFilters[i].ClassFilter);
		}
	}
	
	if (ClassFilters.Length == 0)
	{
		ClassFilters.AddItem(ePAFT_None);
	}

	return ClassFilters;
}

static function bool IsLikeTemplar(name SoldierClassTemplateName)
{
	return default.TemplarLikeSoldierClasses.Find(SoldierClassTemplateName) != INDEX_NONE;
}

static function bool IsLikeSpark(name CharacterTemplateName)
{
	return default.SparkLikeCharacterTemplates.Find(CharacterTemplateName) != INDEX_NONE;
}