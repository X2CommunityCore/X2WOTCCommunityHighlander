//---------------------------------------------------------------------------------------
//  FILE:    XComGameState_Item.uc
//  AUTHOR:  Ryan McFall  --  10/10/2013
//  PURPOSE: This object represents the instance data for an item in the tactical game for
//           X-Com
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComGameState_Item extends XComGameState_BaseObject 
	dependson(XGInventoryNativeBase)	
	implements(UIQueryInterfaceItem, X2VisualizedInterface)
	native(Core);

//Instance-only variables
var() int Quantity;
var int LastQuantityChange;
var() int MergedItemCount;
var() bool bMergedOut;
var() StateObjectReference LoadedAmmo;
var() StateObjectReference CosmeticUnitRef; //Specifies a 'unit' associated with this item. Used with the gremlin, which is technically an item but moves and acts like a unit
var() StateObjectReference AttachedUnitRef; //Certain items such as the gremlin can be temporarily attached to another unit. This field tracks that attachment
var() StateObjectReference TechRef; // Certain items act as requirements for specific tech states (Facility Leads)
var() StateObjectReference LinkedEntity; // Certain items are linked to other gamestates and need to store this information (needed for chosen)

//Templated variables
var() ELocation ItemLocation; //Items not located on a unit will have ELocation_None - visual attachment point
var() int Ammo;
var() EInventorySlot InventorySlot;     //  Gameplay location - item is pretty much in the templated slot or in a backpack

var() protected name            m_TemplateName;
var() protected X2ItemTemplate  m_ItemTemplate;

//  Weapon upgrade system
var() protected array<name>                     m_arrWeaponUpgradeNames;
var() protected array<X2WeaponUpgradeTemplate>  m_arrWeaponUpgradeTemplates;

var() StateObjectReference          OwnerStateObject;
var() array<StateObjectReference>   ContainedItems;         //  XComGameState_Items which are inside of this one.   
var() StateObjectReference          SoldierKitOwner;        //  if this item is a soldier kit, this is the soldier that died

var() array<StatBoost>				StatBoosts;  // Used for Personal Combat Sims to hold rolled on stat boost data

var() TWeaponAppearance WeaponAppearance; // Used for storing customization state for Primary Weapons
var() string Nickname; //Storage for the the name of the item

function SetInitialState(XGItem Visualizer)
{
	local XGInventoryItem Item;

	Item = XGInventoryItem(Visualizer);
	ItemLocation = Item.m_eSlot;	
}

function Actor FindOrCreateVisualizer( optional XComGameState Gamestate = none )
{
	local Actor ItemVisualizer;

	ItemVisualizer = `XCOMHISTORY.GetVisualizer( ObjectID );
	if (ItemVisualizer == none)
	{
		class'XGItem'.static.CreateVisualizer( self );
	}

	return ItemVisualizer;
}

function SyncVisualizer(optional XComGameState GameState = none)
{
	local X2WeaponTemplate WeaponTemplate;
	local XGWeapon WeaponVis;
	local XComWeapon WeaponMeshVis;

	if (Ammo == 0)
	{
		WeaponTemplate = X2WeaponTemplate(GetMyTemplate());
		if (WeaponTemplate != None && WeaponTemplate.bHideWithNoAmmo)
		{
			WeaponVis = XGWeapon(GetVisualizer());
			if (WeaponVis != None)
			{
				WeaponMeshVis = WeaponVis.GetEntity();
				if (WeaponMeshVis != None)
				{
					WeaponMeshVis.Mesh.SetHidden(true);
				}
			}
		}
	}
}

function AppendAdditionalSyncActions( out VisualizationActionMetadata ActionMetadata, const XComGameStateContext Context)
{
}

static function X2ItemTemplateManager GetMyTemplateManager()
{
	return class'X2ItemTemplateManager'.static.GetItemTemplateManager();
}

simulated function name GetMyTemplateName()
{
	return m_TemplateName;
}

simulated native function X2ItemTemplate GetMyTemplate();

simulated native function TTile GetTileLocation();

/// <summary>
/// Called immediately prior to loading, this method is called on each state object so that its resources can be ready when the map completes loading. Request resources
/// should output an array of strings containing archetype paths to load
/// </summary>
event RequestResources(out array<string> ArchetypesToLoad)
{
	local X2EquipmentTemplate EquipmentTemplate;	
	local int i;

	super.RequestResources(ArchetypesToLoad);

	//Load our related resources
	EquipmentTemplate = X2EquipmentTemplate(GetMyTemplate());
	if(EquipmentTemplate != none)
	{
		if(EquipmentTemplate.GameArchetype != "")
		{
			ArchetypesToLoad.AddItem(EquipmentTemplate.GameArchetype);
		}

		if(EquipmentTemplate.AltGameArchetype != "")
		{
			ArchetypesToLoad.AddItem(EquipmentTemplate.AltGameArchetype);
		}

		if(EquipmentTemplate.CosmeticUnitTemplate != "")
		{
			ArchetypesToLoad.AddItem(EquipmentTemplate.CosmeticUnitTemplate);
		}
		
		for (i = 0; i < EquipmentTemplate.AltGameArchetypeArray.Length; ++i)
		{
			if (EquipmentTemplate.AltGameArchetypeArray[i].ArchetypeString != "")
			{
				ArchetypesToLoad.AddItem(EquipmentTemplate.AltGameArchetypeArray[i].ArchetypeString);
			}
		}
	}
}

event OnCreation(optional X2DataTemplate Template)
{	
	local X2ItemTemplateManager ItemManager;
	local X2EquipmentTemplate EquipmentTemplate;
	local X2WeaponTemplate WeaponTemplate;
	local StatBoost ItemStatBoost;
	local int idx;
	local bool bInSkirmish;

	super.OnCreation(Template);

	m_ItemTemplate = X2ItemTemplate(Template);
	m_TemplateName = Template.DataName;

	Ammo = GetClipSize();

	EquipmentTemplate = X2EquipmentTemplate(m_ItemTemplate);

	if(EquipmentTemplate != none)
	{
		ItemManager = GetMyTemplateManager();
		//Issue #295 - Add a 'none' check before using `SCREENSTACK
		if (`SCREENSTACK != none)
		{
			bInSkirmish = `SCREENSTACK.GetFirstInstanceOf(class'UITLE_SkirmishModeMenu') != none;
		}

		for(idx = 0; idx < EquipmentTemplate.StatsToBoost.Length; idx++)
		{
			if(ItemManager.GetItemStatBoost(EquipmentTemplate.StatBoostPowerLevel, EquipmentTemplate.StatsToBoost[idx], ItemStatBoost, bInSkirmish))
			{
				StatBoosts.AddItem(ItemStatBoost);
			}
		}
		WeaponTemplate = X2WeaponTemplate(m_ItemTemplate);

		if( WeaponTemplate != None )
		{
			//  primary weapon goes in the right hand, everything else is stowed
			if( WeaponTemplate.InventorySlot == eInvSlot_PrimaryWeapon )
			{
				ItemLocation = eSlot_RightHand;
			}
			else
			{
				ItemLocation = WeaponTemplate.StowedLocation;
			}
		}
	}
}

function OnBeginTacticalPlay(XComGameState NewGameState)
{
	RegisterForCosmeticUnitEvents(NewGameState);
}

protected function RegisterForCosmeticUnitEvents(XComGameState NewGameState)
{
	local X2EventManager EventManager;
	local Object ThisObj;

	super.OnBeginTacticalPlay(NewGameState);
	
	if( CosmeticUnitRef.ObjectID > 0 )
	{	
		//Only items with cosmetic units need to listen for these. If you expand this conditional, make sure you need to as
		//having too many items respond to these events would be costly.
		EventManager = `XEVENTMGR;
		ThisObj = self;	

		EventManager.RegisterForEvent( ThisObj, 'AbilityActivated', OnAbilityActivated, ELD_OnStateSubmitted,,); //Move if we're ordered to
		EventManager.RegisterForEvent( ThisObj, 'UnitDied', OnUnitDied, ELD_OnStateSubmitted,,); //Return to owner if target unit dies or play death anim if owner dies
		EventManager.RegisterForEvent( ThisObj, 'UnitEvacuated', OnUnitEvacuated, ELD_OnStateSubmitted,,); //For gremlin, to evacuate with its owner
		EventManager.RegisterForEvent( ThisObj, 'ItemRecalled', OnItemRecalled, ELD_OnStateSubmitted,,); //Return to owner when specifically requested 
		EventManager.RegisterForEvent( ThisObj, 'ForceItemRecalled', OnForceItemRecalled, ELD_OnStateSubmitted,,); //Return to owner when specifically told
		EventManager.RegisterForEvent(ThisObj, 'UnitIcarusJumped', OnUnitIcarusJumped, ELD_OnStateSubmitted, , ); //Return to owner when specifically told
	}
}


function OnEndTacticalPlay(XComGameState NewGameState)
{
	local StateObjectReference EmptyReference;	
	local X2EventManager EventManager;
	local Object ThisObj;

	super.OnEndTacticalPlay(NewGameState);

	EventManager = `XEVENTMGR;
	ThisObj = self;
	if( CosmeticUnitRef.ObjectID > 0 )
	{
		EventManager.UnRegisterFromEvent( ThisObj, 'UnitMoveFinished' );
		EventManager.UnRegisterFromEvent( ThisObj, 'AbilityActivated' );
		EventManager.UnRegisterFromEvent( ThisObj, 'UnitDied' );
		EventManager.UnRegisterFromEvent( ThisObj, 'ItemRecalled' );
		EventManager.UnRegisterFromEvent( ThisObj, 'ForceItemRecalled' );
	}

	Ammo = GetClipSize();
	MergedItemCount = 0;
	bMergedOut = false;
	CosmeticUnitRef = EmptyReference;
	LoadedAmmo = EmptyReference;
}

function CreateCosmeticItemUnit(XComGameState NewGameState)
{
	local X2EquipmentTemplate EquipmentTemplate;
	local XComGameState_Unit OwningUnitState;
	local XComGameState_Unit CosmeticUnit;
	local TTile CosmeticUnitTile;
	local vector SpawnLocation;

	EquipmentTemplate = X2EquipmentTemplate(GetMyTemplate());
	if(EquipmentTemplate != none 
		&& EquipmentTemplate.CosmeticUnitTemplate != "" 
		&& CosmeticUnitRef.ObjectID <= 0) // only if we didn't already create one
	{
		OwningUnitState = XComGameState_Unit(NewGameState.GetGameStateForObjectID(OwnerStateObject.ObjectID));
		if(OwningUnitState == none)
		{
			OwningUnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(OwnerStateObject.ObjectID));
			if(OwningUnitState == none)
			{
				return;
			}
		}

		// if the owning unit has been removed from play, we don't need to exist
		if(OwningUnitState.bRemovedFromPlay)
		{
			return;
		}

		// we default to being attached to our owner
		AttachedUnitRef = OwningUnitState.GetReference();

		CosmeticUnitTile = OwningUnitState.GetDesiredTileForAttachedCosmeticUnit();

		SpawnLocation = `XWORLD.GetPositionFromTileCoordinates(CosmeticUnitTile);
		CosmeticUnitRef = `SPAWNMGR.CreateUnit(
			SpawnLocation, 
			name(EquipmentTemplate.CosmeticUnitTemplate), 
			OwningUnitState.GetTeam(), 
			false,
			, 
			NewGameState );

		//Force the appearance to use the soldier's settings
		CosmeticUnit = XComGameState_Unit(NewGameState.GetGameStateForObjectID(CosmeticUnitRef.ObjectID));
		CosmeticUnit.kAppearance.nmPatterns = OwningUnitState.kAppearance.nmWeaponPattern;
		CosmeticUnit.kAppearance.iArmorTint = OwningUnitState.kAppearance.iWeaponTint;
		CosmeticUnit.kAppearance.iArmorTintSecondary = OwningUnitState.kAppearance.iArmorTintSecondary;
		XGUnit(CosmeticUnit.GetVisualizer()).GetPawn().SetAppearance(CosmeticUnit.kAppearance);

		if (OwningUnitState.GetMyTemplate().OnCosmeticUnitCreatedFn != None)
		{
			OwningUnitState.GetMyTemplate().OnCosmeticUnitCreatedFn(CosmeticUnit, OwningUnitState, self, NewGameState);
		}

		// now that we have a unit, register for events
		RegisterForCosmeticUnitEvents(NewGameState);
	}
}

