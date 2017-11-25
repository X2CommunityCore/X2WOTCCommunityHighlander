//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIUtilities_Image.uc
//  AUTHOR:  bsteiner 
//  PURPOSE: Container of static helper functions that serve as lookup tables for UI 
//           icon labels and image helpers. 
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIUtilities_Image extends Object;

const DynamicImagePrefix = "img:///";

const FacilityStatus_Health			= "img:///gfxComponents.facility_health_icon";
const FacilityStatus_Power			= "img:///gfxComponents.facility_power_icon";
const FacilityStatus_Staff			= "img:///UILibrary_StrategyImages.facility_staff_icon";
const FacilityStatus_Staff_Empty	= "img:///UILibrary_StrategyImages.facility_staff_icon_empty";
const FacilityStatus_Staff_BG		= "img:///UILibrary_StrategyImages.facility_staff_icon_bg";
const PersonalCombatSim_Empty		= "img:///UILibrary_Common.implants_empty";
const PersonalCombatSim_Locked		= "img:///UILibrary_Common.implants_locked";
const SquadSelect_LockedUtilitySlot = "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_Lock";
const SquadSelect_BlockedUtilitySlot = "img:///UILibrary_StrategyImages.X2InventoryIcons.Inv_Block";

const ObjectivesListCounter_Civilians_Available = "img:///UILibrary_Common.objectives_civilian_available";
const ObjectivesListCounter_Civilians_Dead		= "img:///UILibrary_Common.objectives_civilian_dead";
const ObjectivesListCounter_Civilians_Rescued	= "img:///UILibrary_Common.objectives_civilian_rescued";

const ObjectivesListCounter_Evidence_Available = "img:///UILibrary_Common.objectives_evidence_available";
const ObjectivesListCounter_Evidence_Destroyed = "img:///UILibrary_Common.objectives_evidence_destroyed";
const ObjectivesListCounter_Evidence_Recovered = "img:///UILibrary_Common.objectives_evidence_recovered";

// these are paths, they will have "img:///" prepended to them automatically. Otherwise the
// gameplay systems need to have knowledge of the UI specific image formatting
const TargetIcon_ACV_Panel		= "UILibrary_Common.TargetIcons.target_acv_panel";
const TargetIcon_ACV_Turret		= "UILibrary_Common.TargetIcons.target_acv_turret";
const TargetIcon_ACV_Treads		= "UILibrary_Common.TargetIcons.target_acv_wheel";
const TargetIcon_Advent			= "UILibrary_Common.TargetIcons.target_advent";
const TargetIcon_Chosen			= "UILibrary_XPACK_Common.target_chosen";
const TargetIcon_Alien			= "UILibrary_Common.TargetIcons.target_alien";
const TargetIcon_TheLost		= "UILibrary_XPACK_Common.target_lost";
const TargetIcon_TheLostGroup	= "UILibrary_XPACK_Common.TargetIcons.target_lostgroup";
const TargetIcon_Barrel			= "UILibrary_Common.TargetIcons.target_barrel";
const TargetIcon_Civilian		= "UILibrary_Common.TargetIcons.target_civilian";
const TargetIcon_Door			= "UILibrary_Common.TargetIcons.target_door";
const TargetIcon_Hack			= "UILibrary_Common.TargetIcons.target_hack";
const TargetIcon_Mission		= "UILibrary_Common.TargetIcons.target_mission";
const TargetIcon_Turret			= "UILibrary_Common.TargetIcons.target_turret";
const TargetIcon_VIP			= "UILibrary_Common.TargetIcons.target_vip";
const TargetIcon_XCom			= "UILibrary_Common.TargetIcons.target_xcom";
const TargetIcon_Squadsight		= "UILibrary_Common.TargetIcons.target_squadsight";

const BackpackIcon = "img:///UILibrary_Common.backpack_icon";
const PsiMarkupIcon = "img:///UILibrary_Common.class_gifted";
const LockedAbilityIcon = "img:///UILibrary_PerkIcons.UIPerk_locked";
const UnknownAbilityIcon = "img:///UILibrary_PerkIcons.UIPerk_unknown";
const StrategyShortcutIconBG = "img:///UILibrary_StrategyImages.StrategyShortcut_Background";
const HackRewardIcon = "img:///UILibrary_PerkIcons.UIPerk_hack_reward";

const UnitStatus_StasisLanced	= "img:///UILibrary_Common.status_stunned";
const UnitStatus_Stunned		= "img:///UILibrary_Common.status_stunned";
const UnitStatus_Unconscious	= "img:///UILibrary_Common.status_unconscious";
const UnitStatus_MindControlled = "img:///UILibrary_Common.status_mindcontrolled";
const UnitStatus_Haywire        = "img:///UILibrary_Common.status_haywire";
const UnitStatus_Berserk		= "img:///UILibrary_Common.status_berserk";
const UnitStatus_Revealed		= "img:///UILibrary_Common.status_revealed";
const UnitStatus_Concealed		= "img:///UILibrary_Common.status_concealed";
const UnitStatus_Default		= "img:///UILibrary_Common.status_default";
const UnitStatus_BleedingOut	= "img:///UILibrary_Common.status_default";
const UnitStatus_Burning		= "img:///UILibrary_Common.status_burning";
const UnitStatus_Confused		= "img:///UILibrary_Common.status_default";
const UnitStatus_Disoriented	= "img:///UILibrary_Common.status_disoriented";
const UnitStatus_Poisoned		= "img:///UILibrary_Common.status_poison";
const UnitStatus_Bound			= "img:///UILibrary_Common.status_bound";
const UnitStatus_Marked			= "img:///UILibrary_Common.status_default";
const UnitStatus_Panicked		= "img:///UILibrary_Common.status_panic";
const UnitStatus_Bleeding		= "img:///UILibrary_Common.status_default";

const EventQueue_BlackMarket	= "img:///UILibrary_Common.UIEvent_blackmarket";
const EventQueue_Construction	= "img:///UILibrary_Common.UIEvent_construction";
const EventQueue_Council		= "img:///UILibrary_Common.UIEvent_council";
const EventQueue_Engineer		= "img:///UILibrary_Common.UIEvent_engineer";
const EventQueue_Psi			= "img:///UILibrary_Common.UIEvent_psi";
const EventQueue_Resistance		= "img:///UILibrary_Common.UIEvent_resistance";
const EventQueue_Science		= "img:///UILibrary_Common.UIEvent_science";
const EventQueue_Staff			= "img:///UILibrary_Common.UIEvent_staff";
const EventQueue_Alien			= "img:///UILibrary_Common.UIEvent_alien";
const EventQueue_Advent			= "img:///UILibrary_Common.UIEvent_advent";

