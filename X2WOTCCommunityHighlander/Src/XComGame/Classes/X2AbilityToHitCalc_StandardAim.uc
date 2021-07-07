//---------------------------------------------------------------------------------------
//  FILE:    X2AbilityToHitCalc_StandardAim.uc
//  AUTHOR:  Joshua Bouscher
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2AbilityToHitCalc_StandardAim extends X2AbilityToHitCalc config(GameCore);

var() bool bIndirectFire;                         // Indirect fire is stuff like grenades. Hit chance is 100, but crit and dodge and armor mitigation still exists.
var() bool bMeleeAttack;                          // Melee attacks ignore cover and get their own instrinsic hit bonus.
var() bool bReactionFire;                         // Reaction fire suffers specific penalties to the hit roll. Reaction fire also causes the Flanking hit bonus to be ignored.
var() bool bAllowCrit;                            // Ability will build crit into the hit table as applicable
var() bool bHitsAreCrits;                         // After the roll is made, eHit_Success will always change into eHit_Crit
var() bool bMultiTargetOnly;                      // Guarantees a success for the ability when there is no primary target.
var() bool bOnlyMultiHitWithSuccess;              // Multi hit targets will only be hit as long as there is a successful roll (e.g. Sharpshooter's Faceoff ability)
var() bool bGuaranteedHit;                        // Skips all of the normal hit mods but does allow for armor mitigation rolls as normal.
var() bool bIgnoreCoverBonus;					  // Standard high/low cover bonuses do not apply
var() float FinalMultiplier;                      // Modifier applied to otherwise final aim chance. Will calculate an amount and display the ability as the reason for the modifier.

//  Initial modifiers that are always used by the ability. ModReason will be the ability name.
var() int BuiltInHitMod;
var() int BuiltInCritMod; 

var config bool SHOULD_ENABLE_PENALTY_ON_ANGLE_TO_EXTENDED_HIGH_COVER; // if true, then we should check for extended high cover protecting the target
var config bool SHOULD_DISABLE_BONUS_ON_ANGLE_TO_EXTENDED_LOW_COVER; // if true, then before we try to apply an angle bonus, we should check for extended low cover protecting the target
var config int MAX_TILE_DISTANCE_TO_COVER;		// Maximum tile distance between shooter & target at which an angle bonus can be applied
var config float MIN_ANGLE_TO_COVER;			// Angle to cover at which to apply the MAXimum bonus to hit targets behind cover
var config float MAX_ANGLE_TO_COVER;			// Angle to cover at which to apply the MINimum bonus to hit targets behind cover
var config float MIN_ANGLE_BONUS_MOD;			// the minimum multiplier against the current COVER_BONUS to apply to the angle of attack
var config float MAX_ANGLE_BONUS_MOD;			// the maximum multiplier against the current COVER_BONUS to apply to the angle of attack
var config float MIN_ANGLE_PENALTY;				// the minimum penalty to apply to the angle of attack for a shot against a target behind extended high cover
var config float MAX_ANGLE_PENALTY;				// the maximum penalty to apply to the angle of attack for a shot against a target behind extended high cover
var config int LOW_COVER_BONUS;               // Flat aim penalty for attacker when target is in low cover
var config int HIGH_COVER_BONUS;              // As above, for high cover
var config int MP_FLANKING_CRIT_BONUS;          // All units in multiplayer will use this value
var config int MELEE_HIT_BONUS;
var config int SQUADSIGHT_CRIT_MOD;             // Crit mod when a target is visible only via squadsight
var config int SQUADSIGHT_DISTANCE_MOD;         // Per tile hit mod when a target is visible only via squadsight
var config float REACTION_FINALMOD;
var config float REACTION_DASHING_FINALMOD;

// The baseline size of an XCom squad.
var config int NormalSquadSize;

// In order for XCom shots to receive Aim Assist help, this baseline hit chance must be met.
var config int ReasonableShotMinimumToEnableAimAssist;

// The Maximum score that Aim Assist will produce
var config int MaxAimAssistScore;

// This value is multiplied against the base hit chance for XCom shots.
// (Note that this is only applied in Easy & Normal Difficulty)
var config array<float> BaseXComHitChanceModifier;

// The adjustment applied to XCom attack hit chances for each consecutive missed attack XCom has made this turn.
// (Note that this is only applied in Easy & Normal Difficulty)
var config array<int> MissStreakChanceAdjustment;

// The adjustment applied to Alien attack hit chances for each consecutive successful attack Aliens have made this turn.
// (Note that this is only applied in Easy & Normal Difficulty)
var config array<int> HitStreakChanceAdjustment;

// The adjustment applied to XCom attack hit chances for each soldier XCom has lost below the NormalSquadSize.  
// (Note that this is only applied in Easy Difficulty)
var config array<int> SoldiersLostXComHitChanceAdjustment;

// The adjustment applied to Alien attack hit chances for each soldier XCom has lost below the NormalSquadSize.  
// (Note that this is only applied in Easy Difficulty)
var config array<int> SoldiersLostAlienHitChanceAdjustment;

// This value is multiplied against the base chance to hit for Alien shots against The Lost targets
var config array<float> AlienVsTheLostHitChanceAdjustment;

// This value is multiplied against the base chance to hit for The Lost attacks against Alien targets
var config array<float> TheLostVsAlienHitChanceAdjustment;

// Variable for Issue #237
// This array is tested against crit chance breakdown calculation to ignore modifiers that will be added by effects later
var config array<name> CritUpgradesThatDontUseEffects;

