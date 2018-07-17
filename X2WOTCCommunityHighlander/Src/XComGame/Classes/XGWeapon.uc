//---------------------------------------------------------------------------------------
//  FILE:    XGWeapon.uc  
//  PURPOSE: Visualizer class for items / weapons in X2
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XGWeapon extends XGInventoryItem
	dependson(XGTacticalGameCoreData, XGTacticalGameCoreNativeBase)
	native(Weapon);

var protectedwrite TWeaponAppearance m_kAppearance;
var private XComPatternsContent PatternsContent; 
var transient int NumPossibleTints;

// HAX: This is needed because the UI depends on CreateEntity function, but we need to provide it
//      a state to load attachments from so we can visualize weapon updates without submitting game states
//      Using a hacky member variable because I can't override CreateEntity -sbatista
var private XComGameState_Item InternalWeaponState;
var XComUnitPawn UnitPawn; // strategy doesn't have XGUnit, so this can track our owner
var array<ActorComponent> PawnAttachments;

simulated event PostBeginPlay()
{
	super.PostBeginPlay();
}

simulated function Init(optional XComGameState_Item ItemState=none)
{
	CreateEntity(ItemState);
}

simulated function Actor CreateEntity(optional XComGameState_Item ItemState=none)
{
	//  this is called by the native Init function
	local XComWeapon kNewWeapon;
	local XComWeapon Template;
	local Actor kOwner;	
	local array<WeaponAttachment> WeaponAttachments;
	local StaticMeshComponent MeshComp;
	local SkeletalMeshComponent SkelMeshComp, WeaponMesh, PawnMesh;
	local XComGameState_Unit UnitState;
	local XComGameStateHistory History;
	local XComGameState_Item AppearanceWeapon;
	local X2WeaponTemplate WeaponTemplate;
	local TWeaponAppearance WeaponAppearance;
	local string strArchetype;
	local int i;

	if(Role == ROLE_Authority)
	{
		InternalWeaponState = ItemState;
		History = `XCOMHISTORY;
		if(InternalWeaponState == none)
		{
			InternalWeaponState = XComGameState_Item(History.GetGameStateForObjectID(ObjectID));
		}

		`assert(InternalWeaponState != none);     //  XGWeapon should not exist without an item state at this point
		
		if (UnitPawn != none)
			kOwner = UnitPawn;
		else
		{
			m_kOwner = XGUnit(History.GetVisualizer(ItemState.OwnerStateObject.ObjectID)); //Attempt to locate the owner of this item
			kOwner = m_kOwner != none ? m_kOwner.GetPawn() : none;
		}
		
		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(InternalWeaponState.OwnerStateObject.ObjectID));
		WeaponTemplate = X2WeaponTemplate(InternalWeaponState.GetMyTemplate());
		if (WeaponTemplate != none)
		{
			strArchetype = WeaponTemplate.DetermineGameArchetypeForUnit(InternalWeaponState, UnitState, XComHumanPawn(kOwner).m_kAppearance);
			Template = XComWeapon(`CONTENT.RequestGameArchetype(strArchetype));
		}
		WeaponAttachments = InternalWeaponState.GetWeaponAttachments();

		if (Template == none)           //  if the weapon is a cosmetic unit, for example
			return none;

 		kNewWeapon = Spawn(Template.Class, kOwner,,,,Template);
		
		WeaponMesh = SkeletalMeshComponent(kNewWeapon.Mesh);

		if (XComUnitPawn(kOwner) != none)
			PawnMesh = XComUnitPawn(kOwner).Mesh;
		for (i = 0; i < WeaponAttachments.Length; ++i)
		{
			if (WeaponAttachments[i].AttachToPawn && PawnMesh == none)
				continue;

			if (WeaponAttachments[i].LoadedObject != none)
			{
				if( InternalWeaponState.CosmeticUnitRef.ObjectID < 1 ) //Don't attach items that have a cosmetic unit associated with them
				{
					if (WeaponAttachments[i].LoadedObject.IsA('StaticMesh'))
					{
						MeshComp = new(kNewWeapon) class'StaticMeshComponent';
						MeshComp.SetStaticMesh(StaticMesh(WeaponAttachments[i].LoadedObject));
						MeshComp.bCastStaticShadow = false;
						if (WeaponAttachments[i].AttachToPawn)
						{
							PawnMesh.AttachComponentToSocket(MeshComp, WeaponAttachments[i].AttachSocket);
							PawnAttachments.AddItem(MeshComp);
						}
						else
						{
							WeaponMesh.AttachComponentToSocket(MeshComp, WeaponAttachments[i].AttachSocket);
						}					
					}
					else if (WeaponAttachments[i].LoadedObject.IsA('SkeletalMesh'))
					{
						SkelMeshComp = new(kNewWeapon) class'SkeletalMeshComponent';
						SkelMeshComp.SetSkeletalMesh(SkeletalMesh(WeaponAttachments[i].LoadedObject));
						SkelMeshComp.bCastStaticShadow = false;
						if (WeaponAttachments[i].AttachToPawn)
						{
							PawnMesh.AttachComponentToSocket(SkelMeshComp, WeaponAttachments[i].AttachSocket);
							PawnAttachments.AddItem(SkelMeshComp);
						}
						else
						{
							WeaponMesh.AttachComponentToSocket(SkelMeshComp, WeaponAttachments[i].AttachSocket);
						}					
					}
				}
			}
		}

		kNewWeapon.SetGameData(self);

		//Physics must be set to none, the weapon entity is purely visual until it gets dropped.
		if(kNewWeapon.Physics != PHYS_None)
		{
			kNewWeapon.SetPhysics(PHYS_None);
		}

		m_kEntity = kNewWeapon;

		//Make sure we initialize with the correct flashlight state
		UpdateFlashlightState();

		if(ItemState != none)
		{
			// Start with the default appearance on this item
			WeaponAppearance = ItemState.WeaponAppearance;
				
			if (UnitState != none)
			{				
				// Get the unit's primary weapon appearance
				AppearanceWeapon = UnitState.GetPrimaryWeapon();
				if (AppearanceWeapon != none)
				{
					// If the primary weapon exists, set it as the default
					WeaponAppearance = AppearanceWeapon.WeaponAppearance;

					// But if this item is a weapon which uses armor appearance data, save the tint and pattern from the unit instead
					if (WeaponTemplate != none && WeaponTemplate.bUseArmorAppearance)
					{
						WeaponAppearance.iWeaponTint = UnitState.kAppearance.iArmorTint;
						WeaponAppearance.nmWeaponPattern = UnitState.kAppearance.nmPatterns;
					}
					else
					{
						// If not, check to see if the primary tints from the unit. If it does, grab the secondary weapon appearance instead.
						WeaponTemplate = X2WeaponTemplate(AppearanceWeapon.GetMyTemplate());
						if (WeaponTemplate != none && WeaponTemplate.bUseArmorAppearance)
						{
							AppearanceWeapon = UnitState.GetSecondaryWeapon();
							WeaponAppearance = AppearanceWeapon.WeaponAppearance;
						}
					}
				}
			}

			SetAppearance(WeaponAppearance);
		}

		InternalWeaponState = None;
	}

	return kNewWeapon;
}

// Logic mirrored from XComHumanPawn.uc
simulated function SetAppearance( const out TWeaponAppearance kAppearance, optional bool bRequestContent=true )
{
	m_kAppearance = kAppearance;
	if (bRequestContent)
	{
		RequestFullPawnContent();
	}
}

simulated private function RequestFullPawnContent()
{
	local int i;
	local MeshComponent MeshComp, AttachedComponent;
	local XComLinearColorPalette Palette;
	local X2BodyPartTemplate PartTemplate;
	local X2BodyPartTemplateManager PartManager;
	
	PartManager = class'X2BodyPartTemplateManager'.static.GetBodyPartTemplateManager();

	PartTemplate = PartManager.FindUberTemplate(string('Patterns'), m_kAppearance.nmWeaponPattern);

	if (PartTemplate != none)
	{
		PatternsContent = XComPatternsContent(`CONTENT.RequestGameArchetype(PartTemplate.ArchetypeName, self, none, false));
	}
	else
	{
		PatternsContent = none;
	}

	NumPossibleTints = 0;
	Palette = `CONTENT.GetColorPalette(ePalette_ArmorTint);
	NumPossibleTints = Palette.Entries.Length;

	if(XComWeapon(m_kEntity) != none)
	{
		MeshComp = XComWeapon(m_kEntity).Mesh;
		UpdateMaterials(MeshComp);
	}

	if (SkeletalMeshComponent(MeshComp) != none)
	{	
		for(i = 0; i < SkeletalMeshComponent(MeshComp).Attachments.Length; ++i)
		{
			AttachedComponent = MeshComponent(SkeletalMeshComponent(MeshComp).Attachments[i].Component);
			if(AttachedComponent != none)
			{
				UpdateMaterials(AttachedComponent);
			}
		}
	}
}

simulated private function UpdateMaterials(MeshComponent MeshComp)
{
	local int i;
	local MaterialInterface Mat, ParentMat;
	local MaterialInstanceConstant MIC, ParentMIC, NewMIC;
	
	if (MeshComp != none)
	{
		for (i = 0; i < MeshComp.GetNumElements(); ++i)
		{
			Mat = MeshComp.GetMaterial(i);
			MIC = MaterialInstanceConstant(Mat);

			// It is possible for there to be MITVs in these slots, so check
			if (MIC != none)
			{
				// If this is not a child MIC, make it one. This is done so that the material updates below don't stomp
				// on each other between units.
				if (InStr(MIC.Name, "MaterialInstanceConstant") == INDEX_NONE)
				{
					NewMIC = new (self) class'MaterialInstanceConstant';
					NewMIC.SetParent(MIC);
					MeshComp.SetMaterial(i, NewMIC);
					MIC = NewMIC;
				}
				
				ParentMat = MIC.Parent;
				while (!ParentMat.IsA('Material'))
				{
					ParentMIC = MaterialInstanceConstant(ParentMat);
					if (ParentMIC != none)
						ParentMat = ParentMIC.Parent;
					else
						break;
				}

				UpdateWeaponMaterial(MeshComp, MIC);
			}
		}
	}	
}

// Logic largely based off of UpdateArmorMaterial in XComHumanPawn
simulated function UpdateWeaponMaterial(MeshComponent MeshComp, MaterialInstanceConstant MIC)
{
	local XComLinearColorPalette Palette;
	local LinearColor PrimaryTint;
	local LinearColor SecondaryTint;

	Palette = `CONTENT.GetColorPalette(ePalette_ArmorTint);
	if (Palette != none)
	{
		if(m_kAppearance.iWeaponTint != INDEX_NONE)
		{
			PrimaryTint = Palette.Entries[m_kAppearance.iWeaponTint].Primary;
			MIC.SetVectorParameterValue('Primary Color', PrimaryTint);
		}
		if(m_kAppearance.iWeaponDeco != INDEX_NONE)
		{
			SecondaryTint = Palette.Entries[m_kAppearance.iWeaponDeco].Secondary;
			MIC.SetVectorParameterValue('Secondary Color', SecondaryTint);
		}
	}
	
	//Pattern Addition 2015-5-4 Chang You Wong
	if(PatternsContent != none && PatternsContent.Texture != none)
	{		
		//For Optimization, we want to fix the SetStaticSwitchParameterValueAndReattachShader function
		//When that happens we need to change the relevant package back to using static switches
		//SoldierArmorCustomizable_TC  M_Master_PwrdArm_TC  WeaponCustomizable_TC
		//MIC.SetStaticSwitchParameterValueAndReattachShader('Use Pattern', true, MeshComp);
		MIC.SetScalarParameterValue('PatternUse', 1);		
		MIC.SetTextureParameterValue('Pattern', PatternsContent.Texture);// .ReferencedObjects[0]));
	}
	else
	{
		//Same optimization as above
		//MIC.SetStaticSwitchParameterValueAndReattachShader('Use Pattern', false, MeshComp);
		MIC.SetScalarParameterValue('PatternUse', 0);
		MIC.SetTextureParameterValue('Pattern', none);
	}
}

