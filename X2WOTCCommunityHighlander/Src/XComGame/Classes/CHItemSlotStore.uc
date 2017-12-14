// Issue #118: A template manager to help with Slot Templates
class CHItemSlotStore extends X2DataTemplateManager;


var protected CHItemSlot SlotTemplates[EInventorySlot.EnumCount];

static function CHItemSlotStore GetStore()
{
	return CHItemSlotStore(class'Engine'.static.GetTemplateManager(class'CHItemSlotStore'));
}

/** Called after all template managers have initialized, to verify references to other templates are valid. **/
protected event ValidateTemplatesEvent()
{
	CacheTemplates();
}

public function CHItemSlot GetSlot(EInventorySlot Slot)
{
	return SlotTemplates[Slot];
}

public function array<CHItemSlot> GetAllSlotTemplates()
{
	local int i;
	local array<CHItemSlot> Slots;
	for (i = 0; i < ArrayCount(SlotTemplates); i++)
	{
		if (SlotTemplates[i] != none)
		{
			Slots.AddItem(SlotTemplates[i]);
		}
	}
	return Slots;
}

public function CacheTemplates()
{
	local int i;
	local X2DataTemplate Tmp;
	local CHItemSlot Slot;
	for (i = 0; i < ArrayCount(SlotTemplates); i++)
	{
		SlotTemplates[i] = none;
	}
	foreach IterateTemplates(Tmp, none)
	{
		Slot = CHItemSlot(Tmp);
		if (class'CHItemSlot'.static.IsWithinTemplatedSlotRange(Slot.InvSlot))
		{
			if (SlotTemplates[Slot.InvSlot] == none)
			{
				if ((Slot.SlotCatMask != 0) != Slot.IsUserEquipSlot)
				{
					`REDSCREEN("Warning, Slot" @ GetEnum(Enum'EInventorySlot', Slot.InvSlot) $":" @ Slot.DataName @ "has inconsistent slot category attributes");
				}
				if (Slot.IsMultiItemSlot && (Slot.NeedsPresEquip || Slot.ShowOnCinematicPawns))
				{
					`REDSCREEN("Warning, Slot" @ GetEnum(Enum'EInventorySlot', Slot.InvSlot) $":" @ Slot.DataName @ "is a multi item slot, so it can't have ShowOnCinematicPawns or NeedsPresEquip set");
					
				}
				SlotTemplates[Slot.InvSlot] = Slot;
			}
			else
			{
				`REDSCREEN("Slot" @ GetEnum(Enum'EInventorySlot', Slot.InvSlot) $":" @ Slot.DataName @ "conflicts with" @ SlotTemplates[Slot.InvSlot].DataName);
			}
		}
		else
		{
			`REDSCREEN(Slot.DataName @ GetEnum(Enum'EInventorySlot', Slot.InvSlot) @ "not within Templated Slot Range");
		}
		
	}
}


defaultproperties
{
	TemplateDefinitionClass=class'CHItemSlotSet'
	ManagedTemplateClass=class'CHItemSlot'
}