function EventListenerReturn OnAbilityActivated(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameStateContext_Ability AbilityContext;
	local X2GameRulesetVisibilityInterface TargetInterface;
	local XComGameStateHistory History;	
	local XComGameState NewGameState;
	local XComGameState_Item NewItemState;
	local X2AbilityTemplate AbilityTemplate;
	local XComGameState_Unit AttachedUnitState, NewCosmeticState;

	if( CosmeticUnitRef.ObjectID > 0 && GameState.GetContext().InterruptionStatus != eInterruptionStatus_Interrupt)
	{		
		History = `XCOMHISTORY;

		AbilityContext = XComGameStateContext_Ability(GameState.GetContext());
		if (AbilityContext != none && AbilityContext.InputContext.ItemObject.ObjectID == ObjectID) //If we were used in this ability, then process
		{
			AbilityTemplate = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate(AbilityContext.InputContext.AbilityTemplateName);
			if (AbilityTemplate.bStationaryWeapon)
				return ELR_NoInterrupt;

			if( AbilityContext.InputContext.PrimaryTarget.ObjectID > 0 )
			{
				TargetInterface = X2GameRulesetVisibilityInterface(History.GetGameStateForObjectID(AbilityContext.InputContext.PrimaryTarget.ObjectID));
				if( TargetInterface != none )
				{
					NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Equipment reassigned");
					
					//Update the attached unit for this item
					NewItemState = XComGameState_Item(NewGameState.ModifyStateObject(self.Class, ObjectID));
					NewItemState.AttachedUnitRef = AbilityContext.InputContext.PrimaryTarget;

					AttachedUnitState = XComGameState_Unit(History.GetGameStateForObjectID(NewItemState.AttachedUnitRef.ObjectID));
					if (AttachedUnitState != none)
					{
						NewCosmeticState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', CosmeticUnitRef.ObjectID));
						NewCosmeticState.SetVisibilityLocation( AttachedUnitState.TileLocation );
					}
					
					`GAMERULES.SubmitGameState(NewGameState);
				}
				else
				{
					`redscreen("Gremlin was unable to move to target for ability"@AbilityContext.InputContext.AbilityTemplateName@" with target object:"@AbilityContext.InputContext.PrimaryTarget.ObjectID);
				}
			}
			else if( AbilityContext.InputContext.TargetLocations.Length > 0 )
			{
				// don't do anything, but this case shouldn't cause a redscreen either
			}
			else
			{
				`redscreen("Gremlin was unable to find a target to move to for ability"@AbilityContext.InputContext.AbilityTemplateName);
			}
		}
	}

	return ELR_NoInterrupt;
}

function EventListenerReturn OnItemRecalled(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameState_Ability AbilityState;
	local XComGameState_Item RecalledItem;
	
	if (CosmeticUnitRef.ObjectID > 0)
	{		
		AbilityState = XComGameState_Ability(EventData);
		RecalledItem = AbilityState.GetSourceWeapon();
		if (RecalledItem.ObjectID == ObjectID)
		{
			RecallItem(RecalledItem, GameState);
		}
	}
	return ELR_NoInterrupt;
}