const MissionObjective_AttachBomb			= "img:///UILibrary_Common.Objective_AttachBomb";
const MissionObjective_Broadcast			= "img:///UILibrary_Common.Objective_Broadcast";
const MissionObjective_DestroyAlienFacility = "img:///UILibrary_Common.Objective_DestroyAlienFacility";
const MissionObjective_GoldenPath			= "img:///UILibrary_Common.Objective_GoldenPath";
const MissionObjective_HackWorkstation		= "img:///UILibrary_Common.Objective_HackWorkstation";
const MissionObjective_ProtectDevice		= "img:///UILibrary_Common.Objective_ProtectDevice";
const MissionObjective_RecoverItem			= "img:///UILibrary_Common.Objective_RecoverItem";
const MissionObjective_UFO					= "img:///UILibrary_Common.Objective_UFO";
const MissionObjective_VIP					= "img:///UILibrary_Common.Objective_VIP";
const MissionObjective_VIPBad				= "img:///UILibrary_Common.Objective_VIPBad";
const MissionObjective_VIPGood				= "img:///UILibrary_Common.Objective_VIPGood";

const AlertIcon_Science				= "img:///UILibrary_StrategyImages.AlertIcons.Icon_science";
const AlertIcon_Science_Black		= "img:///UILibrary_StrategyImages.AlertIcons.Icon_science_black";
const AlertIcon_Construction		= "img:///UILibrary_StrategyImages.AlertIcons.Icon_construction";
const AlertIcon_Construction_Black	= "img:///UILibrary_StrategyImages.AlertIcons.Icon_construction_black";
const AlertIcon_Engineering			= "img:///UILibrary_StrategyImages.AlertIcons.Icon_engineering";
const AlertIcon_Engineering_Black	= "img:///UILibrary_StrategyImages.AlertIcons.Icon_engineering_black";

const MissionIcon_Advent		= "img:///UILibrary_StrategyImages.X2StrategyMap.MissionIcon_Advent";
const MissionIcon_Alien			= "img:///UILibrary_StrategyImages.X2StrategyMap.MissionIcon_Alien";
const MissionIcon_BlackMarket	= "img:///UILibrary_StrategyImages.X2StrategyMap.MissionIcon_BlackMarket";
const MissionIcon_Council		= "img:///UILibrary_StrategyImages.X2StrategyMap.MissionIcon_Council";
const MissionIcon_Goldenpath	= "img:///UILibrary_StrategyImages.X2StrategyMap.MissionIcon_Goldenpath";
const MissionIcon_GOPS			= "img:///UILibrary_StrategyImages.X2StrategyMap.MissionIcon_GOPS";
const MissionIcon_POI			= "img:///UILibrary_StrategyImages.X2StrategyMap.MissionIcon_POI";
const MissionIcon_Resistance	= "img:///UILibrary_StrategyImages.X2StrategyMap.MissionIcon_Resistance";
const MissionIcon_Generic		= "img:///UILibrary_StrategyImages.X2StrategyMap.MapPin_Generic";

const LootIcon_Loot		        = "img:///UILibrary_Common.UIEvent_loot";
const LootIcon_Artifacts		= "img:///UILibrary_Common.UIEvent_alien_skull";
const LootIcon_Objectives		= "img:///UILibrary_Common.UIEvent_objective";

const CombatLose                = "img:///UILibrary_Common.Alert_Combat_Lose";

// ----------------------------------------------------------------------------------------
// HTML icons, stored in the Flash Components file so that text fields have access to them. 
// Since they are a library ID in the Components file, no prefix is needed. 
const HTML_ObjectivesIcon = "objective_icon";

const HTML_PopSupportIcon= "resistance_icon";
const HTML_PopSupportPip= "popular_pip_icon";
const HTML_PopSupportPlusIcon= "popular_add_icon";

const HTML_AlienAlertIcon= "alien_icon";
const HTML_AlienAlertPip= "alert_pip_icon";
const HTML_AlienAlertPlusIcon = "facility_health_icon";

const HTML_PromotionIcon = "promote_icon";
const HTML_AttentionIcon = "attention_icon";
const HTML_ObjectiveIcon = "objective_icon";

const HTML_MicOn     = "mic_on";
const HTML_MicOff    = "mic_off";
const HTML_MicActive = "mic_active";

const HTML_AnarchysChildrenIcon = "anarchy_icon";
const HTML_HunterIcon = "hunter_icon";
const HTML_GearIcon = "UIEvent_engineer";

const PathPrefix = "img:///";

// ----------------------------------------------------------------------------------------

/// <summary>
/// Gets a scaleform friendly pathname from the specified image that can be used to load the image in flash.
/// </summary>
simulated static final function string GetImgPathFromResource(Texture2D Image)
{
	if(Image == none)
	{
		return "";
	}
	else
	{
		return "img:///" $ PathName(Image);
	}
}

simulated static function string GetRankLabel(int iRank, optional bool bIsShiv = false)
{
	if( bIsShiv )
	{
		if(iRank < 0)
			return "shiv1";

		return "shiv" $ (iRank+1);
	}

	if(iRank < 0)
		return "rank0";

	return "rank" $ iRank;
}

simulated static function string GetRankIcon(int iRank, name ClassName)
{
	local X2SoldierClassTemplate ClassTemplate;
	local string strImageName;

	ClassTemplate = class'X2SoldierClassTemplateManager'.static.GetSoldierClassTemplateManager().FindSoldierClassTemplate(ClassName);
	
	if (ClassTemplate != none && ClassTemplate.RankIcons.Length > 0)
	{
		strImageName = ClassTemplate.RankIcons[iRank];
	}
	else
	{
		switch (iRank)
		{
		case 0: strImageName = "UILibrary_Common.rank_rookie";			break;
		case 1: strImageName = "UILibrary_Common.rank_squaddie";		break;
		case 2: strImageName = "UILibrary_Common.rank_lieutenant";		break;
		case 3: strImageName = "UILibrary_Common.rank_sergeant";		break;
		case 4: strImageName = "UILibrary_Common.rank_captain";			break;
		case 5: strImageName = "UILibrary_Common.rank_major";			break;
		case 6: strImageName = "UILibrary_Common.rank_colonel";		    break;
		case 7: strImageName = "UILibrary_Common.rank_commander";       break;
		case 8: strImageName = "UILibrary_Common.rank_fieldmarshall";   break;
		}
	}
	return "img:///" $ strImageName;
}

simulated static function string GetClassLabelFromTemplate(X2SoldierClassTemplate SoldierClassTemplate)
{
	if( SoldierClassTemplate != none )
		return Locs(SoldierClassTemplate.IconImage);
	return "none";
}



