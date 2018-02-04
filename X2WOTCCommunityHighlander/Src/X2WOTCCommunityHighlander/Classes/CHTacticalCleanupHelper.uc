//---------------------------------------------------------------------------------------
//  FILE:   CHTacticalCleanupHelper.uc
//
//	Issue #178
//
class CHTacticalCleanupHelper extends Object config(Game);

var config array<name> CharacterTypesToCleanup;

// void CleanupObsoleteTacticalGamestate()
static function CleanupObsoleteTacticalGamestate()
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_Unit UnitState;
	local int UnitGameStatesRemoved, ItemGameStatesRemoved;
	local XComGameState ArchiveState;
	local int LastArchiveStateIndex;
	local array<XComGameState_Item> InventoryItems;
	local XComGameState_Item Item;

	History = `XCOMHISTORY;
	//mark all transient tactical gamestates as removed
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Test remove all ability gamestates");
	// grab the archived strategy state from the history and the headquarters object
	LastArchiveStateIndex = History.FindStartStateIndex() - 1;
	ArchiveState = History.GetGameStateFromHistory(LastArchiveStateIndex, eReturnType_Copy, false);
	UnitGameStatesRemoved = 0;
	ItemGameStatesRemoved = 0;

	foreach ArchiveState.IterateByClassType(class'XComGameState_Unit', UnitState)
	{
		if (UnitTypeShouldBeCleanedUp(UnitState))
		{
			InventoryItems = UnitState.GetAllInventoryItems(ArchiveState);
			foreach InventoryItems (Item)
			{
				NewGameState.RemoveStateObject (Item.ObjectID);
				ItemGameStatesRemoved++;
			}
			NewGameState.RemoveStateObject (UnitState.ObjectID);
			UnitGameStatesRemoved++;
		}
	}

	class'X2TacticalGameRuleset'.static.ReleaseScriptLog("REMOVED " $ UnitGameStatesRemoved $ " obsolete enemy unit gamestates when loading into strategy");
	class'X2TacticalGameRuleset'.static.ReleaseScriptLog("REMOVED " $ ItemGameStatesRemoved $ " obsolete enemy item gamestates when loading into strategy");
	History.AddGameStateToHistory(NewGameState);
}

// bool UnitTypeShouldBeCleanedUp(XComGameState_Unit UnitState)
static function bool UnitTypeShouldBeCleanedUp(XComGameState_Unit UnitState)
{
	local X2CharacterTemplate CharTemplate;
	local name CharTemplateName;
	local int IncludeIdx;

	CharTemplate = UnitState.GetMyTemplate();
	if (CharTemplate == none) { return false; }
	CharTemplateName = UnitState.GetMyTemplateName();
	if (CharTemplateName == '') { return false; }
	
	if (!CharTemplate.bIsSoldier) // Sanity check
	{
		IncludeIdx = default.CharacterTypesToCleanup.Find(CharTemplateName);
		if (IncludeIdx != INDEX_NONE)
		{
			return true;
		}
	}
	return false;
}