simulated function Actor CreateEntityFromWeaponState(XComGameState_Item WeaponState)
{
	//Destroy the former entity and make a new one
	m_kEntity.Destroy(); 
	InternalWeaponState = WeaponState;
	m_kEntity = CreateEntity(WeaponState);

	//Physics must be set to none, the weapon entity is purely visual until it gets dropped.
	if(m_kEntity.Physics != PHYS_None)
	{
		m_kEntity.SetPhysics(PHYS_None);
	}

	return m_kEntity;
}

simulated event XComWeapon GetEntity()
{
	return XComWeapon(m_kEntity);
}

event Destroyed()
{
	local XGWeapon VisualizerCheck;
	local SkeletalMeshComponent PawnMesh;
	local int i;

	m_kEntity.SetHidden(true);
	m_kEntity.Destroy();

	if( UnitPawn != None )
	{
		PawnMesh = UnitPawn.Mesh;

		if( PawnMesh != None )
		{
			for( i = 0; i < PawnAttachments.Length; ++i )
			{
				PawnMesh.DetachComponent(PawnAttachments[i]);
			}
			PawnAttachments.Length = 0;
		}
	}


	//Clear us out of the visualizer map kept on the history. But only if we are the current entry for this object ID!
	VisualizerCheck = XGWeapon(`XCOMHISTORY.GetVisualizer(ObjectID));
	if(VisualizerCheck == self)
	{
		`XCOMHISTORY.SetVisualizer(ObjectID, none);
	}

	super.Destroyed();
}