function RollForAbilityHit(XComGameState_Ability kAbility, AvailableTarget kTarget, out AbilityResultContext ResultContext)
{
	local EAbilityHitResult HitResult;
	local int MultiIndex, CalculatedHitChance;
	local ArmorMitigationResults ArmorMitigated;

	if (bMultiTargetOnly)
	{
		ResultContext.HitResult = eHit_Success;
	}
	else
	{
		InternalRollForAbilityHit(kAbility, kTarget, true, ResultContext, HitResult, ArmorMitigated, CalculatedHitChance);
		ResultContext.HitResult = HitResult;
		ResultContext.ArmorMitigation = ArmorMitigated;
		ResultContext.CalculatedHitChance = CalculatedHitChance;
	}

	for (MultiIndex = 0; MultiIndex < kTarget.AdditionalTargets.Length; ++MultiIndex)
	{
		if (bOnlyMultiHitWithSuccess && class'XComGameStateContext_Ability'.static.IsHitResultMiss(HitResult))
		{
			ResultContext.MultiTargetHitResults.AddItem(eHit_Miss);
			ResultContext.MultiTargetArmorMitigation.AddItem(ArmorMitigated);
			ResultContext.MultiTargetStatContestResult.AddItem(0);
		}
		else
		{
			kTarget.PrimaryTarget = kTarget.AdditionalTargets[MultiIndex];
			InternalRollForAbilityHit(kAbility, kTarget, false, ResultContext, HitResult, ArmorMitigated, CalculatedHitChance);
			ResultContext.MultiTargetHitResults.AddItem(HitResult);
			ResultContext.MultiTargetArmorMitigation.AddItem(ArmorMitigated);
			ResultContext.MultiTargetStatContestResult.AddItem(0);
		}
	}
}

function InternalRollForAbilityHit(XComGameState_Ability kAbility, AvailableTarget kTarget, bool bIsPrimaryTarget, const out AbilityResultContext ResultContext, out EAbilityHitResult Result, out ArmorMitigationResults ArmorMitigated, out int HitChance)
{
	local int i, RandRoll, Current, ModifiedHitChance;
	local EAbilityHitResult DebugResult, ChangeResult;
	local ArmorMitigationResults Armor;
	local XComGameState_Unit TargetState, UnitState;
	local XComGameState_Player PlayerState;
	local XComGameStateHistory History;
	local StateObjectReference EffectRef;
	local XComGameState_Effect EffectState;
	local bool bRolledResultIsAMiss, bModHitRoll;
	local bool HitsAreCrits;
	local string LogMsg;
	local ETeam CurrentPlayerTeam;
	local ShotBreakdown m_ShotBreakdown;

	History = `XCOMHISTORY;

	`log("===" $ GetFuncName() $ "===", true, 'XCom_HitRolls');
	`log("Attacker ID:" @ kAbility.OwnerStateObject.ObjectID, true, 'XCom_HitRolls');
	`log("Target ID:" @ kTarget.PrimaryTarget.ObjectID, true, 'XCom_HitRolls');
	`log("Ability:" @ kAbility.GetMyTemplate().LocFriendlyName @ "(" $ kAbility.GetMyTemplateName() $ ")", true, 'XCom_HitRolls');

	ArmorMitigated = Armor;     //  clear out fields just in case
	HitsAreCrits = bHitsAreCrits;
	if (`CHEATMGR != none)
	{
		if (`CHEATMGR.bForceCritHits)
			HitsAreCrits = true;

		if (`CHEATMGR.bNoLuck)
		{
			`log("NoLuck cheat forcing a miss.", true, 'XCom_HitRolls');
			Result = eHit_Miss;			
			return;
		}
		if (`CHEATMGR.bDeadEye)
		{
			UnitState = XComGameState_Unit(History.GetGameStateForObjectID(kAbility.OwnerStateObject.ObjectID));
			if( !`CHEATMGR.bXComOnlyDeadEye || !UnitState.ControllingPlayerIsAI() )
			{
				`log("DeadEye cheat forcing a hit.", true, 'XCom_HitRolls');
				Result = eHit_Success;
				if( HitsAreCrits )
					Result = eHit_Crit;
				return;
			}
		}
	}

	HitChance = GetHitChance(kAbility, kTarget, m_ShotBreakdown, true);
	RandRoll = `SYNC_RAND_TYPED(100, ESyncRandType_Generic);
	Result = eHit_Miss;

	`log("=" $ GetFuncName() $ "=", true, 'XCom_HitRolls');
	`log("Final hit chance:" @ HitChance, true, 'XCom_HitRolls');
	`log("Random roll:" @ RandRoll, true, 'XCom_HitRolls');
	//  GetHitChance fills out m_ShotBreakdown and its ResultTable
	for (i = 0; i < eHit_Miss; ++i)     //  If we don't match a result before miss, then it's a miss.
	{
		Current += m_ShotBreakdown.ResultTable[i];
		DebugResult = EAbilityHitResult(i);
		`log("Checking table" @ DebugResult @ "(" $ Current $ ")...", true, 'XCom_HitRolls');
		if (RandRoll < Current)
		{
			Result = EAbilityHitResult(i);
			`log("MATCH!", true, 'XCom_HitRolls');
			break;
		}
	}	
	if (HitsAreCrits && Result == eHit_Success)
		Result = eHit_Crit;

	UnitState = XComGameState_Unit(History.GetGameStateForObjectID(kAbility.OwnerStateObject.ObjectID));
	TargetState = XComGameState_Unit(History.GetGameStateForObjectID(kTarget.PrimaryTarget.ObjectID));
	
	// Issue #426: ChangeHitResultForX() code block moved to later in method.
	/// HL-Docs: ref:Bugfixes; issue:426
	/// Fix `X2AbilityToHitCalc_StandardAim` discarding unfavorable (for XCOM) changes to hit results from effects
	// Due to how GetModifiedHitChanceForCurrentDifficulty() is implemented, it reverts attempts to change
	// XCom Hits to Misses, or enemy misses to hits.
	// The LW2 graze band issues are related to this phenomenon, since the graze band has the effect
	// of changing some what "should" be enemy misses to hits (specifically graze result)

	// Aim Assist (miss streak prevention)
	bRolledResultIsAMiss = class'XComGameStateContext_Ability'.static.IsHitResultMiss(Result);
	
	//  reaction  fire shots and guaranteed hits do not get adjusted for difficulty
	if( UnitState != None &&
		!bReactionFire &&
		!bGuaranteedHit && 
		m_ShotBreakdown.SpecialGuaranteedHit == '')
	{
		PlayerState = XComGameState_Player(History.GetGameStateForObjectID(UnitState.GetAssociatedPlayerID()));
		CurrentPlayerTeam = PlayerState.GetTeam();

		if( bRolledResultIsAMiss && CurrentPlayerTeam == eTeam_XCom )
		{
			ModifiedHitChance = GetModifiedHitChanceForCurrentDifficulty(PlayerState, TargetState, HitChance);

			if( RandRoll < ModifiedHitChance )
			{
				Result = eHit_Success;
				bModHitRoll = true;
				`log("*** AIM ASSIST forcing an XCom MISS to become a HIT!", true, 'XCom_HitRolls');
			}
		}
		else if( !bRolledResultIsAMiss && (CurrentPlayerTeam == eTeam_Alien || CurrentPlayerTeam == eTeam_TheLost) )
		{
			ModifiedHitChance = GetModifiedHitChanceForCurrentDifficulty(PlayerState, TargetState, HitChance);

			if( RandRoll >= ModifiedHitChance )
			{
				Result = eHit_Miss;
				bModHitRoll = true;
				`log("*** AIM ASSIST forcing an Alien HIT to become a MISS!", true, 'XCom_HitRolls');
			}
		}
	}

	`log("***HIT" @ Result, !bRolledResultIsAMiss, 'XCom_HitRolls');
	`log("***MISS" @ Result, bRolledResultIsAMiss, 'XCom_HitRolls');

	// Start Issue #426: Block moved from earlier. Only code change is for lightning reflexes,
	// because bRolledResultIsAMiss was used for both aim assist and reflexes
	if (UnitState != none && TargetState != none)
	{
		foreach UnitState.AffectedByEffects(EffectRef)
		{
			EffectState = XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID));
			if (EffectState != none)
			{
				if (EffectState.GetX2Effect().ChangeHitResultForAttacker(UnitState, TargetState, kAbility, Result, ChangeResult))
				{
					`log("Effect" @ EffectState.GetX2Effect().FriendlyName @ "changing hit result for attacker:" @ ChangeResult,true,'XCom_HitRolls');
					Result = ChangeResult;
				}
			}
		}
		foreach TargetState.AffectedByEffects(EffectRef)
		{
			EffectState = XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID));
			if (EffectState != none)
			{
				if (EffectState.GetX2Effect().ChangeHitResultForTarget(EffectState, UnitState, TargetState, kAbility, bIsPrimaryTarget, Result, ChangeResult))
				{
					`log("Effect" @ EffectState.GetX2Effect().FriendlyName @ "changing hit result for target:" @ ChangeResult, true, 'XCom_HitRolls');
					Result = ChangeResult;
				}
			}
		}
	}

	if (TargetState != none)
	{
		//  Check for Lightning Reflexes
		if (bReactionFire && TargetState.bLightningReflexes && !class'XComGameStateContext_Ability'.static.IsHitResultMiss(Result))
		{
			Result = eHit_LightningReflexes;
			`log("Lightning Reflexes triggered! Shot will miss.", true, 'XCom_HitRolls');
		}
	}	
	// End Issue #426

	if (UnitState != none && TargetState != none)
	{
		LogMsg = class'XLocalizedData'.default.StandardAimLogMsg;
		LogMsg = repl(LogMsg, "#Shooter", UnitState.GetName(eNameType_RankFull));
		LogMsg = repl(LogMsg, "#Target", TargetState.GetName(eNameType_RankFull));
		LogMsg = repl(LogMsg, "#Ability", kAbility.GetMyTemplate().LocFriendlyName);
		LogMsg = repl(LogMsg, "#Chance", bModHitRoll ? ModifiedHitChance : HitChance);
		LogMsg = repl(LogMsg, "#Roll", RandRoll);
		LogMsg = repl(LogMsg, "#Result", class'X2TacticalGameRulesetDataStructures'.default.m_aAbilityHitResultStrings[Result]);
		`COMBATLOG(LogMsg);
	}
}

