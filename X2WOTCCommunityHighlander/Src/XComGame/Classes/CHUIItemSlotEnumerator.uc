// Issue #118: A UI object that provides a generalized access to the item slots
// to reduce code duplication in related UI classes (Loadout, Squad Select, ...)
// and make the slot system more easily accessible (a more cynical interpretation would be
// "keep all the ugly code we need contained in this class")
// This is for UI purposes only and should not be used for game state code
// It will also almost definitely cause issues if you make changes to the game state while enumerating slots

// This could also have been called Iterator, but a) Iterator is a keyword for (native) functions supporting foreach() nests (which this doesn't support)
// And b) In Java (which UnrealScript is similar to), Enumerator would reflect the functionality more accurately: Not fail-fast and no Remove() method

class CHUIItemSlotEnumerator extends Object;

struct CHSlotPriority
{
	var EInventorySlot Slot;
	var int            Priority;
};

// These are state variables the Iterator uses internally and can (and should be) used from the accessing code
// Current Slot
var protectedwrite EInventorySlot Slot;
var protectedwrite bool           IsMultiSlot;
// for multi-slot items. If IsLocked == true, this is invalid!!!!
var protectedwrite int            IndexInSlot;
// Item State in this slot. May be none, in which case the slot is empty
var protectedwrite XComGameState_Item ItemState;
// This slot is locked. Locked slots may still have items!
var protectedwrite bool IsLocked;
// The reason this slot is locked
var protectedwrite string LockedReason;


// Variable for users to store data in if they really want to
var protectedwrite XComLWTuple Data;

// Internal variables
var protected int SlotIdx;
var protected int MaxShownSlots;
var protected bool SlotUsesUnlockHint;
// Fixed
var protected XComGameState_Unit UnitState;
var protected XComGameState CheckGameState;
var protected array<CHSlotPriority> SlotOrder;
var protected bool UseUnlockHints;


// Pseudo-constructor, use this instead of new'ing
// Parameters:
//     _UnitState: The unit state (required)
//     _CheckGameState: For MP, if the changes are made to a unit within a game state (optional)
//     _SlotPriorities: A list of 2-tuples associating a slot with a priority override (optional)
//     _UseUnlockHints: For Multi-item slots, the slot may provide locked indicator slots (ex: locked utility slots in UISquadSelect), (optional)
//     _OverrideSlotsList: Instead of considering UnitShowSlot on the Slot Templates (and using the default vanilla slots that should be shown), 
//                         provide a slot list that overrides the default slots. Yields varying results when slots don't implement the functions UI code expects them to.
//                         Added so the code in this class can easily be reused (optional)
static function CHUIItemSlotEnumerator CreateEnumerator(XComGameState_Unit _UnitState, optional XComGameState _CheckGameState, optional array<CHSlotPriority> _SlotPriorities, optional bool _UseUnlockHints, optional array<EInventorySlot> _OverrideSlotsList)
{
	local CHUIItemSlotEnumerator En;

	En = new default.Class;
	En.Init(_UnitState, _CheckGameState, _SlotPriorities, _UseUnlockHints, _OverrideSlotsList);

	return En;
}

// Same as in CreateEnumerator, but instead of accepting an array<CHSlotPriority> to override slot priorities, accept two arrays that are zipped into a struct array
// This allows mods to optionally support the highlander without crashing if it isn't present
static function CHUIItemSlotEnumerator CreateEnumeratorZipPriorities(XComGameState_Unit _UnitState, optional XComGameState _CheckGameState, optional array<EInventorySlot> _PriorityOverrideSlots, optional array<int> _PriorityOverridePriorities, optional bool _UseUnlockHints, optional array<EInventorySlot> _OverrideSlotsList)
{
	local array<CHSlotPriority> arr;
	local int i;

	arr.Add(_PriorityOverrideSlots.Length);
	for (i = 0; i < arr.Length; i++)
	{
		arr[i].Slot = _PriorityOverrideSlots[i];
		arr[i].Priority = _PriorityOverridePriorities[i];
	}
	return CreateEnumerator(_UnitState, _CheckGameState, arr, _UseUnlockHints, _OverrideSlotsList);
}