simulated function UpdateFlashlightState()
{
	local ETimeOfDay CurrentTOD;
	local XComGameState_Unit UnitState;
	local XComGameState_BattleData BattleData;
	local PlotDefinition PlotDef;
	local PlotTypeDefinition PlotTypeDef;
	local bool FlashlightOn;

	if (m_kOwner == None)
		return;

	//If the unit is concealed, turn flashlight off.
	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(m_kOwner.ObjectID));
	if (UnitState.IsConcealed())
	{
		FlashlightOn = false;
	}
	else
	{
		//Decide based on time-of-day otherwise.
		CurrentTOD = `ENVLIGHTINGMGR.arrEnvironmentLightingDefs[`ENVLIGHTINGMGR.currentMapIdx].ETimeOfDay;
		if (CurrentTOD == eTimeOfDay_Night)
			FlashlightOn = true;
		else
		{
			BattleData = XComGameState_BattleData( `XCOMHISTORY.GetSingleGameStateObjectForClass( class'XComGameState_BattleData', true ) );

			if ((BattleData != none) && (`TACTICALRULES != none))
			{
				PlotDef = `PARCELMGR.GetPlotDefinition(BattleData.MapData.PlotMapName);
				PlotTypeDef = `PARCELMGR.GetPlotTypeDefinition(PlotDef.strType);
				FlashlightOn = PlotTypeDef.FlashlightsIgnoreTOD;
			}
			else
			{
				FlashlightOn = false;
			}
		}
	}

	SetFlashlightState(FlashlightOn);
}