protected function int GetHitChance(XComGameState_Ability kAbility, AvailableTarget kTarget, optional out ShotBreakdown m_ShotBreakdown, optional bool bDebugLog = false)
{
	local XComGameState_Unit UnitState, TargetState;
	local XComGameState_Item SourceWeapon;
	local GameRulesCache_VisibilityInfo VisInfo;
	local array<X2WeaponUpgradeTemplate> WeaponUpgrades;
	local int i, iWeaponMod, iRangeModifier, Tiles;
	local ShotBreakdown EmptyShotBreakdown;
	local array<ShotModifierInfo> EffectModifiers;
	local StateObjectReference EffectRef;
	local XComGameState_Effect EffectState;
	local XComGameStateHistory History;
	local bool bFlanking, bIgnoreGraze, bSquadsight;
	local string IgnoreGrazeReason;
	local X2AbilityTemplate AbilityTemplate;
	local array<XComGameState_Effect> StatMods;
	local array<float> StatModValues;
	local X2Effect_Persistent PersistentEffect;
	local array<X2Effect_Persistent> UniqueToHitEffects;
	local float FinalAdjust, CoverValue, AngleToCoverModifier, Alpha;
	local bool bShouldAddAngleToCoverBonus;
	local TTile UnitTileLocation, TargetTileLocation;
	local ECoverType NextTileOverCoverType;
	local int TileDistance;

	/// HL-Docs: feature:GetHitChanceEvents; issue:1031; tags:tactical
	/// WARNING! Triggering events in `X2AbilityToHitCalc::GetHitChance()` and other functions called by this function
	/// may freeze (hard hang) the game under certain circumstances.
	///
	/// In our experiments, the game would hang when the player used a moving melee ability when an event was triggered
	/// in `UITacticalHUD_AbilityContainer::ConfirmAbility()`  right above the 
	/// `XComPresentationLayer(Owner.Owner).PopTargetingStates();` line or anywhere further down the script trace,
	/// while another event was also triggered in `GetHitChance()` or anywhere further down the script trace.
	///
	/// The game hangs while executing UI code, but it is the event in the To Hit Calculation logic that induces it.
	/// The speculation is that triggering events in `GetHitChance()` somehow corrupts the event manager, or it
	/// could be a threading issue.

	`log("=" $ GetFuncName() $ "=", bDebugLog, 'XCom_HitRolls');

	//  @TODO gameplay handle non-unit targets
	History = `XCOMHISTORY;
	UnitState = XComGameState_Unit(History.GetGameStateForObjectID( kAbility.OwnerStateObject.ObjectID ));
	TargetState = XComGameState_Unit(History.GetGameStateForObjectID( kTarget.PrimaryTarget.ObjectID ));
	if (kAbility != none)
	{
		AbilityTemplate = kAbility.GetMyTemplate();
		SourceWeapon = kAbility.GetSourceWeapon();			
	}

	//  reset shot breakdown
	m_ShotBreakdown = EmptyShotBreakdown;

	//  check for a special guaranteed hit
	m_ShotBreakdown.SpecialGuaranteedHit = UnitState.CheckSpecialGuaranteedHit(kAbility, SourceWeapon, TargetState);
	m_ShotBreakdown.SpecialCritLabel = UnitState.CheckSpecialCritLabel(kAbility, SourceWeapon, TargetState);

	//  add all of the built-in modifiers
	if (bGuaranteedHit || m_ShotBreakdown.SpecialGuaranteedHit != '')
	{
		//  call the super version to bypass our check to ignore success mods for guaranteed hits
		super.AddModifier(100, AbilityTemplate.LocFriendlyName, m_ShotBreakdown, eHit_Success, bDebugLog);
	}
	else if (bIndirectFire)
	{
		m_ShotBreakdown.HideShotBreakdown = true;
		AddModifier(100, AbilityTemplate.LocFriendlyName, m_ShotBreakdown, eHit_Success, bDebugLog);
	}

	AddModifier(BuiltInHitMod, AbilityTemplate.LocFriendlyName, m_ShotBreakdown, eHit_Success, bDebugLog);
	AddModifier(BuiltInCritMod, AbilityTemplate.LocFriendlyName, m_ShotBreakdown, eHit_Crit, bDebugLog);

	if (UnitState != none && TargetState == none)
	{
		// when targeting non-units, we have a 100% chance to hit. They can't dodge or otherwise
		// mess up our shots
		m_ShotBreakdown.HideShotBreakdown = true;
		AddModifier(100, class'XLocalizedData'.default.OffenseStat, m_ShotBreakdown, eHit_Success, bDebugLog);
	}
	else if (UnitState != none && TargetState != none)
	{				
		if (!bIndirectFire)
		{
			// StandardAim (with direct fire) will require visibility info between source and target (to check cover). 
			if (`TACTICALRULES.VisibilityMgr.GetVisibilityInfo(UnitState.ObjectID, TargetState.ObjectID, VisInfo))
			{	
				if (UnitState.CanFlank() && TargetState.GetMyTemplate().bCanTakeCover && VisInfo.TargetCover == CT_None)
					bFlanking = true;
				if (VisInfo.bClearLOS && !VisInfo.bVisibleGameplay)
					bSquadsight = true;

				//  Add basic offense and defense values
				AddModifier(UnitState.GetBaseStat(eStat_Offense), class'XLocalizedData'.default.OffenseStat, m_ShotBreakdown, eHit_Success, bDebugLog);
				// Single Line Change for Issue #313
				/// HL-Docs: ref:GetStatModifiersFixed
				UnitState.GetStatModifiersFixed(eStat_Offense, StatMods, StatModValues);
				for (i = 0; i < StatMods.Length; ++i)
				{
					AddModifier(int(StatModValues[i]), StatMods[i].GetX2Effect().FriendlyName, m_ShotBreakdown, eHit_Success, bDebugLog);
				}
				//  Flanking bonus (do not apply to overwatch shots)
				if (bFlanking && !bReactionFire && !bMeleeAttack)
				{
					AddModifier(UnitState.GetCurrentStat(eStat_FlankingAimBonus), class'XLocalizedData'.default.FlankingAimBonus, m_ShotBreakdown, eHit_Success, bDebugLog);
				}
				//  Squadsight penalty
				if (bSquadsight)
				{
					Tiles = UnitState.TileDistanceBetween(TargetState);
					//  remove number of tiles within visible range (which is in meters, so convert to units, and divide that by tile size)
					Tiles -= UnitState.GetVisibilityRadius() * class'XComWorldData'.const.WORLD_METERS_TO_UNITS_MULTIPLIER / class'XComWorldData'.const.WORLD_StepSize;
					if (Tiles > 0)      //  pretty much should be since a squadsight target is by definition beyond sight range. but... 
						AddModifier(default.SQUADSIGHT_DISTANCE_MOD * Tiles, class'XLocalizedData'.default.SquadsightMod, m_ShotBreakdown, eHit_Success, bDebugLog);
					else if (Tiles == 0)	//	right at the boundary, but squadsight IS being used so treat it like one tile
						AddModifier(default.SQUADSIGHT_DISTANCE_MOD, class'XLocalizedData'.default.SquadsightMod, m_ShotBreakdown, eHit_Success, bDebugLog);
				}

				//  Check for modifier from weapon 				
				if (SourceWeapon != none)
				{
					iWeaponMod = SourceWeapon.GetItemAimModifier();
					AddModifier(iWeaponMod, class'XLocalizedData'.default.WeaponAimBonus, m_ShotBreakdown, eHit_Success, bDebugLog);

					WeaponUpgrades = SourceWeapon.GetMyWeaponUpgradeTemplates();
					for (i = 0; i < WeaponUpgrades.Length; ++i)
					{
						if (WeaponUpgrades[i].AddHitChanceModifierFn != None)
						{
							if (WeaponUpgrades[i].AddHitChanceModifierFn(WeaponUpgrades[i], VisInfo, iWeaponMod))
							{
								AddModifier(iWeaponMod, WeaponUpgrades[i].GetItemFriendlyName(), m_ShotBreakdown, eHit_Success, bDebugLog);
							}
						}
					}
				}
				//  Target defense
				AddModifier(-TargetState.GetCurrentStat(eStat_Defense), class'XLocalizedData'.default.DefenseStat, m_ShotBreakdown, eHit_Success, bDebugLog);
				
				//  Add weapon range
				if (SourceWeapon != none)
				{
					iRangeModifier = GetWeaponRangeModifier(UnitState, TargetState, SourceWeapon);
					AddModifier(iRangeModifier, class'XLocalizedData'.default.WeaponRange, m_ShotBreakdown, eHit_Success, bDebugLog);
				}			
				//  Cover modifiers
				if (bMeleeAttack)
				{
					AddModifier(MELEE_HIT_BONUS, class'XLocalizedData'.default.MeleeBonus, m_ShotBreakdown, eHit_Success, bDebugLog);
				}
				else
				{
					//  Add cover penalties
					if (TargetState.CanTakeCover())
					{
						// if any cover is being taken, factor in the angle to attack
						if( VisInfo.TargetCover != CT_None && !bIgnoreCoverBonus )
						{
							switch( VisInfo.TargetCover )
							{
							case CT_MidLevel:           //  half cover
								AddModifier(-LOW_COVER_BONUS, class'XLocalizedData'.default.TargetLowCover, m_ShotBreakdown, eHit_Success, bDebugLog);
								CoverValue = LOW_COVER_BONUS;
								break;
							case CT_Standing:           //  full cover
								AddModifier(-HIGH_COVER_BONUS, class'XLocalizedData'.default.TargetHighCover, m_ShotBreakdown, eHit_Success, bDebugLog);
								CoverValue = HIGH_COVER_BONUS;
								break;
							}

							TileDistance = UnitState.TileDistanceBetween(TargetState);

							// from Angle 0 -> MIN_ANGLE_TO_COVER, receive full MAX_ANGLE_BONUS_MOD
							// As Angle increases from MIN_ANGLE_TO_COVER -> MAX_ANGLE_TO_COVER, reduce bonus received by lerping MAX_ANGLE_BONUS_MOD -> MIN_ANGLE_BONUS_MOD
							// Above MAX_ANGLE_TO_COVER, receive no bonus

							//`assert(VisInfo.TargetCoverAngle >= 0); // if the target has cover, the target cover angle should always be greater than 0
							if( VisInfo.TargetCoverAngle < MAX_ANGLE_TO_COVER && TileDistance <= MAX_TILE_DISTANCE_TO_COVER )
							{
								bShouldAddAngleToCoverBonus = (UnitState.GetTeam() == eTeam_XCom);

								// We have to avoid the weird visual situation of a unit standing behind low cover 
								// and that low cover extends at least 1 tile in the direction of the attacker.
								if( (SHOULD_DISABLE_BONUS_ON_ANGLE_TO_EXTENDED_LOW_COVER && VisInfo.TargetCover == CT_MidLevel) ||
									(SHOULD_ENABLE_PENALTY_ON_ANGLE_TO_EXTENDED_HIGH_COVER && VisInfo.TargetCover == CT_Standing) )
								{
									UnitState.GetKeystoneVisibilityLocation(UnitTileLocation);
									TargetState.GetKeystoneVisibilityLocation(TargetTileLocation);
									NextTileOverCoverType = NextTileOverCoverInSameDirection(UnitTileLocation, TargetTileLocation);

									if( SHOULD_DISABLE_BONUS_ON_ANGLE_TO_EXTENDED_LOW_COVER && VisInfo.TargetCover == CT_MidLevel && NextTileOverCoverType == CT_MidLevel )
									{
										bShouldAddAngleToCoverBonus = false;
									}
									else if( SHOULD_ENABLE_PENALTY_ON_ANGLE_TO_EXTENDED_HIGH_COVER && VisInfo.TargetCover == CT_Standing && NextTileOverCoverType == CT_Standing )
									{
										bShouldAddAngleToCoverBonus = false;

										Alpha = FClamp((VisInfo.TargetCoverAngle - MIN_ANGLE_TO_COVER) / (MAX_ANGLE_TO_COVER - MIN_ANGLE_TO_COVER), 0.0, 1.0);
										AngleToCoverModifier = Lerp(MAX_ANGLE_PENALTY,
											MIN_ANGLE_PENALTY,
											Alpha);
										AddModifier(Round(-1.0 * AngleToCoverModifier), class'XLocalizedData'.default.BadAngleToTargetCover, m_ShotBreakdown, eHit_Success, bDebugLog);
									}
								}

								if( bShouldAddAngleToCoverBonus )
								{
									Alpha = FClamp((VisInfo.TargetCoverAngle - MIN_ANGLE_TO_COVER) / (MAX_ANGLE_TO_COVER - MIN_ANGLE_TO_COVER), 0.0, 1.0);
									AngleToCoverModifier = Lerp(MAX_ANGLE_BONUS_MOD,
																MIN_ANGLE_BONUS_MOD,
																Alpha);
									AddModifier(Round(CoverValue * AngleToCoverModifier), class'XLocalizedData'.default.AngleToTargetCover, m_ShotBreakdown, eHit_Success, bDebugLog);
								}
							}
						}
					}
					//  Add height advantage
					if (UnitState.HasHeightAdvantageOver(TargetState, true))
					{
						AddModifier(class'X2TacticalGameRuleset'.default.UnitHeightAdvantageBonus, class'XLocalizedData'.default.HeightAdvantage, m_ShotBreakdown, eHit_Success, bDebugLog);
					}

					//  Check for height disadvantage
					if (TargetState.HasHeightAdvantageOver(UnitState, false))
					{
						AddModifier(class'X2TacticalGameRuleset'.default.UnitHeightDisadvantagePenalty, class'XLocalizedData'.default.HeightDisadvantage, m_ShotBreakdown, eHit_Success, bDebugLog);
					}
				}
			}

			if (UnitState.IsConcealed())
			{
				`log("Shooter is concealed, target cannot dodge.", bDebugLog, 'XCom_HitRolls');
			}
			else
			{
				if (SourceWeapon == none || SourceWeapon.CanWeaponBeDodged())
				{
					if (TargetState.CanDodge(UnitState, kAbility))
					{
						AddModifier(TargetState.GetCurrentStat(eStat_Dodge), class'XLocalizedData'.default.DodgeStat, m_ShotBreakdown, eHit_Graze, bDebugLog);
					}
					else
					{
						`log("Target cannot dodge due to some gameplay effect.", bDebugLog, 'XCom_HitRolls');
					}
				}					
			}
		}					

		//  Now check for critical chances.
		if (bAllowCrit)
		{
			AddModifier(UnitState.GetBaseStat(eStat_CritChance), class'XLocalizedData'.default.CharCritChance, m_ShotBreakdown, eHit_Crit, bDebugLog);
			// Single Line Change for Issue #313
			/// HL-Docs: ref:GetStatModifiersFixed
			UnitState.GetStatModifiersFixed(eStat_CritChance, StatMods, StatModValues);
			for (i = 0; i < StatMods.Length; ++i)
			{
				AddModifier(int(StatModValues[i]), StatMods[i].GetX2Effect().FriendlyName, m_ShotBreakdown, eHit_Crit, bDebugLog);
			}
			if (bSquadsight)
			{
				AddModifier(default.SQUADSIGHT_CRIT_MOD, class'XLocalizedData'.default.SquadsightMod, m_ShotBreakdown, eHit_Crit, bDebugLog);
			}

			if (SourceWeapon !=  none)
			{
				AddModifier(SourceWeapon.GetItemCritChance(), class'XLocalizedData'.default.WeaponCritBonus, m_ShotBreakdown, eHit_Crit, bDebugLog);

				// Issue #237 start, let upgrades modify the crit chance of the breakdown
				WeaponUpgrades = SourceWeapon.GetMyWeaponUpgradeTemplates();
				for (i = 0; i < WeaponUpgrades.Length; ++i)
				{
					// Make sure we check to only use anything from the ini that we've specified doesn't use an Effect to modify crit chance
					// Everything that does use an Effect, e.g. base game Laser Sights, get added in about 23 lines down from here
					if (WeaponUpgrades[i].AddCritChanceModifierFn != None && default.CritUpgradesThatDontUseEffects.Find(WeaponUpgrades[i].DataName) != INDEX_NONE)
					{
						if (WeaponUpgrades[i].AddCritChanceModifierFn(WeaponUpgrades[i], iWeaponMod))
						{
							AddModifier(iWeaponMod, WeaponUpgrades[i].GetItemFriendlyName(), m_ShotBreakdown, eHit_Crit, bDebugLog);
						}
					}
				}
				// Issue #237 end
			}
			if (bFlanking && !bMeleeAttack)
			{
				if (`XENGINE.IsMultiplayerGame())
				{
					AddModifier(default.MP_FLANKING_CRIT_BONUS, class'XLocalizedData'.default.FlankingCritBonus, m_ShotBreakdown, eHit_Crit, bDebugLog);
				}				
				else
				{
					AddModifier(UnitState.GetCurrentStat(eStat_FlankingCritChance), class'XLocalizedData'.default.FlankingCritBonus, m_ShotBreakdown, eHit_Crit, bDebugLog);
				}
			}
		}
		foreach UnitState.AffectedByEffects(EffectRef)
		{
			EffectModifiers.Length = 0;
			EffectState = XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID));
			if (EffectState == none)
				continue;

			PersistentEffect = EffectState.GetX2Effect();
			if (PersistentEffect == none)
				continue;

			if (UniqueToHitEffects.Find(PersistentEffect) != INDEX_NONE)
				continue;

			PersistentEffect.GetToHitModifiers(EffectState, UnitState, TargetState, kAbility, self.Class, bMeleeAttack, bFlanking, bIndirectFire, EffectModifiers);
			if (EffectModifiers.Length > 0)
			{
				if (PersistentEffect.UniqueToHitModifiers())
					UniqueToHitEffects.AddItem(PersistentEffect);

				for (i = 0; i < EffectModifiers.Length; ++i)
				{
					if (!bAllowCrit && EffectModifiers[i].ModType == eHit_Crit)
					{
						if (!PersistentEffect.AllowCritOverride())
							continue;
					}
					AddModifier(EffectModifiers[i].Value, EffectModifiers[i].Reason, m_ShotBreakdown, EffectModifiers[i].ModType, bDebugLog);
				}
			}
			if (PersistentEffect.ShotsCannotGraze())
			{
				bIgnoreGraze = true;
				IgnoreGrazeReason = PersistentEffect.FriendlyName;
			}
		}
		UniqueToHitEffects.Length = 0;
		if (TargetState.AffectedByEffects.Length > 0)
		{
			foreach TargetState.AffectedByEffects(EffectRef)
			{
				EffectModifiers.Length = 0;
				EffectState = XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID));
				if (EffectState == none)
					continue;

				PersistentEffect = EffectState.GetX2Effect();
				if (PersistentEffect == none)
					continue;

				if (UniqueToHitEffects.Find(PersistentEffect) != INDEX_NONE)
					continue;

				PersistentEffect.GetToHitAsTargetModifiers(EffectState, UnitState, TargetState, kAbility, self.Class, bMeleeAttack, bFlanking, bIndirectFire, EffectModifiers);
				if (EffectModifiers.Length > 0)
				{
					if (PersistentEffect.UniqueToHitAsTargetModifiers())
						UniqueToHitEffects.AddItem(PersistentEffect);

					for (i = 0; i < EffectModifiers.Length; ++i)
					{
						if (!bAllowCrit && EffectModifiers[i].ModType == eHit_Crit)
							continue;
						if (bIgnoreGraze && EffectModifiers[i].ModType == eHit_Graze)
							continue;
						AddModifier(EffectModifiers[i].Value, EffectModifiers[i].Reason, m_ShotBreakdown, EffectModifiers[i].ModType, bDebugLog);
					}
				}
			}
		}
		//  Remove graze if shooter ignores graze chance.
		if (bIgnoreGraze)
		{
			AddModifier(-m_ShotBreakdown.ResultTable[eHit_Graze], IgnoreGrazeReason, m_ShotBreakdown, eHit_Graze, bDebugLog);
		}
		//  Remove crit from reaction fire. Must be done last to remove all crit.
		if (bReactionFire)
		{
			AddReactionCritModifier(UnitState, TargetState, m_ShotBreakdown, bDebugLog);
		}
	}

	//  Final multiplier based on end Success chance
	if (bReactionFire && !bGuaranteedHit)
	{
		FinalAdjust = m_ShotBreakdown.ResultTable[eHit_Success] * GetReactionAdjust(UnitState, TargetState);
		AddModifier(-int(FinalAdjust), AbilityTemplate.LocFriendlyName, m_ShotBreakdown, eHit_Success, bDebugLog);
		AddReactionFlatModifier(UnitState, TargetState, m_ShotBreakdown, bDebugLog);
	}
	else if (FinalMultiplier != 1.0f)
	{
		FinalAdjust = m_ShotBreakdown.ResultTable[eHit_Success] * FinalMultiplier;
		AddModifier(-int(FinalAdjust), AbilityTemplate.LocFriendlyName, m_ShotBreakdown, eHit_Success, bDebugLog);
	}

	FinalizeHitChance(m_ShotBreakdown, bDebugLog);
	return m_ShotBreakdown.FinalHitChance;
}

function float GetReactionAdjust(XComGameState_Unit Shooter, XComGameState_Unit Target)
{
	local XComGameStateHistory History;
	// Issue #493: Variable no longer needed
	//local XComGameState_Unit OldTarget;
	local UnitValue ConcealedValue;
	// New Variables for Issue #493
	local int PathIndex;
	local XComGameStateContext_Ability AbilityContext;
	local bool FoundContext;
	// End Issue #493 New vars

	History = `XCOMHISTORY;

	//  No penalty if the shooter went into Overwatch while concealed.
	if (Shooter.GetUnitValue(class'X2Ability_DefaultAbilitySet'.default.ConcealedOverwatchTurn, ConcealedValue))
	{
		if (ConcealedValue.fValue > 0)
			return 0;
	}

	// Start Issue #493
	/// HL-Docs: ref:Bugfixes; issue:493
	/// Allow `REACTION_DASHING_FINALMOD` to reduce reaction fire hit chance against dashing targets
	foreach History.IterateContextsByClassType(class'XComGameStateContext_Ability', AbilityContext,,, History.GetEventChainStartIndex()) //EventChainStartIndex is the earliest what we are reacting to could be, often it *will* be at this index
	{
		if(AbilityContext.InputContext.SourceObject.ObjectID==Target.ObjectID)
		{
			FoundContext = true;
			break;
		}
	}
	if(FoundContext)
	{
		PathIndex = AbilityContext.GetMovePathIndex(Target.ObjectID);// Ok, did we move?
		If (PathIndex!=INDEX_NONE && AbilityContext.InputContext.MovementPaths[PathIndex].CostIncreases.Length!=0)//Dash check
	// End Issue #493
		{
			return default.REACTION_DASHING_FINALMOD;
		}
	}
	return default.REACTION_FINALMOD;
}

function AddReactionFlatModifier(XComGameState_Unit Shooter, XComGameState_Unit Target, out ShotBreakdown m_ShotBreakdown, bool bDebugLog)
{
	local XComGameState_Effect EffectState;
	local StateObjectReference EffectRef;
	local XComGameStateHistory History;
	local X2Effect_Persistent  EffectTemplate;
	local int Modifier;

	History = `XCOMHISTORY;
	foreach Shooter.AffectedByEffects(EffectRef)
	{
		EffectState = XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID));
		EffectTemplate = EffectState.GetX2Effect();
		if (EffectTemplate != none)
		{
			Modifier = 0;
			EffectTemplate.ModifyReactionFireSuccess(Shooter, Target, Modifier);
			AddModifier(Modifier, EffectTemplate.FriendlyName, m_ShotBreakdown, eHit_Success, bDebugLog);
		}
	}
}

function AddReactionCritModifier(XComGameState_Unit Shooter, XComGameState_Unit Target, out ShotBreakdown m_ShotBreakdown, bool bDebugLog)
{
	local XComGameState_Effect EffectState;
	local StateObjectReference EffectRef;
	local XComGameStateHistory History;
	local X2Effect_Persistent  EffectTemplate;

	History = `XCOMHISTORY;
	foreach Shooter.AffectedByEffects(EffectRef)
	{
		EffectState = XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID));
		EffectTemplate = EffectState.GetX2Effect();
		if (EffectTemplate != none && EffectTemplate.AllowReactionFireCrit(Shooter, Target))
			return;
	}

	AddModifier(-m_ShotBreakdown.ResultTable[eHit_Crit], class'XLocalizedData'.default.ReactionFirePenalty, m_ShotBreakdown, eHit_Crit, bDebugLog);
}

