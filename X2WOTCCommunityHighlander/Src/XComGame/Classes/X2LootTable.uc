class X2LootTable extends Object
	native(Core)
	config(GameCore);

cpptext
{
	virtual void RollForLootTableGroup(const FLootTable& LootTable, INT Group, TArray<FName>& RolledLoot);
}

// Issue #8 - Add a loot table interface
struct Remainder {
	var int EntryIndex;
	var float ChanceRemainder;
};

// Issue #8 - making non-private to DLC/Mods can make run-time adjustments 
//             requires re-invoking InitLootTables again
var config array<LootTable> LootTables; 
var private native Map_Mirror       LootTablesMap{TMap<FName, INT>};        //  maps table name to index into LootTables array

// bValidateItemNames when false, expected to be used for character template names.
native function InitLootTables(bool bValidateItemNames=true);		//  validates loot tables and sets up LootTablesMap
native function RollForLootTable(const out name LootTableName, out array<name> RolledLoot);

/// HL-Docs: feature:LootTableAPI; issue:8; tags:tactical
/// Unprivates `LootTables` and adds convenience functions for common OPTC loot table operations.
///
/// ## Refresher on loot tables
///
/// Consider the simplified struct definitions taken from [`X2TacticalGameRulesetDataStructures`](https://github.com/X2CommunityCore/X2WOTCCommunityHighlander/blob/3c6eba4a22980af2eada617d0c12cf67c45e1ac9/X2WOTCCommunityHighlander/Src/XComGame/Classes/X2TacticalGameRulesetDataStructures.uc#L633-L658):
///
/// ```unrealscript
/// struct native LootTableEntry
/// {
/// 	var int     Chance;
/// 	var int     RollGroup;
/// 	var int     MinCount, MaxCount;
/// 
/// 	// Modifier on the chance, multiplicatively applied for each existing Item of type TemplateName acquired:
/// 	// TotalChance = Chance * ChanceModPerExistingItem ^ NumExistingItems
/// 	var float	ChanceModPerExistingItem;
/// 	
/// 	//  NOTE: these two are mutually exclusive, so only one should ever be filled in for a given entry
/// 	var name    TemplateName;
/// 	var name    TableRef;
/// };
/// 
/// struct native LootTable
/// {
/// 	var name    TableName;
/// 	var array<LootTableEntry> Loots;
/// };
/// ```
///
/// When a unit template says "hey, I drop this kind of loot", it references a given `LootTable` by name.
/// For the common random loot, a random unit is designated as a loot carrier at the start of the mission and its loot is rolled.
/// The game then looks at the `Loots` entries and for every distinct `RollGroup` the game rolls a number in
/// the half-open interval `[0; 100[` (largest possible number is 99) to choose the item from that `RollGroup`.
///
/// The game does this by iterating through the `LootTableEntry` entries with the current `RollGroup` and subtracting
/// its `Chance` (after applying `ChanceModPerExistingItem`) from the current chance. If this causes the current chance
/// to go below `0`, this entry has been chosen and the game moves on to the next `RollGroup`.
///
/// This has a number of non-intuitive consequences:
///
/// 1. Within the same `RollGroup`s, the chances are not independent; the game may choose 0 or 1 entries from that group.
/// 2. If the sum of chances in a `RollGroup` is `x < 100`, there is a `100 - x` percent chance that
///   no entry is chosen and this `RollGroup` doesn't roll anything.
/// 3. If the sum of chances is `x = 100`, then every entry will have a percent chance to be chosen identical to the
///   `Chance` of the entry.
/// 4. If the sum of chances is `x > 100`, then the latter entries will actually have a lower chance. Consider entries
///   in the same roll group with chances `90`, `20`, `10`: The first entry will be chosen 9/10 times, the second 1/10 times,
///   and the third never!
///
/// We will discuss later what this means for mods.
///
/// When an entry has been chosen, the game generates between `MinCount` and `MaxCount` of the item listed in `TemplateName`,
/// if it is non-empty -- otherwise, the game invokes the aforedescribed algorithm recursively with the table referenced by name in `TableRef`.
///
/// ## New APIs
///
/// First and foremost, you need a loot table manager to work with. If you are in a place before templates are validated
/// (template creation, `OnPostTemplatesCreated`), the loot table manager doesn't exist yet and you need to operate on the
/// `ClassDefaultObject`; otherwise just request the loot table manager with the singleton accessor:
///
/// ```unrealscript
/// // OPTC or template creation
/// LootManager = X2LootTableManager(class'XComEngine'.static.FindClassDefaultObject("XComGame.X2LootTableManager"));
/// // Otherwise
/// LootManager = class'X2LootTableManager'.static.GetLootTableManager();
/// ```
///
/// The `OPTC` context is going to be the most common one, so the below documentation assumes that it's going to be used.
///
/// ### LootTables
///
/// This feature unprivates the otherwise `config`-only `LootTables` array. You can pretty much change anything there.
/// If your code runs after `OnPostTemplatesCreated` returns, ensure to call `InitLootTables` if you add/remove/move
/// around tables as a whole (the game maintains a name->index lookup for efficiency).
///
/// ### RecalculateLootTableChanceStatic
///
/// * `public static function RecalculateLootTableChanceStatic(name TableName, bool bEquallyDistributed = false);`
///
/// *A non-static variant for the runtime context also exists: `RecalculateLootTableChance`*
///
/// Changes the chances for every entry in the table referred to by `TableName` so that the chances of every `RollGroup`
/// add up to `100`. If `bEquallyDistributed` is `true`, all chances within a roll group will be equal, otherwise the
/// proportions between the chances are maintained.
///
/// This is a useful function for when you just want to add some items to existing roll groups of existing tables.
/// Your items will naturally be placed at the end of the array, so according to consequence 4, your items might never
/// be rolled. Calling this function makes sure your items will have a proportional chance to be rolled.
///
/// **Warning:** Some of the latter functions recalculate chances for a given roll group implicitly unless opted out of.
///
/// **Warning:** Some `RollGroups` have chance sums much lower than `100` so that only sometimes an item from that group
/// drops. Carelessly calling `RecalculateLootTableChance` or forgetting to opt out of recalculating may cause showers of rare loot!
///
///
/// ### AddEntryStatic/RemoveEntryStatic
///
/// * `public static function AddEntryStatic(name TableName, LootTableEntry TableEntry, optional bool bRecalculateChances = true);`
/// * `public static function RemoveEntryStatic(name TableName, LootTableEntry TableEntry, optional bool bRecalculateChances = true);`
///
/// *Non-static variants for the runtime context also exist: `AddEntry`, `Remove`*
///
/// Adds the entry to the given loot table, or removes it. Unless `bRecalculateChances` is set to `false`, also recalculates the
/// chances for the entry's `RollGroup` so that they sum up to 100.
///
/// ### AddLootTableStatic/RemoveLootTableStatic
///
/// Actually, I have no idea why they exist and they probably don't do what you want them to. Don't use them. If you do,
/// also call `InitLootTables` on the `ClassDefaultObject`.
///
/// ## Example:
///
/// ```unrealscript
/// // Adds M2 and M3 to ADVENT mid- and end-game loot, respectively
/// static event OnPostTemplatesCreated()
/// {
/// 	local LootTableEntry M2Entry, M3Entry;
/// 
/// 	M2Entry.Chance = 20;
/// 	M2Entry.MinCount = 1;
/// 	M2Entry.MaxCount = 1;
/// 	M2Entry.TemplateName = 'AdventGremlinM2';
/// 	// RollGroup 1 is 100% a random Weapon Upgrade. This turns it into 20% Gremlin, 80% upgrade.
/// 	M2Entry.RollGroup = 1;
///
/// 	M3Entry = M2Entry;
/// 	M3Entry.TemplateName = 'AdventGremlinM3';
///
/// 	class'X2LootTableManager'.static.AddEntryStatic('ADVENTMidTimedLoot', M2Entry, true);
/// 	class'X2LootTableManager'.static.AddEntryStatic('ADVENTLateTimedLoot', M3Entry, true);
/// }
/// ```
///
/// ## More example:
///
/// [Musashis RPG Overhaul](https://steamcommunity.com/workshop/filedetails/?id=1280477867) uses this feature. Feel free to peruse [its source code!](https://github.com/Musashi1584/RPGO/blob/6d75558880e3dfd60c8fab259bd5283ca9def307/XCOM2RPGOverhaul/Src/XCOM2RPGOverhaul/Classes/X2TemplateHelper_ExtendedUpgrades.uc#L418-L447)