function EventListenerReturn OnForceItemRecalled(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameStateContext_Ability AbilityContext;
	local XComGameState_Item RecalledItem;
	local XComGameStateHistory History;

	if (CosmeticUnitRef.ObjectID > 0)
	{
		// Check if this unit is targeted by the ability
		AbilityContext = XComGameStateContext_Ability(GameState.GetContext());

		if( (AbilityContext.InputContext.PrimaryTarget.ObjectID == CosmeticUnitRef.ObjectID) ||
			(AbilityContext.InputContext.MultiTargets.Find('ObjectID', CosmeticUnitRef.ObjectID) != INDEX_NONE) )
		{
			// This item was a target of the ability
			History = `XCOMHISTORY;

			RecalledItem = XComGameState_Item(History.GetGameStateForObjectID(CosmeticUnitRef.ObjectID));
			RecallItem(RecalledItem, GameState);
		}
	}
	return ELR_NoInterrupt;
}

private function RecallItem(const XComGameState_Item RecalledItem, XComGameState GameState)
{
	local XComGameStateContext_Ability AbilityContext;
	local XComGameState_Unit OwnerState;
	local XComGameState_Item NewRecalledItem;
	local XComGameState NewGameState;
	local XGUnit Visualizer;
	local vector MoveToLoc;
	local XComGameStateHistory History;
	local XComGameState_Unit CosmeticUnitState;
	local bool MoveFromTarget;
	local TTile OwnerStateDesiredAttachTile;

	History = `XCOMHISTORY;
	AbilityContext = XComGameStateContext_Ability( GameState.GetContext( ) );

	OwnerState = XComGameState_Unit(History.GetGameStateForObjectID(OwnerStateObject.ObjectID));
	OwnerStateDesiredAttachTile = OwnerState.GetDesiredTileForAttachedCosmeticUnit();
	if ( OwnerStateDesiredAttachTile != RecalledItem.GetTileLocation())
	{
		if (AttachedUnitRef != OwnerStateObject)
		{
			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Equipment recalled");					
			//Update the attached unit for this item
			NewRecalledItem = XComGameState_Item(NewGameState.ModifyStateObject(self.Class, ObjectID));
			NewRecalledItem.AttachedUnitRef = OwnerStateObject;

			`GAMERULES.SubmitGameState(NewGameState);
		}

		CosmeticUnitState = XComGameState_Unit( History.GetGameStateForObjectID( RecalledItem.CosmeticUnitRef.ObjectID ) );

		MoveFromTarget = (OwnerStateDesiredAttachTile == RecalledItem.GetTileLocation()) && (AbilityContext != none) && (AbilityContext.InputContext.SourceObject.ObjectID == OwnerState.ObjectID);

		if (MoveFromTarget && AbilityContext.InputContext.TargetLocations.Length > 0)
		{
			MoveToLoc = AbilityContext.InputContext.TargetLocations[0];
			CosmeticUnitState.SetVisibilityLocationFromVector( MoveToLoc );
		}

		//  Now move it move it
		Visualizer = XGUnit(History.GetVisualizer(CosmeticUnitRef.ObjectID));
		MoveToLoc = `XWORLD.GetPositionFromTileCoordinates(OwnerStateDesiredAttachTile);
		Visualizer.MoveToLocation(MoveToLoc, CosmeticUnitState);
	}
}

function EventListenerReturn OnUnitDied(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState, CosmeticUnit;
	local XComGameState NewGameState;
	local XComGameState_Item ItemState;
	local vector NewLocation;
	local XComGameStateContext_ChangeContainer ChangeContext;

	UnitState = XComGameState_Unit(EventData);
	//  was this the unit we are attached to or our owner?
	if (UnitState.ObjectID == AttachedUnitRef.ObjectID || UnitState.ObjectID == OwnerStateObject.ObjectID)
	{
		History = `XCOMHISTORY;
		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(OwnerStateObject.ObjectID));
		CosmeticUnit = XComGameState_Unit(History.GetGameStateForObjectID(CosmeticUnitRef.ObjectID));
		//  if it was not our owner, reattach to them
		if ( ( UnitState.ObjectID != OwnerStateObject.ObjectID ) || (OwnerStateObject.ObjectID != AttachedUnitRef.ObjectID) )
		{
			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Attached Unit Died");
			ItemState = XComGameState_Item(NewGameState.ModifyStateObject(Class, ObjectID));
			ItemState.AttachedUnitRef = OwnerStateObject;
			`GAMERULES.SubmitGameState(NewGameState);
						
			if (UnitState != none && CosmeticUnit != none && CosmeticUnit.TileLocation != UnitState.TileLocation)
			{
				NewLocation = `XWORLD.GetPositionFromTileCoordinates(UnitState.TileLocation);
				XGUnit(CosmeticUnit.GetVisualizer()).MoveToLocation(NewLocation);
			}
		}
		//  if it was our owner, we have to die too
		else
		{
			if (CosmeticUnit != none)
			{
				NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Owner Unit Died");
				ChangeContext = XComGameStateContext_ChangeContainer(NewGameState.GetContext());
				ChangeContext.BuildVisualizationFn = ItemOwnerDeathVisualization;
				CosmeticUnit = XComGameState_Unit(NewGameState.ModifyStateObject(CosmeticUnit.Class, CosmeticUnit.ObjectID));
				CosmeticUnit.SetCurrentStat(eStat_HP, 0);
				`GAMERULES.SubmitGameState(NewGameState);
			}				
		}
	}

	return ELR_NoInterrupt;
}

function ItemOwnerDeathVisualization(XComGameState VisualizeGameState)
{
	local VisualizationActionMetadata DeathTrack;
	local XComGameState_Unit UnitState;
	local XComGameStateHistory History;

	//  This game state should contain just the cosmetic unit state having its HP set to 0.
	foreach VisualizeGameState.IterateByClassType(class'XComGameState_Unit', UnitState)
	{
		break;
	}
	History = `XCOMHISTORY;
	DeathTrack.StateObject_OldState = History.GetGameStateForObjectID(UnitState.ObjectID, , VisualizeGameState.HistoryIndex - 1);
	DeathTrack.StateObject_NewState = UnitState;
	DeathTrack.VisualizeActor = UnitState.GetVisualizer();

	class'X2Action_Death'.static.AddToVisualizationTree(DeathTrack, VisualizeGameState.GetContext());	
}

function EventListenerReturn OnUnitEvacuated(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState, CosmeticUnit;
	local XComGameState NewGameState;
	local XComGameStateContext_ChangeContainer ChangeContext;

	UnitState = XComGameState_Unit(EventData);

	// If the unit that evacuated was our owner, then we must also evacuate.
	if (UnitState.ObjectID == OwnerStateObject.ObjectID)
	{
		History = `XCOMHISTORY;
		CosmeticUnit = XComGameState_Unit(History.GetGameStateForObjectID(CosmeticUnitRef.ObjectID));

		if (CosmeticUnit != none)
		{
			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Owner Unit Evacuated");
			ChangeContext = XComGameStateContext_ChangeContainer(NewGameState.GetContext());
			ChangeContext.BuildVisualizationFn = ItemOwnerEvacVisualization;

			// Visualize this context in the same visblock as the evacuating unit.
			ChangeContext.SetDesiredVisualizationBlockIndex(GameState.HistoryIndex);

			CosmeticUnit = XComGameState_Unit(NewGameState.ModifyStateObject(CosmeticUnit.Class, CosmeticUnit.ObjectID));
			CosmeticUnit.EvacuateUnit(NewGameState);
			`GAMERULES.SubmitGameState(NewGameState);
		}
	}

	return ELR_NoInterrupt;
}

function ItemOwnerEvacVisualization(XComGameState VisualizeGameState)
{
	local VisualizationActionMetadata EvacTrack;
	local XComGameState_Unit UnitState;
	local XComGameStateHistory History;
	local X2Action_Evac EvacAction;

	//  This game state should contain just the cosmetic unit state that's evacuating.
	foreach VisualizeGameState.IterateByClassType(class'XComGameState_Unit', UnitState)
	{
		break;
	}

	History = `XCOMHISTORY;
	EvacTrack.StateObject_OldState = History.GetGameStateForObjectID(UnitState.ObjectID, , VisualizeGameState.HistoryIndex - 1);
	EvacTrack.StateObject_NewState = UnitState;
	EvacTrack.VisualizeActor = UnitState.GetVisualizer();

	EvacAction = X2Action_Evac(class'X2Action_Evac'.static.AddToVisualizationTree(EvacTrack, VisualizeGameState.GetContext()));
	EvacAction.bIsVisualizingGremlin = true;

	//Hide the pawn explicitly now - in case the vis block doesn't complete immediately to trigger an update
	class'X2Action_RemoveUnit'.static.AddToVisualizationTree(EvacTrack, VisualizeGameState.GetContext());
}

function EventListenerReturn OnUnitIcarusJumped(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameStateContext_ChangeContainer ChangeContext;
	local XComGameState NewGameState;
	local XComGameState_Unit EventUnitState, AttachedUnitState;
	local XComGameStateHistory History;

	EventUnitState = XComGameState_Unit(EventData);

	History = `XCOMHISTORY;
	AttachedUnitState = XComGameState_Unit(History.GetGameStateForObjectID(AttachedUnitRef.ObjectID));

	if (EventUnitState != none && AttachedUnitState == EventUnitState)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Owner Unit Icarus Jumped");
		ChangeContext = XComGameStateContext_ChangeContainer(NewGameState.GetContext());
		ChangeContext.BuildVisualizationFn = ItemOwnerIcarusJumpVisualization;

		// Visualize this context in the same visblock as the evacuating unit.
		ChangeContext.SetDesiredVisualizationBlockIndex(GameState.HistoryIndex);

		NewGameState.ModifyStateObject(Class, ObjectID);

		`GAMERULES.SubmitGameState(NewGameState);
	}

	return ELR_NoInterrupt;
}

function ItemOwnerIcarusJumpVisualization(XComGameState VisualizeGameState)
{
	local VisualizationActionMetadata IJTrack;
	local XComGameState_Unit UnitState, AttachedUnitState;
	local XComGameState_Item GremlinItemState;
	local XComGameStateHistory History;
	local X2Action_IcarusJumpGremlin IJGremlin;
	local XGUnit GremlinUnit;

	//  This game state should contain just the cosmetic unit state that's evacuating.
	foreach VisualizeGameState.IterateByClassType(class'XComGameState_Item', GremlinItemState)
	{
		break;
	}
	
	History = `XCOMHISTORY;

	UnitState = XComGameState_Unit(History.GetGameStateForObjectID(GremlinItemState.CosmeticUnitRef.ObjectID));
	GremlinUnit = XGUnit(UnitState.GetVisualizer());
		
	IJTrack.StateObject_OldState = History.GetGameStateForObjectID(UnitState.ObjectID, , VisualizeGameState.HistoryIndex - 1);
	IJTrack.StateObject_NewState = UnitState;
	IJTrack.VisualizeActor = GremlinUnit;

	IJGremlin = X2Action_IcarusJumpGremlin(class'X2Action_IcarusJumpGremlin'.static.AddToVisualizationTree(IJTrack, VisualizeGameState.GetContext()));
	AttachedUnitState = XComGameState_Unit(History.GetGameStateForObjectID(AttachedUnitRef.ObjectID));
	IJGremlin.MoveLocation = `XWORLD.GetPositionFromTileCoordinates(AttachedUnitState.TileLocation);

	IJGremlin = X2Action_IcarusJumpGremlin(class'X2Action_IcarusJumpGremlin'.static.AddToVisualizationTree(IJTrack, VisualizeGameState.GetContext()));
	IJGremlin.bPlayInReverse = true;
}

simulated function array<name> GetMyWeaponUpgradeTemplateNames()
{
	return m_arrWeaponUpgradeNames;
}

simulated function array<X2WeaponUpgradeTemplate> GetMyWeaponUpgradeTemplates()
{
	local X2ItemTemplateManager ItemMgr;
	local int i;

	ItemMgr = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	if (m_arrWeaponUpgradeTemplates.Length > m_arrWeaponUpgradeNames.Length)
		m_arrWeaponUpgradeTemplates.Length = 0;

	for (i = 0; i < m_arrWeaponUpgradeNames.Length; ++i)
	{
		if (m_arrWeaponUpgradeTemplates[i] == none || m_arrWeaponUpgradeTemplates[i].DataName != m_arrWeaponUpgradeNames[i])
			m_arrWeaponUpgradeTemplates[i] = X2WeaponUpgradeTemplate(ItemMgr.FindItemTemplate(m_arrWeaponUpgradeNames[i]));
	}

	return m_arrWeaponUpgradeTemplates;
}

//Start Issue #306
simulated function int GetMyWeaponUpgradeCount()
{
	return m_arrWeaponUpgradeNames.Length;
}
// End Issue #306

simulated function array<string> GetMyWeaponUpgradeTemplatesCategoryIcons()
{
	local array<X2WeaponUpgradeTemplate> Templates;
	local int TemplateIdx, LocalIdx;
	local array<string> LocalIcons, FinalIcons; 

	Templates = GetMyWeaponUpgradeTemplates();
	for( TemplateIdx = 0; TemplateIdx < Templates.length; TemplateIdx++ )
	{
		LocalIcons = Templates[TemplateIdx].GetAttachmentInventoryCategoryImages(self);
		
		for( LocalIdx = 0; LocalIdx < LocalIcons.length; LocalIdx++ )
			FinalIcons.AddItem(LocalIcons[LocalIdx]);
	}
	return FinalIcons; 
}

//  Note: this should only be called after verifying the upgrade can be applied successfully, there is no error checking here.
simulated function ApplyWeaponUpgradeTemplate(X2WeaponUpgradeTemplate UpgradeTemplate, optional int SlotIndex = -1)
{
	// If a specific slot was not provided or the slot is past any equipped upgrades, add it to the end of the upgrade list
	if (SlotIndex == -1 || SlotIndex >= m_arrWeaponUpgradeNames.Length)
	{
		m_arrWeaponUpgradeNames.AddItem(UpgradeTemplate.DataName);
		m_arrWeaponUpgradeTemplates.AddItem(UpgradeTemplate);
	}
	else // Otherwise replace the specific slot index
	{
		m_arrWeaponUpgradeNames[SlotIndex] = UpgradeTemplate.DataName;
		m_arrWeaponUpgradeTemplates[SlotIndex] = UpgradeTemplate;
	}

	//  adjust anything upgrades could affect
	Ammo = GetClipSize();
}

simulated function X2WeaponUpgradeTemplate DeleteWeaponUpgradeTemplate(int SlotIndex)
{
	local X2WeaponUpgradeTemplate UpgradeTemplate;
	
	// If an upgrade template exists at the slot index, delete it
	if (SlotIndex < m_arrWeaponUpgradeNames.Length && m_arrWeaponUpgradeNames[SlotIndex] != '')
	{
		UpgradeTemplate = m_arrWeaponUpgradeTemplates[SlotIndex];
		
		m_arrWeaponUpgradeNames[SlotIndex] = '';
		m_arrWeaponUpgradeTemplates[SlotIndex] = none;
	}

	return UpgradeTemplate;
}

simulated function WipeUpgradeTemplates()
{
	m_arrWeaponUpgradeNames.Length = 0;
	m_arrWeaponUpgradeTemplates.Length = 0;

	//  adjust anything upgrades could affect
	Ammo = GetClipSize();
}

simulated function bool HasBeenModified()
{
	local X2WeaponTemplate WeaponTemplate;
	local XComLWTuple Tuple; //start of issue #183 - added mod event hook for mods wanting to have certain items not be stacked
	local bool bOverrideItemModified, bItemModified; 

	Tuple = new class'XComLWTuple';
	Tuple.Id = 'OverrideItemIsModified';
	Tuple.Data.Add(2);
	Tuple.Data[0].kind = XComLWTVBool;
	Tuple.Data[0].b = false; //bOverrideItemModified;
	Tuple.Data[1].kind = XComLWTVBool;
	Tuple.Data[1].b = false; //bItemModified;

	`XEVENTMGR.TriggerEvent('OverrideItemIsModified', Tuple, self, none);
	bOverrideItemModified = Tuple.Data[0].b;
	bItemModified = Tuple.Data[1].b;
	if(bOverrideItemModified){
		return bItemModified; 
	} //end issue #183

	if (Nickname != "")
		return true;

	//start issue #104: added check for whether a item gamestate has any attached component object ids. If so, don't put it in a stack since a mod has attached something to it.
	if (ComponentObjectIDs.Length > 0)
		return true;
	//end issue #104
		
	WeaponTemplate = X2WeaponTemplate( m_ItemTemplate );

	// Single line for Issues #93 and #306
	if ((WeaponTemplate != none) && (GetNumUpgradeSlots() > 0) && (GetMyWeaponUpgradeCount() > 0))
		return true;

	return false;
}

simulated function bool IsStartingItem()
{
	return GetMyTemplate().StartingItem && !HasBeenModified();
}

simulated function bool HasLoadedAmmo()
{
	return LoadedAmmo.ObjectID != 0;
}

simulated native function X2ItemTemplate GetLoadedAmmoTemplate(const XComGameState_Ability AbilityState);

//If the template for this item is of type X2EquipmentTemplate or derived, this will return / load
//the archetypes for that template
simulated function Object GetGameArchetype(optional bool bAlt = false)
{
	local Object GameArchetype;
	local string strArchetype;

	GetMyTemplate();
	
	if( bAlt )
	{
		strArchetype = X2EquipmentTemplate(m_ItemTemplate).AltGameArchetype;
	}
	else
	{
		strArchetype = X2EquipmentTemplate(m_ItemTemplate).GameArchetype;
	}
	
	GameArchetype = `CONTENT.RequestGameArchetype(strArchetype);		
	
	return GameArchetype;	
}

simulated function array<WeaponAttachment> GetWeaponAttachments(optional bool bGetContent=true)
{
	local X2WeaponTemplate WeaponTemplate;
	local array<WeaponAttachment> Attachments;
	local array<X2WeaponUpgradeTemplate> UpgradeTemplates;
	local int i, j, k;
	local bool bReplaced;
	local delegate<X2TacticalGameRulesetDataStructures.CheckUpgradeStatus> ValidateAttachmentFn;
	local XComGameState_Unit OwnerState;
	// variables for Issue #240
	local array<X2DownloadableContentInfo> DLCInfos;
	local X2DownloadableContentInfo DLCInfo;

	WeaponTemplate = X2WeaponTemplate(GetMyTemplate());
	if (WeaponTemplate != none)
	{
		//  copy all default attachments from the weapon template
		for (i = 0; i < WeaponTemplate.DefaultAttachments.Length; ++i)
		{
			Attachments.AddItem(WeaponTemplate.DefaultAttachments[i]);
		}
		UpgradeTemplates = GetMyWeaponUpgradeTemplates();
		for (i = 0; i < UpgradeTemplates.Length; ++i)
		{
			for (j = 0; j < UpgradeTemplates[i].UpgradeAttachments.Length; ++j)
			{
				if (UpgradeTemplates[i].UpgradeAttachments[j].ApplyToWeaponTemplate != WeaponTemplate.DataName)
					continue;

				ValidateAttachmentFn = UpgradeTemplates[i].UpgradeAttachments[j].ValidateAttachmentFn;
				if( ValidateAttachmentFn != None && !ValidateAttachmentFn(UpgradeTemplates) )
				{
					continue;
				}

				bReplaced = false;
				//  look for sockets already known that an upgrade will replace
				for (k = 0; k < Attachments.Length; ++k)
				{
					if( Attachments[k].AttachSocket == UpgradeTemplates[i].UpgradeAttachments[j].AttachSocket )
					{
						Attachments[k].AttachMeshName = UpgradeTemplates[i].UpgradeAttachments[j].AttachMeshName;
						bReplaced = true;
						break;
					}
				}
				//  if not replacing an existing mesh, add the upgrade attachment as a new one
				if( !bReplaced )
				{
					Attachments.AddItem(UpgradeTemplates[i].UpgradeAttachments[j]);
				}
			}
		}
		if (bGetContent)
		{
			OwnerState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(OwnerStateObject.ObjectID));
			for (i = 0; i < Attachments.Length; ++i)
			{
				if (Attachments[i].RequiredGender == eGender_None || (OwnerState != None && OwnerState.kAppearance.iGender == Attachments[i].RequiredGender))
				{
					// If the attachment is only valid for a specific gender, only attach it if the owner matches the gender
					Attachments[i].LoadedObject = `CONTENT.RequestGameArchetype(Attachments[i].AttachMeshName);
					Attachments[i].LoadedProjectileTemplate = `CONTENT.RequestGameArchetype(Attachments[i].AttachProjectileName);
				}
				else if (OwnerState == none && Attachments[i].RequiredGender == eGender_Female)
				{
					// The owner doesn't exist (character pool), so attach a version of the asset so something appears
					Attachments[i].LoadedObject = `CONTENT.RequestGameArchetype(Attachments[i].AttachMeshName);
					Attachments[i].LoadedProjectileTemplate = `CONTENT.RequestGameArchetype(Attachments[i].AttachProjectileName);
				}
			}
		}
	}

	// Start Issue #240
	DLCInfos = `ONLINEEVENTMGR.GetDLCInfos(false);
	foreach DLCInfos(DLCInfo)
	{
		DLCInfo.UpdateWeaponAttachments(Attachments, self);
	}
	// End Issue #240

	return Attachments;
}

simulated function int GetClipSize()
{
	local XComGameStateHistory History;
	local XComGameState_Item SpecialAmmo;
	local int i, ClipSize, AdjustedClipSize;

	// Start Issue #393:
	// Add Tuple Object to pass values through the event trigger
	// to pre-filter event triggers
	local XComLWTuple Tuple;
	// End Issue #393

	ClipSize = -1;
	GetMyTemplate();
	GetMyWeaponUpgradeTemplates();

	if (m_ItemTemplate.IsA('X2WeaponTemplate'))
	{
		ClipSize = X2WeaponTemplate(m_ItemTemplate).iClipSize;
		History = `XCOMHISTORY;
		for (i = 0; i < m_arrWeaponUpgradeTemplates.Length; ++i)
		{
			if (m_arrWeaponUpgradeTemplates[i].AdjustClipSizeFn != none)
			{
				if (m_arrWeaponUpgradeTemplates[i].AdjustClipSizeFn(m_arrWeaponUpgradeTemplates[i], self, ClipSize, AdjustedClipSize))
					ClipSize = AdjustedClipSize;
			}
		}
		if (LoadedAmmo.ObjectID != 0)
		{
			SpecialAmmo = XComGameState_Item(History.GetGameStateForObjectID(LoadedAmmo.ObjectID));
			if (SpecialAmmo != none)
			{
				ClipSize += SpecialAmmo.GetClipSize();
			}
		}
	}
	else if (m_ItemTemplate.IsA('X2AmmoTemplate'))
	{
		ClipSize = X2AmmoTemplate(m_ItemTemplate).ModClipSize;
	}

	// Start Issue #393
	/// HL-Docs: feature:OverrideClipSize; issue:393; tags:tactical
	/// The `OverrideClipSize` event allows mods to override Clip Size 
	/// of a weapon after it has been modified by weapon upgrades and/or loaded ammo.
	///
	/// This can help make a passive ability that modifies Clip Size of the soldier's weapon,
	/// or to explicitly disallow a specific weapon benefitting from effects that modify Clip Size 
	/// by resetting the clip size value to the clip size value stored in the weapon template.
	///    
	///```event
	///EventID: OverrideClipSize,
	///EventData: [inout int iClipSize],
	///EventSource: XComGameState_Item (ItemState),
	///NewGameState: none
	///```
	Tuple = new class'XComLWTuple';
	Tuple.Id = 'OverrideClipSize';
	Tuple.Data.Add(1);
	Tuple.Data[0].kind = XComLWTVInt;
	Tuple.Data[0].i = ClipSize;

	`XEVENTMGR.TriggerEvent('OverrideClipSize', Tuple, self);

	// Read back in the new values for ClipSize
	ClipSize = Tuple.Data[0].i;
	// End Issue #393

	return ClipSize;
}


simulated function bool HasInfiniteAmmo()
{
	// Start Issue #842
	local bool bHasInfiniteAmmo;

	GetMyTemplate();
	if (m_ItemTemplate.IsA('X2WeaponTemplate'))
		bHasInfiniteAmmo = X2WeaponTemplate(m_ItemTemplate).InfiniteAmmo;

	return TriggerOverrideHasInfiniteAmmo(bHasInfiniteAmmo);
	// End Issue #842
}

/// HL-Docs: feature:OverrideHasInfiniteAmmo; issue:842; tags:tactical
/// Allows listeners to override the result of HasInfiniteAmmo
///
/// ```event
/// EventID: OverrideHasInfiniteAmmo,
/// EventData: [ out bool bHasInfiniteAmmo ],
/// EventSource: XComGameState_Item (ItemState),
/// NewGameState: none
/// ```
private function bool TriggerOverrideHasInfiniteAmmo(bool bHasInfiniteAmmo)
{
	local XComLWTuple Tuple;

	Tuple = new class'XComLWTuple';
	Tuple.Id = 'OverrideHasInfiniteAmmo';
	Tuple.Data.Add(1);
	Tuple.Data[0].kind = XComLWTVBool;
	Tuple.Data[0].b = bHasInfiniteAmmo;

	`XEVENTMGR.TriggerEvent('OverrideHasInfiniteAmmo', Tuple, self);

	return Tuple.Data[0].b;
}

simulated function int GetItemSize()
{
	return GetMyTemplate().iItemSize;
}

// Start Issue #119
// Allow mods to override range returned, otherwise perform native behaviour,
// which has been extracted out of native method.
//
//simulated native function int GetItemRange(const XComGameState_Ability AbilityState);
simulated function int GetItemRange(const XComGameState_Ability AbilityState)
{
	local XComLWTuple OverrideTuple;
	local X2GrenadeLauncherTemplate GLTemplate;
	local X2WeaponTemplate WeaponTemplate;
	local XComGameState_Item SourceAmmo;
	local int ReturnRange;

	//`LOG("WE ARE GETTING TO GETNUMUTILITYSLOTS");
	OverrideTuple = new class'XComLWTuple';
	OverrideTuple.Id = 'GetItemRange';
	OverrideTuple.Data.Add(3);
	OverrideTuple.Data[0].kind = XComLWTVBool;
	OverrideTuple.Data[0].b = false;  // override? (true) or add? (false)
	OverrideTuple.Data[1].kind = XComLWTVInt;
	OverrideTuple.Data[1].i = 0;  // override/bonus range
	OverrideTuple.Data[2].kind = XComLWTVObject;
	OverrideTuple.Data[2].o = AbilityState;  // optional ability

	`XEVENTMGR.TriggerEvent('OnGetItemRange', OverrideTuple, self);

	if(OverrideTuple.Data[0].b)
		return OverrideTuple.Data[1].i;

	ReturnRange = OverrideTuple.Data[1].i;

	GetMyTemplate();
	GLTemplate = X2GrenadeLauncherTemplate(m_ItemTemplate);
	if(GLTemplate != none)
	{
		SourceAmmo = AbilityState.GetSourceAmmo();
		if(SourceAmmo != none)
		{
			WeaponTemplate = X2WeaponTemplate(SourceAmmo.GetMyTemplate());
			if(WeaponTemplate != none)
			{
				return ReturnRange + WeaponTemplate.iRange + GLTemplate.IncreaseGrenadeRange;
			}
		}
	}
	WeaponTemplate = X2WeaponTemplate(m_ItemTemplate);
	if(WeaponTemplate != none)
	{
		return ReturnRange + WeaponTemplate.iRange;
	}
	return -1;
}
// End Issue #119

simulated native function int GetItemRadius(const XComGameState_Ability AbilityState);
simulated native function float GetItemCoverage(const XComGameState_Ability AbilityState);

native function bool Validate(XComGameState HistoryGameState, INT GameStateIndex) const;

simulated function GetBaseWeaponDamageValue(XComGameState_BaseObject TargetObjectState, out WeaponDamageValue DamageValue)
{
	local X2WeaponTemplate WeaponTemplate;

	WeaponTemplate = X2WeaponTemplate(GetMyTemplate());
	if (WeaponTemplate != none)
	{
		DamageValue = WeaponTemplate.BaseDamage;
	}
}

simulated function GetWeaponDamageValue(XComGameState_BaseObject TargetObjectState, name Tag, out WeaponDamageValue DamageValue)
{
	local X2WeaponTemplate WeaponTemplate;
	local int i;

	WeaponTemplate = X2WeaponTemplate(GetMyTemplate());
	if (WeaponTemplate != none && Tag != '')
	{
		for (i = 0; i < WeaponTemplate.ExtraDamage.Length; ++i)
		{
			if (WeaponTemplate.ExtraDamage[i].Tag == Tag)
			{
				DamageValue = WeaponTemplate.ExtraDamage[i];
				return;
			}
		}
	}
}

simulated function int GetItemEnvironmentDamage()
{
	GetMyTemplate();
	if (m_ItemTemplate.IsA('X2WeaponTemplate'))
		return X2WeaponTemplate(m_ItemTemplate).iEnvironmentDamage;

	return class'X2WeaponTemplate'.default.iEnvironmentDamage;
}

simulated function int GetItemSoundRange()
{
	local int iSoundRange;
	
	local XComLWTuple Tuple; // Issue #363

	iSoundRange = class'X2WeaponTemplate'.default.iSoundRange;
	GetMyTemplate();
	
	if (m_ItemTemplate.IsA('X2WeaponTemplate'))
	{
		iSoundRange = X2WeaponTemplate(m_ItemTemplate).iSoundRange;
	}

	// Start Issue #363
	Tuple = new class'XComLWTuple';
	Tuple.Id = 'OverrideItemSoundRange';
	Tuple.Data.Add(1);
	Tuple.Data[0].kind = XComLWTVInt;
	Tuple.Data[0].i = iSoundRange;

	`XEVENTMGR.TriggerEvent('OverrideItemSoundRange', Tuple, self, none);
	
	iSoundRange = Tuple.Data[0].i;
	// End Issue #363

	return iSoundRange;
}

// Used only for stat displays. GetClipSize() is functional method for tactical.
simulated function int GetItemClipSize()
{
	GetMyTemplate();
	if (m_ItemTemplate.IsA('X2WeaponTemplate'))
		return X2WeaponTemplate(m_ItemTemplate).iClipSize;

	return class'X2WeaponTemplate'.default.iClipSize;
}

simulated function int GetItemAimModifier()
{
	GetMyTemplate();
	if (m_ItemTemplate.IsA('X2WeaponTemplate'))
		return X2WeaponTemplate(m_ItemTemplate).Aim;

	return class'X2WeaponTemplate'.default.Aim;
}

simulated function int GetItemCritChance()
{
	GetMyTemplate();
	if (m_ItemTemplate.IsA('X2WeaponTemplate'))
		return X2WeaponTemplate(m_ItemTemplate).CritChance;

	return class'X2WeaponTemplate'.default.CritChance;
}

simulated function int GetItemPierceValue()
{
	GetMyTemplate();
	if (m_ItemTemplate.IsA('X2WeaponTemplate'))
		return X2WeaponTemplate(m_ItemTemplate).BaseDamage.Pierce;

	return class'X2WeaponTemplate'.default.BaseDamage.Pierce;
}

// Issue #237 start
simulated function int GetItemRuptureValue()
{
	GetMyTemplate();
	if (m_ItemTemplate.IsA('X2WeaponTemplate'))
	{
		return X2WeaponTemplate(m_ItemTemplate).BaseDamage.Rupture;
	}

	return class'X2WeaponTemplate'.default.BaseDamage.Rupture;
}

simulated function int GetItemShredValue()
{
	GetMyTemplate();
	if (m_ItemTemplate.IsA('X2WeaponTemplate'))
	{
		return X2WeaponTemplate(m_ItemTemplate).BaseDamage.Shred;
	}

	return class'X2WeaponTemplate'.default.BaseDamage.Shred;
}
// Issue #237 end

simulated function bool SoundOriginatesFromOwnerLocation()
{
	GetMyTemplate();
	if (m_ItemTemplate.IsA('X2WeaponTemplate'))
		return X2WeaponTemplate(m_ItemTemplate).bSoundOriginatesFromOwnerLocation;
	return true;
}

simulated function bool CanWeaponBeDodged()
{
	GetMyTemplate();
	if (m_ItemTemplate.IsA('X2WeaponTemplate'))
		return X2WeaponTemplate(m_ItemTemplate).bCanBeDodged;
	return true;
}

simulated function name GetWeaponCategory()
{
	local X2WeaponTemplate Template;

	Template = X2WeaponTemplate(GetMyTemplate());
	if (Template != none)
		return Template.WeaponCat;

	return '';
}

simulated function name GetWeaponTech()
{
	local X2WeaponTemplate Template;

	Template = X2WeaponTemplate(GetMyTemplate());
	if (Template != none)
		return Template.WeaponTech;

	return '';
}

simulated function array<string> GetWeaponPanelImages()
{
	local array<X2WeaponUpgradeTemplate> Upgrades;
	local X2WeaponUpgradeTemplate UpgradeTemplate;
	local array<WeaponAttachment> UpgradeAttachments;
	local array<string> Images; 
	local X2WeaponTemplate WeaponTemplate; 
	local int i; 
	local int iUpgrade;
	local delegate<X2TacticalGameRulesetDataStructures.CheckUpgradeStatus> ValidateAttachmentFn;
	local bool bUpgradeImageFound;

	GetMyTemplate();
	if (m_ItemTemplate.IsA('X2WeaponTemplate'))
	{
		WeaponTemplate = X2WeaponTemplate(m_ItemTemplate); 

		if (m_ItemTemplate.strImage != "")
			Images.AddItem(m_ItemTemplate.strImage);
		else if( X2WeaponTemplate(m_ItemTemplate).WeaponPanelImage != "" )
			Images.AddItem(X2WeaponTemplate(m_ItemTemplate).WeaponPanelImage);

		//First check all Upgrade Images to find valid ones
		Upgrades = GetMyWeaponUpgradeTemplates();
		for (iUpgrade = 0; iUpgrade < Upgrades.length; iUpgrade++)
		{
			UpgradeTemplate = Upgrades[iUpgrade];
			for (i = 0; i < UpgradeTemplate.UpgradeAttachments.length; i++)
			{
				ValidateAttachmentFn = UpgradeTemplate.UpgradeAttachments[i].ValidateAttachmentFn;
				if (ValidateAttachmentFn != None && !ValidateAttachmentFn(Upgrades))
				{
					continue;
				}

				if (UpgradeTemplate.UpgradeAttachments[i].ApplyToWeaponTemplate == GetMyTemplateName())
				{
					UpgradeAttachments.AddItem(UpgradeTemplate.UpgradeAttachments[i]);
					if (UpgradeTemplate.UpgradeAttachments[i].AttachIconName != "")
						Images.AddItem(UpgradeTemplate.UpgradeAttachments[i].AttachIconName);
				}
			}
		}

		//Cycle through base images
		for( i = 0; i < WeaponTemplate.DefaultAttachments.length; i++ )
		{
			bUpgradeImageFound = false;
			if (UpgradeAttachments.length > 0)
			{
				// Look for a replacement image among the attached upgrades
				for (iUpgrade = 0; iUpgrade < UpgradeAttachments.length; iUpgrade++)
				{
					if (UpgradeAttachments[iUpgrade].AttachSocket == WeaponTemplate.DefaultAttachments[i].AttachSocket)
					{
						bUpgradeImageFound = true;
						break;
					}
				}
			}
			
			// If an upgrade image has already been added for that slot, don't add it to the stack
			if (!bUpgradeImageFound && WeaponTemplate.DefaultAttachments[i].AttachIconName != "")
				Images.AddItem(WeaponTemplate.DefaultAttachments[i].AttachIconName);			
		}
	}
	else
	{
		if (m_ItemTemplate.strImage != "")
			Images.AddItem(m_ItemTemplate.strImage);
		else if( X2WeaponTemplate(m_ItemTemplate).WeaponPanelImage != "" )
			Images.AddItem(X2WeaponTemplate(m_ItemTemplate).WeaponPanelImage);
	}

	return Images; 
}

//Items can receive nicknames in certain situations.
function String GenerateNickname()
{	
	local int iGenderChoice;
	local int iNumChoices, iChoice;
	local XComGameState_Unit OwnerState;
	local X2SoldierClassTemplate Template;
		
	OwnerState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(OwnerStateObject.ObjectID));

	Template = OwnerState.GetSoldierClassTemplate();
	iNumChoices = Template.RandomNickNames.Length;

	//Randomly choose a gender
	iGenderChoice = `SYNC_RAND(2);
	if (iGenderChoice == 0)
	{
		iNumChoices += Template.RandomNickNames_Female.Length;
	}
	else
	{
		iNumChoices += Template.RandomNickNames_Male.Length;
	}
	
	iChoice = `SYNC_RAND(iNumChoices);

	if(iChoice < Template.RandomNickNames.Length)
	{
		return Template.RandomNickNames[iChoice];
	}
	else
	{
		iChoice -= Template.RandomNickNames.Length;
	}

	if (iGenderChoice == 0)
	{
		return Template.RandomNickNames_Female[iChoice];
	}
	else
	{
		return Template.RandomNickNames_Male[iChoice];
	}

	return "";
}