function int GetWeaponRangeModifier(XComGameState_Unit Shooter, XComGameState_Unit Target, XComGameState_Item Weapon)
{
	local X2WeaponTemplate WeaponTemplate;
	local int Tiles, Modifier;

	if (Shooter != none && Target != none && Weapon != none)
	{
		WeaponTemplate = X2WeaponTemplate(Weapon.GetMyTemplate());

		if (WeaponTemplate != none)
		{
			Tiles = Shooter.TileDistanceBetween(Target);
			if (WeaponTemplate.RangeAccuracy.Length > 0)
			{
				if (Tiles < WeaponTemplate.RangeAccuracy.Length)
					Modifier = WeaponTemplate.RangeAccuracy[Tiles];
				else  //  if this tile is not configured, use the last configured tile					
					Modifier = WeaponTemplate.RangeAccuracy[WeaponTemplate.RangeAccuracy.Length-1];
			}
		}
	}

	return Modifier;
}

function int GetModifiedHitChanceForCurrentDifficulty(XComGameState_Player Instigator, XComGameState_Unit TargetState, int BaseHitChance)
{
	local int CurrentLivingSoldiers;
	local int SoldiersLost;  // below normal squad size
	local int ModifiedHitChance;
	local XComGameStateHistory History;
	local XComGameState_Unit Unit;
	local ETeam TargetTeam;

	ModifiedHitChance = BaseHitChance;

	History = `XCOMHISTORY;

	foreach History.IterateByClassType(class'XComGameState_Unit', Unit)
	{
		if( Unit.GetTeam() == eTeam_XCom && !Unit.bRemovedFromPlay && Unit.IsAlive() && !Unit.GetMyTemplate().bIsCosmetic )
		{
			++CurrentLivingSoldiers;
		}
	}

	SoldiersLost = Max(0, NormalSquadSize - CurrentLivingSoldiers);

	if (TargetState != none)
	{
		TargetTeam = TargetState.GetTeam( );
	}

	// XCom gets 20% bonus to hit for each consecutive miss made already this turn
	if( Instigator.TeamFlag == eTeam_XCom )
	{
		ModifiedHitChance = BaseHitChance * `ScaleTacticalArrayFloat(BaseXComHitChanceModifier); // 1.2
		if( BaseHitChance >= ReasonableShotMinimumToEnableAimAssist ) // 50
		{
			ModifiedHitChance +=
				Instigator.MissStreak * `ScaleTacticalArrayInt(MissStreakChanceAdjustment) + // 20
				SoldiersLost * `ScaleTacticalArrayInt(SoldiersLostXComHitChanceAdjustment); // 15
		}
	}
	// Aliens get -10% chance to hit for each consecutive hit made already this turn; this only applies if the XCom currently has less than 5 units alive
	else if( Instigator.TeamFlag == eTeam_Alien || Instigator.TeamFlag == eTeam_TheLost )
	{
		if( CurrentLivingSoldiers <= NormalSquadSize ) // 4
		{
			ModifiedHitChance =
				BaseHitChance +
				Instigator.HitStreak * `ScaleTacticalArrayInt(HitStreakChanceAdjustment) + // -10
				SoldiersLost * `ScaleTacticalArrayInt(SoldiersLostAlienHitChanceAdjustment); // -25
		}

		if( Instigator.TeamFlag == eTeam_Alien && TargetTeam == eTeam_TheLost )
		{
			ModifiedHitChance += `ScaleTacticalArrayFloat(AlienVsTheLostHitChanceAdjustment);
		}
		else if( Instigator.TeamFlag == eTeam_TheLost && TargetTeam == eTeam_Alien )
		{
			ModifiedHitChance += `ScaleTacticalArrayFloat(TheLostVsAlienHitChanceAdjustment);
		}
	}

	ModifiedHitChance = Clamp(ModifiedHitChance, 0, MaxAimAssistScore);

	`log("=" $ GetFuncName() $ "=", true, 'XCom_HitRolls');
	`log("Aim Assisted hit chance:" @ ModifiedHitChance, true, 'XCom_HitRolls');

	return ModifiedHitChance;
}

