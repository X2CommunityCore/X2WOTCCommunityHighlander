//---------------------------------------------------------------------------------------
//  FILE:    X2AbilityTag.uc
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2AbilityTag extends XGLocalizeTag
	dependson(X2TacticalGameRulesetDataStructures)
	native(Core);

var Object ParseObj;
var Object StrategyParseObj;
var XComGameState GameState;

native function bool Expand(string InString, out string OutString);

event ExpandHandler(string InString, out string OutString)
{
	local name Type;
	local XComGameStateHistory History;
	local XComGameState_Ability AbilityState;
	local XComGameState_Effect EffectState;
	local XComGameState_Item ItemState;
	local XComGameState_Unit TargetUnitState;
	local X2WeaponUpgradeTemplate UpgradeTemplate;
	local X2GremlinTemplate GremlinTemplate;
	local X2Effect_Burning BurningEffect;
	local X2Effect_ApplyWeaponDamage WeaponDamageEffect;
	local X2AbilityTemplate AbilityTemplate;
	local X2AbilityCost_Ammo AmmoCost;
	local int MinDamage, MaxDamage, Idx;
	local XComGameState_HeadquartersXCom XComHQ;
	local array<X2DownloadableContentInfo> DLCInfos;
	local X2DownloadableContentInfo DLCInfo;

	Type = name(InString);
	History = `XCOMHISTORY;

	switch (Type)
	{
	case 'CANNOTBEDODGED':
		OutString = "";
		AbilityState = XComGameState_Ability(ParseObj);
		if (AbilityState != none)
		{
			ItemState = AbilityState.GetSourceWeapon();
			if (ItemState != none && !ItemState.CanWeaponBeDodged())
			{
				OutString = class'XLocalizedData'.default.CannotBeDodged;
			}
		}
		return;         //  not break, as it is valid for OutString to be blank in this case, and we don't want to redscreen.
	case 'SELFAMMOCOST':
		OutString = "0";
		AbilityTemplate = X2AbilityTemplate(ParseObj);
		if (AbilityTemplate == none)
		{
			AbilityState = XComGameState_Ability(ParseObj);
			if (AbilityState != none)
				AbilityTemplate = AbilityState.GetMyTemplate();
		}
		if (AbilityTemplate != none)
		{
			for (Idx = 0; Idx < AbilityTemplate.AbilityCosts.Length; ++Idx)
			{
				AmmoCost = X2AbilityCost_Ammo(AbilityTemplate.AbilityCosts[Idx]);
				if (AmmoCost != none)
				{
					OutString = string(AmmoCost.iAmmo);
					break;
				}
			}
		}
		break;

	case 'SELFCOOLDOWN':
		OutString = "0";
		AbilityTemplate = X2AbilityTemplate(ParseObj);
		if (AbilityTemplate == none)
		{
			AbilityState = XComGameState_Ability(ParseObj);
			if (AbilityState != none)
				AbilityTemplate = AbilityState.GetMyTemplate();
		}
		if (AbilityTemplate != none)
		{
			if (AbilityTemplate.AbilityCooldown != none)
			{
				//  cooldowns tick at the end of the turn, and we don't show the current turn. so we subtract 1.
				//  (e.g. an ability with a "3 turn" cooldown would have a cooldown value of 4 initially, as it cannot be used again the same turn
				//  and for the next 3 subsequent turns).
				OutString = string(AbilityTemplate.AbilityCooldown.iNumTurns - 1);
			}
		}
		break;

	case 'STASISVEST_BONUSHP':
		OutString = string(class'X2Ability_ItemGrantedAbilitySet'.default.STASIS_VEST_HP_BONUS);
		break;

	case 'STASISVEST_REGEN':
		OutString = string(class'X2Ability_ItemGrantedAbilitySet'.default.STASIS_VEST_REGEN_AMOUNT);
		break;

	case 'STASISVEST_MAXREGEN':
		OutString = string(class'X2Ability_ItemGrantedAbilitySet'.default.STASIS_VEST_MAX_REGEN_AMOUNT);
		break;

	case 'GUARDIAN_PROC':
		OutString = string(class'X2Ability_SpecialistAbilitySet'.default.GUARDIAN_PROC);
		break;

	case 'HUNTERSINSTINCTDMG':
		OutString = string(class'X2Ability_RangerAbilitySet'.default.INSTINCT_DMG);
		break;

	case 'MEDITATIONPREPARATIONSTARTINGFOCUS':
		OutString = string(class'X2Ability_TemplarAbilitySet'.default.MEDITATION_PREPARATION_STARTING_FOCUS);
		break;

	case 'PARKOURTRIGGERCHANCE':
		OutString = string(int(class'X2Ability_SkirmisherAbilitySet'.default.PARKOUR_TRIGGER_CHANCE * 100));
		break;

	case 'IMPROVISEDSILENCERREDUCTION':
		OutString = string(class'X2Ability_ReaperAbilitySet'.default.ImprovisedSilencerShadowBreakScalar * 100);
		break;

	case 'INFILTRATIONHACKINGBONUS':
		OutString = string(class'X2Ability_ReaperAbilitySet'.default.InfiltrationHackBonus);
		break;

	case 'HUNTERSINSTINCTCRIT':
		OutString = string(class'X2Ability_RangerAbilitySet'.default.INSTINCT_CRIT);
		break;

	case 'LIGHTNINGSTRIKEMOVEBONUS':
		OutString = string(class'X2Ability_OfficerTrainingSchool'.default.LIGHTNING_STRIKE_MOVE_BONUS);
		break;

	case 'LIGHTNINGSTRIKEDURATION':
		//  subtract 1 from duration since it counts the current turn, which won't read correctly to the user
		OutString = string(class'X2Ability_OfficerTrainingSchool'.default.LIGHTNING_STRIKE_NUM_TURNS - 1);
		break;

	case 'MEDIKITPERUSEHP':
		OutString = string(class'X2Ability_DefaultAbilitySet'.default.MEDIKIT_PERUSEHP);
		break;

	case 'NANOMEDIKITHEALHP':
		OutString = string(class'X2Ability_DefaultAbilitySet'.default.NANOMEDIKIT_PERUSEHP);
		break;

	case 'GREMLINHEALHP':
		OutString = string(class'X2Ability_DefaultAbilitySet'.default.MEDIKIT_PERUSEHP);
		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom', true));
		if (XComHQ != None && XComHQ.IsTechResearched('BattlefieldMedicine'))
		{
			OutString = string(class'X2Ability_DefaultAbilitySet'.default.NANOMEDIKIT_PERUSEHP);
		}
		break;

	case 'STABILIZECOST':
		OutString = string(class'X2Ability_DefaultAbilitySet'.default.MEDIKIT_STABILIZE_AMMO);
		break;

	case 'COMBATSTIMSDURATION':
		OutString = string(class'X2Ability_ItemGrantedAbilitySet'.default.COMBAT_STIM_DURATION);
		break;

	case 'FRENZYDURATION':
		OutString  = string(class'X2Ability_Archon'.default.FRENZY_TURNS_DURATION);
		break;

	case 'FACELESSREGEN':
		OutString = string(class'X2Ability_Faceless'.default.REGENERATION_HEAL_VALUE);
		break;

	case 'FACELESSREGENMP':
		OutString = string(class'X2Ability_Faceless'.default.REGENERATION_HEALMP_VALUE);
		break;

	case 'BERSERKERMELEERESISTANCE':
		OutString = string(class'X2Ability_Berserker'.default.MELEE_RESISTANCE_ARMOR);
		break;
				
	case 'SUPPRESSIONPENALTY':
		if (`XENGINE.IsMultiplayerGame())
		{
			OutString = string(class'X2Effect_Suppression'.default.MultiplayerTargetAimPenalty);
		}
		else
		{
			OutString = string(class'X2Effect_Suppression'.default.SoldierTargetAimPenalty);
			EffectState = XComGameState_Effect(ParseObj);
			if (EffectState != none)
			{
				TargetUnitState = XComGameState_Unit(History.GetGameStateForObjectID(EffectState.ApplyEffectParameters.SourceStateObjectRef.ObjectID));
				if (TargetUnitState != none && TargetUnitState.GetTeam() != eTeam_XCom && TargetUnitState.GetTeam() != eTeam_Resistance)
					OutString = string(class'X2Effect_Suppression'.default.AlienTargetAimPenalty);
			}
			AbilityState = XComGameState_Ability(ParseObj);
			if (AbilityState != None)
			{
				TargetUnitState = XComGameState_Unit(History.GetGameStateForObjectID(AbilityState.OwnerStateObject.ObjectID));
				if (TargetUnitState.GetTeam() != eTeam_XCom && TargetUnitState.GetTeam() != eTeam_Resistance)
					OutString = string(class'X2Effect_Suppression'.default.AlienTargetAimPenalty);
			}
		}
		break;

	case 'CHAINSHOTPENALTY':
		OutString = string(class'X2Ability_GrenadierAbilitySet'.default.CHAINSHOT_HIT_MOD);
		break;

	case 'SHIELDBEARERSHIELDAMOUNT':
		OutString = string(class'X2Ability_AdventShieldbearer'.default.ENERGY_SHIELD_HP);
		break;

	case 'BATTLESCANNERDURATION':
		OutString = string(class'X2Ability_ItemGrantedAbilitySet'.default.BATTLESCANNER_DURATION);
		break;

	case 'HUNKERDEFENSEBONUS':
		OutString = string(class'X2Ability_DefaultAbilitySet'.default.HUNKERDOWN_DEFENSE);
		break;

	case 'HUNKERDODGEBONUS':
		OutString = string(class'X2Ability_DefaultAbilitySet'.default.HUNKERDOWN_DODGE);
		break;

	case 'HOLOTARGETAIMBONUS':
		OutString = string(class'X2Ability_GrenadierAbilitySet'.default.HOLOTARGET_BONUS);
		break;

	case 'CHOSEN_HOLOTARGETAIMBONUS':
		OutString = string(class'X2Ability_Chosen'.default.HOLOTARGET_BONUS);
		break;

	case 'STEADYHANDSAIMBONUS':
		OutString = string(class'X2Ability_SharpshooterAbilitySet'.default.STEADYHANDS_AIM_BONUS);
		break;

	case 'STEADYHANDSCRITBONUS':
		OutString = string(class'X2Ability_SharpshooterAbilitySet'.default.STEADYHANDS_CRIT_BONUS);
		break;

	case 'AIDPROTOCOLDEFENSEBONUS':
		OutString = string(class'X2Effect_AidProtocol'.default.BASE_DEFENSE);
		EffectState = XComGameState_Effect(ParseObj);
		AbilityState = XComGameState_Ability(ParseObj);
		if (EffectState != none)
		{
			ItemState = XComGameState_Item(History.GetGameStateForObjectID(EffectState.ApplyEffectParameters.ItemStateObjectRef.ObjectID));				
		}
		else if (AbilityState != none)
		{
			ItemState = AbilityState.GetSourceWeapon();
		}
		if (ItemState != none)
		{
			GremlinTemplate = X2GremlinTemplate(ItemState.GetMyTemplate());
			if (GremlinTemplate != none)
				OutString = string(GremlinTemplate.AidProtocolBonus + class'X2Effect_AidProtocol'.default.BASE_DEFENSE);
		}
		break;

	case 'BURNDAMAGE':
		OutString = "0";
		EffectState = XComGameState_Effect(ParseObj);
		if (EffectState != none)
		{
			BurningEffect = X2Effect_Burning(EffectState.GetX2Effect());
			if (BurningEffect != none)
			{
				WeaponDamageEffect = BurningEffect.GetBurnDamage();
				if (WeaponDamageEffect != none)
				{
					MinDamage = WeaponDamageEffect.EffectDamageValue.Damage - WeaponDamageEffect.EffectDamageValue.Spread;
					MaxDamage = WeaponDamageEffect.EffectDamageValue.Damage + WeaponDamageEffect.EffectDamageValue.Spread;
					if (MinDamage == MaxDamage)
					{
						OutString = string(MaxDamage);
					}
					else
					{
						OutString = string(MinDamage) @ "-" @ string(MaxDamage);
					}
				}					
			}
		}
		break;

	case 'BLADEMASTERDMG':
		OutString = string(class'X2Ability_RangerAbilitySet'.default.BLADEMASTER_DMG);
		break;

	case 'BLADEMASTERAIM':
		OutString = string(class'X2Ability_RangerAbilitySet'.default.BLADEMASTER_AIM);
		break;

	case 'RUPTUREAMOUNT':
		OutString = string(class'X2Ability_GrenadierAbilitySet'.default.BULLET_SHRED);
		break;

	case 'DEADEYEDMG':
		OutString = string(int(class'X2Effect_DeadeyeDamage'.default.DamageMultiplier * 100));
		break;

	case 'DEADEYEAIM':
		OutString = string(int(class'X2Ability_SharpshooterAbilitySet'.default.DEADEYE_AIM_MULTIPLIER * 100));
		break;

	case 'BLASTPADDING':
		OutString = string(int(class'X2Ability_GrenadierAbilitySet'.default.BLAST_PADDING_DMG_ADJUST * 100));
		break;

	case 'SHADOWSTRIKEAIM':
		OutString = string(class'X2Ability_RangerAbilitySet'.default.SHADOWSTRIKE_AIM);
		break;

	case 'SHADOWSTRIKECRIT':
		OutString = string(class'X2Ability_RangerAbilitySet'.default.SHADOWSTRIKE_CRIT);
		break;

	case 'RAPIDFIREPENALTY':
		OutString = string(class'X2Ability_RangerAbilitySet'.default.RAPIDFIRE_AIM);
		break;

	case 'SHARPSHOOTERAIMBONUS':
		OutString = string(class'X2Ability_SharpshooterAbilitySet'.default.SHARPSHOOTERAIM_BONUS);
		break;

	case 'FIELDMEDICBONUS':
		OutString = string(class'X2Ability_SpecialistAbilitySet'.default.FIELD_MEDIC_BONUS);
		break;

	case 'TURNSREMAINING':
		EffectState = XComGameState_Effect(ParseObj);
		if( EffectState != None )
		{
			OutString = string(EffectState.iTurnsRemaining);
		}
		break;

		case 'STUNNEDACTIONPOINTS':
			TargetUnitState = XComGameState_Unit(ParseObj);
			if( TargetUnitState.StunnedActionPoints + TargetUnitState.StunnedThisTurn > 0 )
			{
				OutString = string(TargetUnitState.StunnedActionPoints + TargetUnitState.StunnedThisTurn);
			}
			else
			{
				// possible we were stunned, but it was immediately removed. Show the action points the stun consumed
				OutString = string(XComGameState_Unit(History.GetPreviousGameStateForObject(TargetUnitState)).ActionPoints.Length 
								   - TargetUnitState.ActionPoints.Length);
			}
			break;

	case 'COOLUNDERPRESSUREBONUS':
		OutString = string(class'X2Ability_SpecialistAbilitySet'.default.UNDER_PRESSURE_BONUS);
		break;

	case 'BIGGESTBOOMSCHANCE':
		OutString = string(class'X2Effect_BiggestBooms'.default.CRIT_CHANCE_BONUS);
		break;

	case 'BIGGESTBOOMSDAMAGE':
		OutString = string(class'X2Effect_BiggestBooms'.default.CRIT_DAMAGE_BONUS);
		break;

	case 'VOLATILIEMIXDAMAGE':
		OutString = string(class'X2Ability_GrenadierAbilitySet'.default.VOLATILE_DAMAGE);
		break;

	case 'HITWHEREITHURTS':
		OutString = string(class'X2Ability_SharpshooterAbilitySet'.default.HITWHEREITHURTS_CRIT);
		break;

	case 'HELLWEAVEPROCCHANCE':
		OutString = string(class'X2Ability_ItemGrantedAbilitySet'.default.SCORCHCIRCUITS_APPLY_CHANCE);
		break;

	case 'TRACERROUNDSAIMBONUS':
		OutString = string(class'X2Effect_TracerRounds'.default.AimMod);
		break;

	case 'TRACERROUNDSDAMAGEPENALTY':
		OutString = string(class'X2Item_DefaultAmmo'.default.TRACER_DMGMOD);
		break;

	case 'TALONROUNDSCRITCHANCE':
		OutString = string(class'X2Ability_ItemGrantedAbilitySet'.default.TALON_CRITCHANCE);
		break;

	case 'TALONROUNDSCRITDAMAGEBONUS':
		OutString = string(class'X2Ability_ItemGrantedAbilitySet'.default.TALON_CRIT);
		break;

	case 'TALONROUNDSAIMPENALTY':
		OutString = string(class'X2Ability_ItemGrantedAbilitySet'.default.TALON_AIM);
		break;

	case 'APROUNDSPIERCEBONUS':
		OutString = string(class'X2Ability_ItemGrantedAbilitySet'.default.APROUNDS_PIERCE);
		break;

	case 'APROUNDSCRITPENALTY':
		OutString = string(class'X2Ability_ItemGrantedAbilitySet'.default.APROUNDS_CRITCHANCE);
		break;

	case 'APROUNDSCRITDAMAGEPENALTY':
		OutString = string(class'X2Ability_ItemGrantedAbilitySet'.default.APROUNDS_CRIT);
		break;

	case 'FULLTHROTTLEMOBILITY':
		OutString = string(class'X2Ability_SkirmisherAbilitySet'.default.FullThrottleMobility);
		break;

	case 'RECKONINGDAMAGE':
		OutString = string(class'X2Ability_SkirmisherAbilitySet'.default.RECKONING_DMG);
		break;

	case 'ZEROINCRIT':
		OutString = string(class'X2Effect_ZeroIn'.default.CritPerShot);
		break;

	case 'ZEROINAIM':
		OutString = string(class'X2Effect_ZeroIn'.default.LockedInAimPerShot);
		break;		

	case 'BLOODTRAILDAMAGE':
		OutString = string(class'X2Ability_ReaperAbilitySet'.default.BloodTrailDamage);
		break;

	case 'NEEDLEPIERCE':
		OutString = string(class'X2Ability_ReaperAbilitySet'.default.NeedlePierce);
		break;

	case 'SOULHARVESTCRIT':
		OutString = string(class'X2Ability_ReaperAbilitySet'.default.PaleHorseCritBoost);
		break;

	case 'SOULHARVESTMAX':
		OutString = string(class'X2Ability_ReaperAbilitySet'.default.PaleHorseMax);
		break;

	case 'SHRAPNELDAMAGE':
		OutString = string(class'X2Ability_ReaperAbilitySet'.default.HomingShrapnelDamage.Damage - class'X2Ability_ReaperAbilitySet'.default.HomingMineDamage.Damage);
		break;

	case 'SHRAPNELRADIUS':
		OutString = string(Round(class'X2Ability_ReaperAbilitySet'.default.HomingShrapnelBonusRadius / 1.5f));
		break;

	case 'FOCUS1MOBILITY':
		OutString = string(class'X2Ability_TemplarAbilitySet'.default.FOCUS1MOBILITY);
		break;

	case 'FOCUS1DODGE':
		OutString = string(class'X2Ability_TemplarAbilitySet'.default.FOCUS1DODGE);
		break;

	case 'FOCUS1RENDDAMAGE':
		OutString = string(class'X2Ability_TemplarAbilitySet'.default.FOCUS1RENDDAMAGE);
		break;

	case 'FOCUS2MOBILITY':
		OutString = string(class'X2Ability_TemplarAbilitySet'.default.FOCUS2MOBILITY);
		break;

	case 'FOCUS2DODGE':
		OutString = string(class'X2Ability_TemplarAbilitySet'.default.FOCUS2DODGE);
		break;

	case 'FOCUS2RENDDAMAGE':
		OutString = string(class'X2Ability_TemplarAbilitySet'.default.FOCUS2RENDDAMAGE);
		break;

	case 'FOCUS3MOBILITY':
		OutString = string(class'X2Ability_TemplarAbilitySet'.default.FOCUS3MOBILITY);
		break;

	case 'FOCUS3DODGE':
		OutString = string(class'X2Ability_TemplarAbilitySet'.default.FOCUS3DODGE);
		break;

	case 'FOCUS3RENDDAMAGE':
		OutString = string(class'X2Ability_TemplarAbilitySet'.default.FOCUS3RENDDAMAGE);
		break;

	case 'RENDSTUNCHANCE':
		OutString = string(int(class'X2Ability_TemplarAbilitySet'.default.REND_STUN_AND_KNOCKBACK_CHANCE * 100));
		break;

	case 'RENDDISORIENTCHANCE':
		OutString = string(int(class'X2Ability_TemplarAbilitySet'.default.REND_DISORIENT_CHANCE * 100));
		break;

	case 'AMPLIFYDAMAGEMULT':
		OutString = string(int(class'X2Ability_TemplarAbilitySet'.default.AmplifyBonusDamageMult * 100));
		break;

	case 'OVERCHARGECHANCE':
		OutString = string(class'X2Ability_TemplarAbilitySet'.default.OVERCHARGE_FOCUS_CHANCE);
		break;

	case 'RECOILAIMBONUS':
		OutString = string(class'X2Ability_TemplarAbilitySet'.default.VoltHitMod);
		break;

	case 'CHANNELLOOTCHANCE':
		OutString = string(class'X2Ability_TemplarAbilitySet'.default.ChannelChance);
		break;

	case 'CHANNELLOOTPSICHANCE':
		OutString = string(class'X2Ability_TemplarAbilitySet'.default.ChannelPsionicChance);
		break;

	case 'DEFLECTCHANCE':
		OutString = string(class'X2Effect_Deflect'.default.DeflectBaseChance);
		break;

	case 'DEFLECTCHANCEPERFOCUS':
		OutString = string(class'X2Effect_Deflect'.default.DeflectPerFocusChance);
		break;

	case 'REFLECTCHANCE':
		OutString = string(class'X2Effect_Deflect'.default.ReflectBaseChance);
		break;

	case 'VOIDCONDUITACTIONDMG':
		OutString = string(class'X2Ability_TemplarAbilitySet'.default.VoidConduitPerActionDamage);
		break;

	case 'VOIDCONDUITDMG':
		OutString = string(class'X2Ability_TemplarAbilitySet'.default.VoidConduitInitialDamage);
		break;

	case 'STUNSTRIKEHITCHANCE':
		OutString = string(class'X2Ability_TemplarAbilitySet'.default.StunStrikeHitChance);
		break;

	case 'STUNSTRIKEFOCUSHITCHANCE':
		OutString = string(class'X2Ability_TemplarAbilitySet'.default.StunStrikeFocusMultiplierHitChance);
		break;

	case 'STUNSTRIKEDISORIENTCHANCE':
		OutString = string(class'X2Ability_TemplarAbilitySet'.default.StunStrikeDisorientFocusMultiplier);
		break;