// Maps an image enum to an image path that will be created at run-time in Flash.
simulated static function string GetMPMapImagePath(name mapName) 
{
	return "DEPRECATED";
}
// Maps an image enum to an image path that will be created at run-time in Flash.
simulated static function string GetMapImagePath(name mapName) 
{
	if( IsDLC1Map(mapName) )
		return "img:///"$ GetDLC1MapPackage() $ "." $ mapName;
	else if ( IsDLC2Map(mapName) )
		return "img:///"$ GetDLC2MapPackage() $ "." $ mapName;
	else if ( IsHQAssaultMap(mapName) )
		return "img:///"$ GetHQAssaultMapPackage() $ "." $ mapName;
	else
		return "img:///"$ GetCoreMapPackage() $ "." $ mapName;
}
simulated static function string GetMapImagePackagePath(name mapName) 
{
	if( IsDLC1Map(mapName) )
		return GetDLC1MapPackage() $ "." $ mapName;
	else if ( IsDLC2Map(mapName) )
		return GetDLC2MapPackage() $ "." $ mapName;
	else if ( IsHQAssaultMap(mapName) )
		return GetHQAssaultMapPackage() $ "." $ mapName;
	else
		return GetCoreMapPackage() $ "." $ mapName;
}

simulated static function string GetCoreMapPackage()		{ return "DEPRECATED"; }//SHOULD BE REMOVED, OLD EU CODE JAM
simulated static function string GetDLC1MapPackage()		{ return "DEPRECATED"; }//SHOULD BE REMOVED, OLD EU CODE JAM
simulated static function string GetDLC2MapPackage()		{ return "DEPRECATED"; }//SHOULD BE REMOVED, OLD EU CODE JAM
simulated static function string GetHQAssaultMapPackage()	{ return "DEPRECATED"; }//SHOULD BE REMOVED, OLD EU CODE JAM

//Since we can't update the main package, we're stuffing the later map images in separate packages. 
simulated static function bool IsHQAssaultMap(name mapName)
{
	return mapName == 'EWI_HQAssault';
}
simulated static function bool IsDLC1Map(name mapName)
{
	return ( mapName == 'DLC1_1_LowFriends' ||
			 mapName == 'DLC1_2_CnfndLight' ||
			 mapName == 'DLC1_3_Gangplank' );
}
simulated static function bool IsDLC2Map(name mapName)
{
	return ( mapName == 'DLC2_1_Portent' ||
       		 mapName == 'DLC2_2_Deluge'  ||
			 mapName == 'DLC2_3_Furies' );
}