simulated function SetFlashlightState(bool FlashlightEnabled)
{
	local XComWeapon WeaponEnt;
	local SkeletalMeshComponent WeaponMesh;
	local ParticleSystemComponent L;
	local int i;

	WeaponEnt = XComWeapon(m_kEntity);
	if (WeaponEnt == None)
		return;

	WeaponMesh = SkeletalMeshComponent(WeaponEnt.Mesh);
	if (WeaponMesh == None)
		return;

	if ((`STRATEGYRULES != None) && FlashlightEnabled) // No flashlights in strategy
		return;

	//Iterate through attachments, finding any particle systems attached to the FlashLight socket.
	for (i = 0; i < WeaponMesh.Attachments.Length; ++i)
	{
		if (WeaponMesh.Attachments[i].SocketName == 'FlashLight')
		{
			L = ParticleSystemComponent(WeaponMesh.Attachments[i].Component);
			if (L == None)
				continue;

			//This is ugly, but it's reliable.
			//(Calling L.DeactivateSystem will sometimes do nothing, and sometimes cause the component to be removed.)
			L.SetHidden(!FlashlightEnabled);
			L.SetScale(FlashlightEnabled?1.0f:0.0f);

		}
	}
}


// MHU - This is an event so that C++ can query any script-side overloading on the weapon range.
simulated event float LongRange()
{
	//  @TODO gameplay - this should be asked of the item state, not the xgweapon

	local XComGameState_Item Item;
	local X2WeaponTemplate WeaponTemplate;

	Item = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(ObjectID));
	WeaponTemplate = X2WeaponTemplate(Item.GetMyTemplate());

	return WeaponTemplate.iRange >= 0 ? `METERSTOUNITS(WeaponTemplate.iRange) : WeaponTemplate.iRange;
}

simulated function int GetRemainingAmmo()
{
	//  @TODO gameplay - this should be asked of the item state, not the xgweapon

	local XComGameState_Item Item;

	Item = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(ObjectID));
	
	return Item.Ammo;
}

//  This is NOT to be used to replace CreateEntity, this is for outside systems that need a dummy lookalike of the weapon
simulated function DecorateWeaponMesh(SkeletalMeshComponent WeaponMesh)   // this would be CONST if it were native - we do not want to change ANYTHING on the XGWeapon
{
	local XComGameState_Item OurWeapon;
	local MeshComponent AttachedComponent;
	local array<WeaponAttachment> WeaponAttachments;
	local StaticMeshComponent StaticMeshComp;
	local SkeletalMeshComponent SkelMeshComp;
	local int i;

	if (WeaponMesh != none)
	{
		OurWeapon = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(ObjectID));
		`assert(OurWeapon != none);
		WeaponAttachments = OurWeapon.GetWeaponAttachments();
		for (i = 0; i < WeaponAttachments.Length; ++i)
		{
			//  don't attach things to the pawn for this function
			if (WeaponAttachments[i].AttachToPawn)
				continue;

			if (WeaponAttachments[i].LoadedObject != none)
			{
				if( OurWeapon.CosmeticUnitRef.ObjectID < 1 ) //Don't attach items that have a cosmetic unit associated with them
				{
					if (WeaponAttachments[i].LoadedObject.IsA('StaticMesh'))
					{
						StaticMeshComp = new(WeaponMesh) class'StaticMeshComponent';
						StaticMeshComp.SetStaticMesh(StaticMesh(WeaponAttachments[i].LoadedObject));
						StaticMeshComp.bCastStaticShadow = false;
						WeaponMesh.AttachComponentToSocket(StaticMeshComp, WeaponAttachments[i].AttachSocket);
					}
					else if (WeaponAttachments[i].LoadedObject.IsA('SkeletalMesh'))
					{
						SkelMeshComp = new(WeaponMesh) class'SkeletalMeshComponent';
						SkelMeshComp.SetSkeletalMesh(SkeletalMesh(WeaponAttachments[i].LoadedObject));
						SkelMeshComp.bCastStaticShadow = false;
						WeaponMesh.AttachComponentToSocket(SkelMeshComp, WeaponAttachments[i].AttachSocket);
					}
				}
			}
		}

		UpdateMaterials(WeaponMesh);
	
		for(i = 0; i < WeaponMesh.Attachments.Length; ++i)
		{
			AttachedComponent = MeshComponent(WeaponMesh.Attachments[i].Component);
			if(AttachedComponent != none)
			{
				UpdateMaterials(AttachedComponent);
			}
		}
	}
}

//------------------------------------------------------------------------------------------------

defaultproperties
{	
}