// Weapon Upgrades

	case 'CRITINCREASE':
	case 'SCOPEAIMINCREASE':
	case 'EXPMAGINCREASE':
	case 'HAIRTRIGGERCHANCE':
	case 'ALRELOADCOUNT':
	case 'MISSDAMAGEAMT':
	case 'FREEKILLCHANCE':
		UpgradeTemplate = X2WeaponUpgradeTemplate(ParseObj);
		if (UpgradeTemplate != none && UpgradeTemplate.GetBonusAmountFn != none)
		{
			OutString = string(UpgradeTemplate.GetBonusAmountFn(UpgradeTemplate));
		}
		break;

// Hack Rewards

	case 'PRIORITY_DATA_DARK_EVENT_EXTENSION_HOURS':
		OutString = string(class'X2HackReward'.default.PRIORITY_DATA_DARK_EVENT_EXTENSION_HOURS / 24 / 7);
		break;

	case 'WATCH_LIST_CONTACT_COST_MOD':
		OutString = string(int(class'X2HackReward'.default.WATCH_LIST_CONTACT_COST_MOD * 100));
		break;

	case 'INSIGHT_TECH_COMPLETION_MOD':
		OutString = string(int(class'X2HackReward'.default.INSIGHT_TECH_COMPLETION_MOD * 100));
		break;

	case 'SATELLITE_DATA_SCAN_RATE_MOD':
		OutString = string(int(class'X2HackReward'.default.SATELLITE_DATA_SCAN_RATE_MOD * 100));
		break;

	case 'SATELLITE_DATA_SCAN_RATE_DURATION_HOURS':
		OutString = string(class'X2HackReward'.default.SATELLITE_DATA_SCAN_RATE_DURATION_HOURS / 24 / 7);
		break;

	case 'RESISTANCE_BROADCAST_INCOME_BONUS':
		OutString = string(class'X2HackReward'.default.RESISTANCE_BROADCAST_INCOME_BONUS);
		break;

	case 'ENEMY_PROTOCOL_HACKING_BONUS':
		OutString = string(class'X2HackReward'.default.ENEMY_PROTOCOL_HACKING_BONUS);
		break;