simulated static function string GetCharacterCardImage(name TemplateName, optional bool bIsGeneModded = false, optional bool bIsMEC = false)
{
	local string libraryPath;

	libraryPath = "img:///UILibrary_MPCards.MPCard_";

	switch(TemplateName)
	{
		case '':
		case 'Civilian':
		case 'HostileCivilian':
			return "";

		case 'ExaltOperative':      return libraryPath $ "ExaltOperative";
		case 'ExaltSniper':         return libraryPath $ "ExaltSniper";
		case 'ExaltHeavy':          return libraryPath $ "ExaltHeavy";
		case 'ExaltMedic':          return libraryPath $ "ExaltMedic";
		case 'ExaltEliteOperative': return libraryPath $ "ExaltEliteOperative";
		case 'ExaltEliteSniper':    return libraryPath $ "ExaltEliteSniper";
		case 'ExaltEliteHeavy':     return libraryPath $ "ExaltEliteHeavy";
		case 'ExaltEliteMedic':     return libraryPath $ "ExaltEliteMedic";

		case 'Tank':                return libraryPath $ "Soldiers";

		case 'Sectoid':             return libraryPath $ "Sectoid";
		case 'Floater':             return libraryPath $ "Floater";
		case 'Thinman':             return libraryPath $ "Thinman";
		case 'Muton':               return libraryPath $ "Muton";
		case 'Cyberdisc':           return libraryPath $ "Cyberdisc";
		case 'SectoidCommander':    return libraryPath $ "SectoidCommander";
		case 'FloaterHeavy':        return libraryPath $ "FloaterHeavy";
		case 'MutonElite':          return libraryPath $ "MutonElite";
		case 'Ethereal':            return libraryPath $ "Ethereal";

		case 'Chryssalid':          return libraryPath $ "Cryssalid";
		case 'Zombie':              return libraryPath $ "Zombie";
		case 'MutonBerserker':      return libraryPath $ "Berserker";
		case 'Sectopod':            return libraryPath $ "Sectopod";
		case 'Drone':               return libraryPath $ "Drone";
		case 'Outsider':            return libraryPath $ "Outsider";
		case 'EtherealUber':        return libraryPath $ "Ethereal";
		case 'BattleScanner':       return libraryPath $ "Drone";
		case 'Mechtoid':            return libraryPath $ "Mechtoid";
		case 'Seeker':              return libraryPath $ "Seeker";
		case 'ACV':                 return libraryPath $ "ACV";
		
		case 'Soldier':             
			if( bIsGeneModded )         return libraryPath $ "Soldier_GeneMod";
			if( bIsMEC )                return libraryPath $ "Soldier_MEC";
			else                        return libraryPath $ "Soldiers";
	}
	`ASSERT(TemplateName != 'Mechtoid_Alt');
}

simulated static function string GetOTSImageLabel(int iImg)
{
	switch( iImg )
	{
		case eOTSImage_SquadSize_I:     return "_squadSizeI";
		case eOTSImage_Squadsize_II:    return "_squadSizeII";
		case eOTSImage_Will_I:          return "_ironWill";		
		case eOTSImage_XP_I:            return "_wetWork";
		case eOTSImage_HP_I:            return "_rapidRecovery";		
		case eOTSImage_XP_II:           return "_newGuy";
		case eOTSImage_HP_II:           return "_dontYouDieOnMe";
	}

	return "";
}

simulated static function string GetFoundryImagePath(int iImg)
{
	local string scienceLibraryPath;

	scienceLibraryPath         = "img:///UILibrary_StrategyImages.ScienceIcons.";

	switch(iImg)
	{
		case eFoundryImage_SHIV:					return scienceLibraryPath $ "IC_Shiv";
		case eFoundryImage_SHIVHeal:				return scienceLibraryPath $ "IC_HealShiv";
		case eFoundryImage_CaptureDrone:			return scienceLibraryPath $ "IC_AutopsyDrone";
		case eFoundryImage_MedikitII:				return scienceLibraryPath $ "IC_Medikit2";
		case eFoundryImage_ArcThrowerII:			return scienceLibraryPath $ "IC_ArcThrower2";
		case eFoundryImage_LaserCoolant:			return scienceLibraryPath $ "IC_LaserCooling";
		case eFoundryImage_SHIVLaser:				return scienceLibraryPath $ "IC_LaserCannon";
		case eFoundryImage_SHIVPlasma:				return scienceLibraryPath $ "IC_PlasmaCannon";
		case eFoundryImage_Flight:					return scienceLibraryPath $ "IC_ArmorArchangel";
		case eFoundryImage_AlienGrenade:			return scienceLibraryPath $ "IC_Grenade";
		case eFoundryImage_AdvancedConstruction:	return scienceLibraryPath $ "IC_AlienConstruction";
		case eFoundryImage_VehicleRepair:			return scienceLibraryPath $ "IC_InterceptorRepair";
		case eFoundryImage_PistolI:					return scienceLibraryPath $ "IC_Pistol1";
		case eFoundryImage_PistolII:				return scienceLibraryPath $ "IC_Pistol2";
		case eFoundryImage_PistolIII:				return scienceLibraryPath $ "IC_Pistol3";
		case eFoundryImage_SHIVSuppression:			return scienceLibraryPath $ "IC_ShivSuppression";
		case eFoundryImage_StealthSatellites:		return scienceLibraryPath $ "IC_StealthSatellite";
		case eFoundryImage_ScopeUpgrade:			return scienceLibraryPath $ "IC_ScopeUpgrade";		
		case eFoundryImage_AdvancedServomotors:		return scienceLibraryPath $ "IC_AdvancedServomotors";		
		case eFoundryImage_ShapedArmor:			    return scienceLibraryPath $ "IC_ShapedArmor";		
		case eFoundryImage_EleriumFuel:			    return scienceLibraryPath $ "IC_JelliedElerium";		
		case eFoundryImage_SentinelDrone:			return scienceLibraryPath $ "IC_SentinelModule";	
		case eFoundryImage_TacticalRigging:			return scienceLibraryPath $ "IC_TacticalRigging";	
		case eFoundryImage_MECCloseCombat:			return scienceLibraryPath $ "IC_MECCloseCombat";	
	}
}

simulated static function string GetItemImagePath(EItemType eItem)
{
	return "";
}

simulated static function string GetInventoryImagePath(int iImg)
{
	local string inventoryLibraryPath;

	inventoryLibraryPath         = "img:///UILibrary_StrategyImages.InventoryIcons.";
	
	switch(iImg)
	{
		case eInventoryImage_AlienGrenade:					return inventoryLibraryPath $ "Inv_AlienGrenade";
		case eInventoryImage_AlienWeaponFragments:		    return inventoryLibraryPath $ "Inv_AlienWeaponFragments";
		case eInventoryImage_ArcThrower:		            return inventoryLibraryPath $ "Inv_ArcThrower";
		case eInventoryImage_ArmorArchangel:		        return inventoryLibraryPath $ "Inv_ArmorArchangel";
		case eInventoryImage_ArmorCarapace:		            return inventoryLibraryPath $ "Inv_ArmorCarapace";
		case eInventoryImage_ArmorGhost:		            return inventoryLibraryPath $ "Inv_ArmorGhost";
		case eInventoryImage_ArmorKevlar:		            return inventoryLibraryPath $ "Inv_ArmorKevlar";
		case eInventoryImage_ArmorPsi:		                return inventoryLibraryPath $ "Inv_ArmorPsi";
		case eInventoryImage_ArmorSkeleton:		            return inventoryLibraryPath $ "Inv_ArmorSkeleton";
		case eInventoryImage_ArmorTitan:		            return inventoryLibraryPath $ "Inv_ArmorTitan";
		case eInventoryImage_AssaultRifleModern:		    return inventoryLibraryPath $ "Inv_AssaultRifleModern";
		case eInventoryImage_BattleScanner:		            return inventoryLibraryPath $ "Inv_BattleScanner";
		case eInventoryImage_ChitinPlating:		            return inventoryLibraryPath $ "Inv_ChitinPlating";
		case eInventoryImage_CombatStims:		            return inventoryLibraryPath $ "Inv_CombatStims";
		case eInventoryImage_DefenseMatrix:		            return inventoryLibraryPath $ "Inv_DefenseMatrix";
		case eInventoryImage_Firestorm:		                return inventoryLibraryPath $ "Inv_Firestorm";
		case eInventoryImage_FragGrenade:		            return inventoryLibraryPath $ "Inv_FragGrenade";
		case eInventoryImage_GrappleHook:		            return inventoryLibraryPath $ "Inv_GrappleHook";
		case eInventoryImage_Interceptor:		            return inventoryLibraryPath $ "Inv_Interceptor";
		case eInventoryImage_LaserHeavy:		            return inventoryLibraryPath $ "Inv_LaserHeavy";
		case eInventoryImage_LaserPistol:		            return inventoryLibraryPath $ "Inv_LaserPistol";
		case eInventoryImage_LaserRifle:		            return inventoryLibraryPath $ "Inv_LaserRifle";
		case eInventoryImage_LaserShotgun:		            return inventoryLibraryPath $ "Inv_LaserShotgun";
		case eInventoryImage_LaserSniper:		            return inventoryLibraryPath $ "Inv_LaserSniper";
		case eInventoryImage_LMG:		                    return inventoryLibraryPath $ "Inv_LMG";
		case eInventoryImage_MedikitI:		                return inventoryLibraryPath $ "Inv_Medikit";
		case eInventoryImage_MedikitII:						return inventoryLibraryPath $ "Inv_Medikit2";
		case eInventoryImage_MindShield:		            return inventoryLibraryPath $ "Inv_MindShield";
		case eInventoryImage_ReaperRounds:                  return inventoryLibraryPath $ "Inv_ReaperAmmo";	
		case eInventoryImage_MotionDetector:		        return inventoryLibraryPath $ "Inv_MotionDetector";
		case eInventoryImage_NanoFabricVest:		        return inventoryLibraryPath $ "Inv_NanoFabricVest";
		case eInventoryImage_Pistol:		                return inventoryLibraryPath $ "Inv_Pistol";
		case eInventoryImage_PlasmaBlasterLauncher:		    return inventoryLibraryPath $ "Inv_PlasmaBlasterLauncher";
		case eInventoryImage_PlasmaHeavy:		            return inventoryLibraryPath $ "Inv_PlasmaHeavy";
		case eInventoryImage_PlasmaPistol:		            return inventoryLibraryPath $ "Inv_PlasmaPistol";
		case eInventoryImage_PlasmaRifle:		            return inventoryLibraryPath $ "Inv_PlasmaRifle";
		case eInventoryImage_PlasmaRifleLight:		        return inventoryLibraryPath $ "Inv_PlasmaRifleLight";
		case eInventoryImage_PlasmaShotgun:		            return inventoryLibraryPath $ "Inv_PlasmaShotgun";
		case eInventoryImage_PlasmaSniper:					return inventoryLibraryPath $ "Inv_PlasmaSniper";
		case eInventoryImage_RespiratorImplant:				return inventoryLibraryPath $ "Inv_RespiratorImplant";
		case eInventoryImage_RocketLauncher:		        return inventoryLibraryPath $ "Inv_RocketLauncher";
		case eInventoryImage_Satellite:		                return inventoryLibraryPath $ "Inv_Satellite";
		case eInventoryImage_SatelliteTargeting:		    return inventoryLibraryPath $ "Inv_SatelliteTargeting";
		case eInventoryImage_Scope:		                    return inventoryLibraryPath $ "Inv_Scope";
		case eInventoryImage_SHIVI:		                    return inventoryLibraryPath $ "Inv_Shiv1";
		case eInventoryImage_SHIVII:		                return inventoryLibraryPath $ "Inv_Shiv2";
		case eInventoryImage_SHIVIII:		                return inventoryLibraryPath $ "Inv_Shiv3";
		case eInventoryImage_MECCivvies:                    return inventoryLibraryPath $ "Inv_MecCivvies";
		case eInventoryImage_MECI:		                    return inventoryLibraryPath $ "Inv_Mec1";
		case eInventoryImage_MECII:		                    return inventoryLibraryPath $ "Inv_Mec2";
		case eInventoryImage_MECIII:		                return inventoryLibraryPath $ "Inv_Mec3";
		case eInventoryImage_SHIVGattlingGun:		        return inventoryLibraryPath $ "Inv_SHIVGattlingGun";
		case eInventoryImage_SHIVLaserCannon:		        return inventoryLibraryPath $ "Inv_SHIVLaserCannon";
		case eInventoryImage_Shotgun:		                return inventoryLibraryPath $ "Inv_Shotgun";
		case eInventoryImage_SkeletonKey:		            return inventoryLibraryPath $ "Inv_SkeletonKey";
		case eInventoryImage_SmokeGrenade:					return inventoryLibraryPath $ "Inv_SmokeGrenade";
		case eInventoryImage_SniperRifle:					return inventoryLibraryPath $ "Inv_SniperRifle";
		case eInventoryImage_UFOTracking:		            return inventoryLibraryPath $ "Inv_UFOTracking";
		case eInventoryImage_Xenobiology:	                return inventoryLibraryPath $ "Inv_Xenobiology";
		case eInventoryImage_ExaltAssaultRifle:	            return inventoryLibraryPath $ "Inv_ExaltAssaultRifle";
		case eInventoryImage_ExaltLaserAssaultRifle:	    return inventoryLibraryPath $ "Inv_ExaltLaserAssaultRifle";
		case eInventoryImage_ExaltSniperRifle:	            return inventoryLibraryPath $ "Inv_ExaltSniperRifle";
		case eInventoryImage_ExaltLaserSniperRifle:	        return inventoryLibraryPath $ "Inv_ExaltLaserSniperRifle";
		case eInventoryImage_ExaltHeavyMG:	                return inventoryLibraryPath $ "Inv_ExaltHeavyMG";
		case eInventoryImage_ExaltLaserHeavyMG:	            return inventoryLibraryPath $ "Inv_ExaltLaserHeavyMG";
		case eInventoryImage_ExaltRocketLauncher:	        return inventoryLibraryPath $ "Inv_ExaltRocketLauncher";
		case eInventoryImage_MECParticleCannon:	            return inventoryLibraryPath $ "Inv_MECParticleCannon";
		case eInventoryImage_MECChainGun:	                return inventoryLibraryPath $ "Inv_MECChainGun";
		case eInventoryImage_MECRailGun:	                return inventoryLibraryPath $ "Inv_MECRailGun";
		case eInventoryImage_Flashbang:	                    return inventoryLibraryPath $ "Inv_Flashbang"; 
		case eInventoryImage_NeedleGrenade:	                return inventoryLibraryPath $ "Inv_NeedleGrenade";
		case eInventoryImage_MimicBeacon:	                return inventoryLibraryPath $ "Inv_MimicBeacon";
		case eInventoryImage_GhostGrenade:	                return inventoryLibraryPath $ "Inv_GhostGrenade";
		case eInventoryImage_GasGrenade:                    return inventoryLibraryPath $ "Inv_GasGrenade";
	}
}

// Maps an image enum to an image path that will be created at run-time in Flash.
simulated static function string GetStrategyImagePath(int iImg)
{
	local string loadoutLibraryPath, scienceLibraryPath, facilityLibraryPath;


	loadoutLibraryPath     = "img:///UILibrary_StrategyImages.InventoryIcons.";
	scienceLibraryPath     = "img:///UILibrary_StrategyImages.ScienceIcons.";
	facilityLibraryPath    = "img:///UILibrary_StrategyImages.FacilityIcons.";

	switch(iImg)
	{
		// --- BEGIN SOLDIER LOADOUT ---
		case eImage_Pistol:				return loadoutLibraryPath $ "Inv_Pistol";
		case eImage_Rifle:				return loadoutLibraryPath $ "Inv_AssaultRifleModern";
		case eImage_Shotgun:			return loadoutLibraryPath $ "Inv_ShotgunModern";
		case eImage_LMG:				return loadoutLibraryPath $ "Inv_Minigun";
		case eImage_SniperRifle:		return loadoutLibraryPath $ "Inv_SniperRifle";
		case eImage_RocketLauncher:		return loadoutLibraryPath $ "Inv_RocketLauncher";
		case eImage_LaserPistol:		return loadoutLibraryPath $ "Inv_LaserPistol";
		case eImage_LaserRifle:			return loadoutLibraryPath $ "Inv_AssaultRifleLaser";
		case eImage_LaserHeavy:			return loadoutLibraryPath $ "Inv_HeavyLaser";
		case eImage_LaserSniperRifle:	return loadoutLibraryPath $ "Inv_SniperRifleLaser";

		case eImage_PlasmaPistol:		return loadoutLibraryPath $ "Inv_PlasmaPistol";
		case eImage_PlasmaLightRifle:	return loadoutLibraryPath $ "Inv_PlasmaRifleLight";
		case eImage_PlasmaRifle:		return loadoutLibraryPath $ "Inv_PlasmaRifle";
		case eImage_PlasmaHeavy:		return loadoutLibraryPath $ "Inv_HeavyPlasma";
		case eImage_PlasmaSniperRifle:	return loadoutLibraryPath $ "Inv_SniperRiflePlasma";

		case eImage_Beast:				return loadoutLibraryPath $ "Inv_Lv1MedMale_Armor";
		case eImage_Kevlar:				return loadoutLibraryPath $ "Inv_ArmorKevlar";
		case eImage_SkeletonSuit:		return loadoutLibraryPath $ "Inv_ArmorSkeleton";
		case eImage_Carapace:			return loadoutLibraryPath $ "Inv_ArmorCarapace";
		case eImage_Titan:				return loadoutLibraryPath $ "Inv_ArmorTitan";
		case eImage_Ghost:				return loadoutLibraryPath $ "Inv_ArmorGhost";
		case eImage_Archangel:			return loadoutLibraryPath $ "Inv_ArmorArchangel";
		case eImage_PsiArmor:			return loadoutLibraryPath $ "Inv_ArmorPsi";
		case eImage_FragGrenade:		return loadoutLibraryPath $ "Inv_FragGrenade";
		case eImage_SmokeGrenade:		return loadoutLibraryPath $ "Inv_SmokeGrenade";
		case eImage_AlienGrenade:		return loadoutLibraryPath $ "Inv_AlienGrenade";
		case eImage_FlashBang:			return loadoutLibraryPath $ "Inv_Flashbang";
		case eImage_Medikit:			return loadoutLibraryPath $ "Inv_MediKit";
		// --- END SOLDIER LOADOUT ---
		
		// --- BEGIN SCIENCE ICONS ---
		case eImage_AlienWeaponry: 		return scienceLibraryPath $ "IC_AlienWeaponFragments";
		case eImage_Alloys:				return scienceLibraryPath $ "IC_AlienMaterials";
		case eImage_SHIV_I: 			return scienceLibraryPath $ "IC_Shiv1";
		case eImage_Xenobiology: 		return scienceLibraryPath $ "IC_Xenobiology";
		case eImage_LaserRifle: 		return scienceLibraryPath $ "IC_PrecisionLasers";
		case eImage_LaserSniperRifle: 	return scienceLibraryPath $ "IC_LaserSniper";
		case eImage_LaserHeavy: 		return scienceLibraryPath $ "IC_LaserCannon";
		case eImage_PlasmaPistol: 		return scienceLibraryPath $ "IC_PlasmaPistol";
		case eImage_PlasmaLightRifle: 	return scienceLibraryPath $ "IC_PlasmaLightRifle";
		case eImage_PlasmaRifle: 		return scienceLibraryPath $ "IC_PlasmaRifle";
		case eImage_PlasmaHeavy: 		return scienceLibraryPath $ "IC_PlasmaHeavy";
		case eImage_PlasmaSniperRifle: 	return scienceLibraryPath $ "IC_PlasmaSniper";
		case eImage_Interceptor:		return scienceLibraryPath $ "IC_Interceptor";
		case eImage_AlloyCannon: 		return scienceLibraryPath $ "IC_";
		case eImage_Deck2: 				return scienceLibraryPath $ "IC_InterceptorFusionLance";
		case eImage_BlasterLauncher: 	return scienceLibraryPath $ "IC_PlasmaBlasterLauncher";
		case eImage_ArcThrower: 		return scienceLibraryPath $ "IC_ArcThrower";
		case eImage_PsiArmor: 			return scienceLibraryPath $ "IC_";
		case eImage_Device: 			return scienceLibraryPath $ "IC_";
		case eImage_UFONavigation: 		return scienceLibraryPath $ "IC_UFONavigation";
		case eImage_UFOPowersource: 	return scienceLibraryPath $ "IC_UFOPower";
		case eImage_Firestorm: 			return scienceLibraryPath $ "IC_Firestorm";
		case eImage_Lasers: 			return scienceLibraryPath $ "IC_EPM";
		case eImage_Elerium:			return scienceLibraryPath $ "IC_Elerium";
		case eImage_Carapace: 			return scienceLibraryPath $ "IC_ArmorCarapace";
		case eImage_SkeletonSuit: 		return scienceLibraryPath $ "IC_ArmorSkeleton";
		case eImage_Titan: 				return scienceLibraryPath $ "IC_ArmorTitan";
		case eImage_Ghost: 				return scienceLibraryPath $ "IC_ArmorGhost";
		case eImage_Archangel: 			return scienceLibraryPath $ "IC_ArmorArchangel";
		case eImage_HyperwaveBeacon: 	return scienceLibraryPath $ "IC_HyperwaveCommunication";
		case eImage_PsiLink: 			return scienceLibraryPath $ "IC_PsiLink";
		
		// --- END SCIENCE ICONS ---

		// --- BEGIN FACILITY ICONS ---
		
		case eImage_FacilityAccessLift:         return facilityLibraryPath $ "ChooseFacility_AccessLift";
		case eImage_FacilityAlienContainment:   return facilityLibraryPath $ "ChooseFacility_AlienContainment";
		case eImage_FacilityEleriumGenerator:   return facilityLibraryPath $ "ChooseFacility_EleriumGenerator";
		case eImage_FacilityGear:               return facilityLibraryPath $ "ChooseFacility_Workshops";
		case eImage_FacilityFoundry:            return facilityLibraryPath $ "ChooseFacility_Foundry";
		case eImage_FacilityGenerator:          return facilityLibraryPath $ "ChooseFacility_PowerGenerator";
		case eImage_FacilityRadar:              return facilityLibraryPath $ "ChooseFacility_SatelliteUplink";
		case eImage_FacilityLivingQuarters:     return facilityLibraryPath $ "ChooseFacility_TempGenericRoom";
		case eImage_FacilityPsiLabs:            return facilityLibraryPath $ "ChooseFacility_PsionicLabs";
		case eImage_FacilitySuperComputer:      return facilityLibraryPath $ "ChooseFacility_Laboratory";
		case eImage_FacilityLargeRadar:         return facilityLibraryPath $ "ChooseFacility_SatelliteNexusUplink";
		case eImage_FacilityThermoGenerator:    return facilityLibraryPath $ "ChooseFacility_ThermalPowerGenerator";
		case eImage_FacilityOTS:                return facilityLibraryPath $ "ChooseFacility_OfficerTrainingSchool";
		case eImage_FacilityOTS2:               return facilityLibraryPath $ "ChooseFacility_OfficerTrainingSchool";
		case eImage_FacilityXBC:                return facilityLibraryPath $ "ChooseFacility_TempGenericRoom";
		case eImage_FacilityUber:               return facilityLibraryPath $ "ChooseFacility_GollopChamber";
		case eImage_TowerHyperwave:             return facilityLibraryPath $ "ChooseFacility_HyperwaveUplink";

	// --- END FACILITY ICONS ---

		default:
			return ""; //TEMP FOR DEMO so we don't see the tiny rainbow images. bsteiner 2.19.12
			//return "img:///UILibrary_StrategyImages.Int_TEMP";
	}
}

//Verifies the existance of the asset path prefix required for Scaleform's Unreal image loading functionality. 
simulated static function string ValidateImagePath(string ImgPath)
{
	if( ImgPath != "" && InStr(ImgPath, DynamicImagePrefix) == INDEX_NONE )
		return DynamicImagePrefix $ ImgPath;
	return ImgPath;
}

// Maps a facility image enum into a facility label that will be displayed in the BuiltFacility Mission Control Alert.
simulated static function string GetFacilityLabel( int eFacilityImageType )
{
	local string strImage; 
	switch( eFacilityImageType )
	{
		case eImage_TileRock:
			strImage = "Rock";
			break;
		case eImage_TileRockSteam:
			strImage = "RockSteam";
			break;
		case eImage_TileAccessLift:
			strImage = "AccessLift";
			break;
		case eImage_TileConstruction:
			strImage = "Construction";
			break;
		case eImage_TileExcavated:
			strImage = "Excavated";
			break;
		/*case eImage_ExcavatedSteam:
			strImage = "ExcavatedSteam";
			break;*/
		case eImage_TileBeingExcavated:
			strImage = "BeingExcavated";
			break;
		//------------------
		case eImage_OldFunding:
			strImage = "GreyMarket";
			break;
		case eImage_FacilityAccessLift:
			strImage = "AccessLift";
			break;
	   case eImage_FacilityAlienContainment:
			  strImage = "AlienContainment";
			  break;
	   case eImage_FacilityEleriumGenerator:
			  strImage = "EleriumGenerator";
			  break;
	   case eImage_FacilityGear:
			  strImage = "Workshops";
			  break;
	   case eImage_FacilityFoundry:
			  strImage = "Foundry";
			  break;
	   case eImage_FacilityGenerator:
			  strImage = "PowerGenerator";
			  break;
	   case eImage_FacilityRadar:
			  strImage = "SatelliteUplink";
			  break;
	   case eImage_FacilityLivingQuarters:
			  strImage = "UnKnown";
			  break;
	   case eImage_FacilityLargeRadar:
			  strImage = "SatelliteNexusUplink";
			  break;
	   case eImage_FacilityPsiLabs:
			  strImage = "PsionicLabs";
			  break;
		case eImage_Labs:
		case eImage_FacilitySuperComputer:
			  strImage = "Laboratories";
			  break;
	   case eImage_FacilityThermoGenerator:
			  strImage = "ThermalPowerGenerator";
			  break;
	   case eImage_FacilityOTS:
			  strImage = "OfficerTrainingSchool";
			  break;
	   case eImage_FacilityOTS2:
			  strImage = "UnKnown";
			  break;
	   case eImage_FacilityXBC:
			  strImage = "UnKnown";
			  break;
		case eImage_HyperwaveBeacon:
		case eImage_TowerHyperwave: 	
			  strImage = "HyperwaveUplink";
			  break;
		case eImage_FacilityUber:
			  strImage = "GollopChamber";
			  break;
		default: 
			strImage = "Unknown";
	}
	
	return strImage;
}

simulated static function string GetDLCImagePath(int iImg)
{
	local string DLCImagePath;

	DLCImagePath      = "img:///UILibrary_DLCImages.";

	switch(iImg)
	{
		case 0:
			return DLCImagePath $ "DLC_Image0";
		case 1:
			return DLCImagePath $ "DLC_Image1";
		case 2:
			return DLCImagePath $ "DLC_Image2";
		case 3:
			return DLCImagePath $ "DLC_Image3";
		case 4:
			return DLCImagePath $ "DLC_Image4";
		default:
			return DLCImagePath $ "DLC_Image0";

	}
}

// Converts a GameCore/Jake/ProtoUI button enumeration to UI string
simulated static function string GetButtonName( int iGameCoreButtonEnum )
{
	switch( iGameCoreButtonEnum )
	{
		case eButton_None:      return "";
		case eButton_A:         return class'UIUtilities_Input'.static.GetAdvanceButtonIcon();
		case eButton_X:         return class'UIUtilities_Input'.static.GetGamepadIconPrefix() $ class'UIUtilities_Input'.const.ICON_X_SQUARE;
		case eButton_Y:         return class'UIUtilities_Input'.static.GetGamepadIconPrefix() $ class'UIUtilities_Input'.const.ICON_Y_TRIANGLE;
		case eButton_B:         return class'UIUtilities_Input'.static.GetBackButtonIcon();
		case eButton_Start:     return class'UIUtilities_Input'.static.GetGamepadIconPrefix() $class'UIUtilities_Input'.const.ICON_START;
		case eButton_Back:      return class'UIUtilities_Input'.static.GetGamepadIconPrefix() $class'UIUtilities_Input'.const.ICON_BACK_SELECT;
		case eButton_Up:        return class'UIUtilities_Input'.static.GetGamepadIconPrefix() $class'UIUtilities_Input'.const.ICON_DPAD_UP;
		case eButton_Down:      return class'UIUtilities_Input'.static.GetGamepadIconPrefix() $class'UIUtilities_Input'.const.ICON_DPAD_DOWN;
		case eButton_Left:      return class'UIUtilities_Input'.static.GetGamepadIconPrefix() $class'UIUtilities_Input'.const.ICON_DPAD_LEFT;
		case eButton_Right:     return class'UIUtilities_Input'.static.GetGamepadIconPrefix() $class'UIUtilities_Input'.const.ICON_DPAD_RIGHT;
		case eButton_LBumper:   return class'UIUtilities_Input'.static.GetGamepadIconPrefix() $class'UIUtilities_Input'.const.ICON_LB_L1;
		case eButton_RBumper:   return class'UIUtilities_Input'.static.GetGamepadIconPrefix() $class'UIUtilities_Input'.const.ICON_RB_R1;
		case eButton_LTrigger:  return class'UIUtilities_Input'.static.GetGamepadIconPrefix() $class'UIUtilities_Input'.const.ICON_LT_L2;
		case eButton_RTrigger:  return class'UIUtilities_Input'.static.GetGamepadIconPrefix() $class'UIUtilities_Input'.const.ICON_RT_R2;
		case eButton_LStick:    return class'UIUtilities_Input'.static.GetGamepadIconPrefix() $class'UIUtilities_Input'.const.ICON_RSTICK;
		case eButton_RStick:    return class'UIUtilities_Input'.static.GetGamepadIconPrefix() $class'UIUtilities_Input'.const.ICON_LSTICK;
	}
	`warn("Unknown button enum " $ String(iGameCoreButtonEnum) $ ")" );
	return "_unknown";
}