simulated function bool AllowsHeavyWeapon()
{
	local X2ArmorTemplate ArmorTemplate;

	ArmorTemplate = X2ArmorTemplate(GetMyTemplate());
	return ArmorTemplate != None && ArmorTemplate.bHeavyWeapon;
}

simulated function EUISummary_WeaponStats GetWeaponStatsForUI()
{
	local EUISummary_WeaponStats Summary; 
	local int BaseClipSize;
	local WeaponDamageValue DamageValue;
	local array<X2WeaponUpgradeTemplate> WeaponUpgradeTemplates;
	local X2WeaponUpgradeTemplate UpgradeTemplate;

	GetMyTemplate();
	GetBaseWeaponDamageValue(none, DamageValue);

	Summary.Damage		= DamageValue.Damage; 
	Summary.Crit		= GetItemCritChance();
	Summary.Aim			= GetItemAimModifier();
	Summary.ClipSize	= GetClipSize();
	Summary.Range       = GetItemRange(none);

	if (m_ItemTemplate.IsA('X2WeaponTemplate'))
		BaseClipSize = X2WeaponTemplate(m_ItemTemplate).iClipSize;
	Summary.bIsClipSizeModified = BaseClipSize != Summary.ClipSize;

	Summary.SpecialAmmo = GetLoadedAmmoTemplate(none);
	Summary.bIsAmmoModified = Summary.SpecialAmmo != none;

	WeaponUpgradeTemplates = GetMyWeaponUpgradeTemplates();
	foreach WeaponUpgradeTemplates(UpgradeTemplate)
	{
		if (UpgradeTemplate.AddHitChanceModifierFn != none)
			Summary.bIsAimModified = true;

		if (UpgradeTemplate.AddCritChanceModifierFn != none)
			Summary.bIsCritModified = true;

		//  Upgrades cannot modify damage, or range -jbouscher
		// Issue #237 start
		if (UpgradeTemplate.AddCHDamageModifierFn != none)
		{
			if (UpgradeTemplate.CHBonusDamage.Damage > 0)
			{
				Summary.bIsDamageModified = true;
			}
			if (UpgradeTemplate.CHBonusDamage.Spread > 0)
			{
				Summary.bIsSpreadModified = true;
			}
			if (UpgradeTemplate.CHBonusDamage.Crit > 0)
			{
				Summary.bIsCritDamageModified = true;
			}
			if (UpgradeTemplate.CHBonusDamage.Pierce > 0)
			{
				Summary.bIsPierceModified = true;
			}
			if (UpgradeTemplate.CHBonusDamage.Rupture > 0)
			{
				Summary.bIsRuptureModified = true;
			}
			if (UpgradeTemplate.CHBonusDamage.Shred > 0)
			{
				Summary.bIsShredModified = true;
			}
		}
		// Issue #237 end
		Summary.bIsRangeModified = false;
	}

	return Summary;
}