// Hack Reward Abilities

	case 'TargetingAimAndCrit_AimBonus':
		OutString = string(class'X2Ability_HackRewards'.default.TargetingAimAndCrit_AimBonus);
		break;

	case 'TargetingAimAndCrit_CritBonus':
		OutString = string(class'X2Ability_HackRewards'.default.TargetingAimAndCrit_CritBonus);
		break;

	case 'TargetingDodge_DodgeBonus':
		OutString = string(class'X2Ability_HackRewards'.default.TargetingDodge_DodgeBonus);
		break;

	case 'TargetingCrit_CritBonus':
		OutString = string(class'X2Ability_HackRewards'.default.TargetingCrit_CritBonus);
		break;

	case 'Hypnography_WillBonus':
		OutString = string(int(-class'X2Ability_HackRewards'.default.Hypnography_WillBonus));
		break;

	case 'VideoFeed_SightBonus':
		OutString = string(int(class'X2Ability_HackRewards'.default.VideoFeed_SightBonus));
		break;

	case 'Distortion_WillBonus':
		OutString = string(int(-class'X2Ability_HackRewards'.default.Distortion_WillBonus));
		break;

	case 'Blitz_Charges':
		OutString = string(class'X2Ability_HackRewards'.default.Blitz_Charges);
		break;

	case 'Override_Charges':
		OutString = string(class'X2Ability_HackRewards'.default.Override_Charges);
		break;

	case 'MARKTARGETAIMBONUS':
		OutString = string(class'X2Effect_Marked'.default.ACCURACY_CHANCE_BONUS);
		break;

	case 'CLASSNAME':
		if (StrategyParseObj != none)
			TargetUnitState = XComGameState_Unit(StrategyParseObj);
		else
		{
			AbilityState = XComGameState_Ability(ParseObj);
			EffectState = XComGameState_Effect(ParseObj);
			if (AbilityState != none)
				TargetUnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(AbilityState.OwnerStateObject.ObjectID));
			else if (EffectState != none)
				TargetUnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(EffectState.ApplyEffectParameters.TargetStateObjectRef.ObjectID));
			else
			{
				// If everything else fails, use a generic primary weapon string
				AbilityTemplate = X2AbilityTemplate(ParseObj);
				OutString = AbilityTemplate.LocDefaultSoldierClass;
			}
		}
		if (TargetUnitState != none)
		{
			// Use the GameState check here because in Multiplayer games there is no History
			OutString = TargetUnitState.GetSoldierClassTemplate().DisplayName;
		}
		break;

	case 'WEAPONNAME':
		if (StrategyParseObj != none)
			TargetUnitState = XComGameState_Unit(StrategyParseObj);
		else
		{
			AbilityState = XComGameState_Ability(ParseObj);
			EffectState = XComGameState_Effect(ParseObj);
			if (AbilityState != none)
				TargetUnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(AbilityState.OwnerStateObject.ObjectID));
			else if (EffectState != none)
				TargetUnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(EffectState.ApplyEffectParameters.TargetStateObjectRef.ObjectID));
			else
			{
				// If everything else fails, use a generic primary weapon string
				AbilityTemplate = X2AbilityTemplate(ParseObj);
				OutString = AbilityTemplate.LocDefaultPrimaryWeapon;
			}
		}
		if (TargetUnitState != none)
		{
			// Use the GameState check here because in Multiplayer games there is no History
			OutString = TargetUnitState.GetItemInSlot(eInvSlot_PrimaryWeapon, GameState).GetMyTemplate().GetItemAbilityDescName();
		}
		break;

	case 'SECONDARYWEAPONNAME':
		if (StrategyParseObj != none)
			TargetUnitState = XComGameState_Unit(StrategyParseObj);
		else
		{
			AbilityState = XComGameState_Ability(ParseObj);
			EffectState = XComGameState_Effect(ParseObj);
			if (AbilityState != none)
				TargetUnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(AbilityState.OwnerStateObject.ObjectID));
			else if (EffectState != none)
				TargetUnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(EffectState.ApplyEffectParameters.TargetStateObjectRef.ObjectID));
			else
			{
				// If everything else fails, use a generic secondary weapon string
				AbilityTemplate = X2AbilityTemplate(ParseObj);
				OutString = AbilityTemplate.LocDefaultSecondaryWeapon;
			}
		}
		if (TargetUnitState != none)
		{
			// Use the GameState check here because in Multiplayer games there is no History
			OutString = TargetUnitState.GetItemInSlot(eInvSlot_SecondaryWeapon, GameState).GetMyTemplate().GetItemAbilityDescName();
		}
		break;
	}

	if (OutString != "")        //  the string was handled already
		return;

	//  allow DLC info to handle the tag
	DLCInfos = `ONLINEEVENTMGR.GetDLCInfos(false);
	foreach DLCInfos(DLCInfo)
	{
		if (DLCInfo.AbilityTagExpandHandler(InString, OutString))
			return;
	}

	`RedScreenOnce("Unhandled localization tag: '"$Tag$":"$InString$"'");
	OutString = "<Ability:"$InString$"/>";
}

DefaultProperties
{
	Tag = "Ability";
}