protected function AddModifier(const int ModValue, const string ModReason, out ShotBreakdown m_ShotBreakdown, EAbilityHitResult ModType = eHit_Success, bool bDebugLog = false)
{
	if (bGuaranteedHit || m_ShotBreakdown.SpecialGuaranteedHit != '')
	{
		if (ModType != eHit_Crit)             //  for a guaranteed hit, the only possible modifier is to allow for crit
			return;
	}

	super.AddModifier(ModValue, ModReason, m_ShotBreakdown, ModType, bDebugLog);
}


// Cover checking for configurations similar to this:
///////////////
//
// D3
// 12
//   
//   S
//
///////////////
// S = Source
// D = Dest
// Primary Cover is between D -> 3
// Extended Cover is between 1 -> 2
// Corner Cover is between D -> 1
//
// If 1 is the obstructed tile below the start of an upward ramp, we assume extended high cover exists.

function ECoverType NextTileOverCoverInSameDirection(const out TTile SourceTile, const out TTile DestTile)
{
	local TTile TileDifference, AdjacentTile;
	local XComWorldData WorldData;
	local int AnyCoverDirectionToCheck, LowCoverDirectionToCheck, CornerCoverDirectionToCheck, CornerLowCoverDirectionToCheck;
	local TileData AdjacentTileData, DestTileData;
	local ECoverType BestCover;

	WorldData = `XWORLD;

	AdjacentTile = DestTile;

	TileDifference.X = SourceTile.X - DestTile.X;
	TileDifference.Y = SourceTile.Y - DestTile.Y;

	if( Abs(TileDifference.X) > Abs(TileDifference.Y) )
	{
		if( TileDifference.X > 0 )
		{
			++AdjacentTile.X;

			CornerCoverDirectionToCheck = WorldData.COVER_West;
			CornerLowCoverDirectionToCheck = WorldData.COVER_WLow;
		}
		else
		{
			--AdjacentTile.X;

			CornerCoverDirectionToCheck = WorldData.COVER_East;
			CornerLowCoverDirectionToCheck = WorldData.COVER_ELow;
		}

		if( TileDifference.Y > 0 )
		{
			AnyCoverDirectionToCheck = WorldData.COVER_North;
			LowCoverDirectionToCheck = WorldData.COVER_NLow;
		}
		else
		{
			AnyCoverDirectionToCheck = WorldData.COVER_South;
			LowCoverDirectionToCheck = WorldData.COVER_SLow;
		}
	}
	else
	{
		if( TileDifference.Y > 0 )
		{
			++AdjacentTile.Y;

			CornerCoverDirectionToCheck = WorldData.COVER_North;
			CornerLowCoverDirectionToCheck = WorldData.COVER_NLow;
		}
		else
		{
			--AdjacentTile.Y;

			CornerCoverDirectionToCheck = WorldData.COVER_South;
			CornerLowCoverDirectionToCheck = WorldData.COVER_SLow;
		}

		if( TileDifference.X > 0 )
		{
			AnyCoverDirectionToCheck = WorldData.COVER_West;
			LowCoverDirectionToCheck = WorldData.COVER_WLow;
		}
		else
		{
			AnyCoverDirectionToCheck = WorldData.COVER_East;
			LowCoverDirectionToCheck = WorldData.COVER_ELow;
		}
	}

	WorldData.GetTileData(DestTile, DestTileData);

	BestCover = CT_None;

	if( (DestTileData.CoverFlags & CornerCoverDirectionToCheck) != 0 )
	{
		if( (DestTileData.CoverFlags & CornerLowCoverDirectionToCheck) == 0 )
		{
			// high corner cover
			return CT_Standing;
		}
		else
		{
			// low corner cover - still need to check for high adjacent cover
			BestCover = CT_MidLevel;
		}
	}
	
	if( !WorldData.IsTileFullyOccupied(AdjacentTile) ) // if the tile is fully occupied, it won't have cover information - we need to check the corner cover value instead
	{
		WorldData.GetTileData(AdjacentTile, AdjacentTileData);

		// cover flags are valid - if they don't provide ANY cover in the specified direction, return CT_None
		if( (AdjacentTileData.CoverFlags & AnyCoverDirectionToCheck) != 0 )
		{
			// if the cover flags in the specified direction don't have the low cover flag, then it is high cover
			if( (AdjacentTileData.CoverFlags & LowCoverDirectionToCheck) == 0 )
			{
				// high adjacent cover
				BestCover = CT_Standing;
			}
			else
			{
				// low adjacent cover
				BestCover = CT_MidLevel;
			}
		}
	}
	else
	{
		// test if the adjacent tile is occupied because it is the base of a ramp
		++AdjacentTile.Z;
		if( WorldData.IsRampTile(AdjacentTile) )
		{
			BestCover = CT_Standing;
		}
	}

	return BestCover;
}

DefaultProperties
{
	bAllowCrit=true
	FinalMultiplier=1.0f
}