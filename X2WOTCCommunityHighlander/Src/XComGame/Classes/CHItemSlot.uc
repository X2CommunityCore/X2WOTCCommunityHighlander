// Issue #118: This class provides instructions for various game systems
// regarding the handling of any additional items slots we define
// This is used as a way to only have the minumum required code in the Highlander
// and externalize the code that handles those slots into other mods.
// It also abstracts some behavior of vanilla slots into static helper functions

// Many of these functions reference a CheckGameState: This is used to handle Multiplayer more gracefully
// Multiplayer doesn't use a History, but rather a single game state that is never submitted.
// Hence, many functions may need a game state to determine slot behavior. We could have avoided
// using this in multiplayer at all, but it's better to use a single approach
// Mod code is encouraged to make use of this, by not relying on the history alone
// (i.e. use Unit.GetItemInSlot, it can search an existing game state)
class CHItemSlot extends Object;

// Simple array of Slot Templates. Only accessed on the static CDO.
// Add to it from any given CreateTemplates function, modify in OnPostTemplatesCreated
var private CHItemSlot SlotTemplates[EInventorySlot.EnumCount];

// These are Slot Categories! In vanilla:
// Item = Utility, Grenade/Ammo Pocket; Weapon = Primary, Secondary, Heavy; Armor = Armor, Heavy Weapon
// A lot of UI code and options rely on these 
const SLOT_ARMOR       = 0x00000001; // affected by StripArmor
const SLOT_WEAPON      = 0x00000002; // affected by StripWeapons
const SLOT_ITEM        = 0x00000004; // affected by StripItems
const SLOT_MISC        = 0x00000008; // affected by code that strips all items
const SLOT_ALL         = 0x0000000F; // combined mask for all these slot types


// There can only be one Template per slot
var EInventorySlot InvSlot;

// Bitfield of the above constants. Only non-zero if this slot can be equipped and unequipped by hand,
// and if MakeItemsAvailable should pick this slot up
var int SlotCatMask;
// should be equivalent to SlotCatMask != 0, keeping it for potential validation
var bool IsUserEquipSlot;

// This slot contains equipment and *may* be subject to 
// Class Restrictions for Armor and Weapon Templates
// And the Unique rule potentially only allowing a single type per category
// It does NOT mean that this slot should be displayed for this unit, or that the
// user can manipulate this slot
var bool IsEquippedSlot;

// If this is an equipped slot, this slot is ignored when considering the unique rule
var bool BypassesUniqueRule;

// Can this slot hold more than one item (similar to Utility Slots)?
var bool IsMultiItemSlot;

// If this slot is displayed, it can be displayed in a compact format in the SquadSelect screen
// This imposes two limitations:
// 1) Its item 2d images should be higher than wide, and 
// 2) Its priority is forced to be lower than any other non-small slot ("small items come last")
// Slots are sorted first by priority, and then by Small-Notsmall
var bool IsSmallSlot;

// DELEGATES
// A LOT OF DELEGATES

// Required
delegate bool CanAddItemToSlotFn(CHItemSlot Slot, XComGameState_Unit Unit, X2ItemTemplate Template, optional XComGameState CheckGameState, optional int Quantity = 1, optional XComGameState_Item ItemState);
delegate bool UnitHasSlotFn(CHItemSlot Slot, XComGameState_Unit UnitState, out string LockedReason, optional XComGameState CheckGameState);
delegate int GetPriorityFn(CHItemSlot Slot, XComGameState_Unit UnitState, optional XComGameState CheckGameState);
// Required if IsMultiItemSlot
delegate int GetMaxItemCountFn(CHItemSlot Slot, XComGameState_Unit UnitState, optional XComGameState CheckGameState);