simulated static function string GetShipIconLabel(EShipType type)
{
	switch( type )
	{
		case eShip_Interceptor: return "interceptor";
		case eShip_Firestorm:   return "firestorm";
	}
	`warn("Unknown ship type enum: " $ String(type));
	return "_unknown";
}

simulated static function string GetMissionListItemIcon( int iImage, optional int iState = eUIState_Good)
{
	switch( iImage  )
	{
		case eImage_OldUFO:     return "_Abduction"; 
		case eImage_OldTerror:  return "_TerrorSite"; 
		case eImage_MCUFOCrash: return "_Crash"; 
		case eImage_OldAssault: return "_LandedUFO"; 
		case eImage_AlienBase:  return "_AlienBase"; 
		case eImage_Temple:     return "_Final";
		case eImage_OldFunding: return "_Special";
		case eImage_RadarUFO:   
			if(iState == eUIState_Bad)
				return  "_StopScanning";
			else
				return  "_ScanForUFO";

		default:                return  "_Unknown"; 

		// "_HQAssault" // Unused? 
		// "_Special"  // Unused? 
	}
}

simulated static function string GetEventListFCRequestIcon( int iContinentMakingRequest )
{
	switch( iContinentMakingRequest )
	{
		case eContinent_NorthAmerica: return "_continentB";
		case eContinent_SouthAmerica: return "_continentA";
		case eContinent_Europe: return "_continentC";
		case eContinent_Asia:   return "_continentD";
		case eContinent_Africa: return "_continentE";
		default:                return  "_Unknown"; 
	}
}

simulated static function string GetMPPingLabel( int ping )
{
	local TMPPingRanges PingRanges;

	foreach class'XComMPData'.default.m_arrPingRanges(PingRanges)
	{
		if (ping <= PingRanges.m_iPing)
		{
			return PingRanges.m_strUITag;
		}
	}

	return "fail"; // label for no connection or really really bad
}

simulated static function StripSpecialMissionFromMapName( out string mapName )
{
	mapName = Repl( mapName, "_Bomb", "" );
	mapName = Repl( mapName, "_Rescue", "" );
	mapName = Repl( mapName, "_Extraction", "" );
	mapName = Repl( mapName, "_Assault", "" );
}

simulated static function string GetToDoWidgetImagePath(int iImg)
{
	local string Path;

	Path = "img:///UILibrary_StrategyImages.X2StrategyMap.";
	
	switch(iImg)
	{
	case eUIToDoCat_Research:		return Path $ "Todo_Science";
	case eUIToDoCat_Engineering:	return Path $ "Todo_Weapons";
	case eUIToDoCat_Power:			return Path $ "Todo_Power";
	case eUIToDoCat_Resistance:		return Path $ "Todo_Resistance";
	case eUIToDoCat_Income:			return Path $ "Todo_Supplies";
	case eUIToDoCat_Staffing:		return Path $ "Todo_Staff";
	case eUIToDoCat_ProvingGround:	return Path $ "Todo_Facility";
	case eUIToDoCat_SoldierStatus:	return Path $ "Todo_Soldier";
	case eUIToDoCat_SoldierBonds:	return "img:///UILibrary_XPACK_StrategyImages.Todo_Bond";
	default:						return Path $ "Todo_Default";
	}
}

simulated static function string GetPsiFeedbackMeterLabel( int iMindshockValue )
{
	switch( iMindshockValue )
	{
	case 0: return "disorient"; 
	case 1: return "stun"; 
	case 2: return "panic"; 
	case 3: return "unconscious"; 
	case 4: return "damage"; 
	}
}

simulated static function string GetPCSImage(XComGameState_Item Item)
{
	local ECharStatType StatType;

	StatType = class'UIUtilities_Strategy'.static.GetStatBoost(Item).StatType;

	switch(StatType)
	{
	case eStat_HP:          return "img:///UILibrary_Common.implants_health";
	case eStat_Mobility:    return "img:///UILibrary_Common.implants_mobility";
	case eStat_Offense:     return "img:///UILibrary_Common.implants_offense";
	case eStat_PsiOffense:  return "img:///UILibrary_Common.implants_psi";
	case eStat_Will:        return "img:///UILibrary_Common.implants_will";
	case eStat_Dodge:		return "img:///UILibrary_Common.implants_psi";
	default:                return "img:///UILibrary_Common.implants_empty";
	}
}

simulated static function string GetTutorialImage_Ambush()
{
	return "img:///UILibrary_Common.TUTORIAL.Tutorial_Ambush";
}

simulated static function string GetTutorialImage_Melee()
{
	return "img:///UILibrary_Common.TUTORIAL.Tutorial_Melee";
}

simulated static function string GetTutorialImage_SoldierBonds()
{
	return "img:///UILibrary_XPACK_Common.Tutorial_bonds";
}

simulated static function string GetTutorialImage_Dazed()
{
	return "img:///UILibrary_XPACK_Common.Tutorial_dazedrevive";
}

simulated static function string GetTutorialImage_TargetPreview()
{
	return "img:///UILibrary_XPACK_Common.Tutorial_targetpreview";
}

simulated static function string GetTutorialImage_TrackingShot()
{
	return "img:///UILibrary_XPACK_Common.Tutorial_trackingshot";
}

simulated static function string GetTutorialImage_Templar()
{
	return "img:///UILibrary_XPACK_Common.Tutorial_templar";
}

simulated static function string GetTutorialImage_TemplarMomentum()
{
	return "img:///UILibrary_XPACK_Common.Tutorial_momentumparry";
}

simulated static function string GetTutorialImage_Reaper()
{
	return "img:///UILibrary_XPACK_Common.Tutorial_reaper";
}

simulated static function string GetTutorialImage_Skirmisher()
{
	return "img:///UILibrary_XPACK_Common.Tutorial_skirmisher";
}


//Match frame labels in Flash:
const StrategyPolicyTab_All = "_deck";
const StrategyPolicyTab_XCOM = "_xcom";
const StrategyPolicyTab_Skirmisher = "_skirmisher";
const StrategyPolicyTab_Reaper = "_reaper";
const StrategyPolicyTab_Templar = "_templar";

const FactionIcon_XCOM = "UILibrary_XPACK_Common.Faction_XCOM";

static function string GetImageLabelForFaction(XComGameState_ResistanceFaction FactionState)
{
	local name FactionName;

	if (FactionState != None)
	{
		FactionName = FactionState.GetMyTemplate().DataName;
	}
	
	switch( FactionName )
	{
	case 'Faction_Skirmishers':						return StrategyPolicyTab_Skirmisher;
	case 'Faction_Reapers':							return StrategyPolicyTab_Reaper;
	case 'Faction_Templars': 						return StrategyPolicyTab_Templar;
	
	default:
		return StrategyPolicyTab_XCOM;
	}
}



static function string GetFlashLabelForFaction(name AssociatedEntity)
{
	switch (AssociatedEntity)
	{
	case 'Faction_Templars':		return StrategyPolicyTab_Templar;
	case 'Faction_Reapers':			return StrategyPolicyTab_Reaper;
	case 'Faction_Skirmishers':		return StrategyPolicyTab_Skirmisher;
	case 'Faction_XCOM':			return StrategyPolicyTab_XCOM;
	}

	//Fail! Return something for obvious debugging 
	return StrategyPolicyTab_All;
}