protected function Init(XComGameState_Unit _UnitState, optional XComGameState _CheckGameState, optional array<CHSlotPriority> _SlotPriorities, optional bool _UseUnlockHints, optional array<EInventorySlot> _OverrideSlotsList)
{
	local array<EInventorySlot> SlotEnums;
	local int i, idx;
	local string strDummy;

	UnitState = _UnitState;
	CheckGameState = _CheckGameState;
	UseUnlockHints = _UseUnlockHints;
	Data = new class'XComLWTuple';

	if (_OverrideSlotsList.Length > 0)
	{
		SlotEnums = _OverrideSlotsList;
	}
	else
	{
		SlotEnums = class'CHItemSlot'.static.GetDefaultDisplayedSlots(UnitState, CheckGameState);
	}
	SlotOrder.Length = SlotEnums.Length;
	for (i = 0; i < SlotEnums.Length; i++)
	{
		SlotOrder[i].Slot = SlotEnums[i];
		idx = _SlotPriorities.Find('Slot', SlotEnums[i]);
		if (idx != INDEX_NONE)
		{
			SlotOrder[i].Priority = _SlotPriorities[idx].Priority;
		}
		else
		{
			SlotOrder[i].Priority = class'CHItemSlot'.static.SlotGetPriority(SlotEnums[i], UnitState, CheckGameState);
		}
	}
	for (i = SlotOrder.Length - 1; i >= 0; i--)
	{
		// For Multi item slots, a count > 0 is the number of items, -1 means infinite. So == 0 means we don't want to show it at all.
		if (class'CHItemSlot'.static.SlotIsMultiItem(SlotOrder[i].Slot)
			&& class'CHItemSlot'.static.SlotGetMaxItemCount(SlotOrder[i].Slot, UnitState, CheckGameState) == 0
			// We still might want to show an unlock hint though
			&& !(UseUnlockHints && class'CHItemSlot'.static.SlotGetMultiUnlockHint(SlotOrder[i].Slot, UnitState, strDummy, CheckGameState)))
		{
			SlotOrder.Remove(i, 1);
		}
	}
	SlotOrder.Sort(BySmallAndPriority);

	SlotIdx = -1;
	IndexInSlot = 0;
}

private function int BySmallAndPriority(CHSlotPriority A, CHSlotPriority B)
{
	if (class'CHItemSlot'.static.SlotIsSmall(A.Slot) && !class'CHItemSlot'.static.SlotIsSmall(B.Slot))
	{
		return -1;
	}
	else if (!class'CHItemSlot'.static.SlotIsSmall(A.Slot) && class'CHItemSlot'.static.SlotIsSmall(B.Slot))
	{
		return 1;
	}
	return B.Priority - A.Priority;
}

// Returns true if a call to Next() still leaves the Enumerator in a valid state
function bool HasNext()
{
	return (IsMultiSlot && IndexInSlot + 1 < MaxShownSlots) 
	    // Every Slot in SlotOrder is either a single item slot or a multi item slot with at least one item (see initialization code)
	    || (SlotIdx + 1 < SlotOrder.Length);
}

// Advances the Enumerator, yielding the next item or (potentially free) slot
function Next()
{
	local int iMax;
	local array<XComGameState_Item> Items;
	local string strDummy;

	if (IsMultiSlot && IndexInSlot + 1 < MaxShownSlots)
	{
		IndexInSlot++;
	}
	else if (SlotIdx + 1 < SlotOrder.Length)
	{
		SlotIdx++;
		Slot = SlotOrder[SlotIdx].Slot;
		IsMultiSlot = class'CHItemSlot'.static.SlotIsMultiItem(Slot);
		IndexInSlot = 0;
		if (IsMultiSlot)
		{
			iMax = class'CHItemSlot'.static.SlotGetMaxItemCount(Slot, UnitState, CheckGameState);
			SlotUsesUnlockHint = UseUnlockHints && class'CHItemSlot'.static.SlotGetMultiUnlockHint(Slot, UnitState, strDummy, CheckGameState);
			if (SlotUsesUnlockHint)
			{
				iMax++;
			}
			// Only show items with a size here. Generally, items are supposed to have a size, which makes them occupy several slots
			// But that functionality is not well supported in XComGame. The only item with size 0 is the XPAD, which we don't want
			// And we will be consistent with that behavior here
			// Start Issue #302;
			Items = UnitState.GetAllItemsInSlot(Slot, CheckGameState, , true /* bHasSize */);
			MaxShownSlots = iMax == -1 ? Items.Length + 1 : iMax;
			// End Issue #302
		}
	}
	else
	{
		`REDSCREEN(default.Class $ "::" $ GetFuncName() $ " : reached end of slots, make sure to check HasNext() before\n" @ GetScriptTrace());
	}

	IsLocked = false;
	if (IsMultiSlot)
	{
		Items = UnitState.GetAllItemsInSlot(Slot, CheckGameState, , true /* bHasSize */);
		if (IndexInSlot == MaxShownSlots - 1 && SlotUsesUnlockHint && class'CHItemSlot'.static.SlotGetMultiUnlockHint(Slot, UnitState, LockedReason, CheckGameState))
		{
			ItemState = none;
			IsLocked = true;
			return;
		}
		if (IndexInSlot >= Items.Length)
		{
			ItemState = none;
		}
		else
		{
			ItemState = Items[IndexInSlot];
		}
	}
	else
	{
		ItemState = UnitState.GetItemInSlot(Slot, CheckGameState);
	}
	IsLocked = !class'CHItemSlot'.static.SlotAvailable(Slot, LockedReason, UnitState, CheckGameState);	
}