// Optional
delegate AddItemToSlotFn(CHItemSlot Slot, XComGameState_Unit Unit, XComGameState_Item Item, XComGameState NewGameState);
delegate bool CanRemoveItemFromSlotFn(CHItemSlot Slot, XComGameState_Unit Unit, XComGameState_Item ItemState, optional XComGameState CheckGameState);
delegate RemoveItemFromSlotFn(CHItemSlot Slot, XComGameState_Unit Unit, XComGameState_Item ItemState, optional XComGameState NewGameState);
// Default true. If false, make sure to update ValidateLoadout.
delegate bool CanSlotBeUnequippedFn(CHItemSlot Slot, XComGameState_Unit Unit, XComGameState_Item ItemState, optional XComGameState CheckGameState);
delegate array<X2EquipmentTemplate> GetBestGearForSlotFn(CHItemSlot Slot, XComGameState_Unit Unit);
delegate ValidateLoadoutFn(CHItemSlot Slot, XComGameState_Unit Unit, XComGameState_HeadquartersXCom XComHQ, XComGameState NewGameState);
// Falls back to class'UIArmory_Loadout'.default.m_strInventoryLabels
delegate string GetDisplayNameFn(CHItemSlot Slot);
// Uses the first character DisplayName, encouraged to override because language doesn't work that way
delegate string GetDisplayLetterFn(CHItemSlot Slot);
// Falls back to UnitHasSlot. This is only used for generic loadout code. For example, 
// eInvSlot_CombatSim has this as false, but UIArmory_Implants still allows it to be equipped
delegate bool UnitShowSlotFn(CHItemSlot Slot, XComGameState_Unit UnitState, optional XComGameState CheckGameState);
// if IsMultiItemSlot, show an addditional locked slot with an optional tooltip for how to unlock it
// This is only called if this slot is shown at all (via UnitShowSlotFn)
delegate bool GetMultiSlotUnlockHintFn(CHItemSlot Slot, XComGameState_Unit UnitState, out string strReason, optional XComGameState CheckGameState);

// Called from XComGameState_Unit::CanAddItemToInventory if the slot is templated and the Game doesn't know what to do
// Quantity is unused in any of the vanilla slots
function bool CanAddItemToSlot(XComGameState_Unit Unit, X2ItemTemplate Template, optional XComGameState CheckGameState, optional int Quantity = 1, optional XComGameState_Item ItemState)
{
	return CanAddItemToSlotFn(self, Unit, Template,  CheckGameState, Quantity, ItemState);
}

// Called from XComGameState_Unit::AddItemToInventory if the slot is templated and the Game doesn't know what to do
function AddItemToSlot(XComGameState_Unit Unit, XComGameState_Item Item, XComGameState NewGameState)
{
	if (AddItemToSlotFn != none)
	{
		AddItemToSlotFn(self, Unit, Item, NewGameState);
	}
}

// Called from XComGameState_Unit::CanRemoveItemFromInventory if the slot is templated and the Game doesn't know what to do
function bool CanRemoveItemFromSlot(XComGameState_Unit Unit, XComGameState_Item ItemState, optional XComGameState CheckGameState)
{
	if (CanRemoveItemFromSlotFn != none)
	{
		return CanRemoveItemFromSlotFn(self, Unit, ItemState, CheckGameState);
	}
	return true;
}

// Called from XComGameState_Unit::RemoveItemFromInventory if the slot is templated and the Game doesn't know what to do
function RemoveItemFromSlot(XComGameState_Unit Unit, XComGameState_Item ItemState, optional XComGameState NewGameState)
{
	if (RemoveItemFromSlotFn != none)
	{
		RemoveItemFromSlotFn(self, Unit, ItemState, NewGameState);
	}
}

// Called from UIArmory_LoadoutItem, can be used to allow slots to be empty (instead of re-equipping an infinite item)
// ItemState is the Item that was just removed
function bool CanSlotBeUnequipped(XComGameState_Unit Unit, XComGameState_Item ItemState, optional XComGameState CheckGameState)
{
	if (CanSlotBeUnequippedFn != none)
	{
		return CanSlotBeUnequippedFn(self, Unit, ItemState, CheckGameState);
	}
	return false;
}

// Called from XComGameState_Unit::GetBestGearForSlot if the slot is templated and the Game doesn't know what to do
function array<X2EquipmentTemplate> GetBestGearForSlot(XComGameState_Unit Unit)
{
	local array<X2EquipmentTemplate> arr;
	if (GetBestGearForSlotFn != none)
	{
		return GetBestGearForSlotFn(self, Unit);
	}
	arr.Length = 0;
	return arr;
}

// Called from XComGameState_Unit::ValidateLoadout, regardless of whether the unit has the slot or not.
// This can be used to add a missing item, or remove an item the unit shouldn't have
function ValidateLoadout(XComGameState_Unit Unit, XComGameState_HeadquartersXCom XComHQ, XComGameState NewGameState)
{
	if (ValidateLoadoutFn != none)
	{
		ValidateLoadoutFn(self, Unit, XComHQ, NewGameState);
	}
}

