class X2LootTable extends Object
	native(Core)
	config(GameCore);

cpptext
{
	virtual void RollForLootTableGroup(const FLootTable& LootTable, INT Group, TArray<FName>& RolledLoot);
}

var private config array<LootTable> LootTables;
var private native Map_Mirror       LootTablesMap{TMap<FName, INT>};        //  maps table name to index into LootTables array

// bValidateItemNames when false, expected to be used for character template names.
native function InitLootTables(bool bValidateItemNames=true);		//  validates loot tables and sets up LootTablesMap
native function RollForLootTable(const out name LootTableName, out array<name> RolledLoot);

