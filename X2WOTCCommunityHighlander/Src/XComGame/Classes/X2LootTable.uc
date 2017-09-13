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

// Start Issue #8 - Add a loot table interface
/**
  * For pre start state manipulation of loot tables use the static methods in OnPostTemplatesCreated like this
  * class'X2LootTableManager'.static.AddEntryStatic(LootTableName, LootTableEntry);
  * 
  * At runtime you can use the singleton instance like
  * 
  * LootManager = class'X2LootTableManager'.static.GetLootTableManager();
  * LootManager.AddEntry(LootTableName, LootTableEntry);
  * LootManager.InitLootTables();
  * 
  * this will also reinitialise the loot tables.
  * 
  * For bulk add to loot tables you can move the chance recalculation to the end:
  * 
  * LootManager.AddEntry(TableName, EntryToAdd, false);
  * LootManager.AddEntry(TableName, EntryToAdd, false);
  * LootManager.AddEntry(TableName, EntryToAdd, false);
  * LootManager.RecalculateLootTableChance(TableName);
  * 
  * This way your chance ratio is preserved.
  **/
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
					NewChance = 100 / SumChances * OldChance;
				}
				NewSumChances += NewChance;

				EntryRemainder.ChanceRemainder = (100 / SumChances * OldChance) - NewChance;
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