simulated function array<EUISummary_WeaponUpgrade> GetWeaponUpgradesForTooltipUI()
{
	local array<X2WeaponUpgradeTemplate> Upgrades; 
	local array<EUISummary_WeaponUpgrade> Entries; 
	local EUISummary_WeaponUpgrade SummaryEntry;
	local int iUpgrade; 

	Upgrades = GetMyWeaponUpgradeTemplates(); 

	for( iUpgrade = 0; iUpgrade < Upgrades.length; iUpgrade++ )
	{
		SummaryEntry.UpgradeTemplate = Upgrades[iUpgrade];

		//TODO: @gameplay: Add label/values for things that this upgrade modifies on the weapon. 
		//foreach modifiedStats(stat) ... 
		//{
			SummaryEntry.Labels.AddItem("STAT"); //TEMP
			SummaryEntry.Values.AddItem("-1");	 //TEMP 
		//}

		Entries.AddItem(SummaryEntry);
	}
	
	return Entries; 
}

simulated function string GetUpgradeEffectForUI(X2WeaponUpgradeTemplate UpgradeTemplate)
{
	local string StatModifiers;
	local EUISummary_WeaponStats UpgradeStats;

	if(UpgradeTemplate.TinySummary != "")
	{
		return UpgradeTemplate.TinySummary;
	}
	else
	{
		UpgradeStats = GetUpgradeModifiersForUI(UpgradeTemplate);
		
		// Issue #237 start
		if(UpgradeStats.bIsDamageModified || UpgradeStats.bIsSpreadModified)
		{
			if (UpgradeStats.bIsSpreadModified)
			{
				StatModifiers $= AddStatModifierSpread(StatModifiers != "", class'XLocalizedData'.default.DamageLabel, UpgradeStats.DamageValue.Damage - UpgradeStats.DamageValue.Spread, UpgradeStats.DamageValue.Damage + UpgradeStats.DamageValue.Spread);
			}
			else
			{
				StatModifiers $= AddStatModifier(StatModifiers != "", class'XLocalizedData'.default.DamageLabel, UpgradeStats.DamageValue.Damage);
			}
		}
		if(UpgradeStats.bIsCritDamageModified)
		{
			StatModifiers $= AddStatModifier(StatModifiers != "", class'XLocalizedData'.default.CriticalDamageLabel, UpgradeStats.DamageValue.Crit);
		}
		// Issue #237 end
		if(UpgradeStats.bIsAimModified)
			StatModifiers $= AddStatModifier(StatModifiers != "", class'XLocalizedData'.default.AimLabel, UpgradeStats.Aim);
		if(UpgradeStats.bIsCritModified)
			StatModifiers $= AddStatModifier(StatModifiers != "", class'XLocalizedData'.default.CritChanceLabel, UpgradeStats.Crit);
		// Issue #237 start - Setting up two sections to keep the organization uniform
		if(UpgradeStats.bIsPierceModified)
		{
			StatModifiers $= AddStatModifier(StatModifiers != "", class'XLocalizedData'.default.PierceLabel, UpgradeStats.DamageValue.Pierce);
		}
		if(UpgradeStats.bIsRuptureModified)
		{
			StatModifiers $= AddStatModifier(StatModifiers != "", class'XLocalizedData'.default.RuptureLabel, UpgradeStats.DamageValue.Rupture);
		}
		if(UpgradeStats.bIsShredModified)
		{
			StatModifiers $= AddStatModifier(StatModifiers != "", class'XLocalizedData'.default.ShredLabel, UpgradeStats.DamageValue.Shred);
		}
		// Issue #237 end
		if(UpgradeStats.bIsClipSizeModified)
			StatModifiers $= AddStatModifier(StatModifiers != "", class'XLocalizedData'.default.ClipSizeLabel, UpgradeStats.ClipSize);
		if (UpgradeStats.bIsFreeFirePctModified)
			StatModifiers $= AddStatModifier(StatModifiers != "", class'XLocalizedData'.default.FreeFireLabel, UpgradeStats.FreeFirePct);
		if (UpgradeStats.bIsFreeFirePctModified)
			StatModifiers $= AddStatModifier(StatModifiers != "", class'XLocalizedData'.default.FreeReloadLabel, UpgradeStats.FreeReloads);
		if (UpgradeStats.bIsMissDamageModified)
			StatModifiers $= AddStatModifier(StatModifiers != "", class'XLocalizedData'.default.MissDamageLabel, UpgradeStats.MissDamage);
		if (UpgradeStats.bIsFreeKillPctModified)
			StatModifiers $= AddStatModifier(StatModifiers != "", class'XLocalizedData'.default.FreeKillLabel, UpgradeStats.FreeKillPct);

		return StatModifiers;
	}
}

simulated function string AddStatModifier(bool bAddCommaSeparator, string Label, int Value, optional int ColorState = eUIState_Normal, optional string PostFix, optional bool bSymbolOnRight)
{
	local string Result;
	if(bAddCommaSeparator) Result $= ", ";
	Result $= Label;
	if(bSymbolOnRight)
		Result @= Value $ (Value >= 0 ? "+" : "");	//Issue #1101 - Weapon Upgrade with negative stat modifier shows as "--x"
	else
		Result @= (Value >= 0 ? "+" : "") $ Value;	//Issue #1101 - Weapon Upgrade with negative stat modifier shows as "--x"
	Result = class'UIUtilities_Text'.static.GetColoredText(Result $ PostFix, ColorState);
	Result = class'UIUtilities_Text'.static.FormatCommaSeparatedNouns(Result);
	return Result;
}