// If IsMultiSlot, this gets the number of items this slot can hold (similar to Utility Items)
// If -1, there is no limit on the number of items this slot can hold.
//   In this case, if this slot is displayed, UI should show one (1) empty slot and let the list grow or shrink when items are added / removed
function int GetMaxItemCount(XComGameState_Unit UnitState, optional XComGameState CheckGameState)
{
	return GetMaxItemCountFn(self, UnitState, CheckGameState);
}

// Is non-infinite IsMultiSlot, this function provides an optional empty "locked" slot entry to be shown. Since HasSlot/ShowSlot only works for the
// entire slot, it can't be used to make some slots locked. Additionally, the locked slot would be more than the current MaxItemCount
// UI is not required to implement this, currently this is only used as a formalization of the code in UISquadSelect_ListItem (show a locked utility slot under special circumstances)
function bool GetMultiSlotUnlockHint(XComGameState_Unit UnitState, out string strReason, optional XComGameState CheckGameState)
{
	if (GetMultiSlotUnlockHintFn != none)
	{
		return GetMultiSlotUnlockHintFn(self, UnitState, strReason, CheckGameState);
	}
	strReason = "";
	return false;
}

// Return the name of this slot
function string GetDisplayName()
{
	if (GetDisplayNameFn != none)
	{
		return GetDisplayNameFn(self);
	}
	return class'UIArmory_Loadout'.default.m_strInventoryLabels[int(InvSlot)];
}

// Single letter that abbreviates the slot name
function string GetDisplayLetter()
{
	if (GetDisplayLetterFn != none)
	{
		return GetDisplayLetterFn(self);
	}
	// Inevitably breaks with Unicode characters
	return Left(GetDisplayName(), 1);
}

// Return true if the slot should be shown for this unit
function bool UnitShowSlot(XComGameState_Unit UnitState, optional XComGameState CheckGameState)
{
	local string strDummy;
	if (UnitShowSlotFn != none)
	{
		return UnitShowSlotFn(self, UnitState, CheckGameState);
	}
	return UnitHasSlot(UnitState, strDummy, CheckGameState);
}

// Return true if the unit has this slot. This means that this slot is not locked
// If the slot should be shown (see above function) but it's locked, LockedReason should be filled out
function bool UnitHasSlot(XComGameState_Unit UnitState, out string LockedReason, optional XComGameState CheckGameState)
{
	return UnitHasSlotFn(self, UnitState, LockedReason, CheckGameState);
}

// Called from CHUIItemSlotEnumerator to determine a slot order
// Higher number -> appears later. See notes in IsSmallSlot
// For vanilla slots, Priority = int(Slot) * 10;
function int GetPriority(XComGameState_Unit UnitState, optional XComGameState CheckGameState)
{
	return GetPriorityFn(self, UnitState, CheckGameState);
}


// Static Helper Functions

// Returns true if and only if this slot is provided by the vanilla game
// and does not need any custom handling
final static function bool IsVanillaProvidedSlot(EInventorySlot Slot)
{
	return Slot > eInvSlot_Unknown && Slot < eInvSlot_END_VANILLA_SLOTS;
}

// Returns true if and only if this slot is within the templated slot range
final static function bool IsWithinTemplatedSlotRange(EInventorySlot Slot)
{
	return Slot > eInvSlot_BEGIN_TEMPLATED_SLOTS && Slot < eInvSlot_END_TEMPLATED_SLOTS;
}

// Returns true if and only if this slot is within the Templated Slot range and has an existing template
final static function bool SlotIsTemplated(EInventorySlot Slot)
{
	return GetTemplateForSlot(Slot) != none;
}

// Returns the template controlling this slot if it exists, none otherwise
final static function CHItemSlot GetTemplateForSlot(EInventorySlot Slot)
{
	if (Slot > eInvSlot_BEGIN_TEMPLATED_SLOTS && Slot < eInvSlot_END_TEMPLATED_SLOTS)
	{
		// May be none, but a static array handles that just fine
		return class'CHItemSlot'.default.SlotTemplates[int(Slot)];
	}
	return none;
}

final static function array<CHItemSlot> GetAllSlotTemplates()
{
	local array<CHItemSlot> Slots;
	local int i;
	for (i = 0; i < ArrayCount(class'CHItemSlot'.default.SlotTemplates); i++)
	{
		if (class'CHItemSlot'.default.SlotTemplates[i] != none)
		{
			Slots.AddItem(class'CHItemSlot'.default.SlotTemplates[i]);
		}
	}
	return Slots;
}