/// Start Issue #8
public function AddLootTable(LootTable LootTableToAdd)
{
	AddLootTableInternal(self, LootTableToAdd);
}

public function RemoveLootTable(LootTable LootTableToRemove)
{
	LootTables.RemoveItem(LootTableToRemove);
}

public function AddEntry(name TableName, LootTableEntry TableEntry, optional bool bRecalculateChances = true)
{
	AddEntryInternal(self, TableName, TableEntry, bRecalculateChances);
}

public function RemoveEntry(name TableName, LootTableEntry TableEntry, optional bool bRecalculateChances = true)
{
	RemoveEntryInternal(self, TableName, TableEntry, bRecalculateChances);
}
// Recalculate chances for an entire loot table
public function RecalculateLootTableChance(name TableName, bool bEquallyDistributed = false)
{
	RecalculateLootTableChanceInternal(self, TableName, bEquallyDistributed);
}

// **************************************************
// Static function
// Should be used before Loot Tables are initialized
// e.g. OnPostTemplatesCreated
// **************************************************
public static function AddLootTableStatic(LootTable AddLootTable)
{
	AddLootTableInternal(GetX2LootTableCDO(), AddLootTable);
}

public static function RemoveLootTableStatic(LootTable RemoveLootTable)
{
	local X2LootTable LootTable;

	LootTable = GetX2LootTableCDO();
	LootTable.LootTables.RemoveItem(RemoveLootTable);
}