// Issue #237 start
simulated function string AddStatModifierSpread(bool bAddCommaSeparator, string Label, int FirstValue, int SecondValue, optional int ColorState = eUIState_Normal, optional string PostFix, optional bool bSymbolOnRight)
{
	local string Result;
	local bool bFirstValueNegative;

	if (FirstValue < 0)
	{
		bFirstValueNegative = true;
	}
	if(bAddCommaSeparator)
	{
		Result $= ", ";
	}

	// Second value will always be greater than first value, so if the first value is positive, we don't need to check the second.
	Result $= Label;
	if(bSymbolOnRight)
	{
		Result @= FirstValue $ (bFirstValueNegative ? "-" : "+") $ "-" $ SecondValue $ (bFirstValueNegative && (SecondValue < 0)) ? "-" : "+";
	}
	else
	{
		Result @= (bFirstValueNegative ? "-" : "+") $ FirstValue $ "-" $ SecondValue;
	}

	Result = class'UIUtilities_Text'.static.GetColoredText(Result $ PostFix, ColorState);
	Result = class'UIUtilities_Text'.static.FormatCommaSeparatedNouns(Result);
	return Result;
}
// Issue #237 end

simulated function EUISummary_WeaponStats GetUpgradeModifiersForUI(X2WeaponUpgradeTemplate UpgradeTemplate)
{
	local int i, tmp;
	local GameRulesCache_VisibilityInfo VisInfo; // Aim Upgrades require VisibilityInfo since the aim benefit changes based on current cover state of the target
	local EUISummary_WeaponStats TotalUpgradeSummary;
	local array<X2WeaponUpgradeTemplate> WeaponUpgrades;
	local XComGameState_HeadquartersXCom XComHQ;
	local StateObjectReference ObjectRef;
	local XComGameState_Tech BreakthroughTech;
	local X2TechTemplate TechTemplate;
	local X2AbilityTemplateManager AbilityTemplateMan;
	local X2AbilityTemplate AbilityTemplate;
	local X2Effect TargetEffect;
	local X2Effect_BonusWeaponDamage BonusDamage;

	WeaponUpgrades = GetMyWeaponUpgradeTemplates();

	if(UpgradeTemplate != none && WeaponUpgrades.Find(UpgradeTemplate) == INDEX_NONE)	// Issue #237 - Only add this upgrade if it's not already on the item
		WeaponUpgrades.AddItem(UpgradeTemplate);

	for(i = 0; i < WeaponUpgrades.Length; ++i)
	{
		UpgradeTemplate = WeaponUpgrades[i];

		//TODO: @gameplay: ensure all upgrade stat modifications are accounted for here
		if(UpgradeTemplate == none)
			continue;
		
		// Issue #237 start
		if (UpgradeTemplate.AddCHDamageModifierFn != none)
		{
			if (UpgradeTemplate.CHBonusDamage.Damage > 0)
			{
				TotalUpgradeSummary.bIsDamageModified = true;
				UpgradeTemplate.AddCHDamageModifierFn(UpgradeTemplate, tmp, 'Damage');
				TotalUpgradeSummary.DamageValue.Damage += tmp;
			}
			if (UpgradeTemplate.CHBonusDamage.Spread > 0)
			{
				TotalUpgradeSummary.bIsSpreadModified = true;
				UpgradeTemplate.AddCHDamageModifierFn(UpgradeTemplate, tmp, 'Spread');
				TotalUpgradeSummary.DamageValue.Spread += tmp;
			}
			if (UpgradeTemplate.CHBonusDamage.Crit > 0)
			{
				TotalUpgradeSummary.bIsCritDamageModified = true;
				UpgradeTemplate.AddCHDamageModifierFn(UpgradeTemplate, tmp, 'Crit');
				TotalUpgradeSummary.DamageValue.Crit += tmp;
			}
			if (UpgradeTemplate.CHBonusDamage.Pierce > 0)
			{
				TotalUpgradeSummary.bIsPierceModified = true;
				UpgradeTemplate.AddCHDamageModifierFn(UpgradeTemplate, tmp, 'Pierce');
				TotalUpgradeSummary.DamageValue.Pierce += tmp;
			}
			if (UpgradeTemplate.CHBonusDamage.Rupture > 0)
			{
				TotalUpgradeSummary.bIsRuptureModified = true;
				UpgradeTemplate.AddCHDamageModifierFn(UpgradeTemplate, tmp, 'Rupture');
				TotalUpgradeSummary.DamageValue.Rupture += tmp;
			}
			if (UpgradeTemplate.CHBonusDamage.Shred > 0)
			{
				TotalUpgradeSummary.bIsShredModified = true;
				UpgradeTemplate.AddCHDamageModifierFn(UpgradeTemplate, tmp, 'Shred');
				TotalUpgradeSummary.DamageValue.Shred += tmp;
			}
		}
		// Issue #237 end
		if(UpgradeTemplate.AddHitChanceModifierFn != none)
		{
			VisInfo.TargetCover = CT_MAX;
			TotalUpgradeSummary.bIsAimModified = true;
			UpgradeTemplate.AddHitChanceModifierFn(UpgradeTemplate, VisInfo, tmp); // we only want the modifier for max cover
			TotalUpgradeSummary.Aim += tmp; // Issue #237, allow multiple upgrades to change the same stat
		}
		if (UpgradeTemplate.AddCritChanceModifierFn != None)
		{
			TotalUpgradeSummary.bIsCritModified = true;
			UpgradeTemplate.AddCritChanceModifierFn(UpgradeTemplate, tmp);
			TotalUpgradeSummary.Crit += tmp; // Issue #237, allow multiple upgrades to change the same stat
		}
		if(UpgradeTemplate.AdjustClipSizeFn != none)
		{
			TotalUpgradeSummary.bIsClipSizeModified = true;
			UpgradeTemplate.AdjustClipSizeFn(UpgradeTemplate, self, 0, tmp); // we only want the modifier, so pass 0 for current
			TotalUpgradeSummary.ClipSize += tmp; // Issue #237, allow multiple upgrades to change the same stat
		}
		if (UpgradeTemplate.FreeFireChance > 0)
		{
			TotalUpgradeSummary.bIsFreeFirePctModified = true;
			TotalUpgradeSummary.FreeFirePct += UpgradeTemplate.GetBonusAmountFn(UpgradeTemplate); // Issue #237, allow multiple upgrades to change the same stat
		}
		if (UpgradeTemplate.NumFreeReloads > 0)
		{
			TotalUpgradeSummary.bIsFreeReloadsModified = true;
			TotalUpgradeSummary.FreeReloads += UpgradeTemplate.GetBonusAmountFn(UpgradeTemplate); // Issue #237, allow multiple upgrades to change the same stat
		}
		if (UpgradeTemplate.BonusDamage.Damage > 0)
		{
			TotalUpgradeSummary.bIsMissDamageModified = true;
			TotalUpgradeSummary.MissDamage += UpgradeTemplate.GetBonusAmountFn(UpgradeTemplate); // Issue #237, allow multiple upgrades to change the same stat
		}
		if (UpgradeTemplate.FreeKillChance > 0)
		{
			TotalUpgradeSummary.bIsFreeKillPctModified = true;
			TotalUpgradeSummary.FreeKillPct += UpgradeTemplate.GetBonusAmountFn(UpgradeTemplate); // Issue #237, allow multiple upgrades to change the same stat
		}
	}

	XComHQ = XComGameState_HeadquartersXCom( `XCOMHISTORY.GetSingleGameStateObjectForClass( class'XComGameState_HeadquartersXCom', true ) );
	if (XComHQ != none)
	{
		AbilityTemplateMan = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();

		foreach XComHQ.TacticalTechBreakthroughs(ObjectRef)
		{
			BreakthroughTech = XComGameState_Tech(`XCOMHISTORY.GetGameStateForObjectID(ObjectRef.ObjectID));
			TechTemplate = BreakthroughTech.GetMyTemplate();

			if (TechTemplate.BreakthroughCondition != none && TechTemplate.BreakthroughCondition.MeetsCondition(self))
			{
				AbilityTemplate = AbilityTemplateMan.FindAbilityTemplate( TechTemplate.RewardName );
				foreach AbilityTemplate.AbilityTargetEffects( TargetEffect )
				{
					BonusDamage = X2Effect_BonusWeaponDamage( TargetEffect );
					if (BonusDamage != none)
					{
						TotalUpgradeSummary.bIsDamageModified = true;
						// Single Line for #371
						TotalUpgradeSummary.DamageValue.Damage += BonusDamage.BonusDmg;
					}
				}
			}
		}
	}
	// Single Line for #371 : Just for consistency!
	TotalUpgradeSummary.Damage = TotalUpgradeSummary.DamageValue.Damage;

	return TotalUpgradeSummary;
}

simulated function array<UISummary_ItemStat> GetUISummary_ItemBasicStats()
{
	local array<UISummary_ItemStat> Result;

	// TODO: @gameplay: Other stat functions and types 
	if (m_ItemTemplate.IsA('X2WeaponTemplate'))
	{
		Result = GetUISummary_WeaponStats();
	}
	else
	{
		Result = GetUISummary_DefaultStats();
	}
	
	return Result;
}

simulated function array<UISummary_ItemStat> GetUISummary_ItemSecondaryStats()
{
	// TODO: @gameplay: Other stat functions and types 
	if (m_ItemTemplate.IsA('X2WeaponTemplate'))
		return GetUISummary_WeaponUpgradeStats();
	else
		return GetUISummary_DefaultStats(); 
}