// Only call during Template creation!
final static function AddSlotTemplate(CHItemSlot Slot, optional bool bOverwrite = false)
{
	local CHItemSlot SlotsCDO;
	SlotsCDO = CHItemSlot(class'XComEngine'.static.GetClassDefaultObject(class'CHItemSlot'));
	if (IsWithinTemplatedSlotRange(Slot.InvSlot) && (SlotsCDO.SlotTemplates[Slot.InvSlot] == none || bOverwrite))
	{
		SlotsCDO.SlotTemplates[Slot.InvSlot] = Slot;
	}
}


// Abstraction functions so we don't have to put the switch() and SlotIsTemplated() everywhere in the code base

static function bool SlotIsSmall(EInventorySlot Slot)
{
	return Slot == eInvSlot_Utility || Slot == eInvSlot_GrenadePocket || Slot == eInvSlot_AmmoPocket || (SlotIsTemplated(Slot) && GetTemplateForSlot(Slot).IsSmallSlot);
}

static function bool SlotShouldBeShown(EInventorySlot Slot, XComGameState_Unit Unit, optional XComGameState CheckGameState)
{
	local string strDummy;
	if (SlotIsTemplated(Slot))
	{
		return GetTemplateForSlot(Slot).UnitShowSlot(Unit, CheckGameState);
	}
	else
	{
		switch (Slot)
		{
			case eInvSlot_Mission:
			case eInvSlot_Backpack:
			case eInvSlot_Loot:
			// CombatSims is hidden as a loadout slot. Special UI that specificially considers CombatSims (SoldierHeader, Armory_Implants, mod code)
			// Can choose to ignore this
			case eInvSlot_CombatSim:
			case eInvSlot_TertiaryWeapon:
			case eInvSlot_QuaternaryWeapon:
			case eInvSlot_QuinaryWeapon:
			case eInvSlot_SenaryWeapon:
			case eInvSlot_SeptenaryWeapon:
				// hidden slots
				return false;
			default:
				return SlotAvailable(Slot, strDummy, Unit, CheckGameState);
		}
	}
	return false;
}

static function bool SlotAvailable(EInventorySlot Slot, out string LockedReason, XComGameState_Unit Unit, optional XComGameState CheckGameState)
{
	LockedReason = "";
	switch (Slot)
	{
		case eInvSlot_Armor:
		case eInvSlot_PrimaryWeapon:
			return true;
		case eInvSlot_SecondaryWeapon:
			return Unit.NeedsSecondaryWeapon();
		case eInvSlot_HeavyWeapon:
			return Unit.HasHeavyWeapon(CheckGameState);
		case eInvSlot_Utility:
		case eInvSlot_CombatSim:
			// Units always have a utility slot, but sometimes eStat_UtilityItems == 0. We consider the slot to be available
			// Same for CombatSim
			return true;
		case eInvSlot_GrenadePocket:
			return Unit.HasGrenadePocket();
		case eInvSlot_AmmoPocket:
			return Unit.HasAmmoPocket();
		default:
			if (SlotIsTemplated(Slot)) {
				return GetTemplateForSlot(Slot).UnitHasSlot(Unit, LockedReason, CheckGameState);
			}
			// Mission, backpack, Loot, Tertiary-Septenary are always available
			return true;
	}
	
}

static function int SlotGetPriority(EInventorySlot Slot, XComGameState_Unit Unit, optional XComGameState CheckGameState)
{
	if (IsVanillaProvidedSlot(Slot))
	{
		return 10 * int(Slot);
	}
	else if (SlotIsTemplated(Slot))
	{
		return GetTemplateForSlot(Slot).GetPriority(Unit, CheckGameState);
	}
	return -1;
}

static function array<EInventorySlot> GetDisplayedSlots(XComGameState_Unit Unit, optional XComGameState CheckGameState)
{
	local int i;
	local array<EInventorySlot> Slots;
	for (i = eInvSlot_Unknown + 1; i < eInvSlot_END_VANILLA_SLOTS; i++)
	{
		if (SlotShouldBeShown(EInventorySlot(i), Unit, CheckGameState))
		{
			Slots.AddItem(EInventorySlot(i));
		}
	}

	for (i = eInvSlot_BEGIN_TEMPLATED_SLOTS + 1; i < eInvSlot_END_TEMPLATED_SLOTS; i++)
	{
		if (SlotShouldBeShown(EInventorySlot(i), Unit, CheckGameState))
		{
			Slots.AddItem(EInventorySlot(i));
		}
	}
	return Slots;
}