public static function AddEntryStatic(name TableName, LootTableEntry AddTableEntry, optional bool bRecalculateChances = true)
{
	AddEntryInternal(GetX2LootTableCDO(), TableName, AddTableEntry, bRecalculateChances);
}

public static function RemoveEntryStatic(name TableName, LootTableEntry TableEntry, optional bool bRecalculateChances = true)
{
	RemoveEntryInternal(GetX2LootTableCDO(), TableName, TableEntry, bRecalculateChances);
}

// Recalculate chances for an entire loot table
public static function RecalculateLootTableChanceStatic(name TableName, bool bEquallyDistributed = false)
{
	RecalculateLootTableChanceInternal(GetX2LootTableCDO(), TableName, bEquallyDistributed);
}

// **************************************************
// Private function
// **************************************************
private static function X2LootTable GetX2LootTableCDO()
{
	return X2LootTable(class'Engine'.static.FindClassDefaultObject(string(default.Class.Name)));
}

private static function AddLootTableInternal(X2LootTable LootTable, LootTable AddLootTable)
{
	local LootTableEntry LootEntry;

	if (LootTable.LootTables.Find('TableName', AddLootTable.TableName) == INDEX_NONE)
	{
		`LOG("Adding LootTable" @ AddLootTable.TableName @ "with" @ AddLootTable.Loots.Length @ "entries",, default.Class.Name);

		LootTable.LootTables.AddItem(AddLootTable);

		foreach AddLootTable.Loots(LootEntry)
		{
			AddEntryInternal(LootTable, AddLootTable.TableName, LootEntry, false);
		}

		RecalculateLootTableChanceInternal(LootTable, AddLootTable.TableName, false);
	}
}

private static function RemoveEntryInternal(
	X2LootTable LootTable,
	name TableName,
	LootTableEntry TableEntry,
	bool bRecalculateChances)
{
	local int Index, EntryIndex;

	Index = LootTable.LootTables.Find('TableName', TableName);

	if (Index  != INDEX_NONE)
	{
		for (EntryIndex = LootTable.LootTables[Index].Loots.Length -1; EntryIndex >= 0; EntryIndex--)
		{
			if (LootTable.LootTables[Index].Loots[EntryIndex].RollGroup == TableEntry.RollGroup &&
				LootTable.LootTables[Index].Loots[EntryIndex].TemplateName == TableEntry.TemplateName &&
				LootTable.LootTables[Index].Loots[EntryIndex].TableRef == TableEntry.TableRef
			)
			{
				// Remove the table entry
				LootTable.LootTables[Index].Loots.Remove(EntryIndex, 1);

				`LOG("Removing LootEntry" @ TableEntry.TemplateName @ TableEntry.TableRef @ "from LootTable" @ LootTable.LootTables[Index].TableName,, default.Class.Name);

				// Recalculate the chances for the roll group
				if (bRecalculateChances)
					RecalculateChancesForRollGroup(LootTable, Index, TableEntry.RollGroup, false);
			}
		}
	}
}