simulated function array<UISummary_ItemStat> GetUISummary_DefaultStats()
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Tech BreakthroughTech;
	local X2AbilityTemplateManager AbilityTemplateMan;
	local StateObjectReference ObjectRef;
	local X2TechTemplate TechTemplate;
	local X2AbilityTemplate AbilityTemplate;
	local X2Effect TargetEffect;
	local array<X2Effect_PersistentStatChange> StatChangeEffects;
	local X2Effect_PersistentStatChange StatChangeEffect;
	local StatChange Change;
	local array<UISummary_ItemStat> Stats; 
	local UISummary_ItemStat		Item; 
	local int Index, idx;
	local X2EquipmentTemplate EquipmentTemplate;
	local delegate<X2StrategyGameRulesetDataStructures.SpecialRequirementsDelegate> ShouldStatDisplayFn;

	EquipmentTemplate = X2EquipmentTemplate(m_ItemTemplate);

	if( EquipmentTemplate != None )
	{
		// Search XComHQ for any breakthrough techs which modify the stats on this item, and store those stat changes
		XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
		if (XComHQ != none)
		{
			AbilityTemplateMan = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();

			foreach XComHQ.TacticalTechBreakthroughs(ObjectRef)
			{
				BreakthroughTech = XComGameState_Tech(`XCOMHISTORY.GetGameStateForObjectID(ObjectRef.ObjectID));
				TechTemplate = BreakthroughTech.GetMyTemplate();

				if (TechTemplate.BreakthroughCondition != none && TechTemplate.BreakthroughCondition.MeetsCondition(self))
				{
					AbilityTemplate = AbilityTemplateMan.FindAbilityTemplate(TechTemplate.RewardName);
					foreach AbilityTemplate.AbilityTargetEffects(TargetEffect)
					{
						StatChangeEffect = X2Effect_PersistentStatChange(TargetEffect);
						if (StatChangeEffect != none)
						{
							StatChangeEffects.AddItem(StatChangeEffect);
						}
					}
				}
			}
		}

		for( Index = 0; Index < EquipmentTemplate.UIStatMarkups.Length; ++Index )
		{
			ShouldStatDisplayFn = EquipmentTemplate.UIStatMarkups[Index].ShouldStatDisplayFn;
			if (ShouldStatDisplayFn != None && !ShouldStatDisplayFn())
			{
				continue;
			}

			if( EquipmentTemplate.UIStatMarkups[Index].StatModifier != 0 || EquipmentTemplate.UIStatMarkups[Index].bForceShow )
			{
				// Start with the value from the stat markup
				Item.Label = EquipmentTemplate.UIStatMarkups[Index].StatLabel;
				Item.Value = string(EquipmentTemplate.UIStatMarkups[Index].StatModifier);

				// Then check all of the stat change effects from techs and add any appropriate modifiers
				foreach StatChangeEffects(StatChangeEffect)
				{
					for (idx = 0; idx < StatChangeEffect.m_aStatChanges.Length; ++idx)
					{
						Change = StatChangeEffect.m_aStatChanges[idx];
						if ((Change.StatType == EquipmentTemplate.UIStatMarkups[idx].StatType) && (Change.ModOp == MODOP_Addition))
						{
							Item.Value $= AddStatModifier(false, "", Change.StatAmount, eUIState_Good);
						}
					}
				}				
				
				Stats.AddItem(Item);
			}
		}
	}

	return Stats; 
}
simulated function array<UISummary_ItemStat> GetUISummary_WeaponStats(optional X2WeaponUpgradeTemplate PreviewUpgradeStats)
{
	local array<UISummary_ItemStat> Stats; 
	local UISummary_ItemStat		Item;
	local UIStatMarkup				StatMarkup;
	local WeaponDamageValue         DamageValue;
	local EUISummary_WeaponStats    UpgradeStats;
	local X2WeaponTemplate WeaponTemplate;
	local delegate<X2StrategyGameRulesetDataStructures.SpecialRequirementsDelegate> ShouldStatDisplayFn;
	local int Index;

	// Variables for Issue #237
	local int PreInt, PostInt;
	local EUIState ColorState;

	// Safety check: you need to be a weapon to use this. 
	WeaponTemplate = X2WeaponTemplate(m_ItemTemplate);
	if( WeaponTemplate == none ) 
		return Stats; 

	if(PreviewUpgradeStats != none) 
		UpgradeStats = GetUpgradeModifiersForUI(PreviewUpgradeStats);
	else
		UpgradeStats = GetUpgradeModifiersForUI(X2WeaponUpgradeTemplate(m_ItemTemplate));
		
	// Issue #237 start
	// Damage-----------------------------------------------------------------------
	if (!WeaponTemplate.bHideDamageStat)
	{
		Item.Label = class'XLocalizedData'.default.DamageLabel;
		GetBaseWeaponDamageValue(none, DamageValue);
		if (DamageValue.Damage == 0 && (UpgradeStats.bIsDamageModified || UpgradeStats.bIsSpreadModified))
		{
			if (UpgradeStats.bIsSpreadModified)
			{
				Item.Value = AddStatModifierSpread(false, "", UpgradeStats.DamageValue.Damage - UpgradeStats.DamageValue.Spread, UpgradeStats.DamageValue.Damage + UpgradeStats.DamageValue.Spread, eUIState_Good);
			}
			else
			{
				Item.Value = AddStatModifier(false, "", UpgradeStats.DamageValue.Damage, eUIState_Good);
			}
			Stats.AddItem(Item);
		}
		else if (DamageValue.Damage > 0)
		{
			// Trying to set this up in a single line of code is obnoxious, so I'm splitting it up
			PreInt = DamageValue.Damage;
			PostInt = DamageValue.Damage;
			ColorState = eUIState_Normal;
			if (DamageValue.Spread > 0 || DamageValue.PlusOne > 0)
			{
				PreInt -= DamageValue.Spread;
				PostInt += DamageValue.Spread + ((DamageValue.PlusOne > 0) ? 1 : 0);
			}
			if (UpgradeStats.bIsDamageModified)
			{
				PreInt += UpgradeStats.DamageValue.Damage;
				PostInt += UpgradeStats.DamageValue.Damage;
			}
			if (UpgradeStats.bIsSpreadModified)
			{
				PreInt -= UpgradeStats.DamageValue.Spread;
				PostInt += UpgradeStats.DamageValue.Spread;
			}

			// Call it good if the ending average is better than the starting value, bad otherwise
			if (((PreInt + PostInt) / 2) > DamageValue.Damage)
			{
				ColorState = eUIState_Good;
			}
			else if (((PreInt + PostInt) / 2) < DamageValue.Damage)
			{
				ColorState = eUIState_Bad;
			}

			if (PreInt != PostInt)
			{
				if (ColorState != eUIState_Normal)
				{
					Item.Value = AddStatModifierSpread(false, "", PreInt, PostInt, ColorState);
				}
				else
				{
					Item.Value = string(PreInt) $ "-" $ string(PostInt);
				}
			}
			else
			{
				if (ColorState != eUIState_Normal)
				{
					Item.Value = AddStatModifier(false, "", PreInt, ColorState);
				}
				else
				{
					Item.Value = string(PreInt);
				}
			}

			Stats.AddItem(Item);
		}
	}
	//TODO: Item.ValueState = bIsDamageModified ? eUIState_Good : eUIState_Normal;

	// Crit Damage-----------------------------------------------------------------------
	if (!WeaponTemplate.bHideDamageStat)
	{
		Item.Label = class'XLocalizedData'.default.CriticalDamageLabel;
		GetBaseWeaponDamageValue(none, DamageValue);
		if (DamageValue.Crit == 0 && UpgradeStats.bIsCritDamageModified)
		{
			Item.Value = AddStatModifier(false, "", UpgradeStats.DamageValue.Crit, eUIState_Good);
			Stats.AddItem(Item);
		}
		else if (DamageValue.Crit > 0)
		{
			Item.Value = string(DamageValue.Crit);

			if (UpgradeStats.bIsCritDamageModified)
			{
				Item.Value $= AddStatModifier(false, "", UpgradeStats.DamageValue.Crit, eUIState_Good);
			}
			Stats.AddItem(Item);
		}
	}
	// Issue #237 end

	// Clip Size --------------------------------------------------------------------
	if (m_ItemTemplate.ItemCat == 'weapon' && !WeaponTemplate.bHideClipSizeStat)
	{
		Item.Label = class'XLocalizedData'.default.ClipSizeLabel;
		if (PopulateWeaponStat(GetItemClipSize(), UpgradeStats.bIsClipSizeModified, UpgradeStats.ClipSize, Item))
			Stats.AddItem(Item);
	}

	// Crit -------------------------------------------------------------------------
	Item.Label = class'XLocalizedData'.default.CriticalChanceLabel;
	if (PopulateWeaponStat(GetItemCritChance(), UpgradeStats.bIsCritModified, UpgradeStats.Crit, Item, true))
		Stats.AddItem(Item);

	// Ensure that any items which are excluded from stat boosts show values that show up in the Soldier Header
	if (class'UISoldierHeader'.default.EquipmentExcludedFromStatBoosts.Find(m_ItemTemplate.DataName) == INDEX_NONE)
	{
		// Aim -------------------------------------------------------------------------
		Item.Label = class'XLocalizedData'.default.AimLabel;
		if (PopulateWeaponStat(GetItemAimModifier(), UpgradeStats.bIsAimModified, UpgradeStats.Aim, Item, true))
			Stats.AddItem(Item);
	}

	// Issue #237 start
	// Pierce -------------------------------------------------------------------------
	Item.Label = class'XLocalizedData'.default.PierceLabel;
	if (PopulateWeaponStat(GetItemPierceValue(), UpgradeStats.bIsPierceModified, UpgradeStats.DamageValue.Pierce, Item, false))
		Stats.AddItem(Item);
	// Pierce -------------------------------------------------------------------------
	Item.Label = class'XLocalizedData'.default.RuptureLabel;
	if (PopulateWeaponStat(GetItemRuptureValue(), UpgradeStats.bIsRuptureModified, UpgradeStats.DamageValue.Rupture, Item, false))
		Stats.AddItem(Item);
	// Shred -------------------------------------------------------------------------
	Item.Label = class'XLocalizedData'.default.ShredLabel;
	if (PopulateWeaponStat(GetItemShredValue(), UpgradeStats.bIsShredModified, UpgradeStats.DamageValue.Shred, Item, false))
		Stats.AddItem(Item);
	// Issue #237 end

	// Free Fire
	Item.Label = class'XLocalizedData'.default.FreeFireLabel;
	if (PopulateWeaponStat(0, UpgradeStats.bIsFreeFirePctModified, UpgradeStats.FreeFirePct, Item, true))
		Stats.AddItem(Item);

	// Free Reloads
	Item.Label = class'XLocalizedData'.default.FreeReloadLabel;
	if (PopulateWeaponStat(0, UpgradeStats.bIsFreeReloadsModified, UpgradeStats.FreeReloads, Item))
		Stats.AddItem(Item);

	// Miss Damage
	Item.Label = class'XLocalizedData'.default.MissDamageLabel;
	if (PopulateWeaponStat(0, UpgradeStats.bIsMissDamageModified, UpgradeStats.MissDamage, Item))
		Stats.AddItem(Item);

	// Free Kill
	Item.Label = class'XLocalizedData'.default.FreeKillLabel;
	if (PopulateWeaponStat(0, UpgradeStats.bIsFreeKillPctModified, UpgradeStats.FreeKillPct, Item, true))
		Stats.AddItem(Item);

	// Add any extra stats and benefits
	for (Index = 0; Index < WeaponTemplate.UIStatMarkups.Length; ++Index)
	{
		StatMarkup = WeaponTemplate.UIStatMarkups[Index];
		ShouldStatDisplayFn = StatMarkup.ShouldStatDisplayFn;
		if (ShouldStatDisplayFn != None && !ShouldStatDisplayFn())
		{
			continue;
		}

		if ((StatMarkup.StatModifier != 0 || StatMarkup.bForceShow)
			// Start Issue #237: Employ a heuristic to filter out the new stats we 
			// already got above in our patch. This isn't 100% accurate, but
			// more of a compatibility fix for stats that people have a reasonable
			// motivation to add manually due to the base game not handling them.
			// (Also, we accidentally doubled the UI shred display for grenades. Whoops.)
			&& StatMarkup.StatLabel != class'XLocalizedData'.default.ShredLabel
    		&& StatMarkup.StatLabel != class'XLocalizedData'.default.PierceLabel
			&& StatMarkup.StatLabel != class'XLocalizedData'.default.RuptureLabel
			// End Issue #237
			)
		{
			Item.Label = StatMarkup.StatLabel;
			Item.Value = string(StatMarkup.StatModifier) $ StatMarkup.StatUnit;
			Stats.AddItem(Item);
		}
	}

	return Stats;
}

simulated function bool PopulateWeaponStat(int Value, bool bIsStatModified, int UpgradeValue, out UISummary_ItemStat Item, optional bool bIsPercent)
{
	if (Value > 0)
	{
		if (bIsStatModified)
		{
			Item.Value = AddStatModifier(false, "", UpgradeValue, eUIState_Good, "", true);
			Item.Value $= string(Value) $ (bIsPercent ? "%" : "");
		}
		else
		{
			Item.Value = string(Value) $ (bIsPercent ? "%" : "");
		}
		return true;
	}
	else if (bIsStatModified)
	{
		Item.Value = AddStatModifier(false, "", UpgradeValue, eUIState_Good, (bIsPercent ? "%" : ""), false);
		return true;
	}

	return false;
}

simulated function array<UISummary_ItemStat> GetUISummary_AmmoStats()
{
	local X2ItemTemplate			SpecialAmmo;
	local array<UISummary_ItemStat> Stats;
	local UISummary_ItemStat		Item;

	// Safety check: you need to be a weapon to use this. 
	if( !m_ItemTemplate.IsA('X2WeaponTemplate') ) return Stats;

	// Ammo Type ----------------------------------------------------------------
	SpecialAmmo = GetLoadedAmmoTemplate(none);

	if( SpecialAmmo != none )
	{
		Item.Label = class'XLocalizedData'.default.AmmoTypeHeader;
		Item.LabelStyle = eUITextStyle_Tooltip_H1;
		Stats.AddItem(Item);

		Item.Label = SpecialAmmo.GetItemFriendlyName();
		Item.LabelStyle = eUITextStyle_Tooltip_H2; 

		Item.Value = SpecialAmmo.GetItemBriefSummary();
		Item.ValueStyle = eUITextStyle_Tooltip_Body; 

		Stats.AddItem(Item);
	}
	// -------------------------------------------------------------------------

	return Stats;
}

simulated function array<UISummary_ItemStat> GetUISummary_WeaponUpgradeStats()
{
	local array<X2WeaponUpgradeTemplate> Upgrades; 
	local X2WeaponUpgradeTemplate UpgradeTemplate; 
	local array<UISummary_ItemStat> Stats; 
	local UISummary_ItemStat Item;
	local int iUpgrade; 

	Upgrades = GetMyWeaponUpgradeTemplates(); 

	if( Upgrades.length > 0 )
	{
		Item.Label = class'XLocalizedData'.default.UpgradesHeader; 
		Item.LabelStyle = eUITextStyle_Tooltip_H1; 
		Stats.AddItem(Item); 
	}

	for( iUpgrade = 0; iUpgrade < Upgrades.length; iUpgrade++ )
	{
		UpgradeTemplate = Upgrades[iUpgrade];
		
		Item.Label = UpgradeTemplate.GetItemFriendlyName();
		Item.LabelStyle = eUITextStyle_Tooltip_H2; 

		Item.Value = GetUpgradeEffectForUI(UpgradeTemplate);
		Item.ValueStyle = eUITextStyle_Tooltip_Body; 

		Stats.AddItem(Item);
	}

	return Stats; 
}

simulated function array<UISummary_TacaticalText> GetUISummary_TacticalTextAbilities()
{
	local bool bIsIn3D;
	local X2EquipmentTemplate       EquipmentTemplate; 
	local X2AbilityTemplateManager  AbilityTemplateManager;
	local X2AbilityTemplate         AbilityTemplate; 
	local name                      AbilityName;
	local UISummary_Ability        UISummaryAbility; 
	local UISummary_TacaticalText  Data; 
	local array<UISummary_TacaticalText> Items; 

	EquipmentTemplate = X2EquipmentTemplate(m_ItemTemplate);
	if( EquipmentTemplate == none ) return Items;  //Empty.

	bIsIn3D = `SCREENSTACK.GetCurrentScreen().bIsIn3D;

	AbilityTemplateManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
	foreach EquipmentTemplate.Abilities(AbilityName)
	{
		AbilityTemplate = AbilityTemplateManager.FindAbilityTemplate(AbilityName);
		if( AbilityTemplate != none  && AbilityTemplate.bDisplayInUITacticalText )
		{
			UISummaryAbility = AbilityTemplate.GetUISummary_Ability();
			Data.Name = class'UIUtilities_Text'.static.AddFontInfo(UISummaryAbility.Name, bIsIn3D, true, true);
			Data.Description = class'UIUtilities_Text'.static.AddFontInfo(UISummaryAbility.Description, bIsIn3D, false);
			Data.Icon = UISummaryAbility.Icon;
			Items.AddItem(Data);
		}
	}

	return Items; 
}

simulated function array<UISummary_TacaticalText> GetUISummary_TacticalTextUpgrades()
{
	local array<X2WeaponUpgradeTemplate> Upgrades; 
	local X2WeaponUpgradeTemplate UpgradeTemplate; 
	local UISummary_TacaticalText Data; 
	local array<UISummary_TacaticalText> Items;
	local int iUpgrade; 
	local array<string> UpgradeIcons; 

	Upgrades = GetMyWeaponUpgradeTemplates(); 

	for( iUpgrade = 0; iUpgrade < Upgrades.length; iUpgrade++ )
	{
		UpgradeTemplate = Upgrades[iUpgrade];
		
		Data.Name = UpgradeTemplate.GetItemFriendlyName(); 
		Data.Description = UpgradeTemplate.GetItemBriefSummary(); 

		UpgradeIcons = UpgradeTemplate.GetAttachmentInventoryCategoryImages(self);
		if( UpgradeIcons.length > 0 )
			Data.Icon = UpgradeIcons[0];
		else
			Data.Icon = "";

		Items.AddItem(Data);
	}

	return Items; 
}


simulated function array<UISummary_TacaticalText> GetUISummary_TacticalText()
{
	local bool bIsIn3D;
	local int FontSize;
	local string TacticalText;
	local EUIState ColorState;
	local UISummary_TacaticalText Data; 
	local array<UISummary_TacaticalText> Items;

	ColorState = eUIState_Normal;
	bIsIn3D = `SCREENSTACK.GetCurrentScreen().bIsIn3D;
	FontSize = bIsIn3D ? class'UIUtilities_Text'.const.BODY_FONT_SIZE_3D : class'UIUtilities_Text'.const.BODY_FONT_SIZE_2D;

	if(GetMyTemplate() != none)
		TacticalText = GetMyTemplate().GetItemTacticalText();

	if( TacticalText == "" )
	{
		ColorState = eUIState_Bad;
		TacticalText = "DEBUG: @Design: Missing TacticalText in '" $ GetMyTemplateName() $ "' template."; 
	}

	Data.Description = class'UIUtilities_Text'.static.GetColoredText(TacticalText, ColorState, FontSize);
	Items.AddItem(Data);

	return Items; 
}

//---------------------------------------------------------------------------------------
function OnItemBuilt(XComGameState NewGameState)
{
	if (GetMyTemplate().OnBuiltFn != none)
	{
		GetMyTemplate().OnBuiltFn(NewGameState, self);
	}
}

//---------------------------------------------------------------------------------------
function bool IsNeededForGoldenPath()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Objective ObjectiveState;
	local XComGameState_Tech TechState;
	local X2ObjectiveTemplate ObjTemplate;
	local name TechName;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	foreach History.IterateByClassType(class'XComGameState_Objective', ObjectiveState)
	{
		if(ObjectiveState.ObjState < eObjectiveState_InProgress)
		{
			ObjTemplate = ObjectiveState.GetMyTemplate();
			if (ObjTemplate != none)
			{
				if (ObjTemplate.AssignmentRequirements.RequiredItems.Find(GetMyTemplateName()) != INDEX_NONE)
				{
					return true;
				}

				foreach ObjTemplate.AssignmentRequirements.RequiredTechs(TechName)
				{
					foreach History.IterateByClassType(class'XComGameState_Tech', TechState)
					{
						if (!XComHQ.TechIsResearched(TechState.GetReference()) && TechState.GetMyTemplateName() == TechName &&
							TechState.GetMyTemplate().Requirements.RequiredItems.Find(GetMyTemplateName()) != INDEX_NONE)
						{
							return true;
						}
					}
				}
			}
		}

		if(ObjectiveState.ObjState < eObjectiveState_Completed)
		{
			ObjTemplate = ObjectiveState.GetMyTemplate();
			if (ObjTemplate != none)
			{
				if (ObjTemplate.CompletionRequirements.RequiredItems.Find(GetMyTemplateName()) != INDEX_NONE)
				{
					return true;
				}

				foreach ObjTemplate.CompletionRequirements.RequiredTechs(TechName)
				{
					foreach History.IterateByClassType(class'XComGameState_Tech', TechState)
					{
						if (!XComHQ.TechIsResearched(TechState.GetReference()) && TechState.GetMyTemplateName() == TechName &&
							TechState.GetMyTemplate().Requirements.RequiredItems.Find(GetMyTemplateName()) != INDEX_NONE)
						{
							return true;
						}
					}
				}
			}
		}
	}


	return false;
}

static function FilterOutGoldenPathItems(out array<StateObjectReference> ItemsToFilter)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Objective ObjectiveState;
	local XComGameState_Tech TechState;
	local X2ObjectiveTemplate ObjTemplate;
	local name TechName;

	local name ItemTemplateName;
	local array<name> ItemTemplatesToFilter;

	local int i;
	local XComGameState_Item ItemState;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	foreach History.IterateByClassType(class'XComGameState_Objective', ObjectiveState)
	{
		if(ObjectiveState.ObjState < eObjectiveState_InProgress)
		{
			ObjTemplate = ObjectiveState.GetMyTemplate();
			if (ObjTemplate != none)
			{
				foreach ObjTemplate.AssignmentRequirements.RequiredItems(ItemTemplateName)
				{
					if(ItemTemplatesToFilter.Find(ItemTemplateName) == INDEX_NONE)
						ItemTemplatesToFilter.AddItem(ItemTemplateName);
				}

				foreach ObjTemplate.AssignmentRequirements.RequiredTechs(TechName)
				{
					foreach History.IterateByClassType(class'XComGameState_Tech', TechState)
					{
						if (!XComHQ.TechIsResearched(TechState.GetReference()) && TechState.GetMyTemplateName() == TechName)
						{
							foreach TechState.GetMyTemplate().Requirements.RequiredItems(ItemTemplateName)
							{
								if(ItemTemplatesToFilter.Find(ItemTemplateName) == INDEX_NONE)
									ItemTemplatesToFilter.AddItem(ItemTemplateName);
							}
						}
					}
				}
			}
		}

		if(ObjectiveState.ObjState < eObjectiveState_Completed)
		{
			ObjTemplate = ObjectiveState.GetMyTemplate();
			if (ObjTemplate != none)
			{
				foreach ObjTemplate.CompletionRequirements.RequiredItems(ItemTemplateName)
				{
					if(ItemTemplatesToFilter.Find(ItemTemplateName) == INDEX_NONE)
						ItemTemplatesToFilter.AddItem(ItemTemplateName);
				}

				foreach ObjTemplate.CompletionRequirements.RequiredTechs(TechName)
				{
					foreach History.IterateByClassType(class'XComGameState_Tech', TechState)
					{
						if (!XComHQ.TechIsResearched(TechState.GetReference()) && TechState.GetMyTemplateName() == TechName)
						{
							foreach TechState.GetMyTemplate().Requirements.RequiredItems(ItemTemplateName)
							{
								if(ItemTemplatesToFilter.Find(ItemTemplateName) == INDEX_NONE)
									ItemTemplatesToFilter.AddItem(ItemTemplateName);
							}
						}
					}
				}
			}
		}
	}


	for(i = ItemsToFilter.Length - 1; i >= 0; i--)
	{
		ItemState = XComGameState_Item(History.GetGameStateForObjectID(ItemsToFilter[i].ObjectID));
		if(ItemTemplatesToFilter.Find(ItemState.GetMyTemplateName()) != INDEX_NONE)
			ItemsToFilter.Remove(i, 1);
	}
}

function bool ShouldDisplayWeaponAndAmmo()
{
	local X2WeaponTemplate WeaponTemplate;
	local bool bDisplayWeaponAndAmmo;

	bDisplayWeaponAndAmmo = false;
	WeaponTemplate = X2WeaponTemplate(m_ItemTemplate);

	if( WeaponTemplate != None )
	{
		bDisplayWeaponAndAmmo = WeaponTemplate.bDisplayWeaponAndAmmo;
	}

	return bDisplayWeaponAndAmmo;
}

function bool IsMissionObjectiveItem()
{
	local X2ItemTemplate ItemTemplate;

	ItemTemplate = GetMyTemplate();

	if (ItemTemplate.ItemCat == 'goldenpath' || ItemTemplate.ItemCat == 'quest' || (ItemTemplate.IsObjectiveItemFn != none && ItemTemplate.IsObjectiveItemFn()))
		return true;

	return false;
}

// Start Issue #93
/// HL-Docs: feature:OverrideNumUpgradeSlots; issue:93; tags:strategy
/// This event allows mods to modify the number of upgrade slots for each individual item state.
/// 
/// ```event
/// EventID: OverrideNumUpgradeSlots,
/// EventData: [inout int NumUpgradeSlots],
///	EventSource: XComGameState_Item (ItemState),
/// NewGameState: none
/// ```
function int GetNumUpgradeSlots()
{
	local XComLWTuple Tuple;

	Tuple = new class'XComLWTuple';
	Tuple.Id = 'OverrideNumUpgradeSlots';
	Tuple.Data.Add(1);
	Tuple.Data[0].kind = XComLWTVInt;
	Tuple.Data[0].i = GetMyTemplate().GetNumUpgradeSlots();

	`XEVENTMGR.TriggerEvent('OverrideNumUpgradeSlots', Tuple, self);

	return Tuple.Data[0].i;
}
// End Issue #93

// Issue #260 start
/// HL-Docs: feature:CanWeaponApplyUpgrade; issue:260; tags:strategy
/// This function will be used to cycle through DLCInfos that will allow mods to check generally
/// whether or not a weapon is compatible with an upgrade. X2WeaponUpgradeTemplate::CanApplyUpgradeToWeapon
/// still exists as the "can this upgrade be applied to this weapon RIGHT NOW?"
///
/// * The best use case for this is to bar your weapon from applying upgrades that don't meet your criteria,
///   without having to edit those upgrades directly.
/// * Note that this check is /in addition to/, and not /in lieu of/, CanApplyUpgradeToWeapon. This means
///   you cannot use it to override that function's return value.
function bool CanWeaponApplyUpgrade(X2WeaponUpgradeTemplate UpgradeTemplate)
{
	local int i;
	local array<X2DownloadableContentInfo> DLCInfos;
	
	DLCInfos = `ONLINEEVENTMGR.GetDLCInfos(false);
	for(i = 0; i < DLCInfos.Length; ++i)
	{
		if (!DLCInfos[i].CanWeaponApplyUpgrade(self, UpgradeTemplate))
		{
			return false;
		}
	}
	return true;
}
// Issue #260 end

DefaultProperties
{
	Quantity=1
}