static function bool SlotIsMultiItem(EInventorySlot Slot)
{
	return Slot == eInvSlot_Backpack || Slot == eInvSlot_Utility || Slot == eInvSlot_CombatSim || (SlotIsTemplated(Slot) && GetTemplateForSlot(Slot).IsMultiItemSlot);
}

// Only valid for Multi-Item slots!
// Return -1 for infinite
static function int SlotGetMaxItemCount(EInventorySlot Slot, XComGameState_Unit Unit, optional XComGameState CheckGameState)
{
	if (SlotIsMultiItem(Slot) == false)
	{
		`REDSCREEN(GetFuncName() $ " called with Slot " $ GetEnum(Enum'EInventorySlot', Slot) $ " which is no Multi-item slot!\n" @ GetScriptTrace());
		return 0;
	}
	switch (Slot)
	{
		case eInvSlot_Utility:
			return Unit.IsMPCharacter() ? Unit.GetMPCharacterTemplate().NumUtilitySlots : int(Unit.GetCurrentStat(eStat_UtilityItems));
		case eInvSlot_CombatSim:
			return int(Unit.GetCurrentStat(eStat_CombatSims));
		case eInvSlot_Backpack:
			return -1;
		default:
			// Due to the check for SlotIsMultiItem, this slot must be templated
			return GetTemplateForSlot(Slot).GetMaxItemCount(Unit, CheckGameState);
	}
}

static function bool SlotGetMultiUnlockHint(EInventorySlot Slot, XComGameState_Unit Unit, out string strReason, optional XComGameState CheckGameState)
{
	if (Slot == eInvSlot_Utility)
	{
		if (Unit.GetCurrentStat(eStat_UtilityItems) == 0)
		{
			if (Unit.IsResistanceHero())
			{
				// Hero soldiers cannot gain an extra slot via armor, so we just say "can't edit"
				strReason = class'UIArmory_Loadout'.default.m_strCannotEdit; // "Cannot edit"
				return true;
			}
			else
			{
				// If we don't have any utility slots and aren't a resistance hero, we don't have utility slots. Period.
				// (Sparks)
				strReason = class'UISquadSelect_ListItem'.default.m_strNoUtilitySlots; // "No utility slots available"
				return true;
			}
		}
		else if (!Unit.HasExtraUtilitySlot())
		{
			// Normal soldiers that don't have an extra utility slot can gain an additional one via Predator Armor
			// TODO: They can also gain one via Tactical Rigging / equivalent, but we don't have localization for that
			strReason = class'UISquadSelect_ListItem'.default.m_strNeedsMediumArmor; // "Requires advanced armor"
			return true;
		}
	}
	else if (SlotIsTemplated(Slot))
	{
		return GetTemplateForSlot(Slot).GetMultiSlotUnlockHint(Unit, strReason, CheckGameState);
	}
}

// Use this to collect slots to MakeItemsAvailable. SlotMask is a Bit Mask from the consts above, SLOT_ALL is a shortcut for SLOT_ARMOR|SLOT_WEAPON|SLOT_ITEM
// Slots are not sorted in any way
static function CollectSlots(int SlotMask, out array<EInventorySlot> Slots)
{
	local array<CHItemSlot> AllSlots;
	local CHItemSlot Slot;

	if ((SlotMask & SLOT_ARMOR) != 0)
	{
		Slots.AddItem(eInvSlot_Armor);
		Slots.AddItem(eInvSlot_HeavyWeapon);
	}
	if ((SlotMask & SLOT_WEAPON) != 0)
	{
		Slots.AddItem(eInvSlot_PrimaryWeapon);
		Slots.AddItem(eInvSlot_SecondaryWeapon);
		Slots.AddItem(eInvSlot_HeavyWeapon);
	}
	if ((SlotMask & SLOT_ITEM) != 0)
	{
		Slots.AddItem(eInvSlot_Utility);
		Slots.AddItem(eInvSlot_GrenadePocket);
		Slots.AddItem(eInvSlot_AmmoPocket);
	}

	AllSlots = GetAllSlotTemplates();
	foreach AllSlots(Slot)
	{
		if ((Slot.SlotCatMask & SlotMask) != 0)
		{
			Slots.AddItem(Slot.InvSlot);
		}
	}
}