private static function AddEntryInternal(
	X2LootTable LootTable,
	name TableName,
	LootTableEntry TableEntry,
	bool bRecalculateChances)
{
	local int Index;

	Index = LootTable.LootTables.Find('TableName', TableName);

	if (Index  != INDEX_NONE && TableEntry.Chance <= 100 && TableEntry.Chance > 0)
	{
		// Add the new table entry
		LootTable.LootTables[Index].Loots.AddItem(TableEntry);

		`LOG("Adding LootEntry" @ TableEntry.TemplateName @ TableEntry.TableRef @ "from LootTable" @ LootTable.LootTables[Index].TableName,, default.Class.Name);

		// Recalculate the chances for the roll group
		if (bRecalculateChances)
			RecalculateChancesForRollGroup(LootTable, Index, TableEntry.RollGroup, false);
	}
}

private static function RecalculateLootTableChanceInternal(X2LootTable LootTable, name TableName, bool bEquallyDistributed = false)
{
	local LootTableEntry TableEntry;
	local array<int> RollGroups;
	local int Index, RollGroup;

	Index = LootTable.LootTables.Find('TableName', TableName);
	if (Index != INDEX_NONE)
	{
		foreach LootTable.LootTables[Index].Loots(TableEntry)
		{
			if (RollGroups.Find(TableEntry.RollGroup) == INDEX_NONE)
			{
				RollGroups.AddItem(TableEntry.RollGroup);
			}
		}

		foreach RollGroups(RollGroup)
		{
			RecalculateChancesForRollGroup(LootTable, Index, RollGroup, bEquallyDistributed);
		}
	}
}



function int SortRemainder(Remainder A, Remainder B)
{
	return A.ChanceRemainder < B.ChanceRemainder ? -1 : 0;
}

// When the sum of chances is unequal 100% after adding/removing an entry, recalculate chances to 100% total
private static function RecalculateChancesForRollGroup(X2LootTable LootTable, int Index, int RollGroup, bool bEquallyDistributed)
{
	local LootTableEntry TableEntry;
	local int OldChance, NewChance, SumChances, NewSumChances, TableEntryIndex, RoundDiff;
	local array<Remainder> Remainders;
	local Remainder EntryRemainder;

	`LOG("Recalculating loot chances for Loot Table" @ LootTable.LootTables[Index].TableName @ "RollGroup" @ RollGroup @ " Equally Distributed" @ bEquallyDistributed,, default.Class.Name);
	`LOG("	Chances before recalculation:",, default.Class.Name);
	foreach LootTable.LootTables[Index].Loots(TableEntry)
	{
		if (TableEntry.RollGroup == RollGroup)
		{
			SumChances += TableEntry.Chance;
			`LOG("		" @ TableEntry.TemplateName @ TableEntry.TableRef @ TableEntry.Chance,, default.Class.Name);
		}
	}

	`LOG("	Sum Chances " @ SumChances,, default.Class.Name);

	if (SumChances != 100)
	{
		for (TableEntryIndex = 0; TableEntryIndex < LootTable.LootTables[Index].Loots.Length; TableEntryIndex++)
		{
			if (LootTable.LootTables[Index].Loots[TableEntryIndex].RollGroup == RollGroup)
			{
				OldChance = LootTable.LootTables[Index].Loots[TableEntryIndex].Chance;

				if (bEquallyDistributed)
				{
					NewChance = 100 / LootTable.LootTables[Index].Loots.Length;
				}
				else
				{
					NewChance = 100 * OldChance / SumChances;
				}
				NewSumChances += NewChance;

				EntryRemainder.ChanceRemainder = (100 * OldChance / SumChances) - NewChance;
				EntryRemainder.EntryIndex = TableEntryIndex;
				Remainders.AddItem(EntryRemainder);

				LootTable.LootTables[Index].Loots[TableEntryIndex].Chance = NewChance;
			}
		}


		// even out round based differences using the largest remainder method
		Remainders.Sort(SortRemainder);
		RoundDiff = (100 - NewSumChances);
		while (RoundDiff != 0)
		{
			foreach Remainders(EntryRemainder)
			{
				if (RoundDiff > 0)
				{
					LootTable.LootTables[Index].Loots[EntryRemainder.EntryIndex].Chance += 1;
					RoundDiff--;
				}
				else if (RoundDiff < 0)
				{
					LootTable.LootTables[Index].Loots[EntryRemainder.EntryIndex].Chance -= 1;
					RoundDiff++;
				}
				else if (RoundDiff == 0)
				{
					break;
				}
			}
		}
	}

	`LOG("	Chances after recalculation:",, default.Class.Name);
	SumChances = 0;
	foreach LootTable.LootTables[Index].Loots(TableEntry)
	{
		if (TableEntry.RollGroup == RollGroup)
		{
			SumChances += TableEntry.Chance;
			`LOG("		" @ TableEntry.TemplateName @ TableEntry.TableRef @ TableEntry.Chance,, default.Class.Name);
		}
	}

	`LOG("	Sum Chances " @ SumChances,, default.Class.Name);
}
// End Issue #8