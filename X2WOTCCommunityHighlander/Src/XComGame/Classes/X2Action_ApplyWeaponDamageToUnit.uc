//-----------------------------------------------------------
// Used by the visualizer system to control a Visualization Actor
//-----------------------------------------------------------
class X2Action_ApplyWeaponDamageToUnit extends X2Action 
	dependson(XComAnimNodeBlendDynamic)
	config(Animation);

var X2AbilityTemplate                                                       AbilityTemplate; //The template for the ability that is affecting us
var Actor                                                                   DamageDealer;
var XComGameState_Unit														SourceUnitState;
var int                                                                     m_iDamage, m_iMitigated, m_iShielded, m_iShredded;
var array<DamageResult>                                                     DamageResults;
var array<EAbilityHitResult>                                                HitResults;
var name																	DamageTypeName;
var Vector                                                                  m_vHitLocation;
var Vector                                                                  m_vMomentum;
var bool                                                                    bGoingToDeathOrKnockback;
var bool                                                                    bWasHit;
var bool                                                                    bWasCounterAttack;
var bool                                                                    bCounterAttackAnim;
var XComGameStateContext_Ability                                            AbilityContext;
var CustomAnimParams                                                        AnimParams;
var EAbilityHitResult                                                       HitResult;
var XComGameStateContext_TickEffect                                         TickContext;
var XComGameStateContext_AreaDamage                                         AreaDamageContext;
var XComGameStateContext_Falling                                            FallingContext;
var XComGameStateContext_ApplyWorldEffects                                  WorldEffectsContext;
var int                                                                     TickIndex;      //This is set by AddX2ActionsForVisualization_Tick
var AnimNodeSequence                                                        PlayingSequence;
var X2Effect                                                                OriginatingEffect;
var X2Effect                                                                AncestorEffect; //In the case of ticking effects causing damage effects, this is the ticking effect (if known and different)
var bool                                                                    bHiddenAction;
var StateObjectReference													CounterAttackTargetRef;
var bool                                                                    bDoOverrideAnim;
var XComGameState_Unit                                                      OverrideOldUnitState;
var X2Effect_Persistent                                                     OverridePersistentEffectTemplate;
var string                                                                  OverrideAnimEffectString;
var bool                                                                    bPlayDamageAnim;  // Only display the first damage hit reaction
var bool                                                                    bIsUnitRuptured;
var bool																	bShouldContinueAnim;
var bool																	bMoving;
var bool																	bSkipWaitForAnim;
var X2Action_MoveDirect														RunningAction;
var config float															HitReactDelayTimeToDeath;
var XComGameState_Unit														UnitState;
var XComGameState_AIGroup													GroupState;
var int																		ScanGroup;
var XGUnit																	ScanUnit;
var XComPerkContentInst														kPerkContent;
var array<name>                                                             TargetAdditiveAnims;
var bool																	bShowFlyovers;		
var bool																	bCombineFlyovers;
var X2Effect DamageEffect;		// If the damage was from an effect, this is the effect
var EAbilityHitResult														EffectHitEffectsOverride;
var X2Action_Fire															CounterattackedAction;

// Needs to match values in DamageMessageBox.as
enum eWeaponDamageType
{
	eWDT_Armor,
	eWDT_Shred,
	eWDT_Repeater,
	eWDT_Psi,
};

function Init()
{
	local int MultiIndex, WorldResultIndex, RedirectIndex;
	local int DmgIndex, ActionIndex;
	local XComGameState_Unit OldUnitState;
	local X2EffectTemplateRef LookupEffect;
	local X2Effect SourceEffect;
	local X2Action_ApplyWeaponDamageToUnit OtherAction;	
	local XComGameState_Item SourceItemGameState;
	local X2WeaponTemplate WeaponTemplate;
	local XComGameStateHistory History;
	local XComGameStateContext_Ability IterateAbility;	
	local XComGameState LastGameStateInInterruptChain;
	local DamageResult DmgResult;	
	local XComGameState_Effect EffectState;
	local StateObjectReference EffectRef;
	local name TargetAdditiveAnim;
	local X2Effect TestEffect;
	local int EffectIndex;
	local bool IsKnockback;
	local array<X2Action> RunningActions;
	local array<X2Action> ApplyDamageToUnitActions;
	local X2Action ParentFireAction;

	super.Init();

	History = `XCOMHISTORY;	

	AbilityContext = XComGameStateContext_Ability(StateChangeContext);	
	if (AbilityContext != none)
	{
		LastGameStateInInterruptChain = AbilityContext.GetLastStateInInterruptChain();

		//Perform special processing for counter attack before doing anything with AbilityContext, as we may need to switch
		//to the counter attack ability context
		if (AbilityContext.ResultContext.HitResult == eHit_CounterAttack)
		{	
			bWasCounterAttack = true;
			//Check if we are the original shooter in a counter attack sequence, meaning that we are now being attacked. The
			//target of a counter attack just plays a different flinch/reaction anim
			IterateAbility = class'X2Ability'.static.FindCounterAttackGameState(AbilityContext, XComGameState_Unit(Metadata.StateObject_NewState));
			if (IterateAbility != None)
			{
				//In this situation we need to update ability context so that it is from the counter attack game state				
				AbilityContext = IterateAbility;
				OldUnitState = XComGameState_Unit(History.GetGameStateForObjectID(Metadata.StateObject_NewState.ObjectID, eReturnType_Reference, AbilityContext.AssociatedState.HistoryIndex - 1));
				UnitState = XComGameState_Unit(History.GetGameStateForObjectID(Metadata.StateObject_NewState.ObjectID, eReturnType_Reference, AbilityContext.AssociatedState.HistoryIndex));
				bCounterAttackAnim = false; //We are the target of the counter attack, don't play the counter attack anim
			}
			else
			{
				CounterAttackTargetRef = AbilityContext.InputContext.SourceObject;
				bCounterAttackAnim = true; //We are counter attacking, play the counter attack anim
				if (FindParentOfType(class'X2Action_Fire', ParentFireAction))
				{
					CounterattackedAction = X2Action_Fire(ParentFireAction);					
				}
			}
		}
		else
		{
			UnitState = XComGameState_Unit(LastGameStateInInterruptChain.GetGameStateForObjectID(Metadata.StateObject_NewState.ObjectID));
			if (UnitState == None) //This can occur for abilities which were interrupted but never resumed, e.g. because the shooter was killed.
				UnitState = XComGameState_Unit(Metadata.StateObject_NewState); //Will typically be the same as the OldState in this case.

			`assert(UnitState != none);			//	this action should have only been added for a unit!
			OldUnitState = XComGameState_Unit(Metadata.StateObject_OldState);
			`assert(OldUnitState != none);
		}
	}
	else
	{
		TickContext = XComGameStateContext_TickEffect(StateChangeContext);
		AreaDamageContext = XComGameStateContext_AreaDamage(StateChangeContext);
		FallingContext = XComGameStateContext_Falling(StateChangeContext);
		WorldEffectsContext = XComGameStateContext_ApplyWorldEffects(StateChangeContext);

		UnitState = XComGameState_Unit(Metadata.StateObject_NewState);
		OldUnitState = XComGameState_Unit(Metadata.StateObject_OldState);
	}

	m_iDamage = 0;
	m_iMitigated = 0;
	
	if (AbilityContext != none)
	{
		SourceUnitState = XComGameState_Unit(History.GetGameStateForObjectID(AbilityContext.InputContext.SourceObject.ObjectID));
		DamageDealer = History.GetGameStateForObjectID(AbilityContext.InputContext.SourceObject.ObjectID).GetVisualizer();
		SourceItemGameState = XComGameState_Item(History.GetGameStateForObjectID(AbilityContext.InputContext.ItemObject.ObjectID));

		if (SourceItemGameState != none)
			WeaponTemplate = X2WeaponTemplate(SourceItemGameState.GetMyTemplate());
	}

	//Set up a damage type
	if (WeaponTemplate != none)
	{
		DamageTypeName = WeaponTemplate.BaseDamage.DamageType;
		if (DamageTypeName == '')
		{
			DamageTypeName = WeaponTemplate.DamageTypeTemplateName;
		}
	}
	else if (TickContext != none || WorldEffectsContext != none)
	{
		for (DmgIndex = 0; DmgIndex < UnitState.DamageResults.Length; ++DmgIndex)
		{
			if (UnitState.DamageResults[DmgIndex].Context == StateChangeContext)
			{
				LookupEffect = UnitState.DamageResults[DmgIndex].SourceEffect.EffectRef;
				SourceEffect = class'X2Effect'.static.GetX2Effect(LookupEffect);
				DamageEffect = SourceEffect;
				if (SourceEffect.DamageTypes.Length > 0)
					DamageTypeName = SourceEffect.DamageTypes[0];
				m_iDamage = UnitState.DamageResults[DmgIndex].DamageAmount;
				break;
			}
		}
	}

	// Start Issue #326: If we still don't have a damage type, try to pull from the manually configured
	/// HL-Docs: ref:Bugfixes; issue:326
	/// Allow damage flyovers from weapon-less Psi abilities to use the Psi damage popup
	// Effect Damage from X2Effect_ApplyWeaponDamage (PsiBombStage2, mod abilities)
	if (DamageTypeName == '')
	{
		if (X2Effect_ApplyWeaponDamage(OriginatingEffect) != none)
		{
			DamageTypeName = X2Effect_ApplyWeaponDamage(OriginatingEffect).EffectDamageValue.DamageType;
		}

		if (DamageTypeName == '')
		{
			DamageTypeName = class'X2Item_DefaultDamageTypes'.default.DefaultDamageType;
		}
	}
	// End Issue #326

	bWasHit = false;
	IsKnockback = false;
	m_vHitLocation = UnitPawn.GetHeadshotLocation();
	if (AbilityContext != none)
	{
		AbilityTemplate =  class'XComGameState_Ability'.static.GetMyTemplateManager().FindAbilityTemplate(AbilityContext.InputContext.AbilityTemplateName);
		`assert(AbilityTemplate != none);
		if (AbilityContext.InputContext.PrimaryTarget.ObjectID == Metadata.StateObject_NewState.ObjectID)
		{
			bWasHit = bWasHit || AbilityContext.IsResultContextHit();	
			HitResult = AbilityContext.ResultContext.HitResult;
			HitResults.AddItem(HitResult);
		}
		
		for (MultiIndex = 0; MultiIndex < AbilityContext.InputContext.MultiTargets.Length; ++MultiIndex)
		{
			if (AbilityContext.InputContext.MultiTargets[MultiIndex].ObjectID == Metadata.StateObject_NewState.ObjectID)
			{
				bWasHit = bWasHit || AbilityContext.IsResultContextMultiHit(MultiIndex);
				HitResult = AbilityContext.ResultContext.MultiTargetHitResults[MultiIndex];
				HitResults.AddItem(HitResult);
			}
		}	

		if (HitResults.Length == 0)
		{
			for (RedirectIndex = 0; RedirectIndex < AbilityContext.ResultContext.EffectRedirects.Length; ++RedirectIndex)
			{
				if (AbilityContext.ResultContext.EffectRedirects[RedirectIndex].RedirectedToTargetRef.ObjectID == Metadata.StateObject_NewState.ObjectID)
				{
					if (AbilityContext.InputContext.PrimaryTarget.ObjectID == AbilityContext.ResultContext.EffectRedirects[RedirectIndex].OriginalTargetRef.ObjectID)
					{
						bWasHit = bWasHit || AbilityContext.IsResultContextHit();
						HitResult = AbilityContext.ResultContext.HitResult;
						HitResults.AddItem(HitResult);
					}
				}
				for (MultiIndex = 0; MultiIndex < AbilityContext.InputContext.MultiTargets.Length; ++MultiIndex)
				{
					if (AbilityContext.InputContext.MultiTargets[MultiIndex].ObjectID == AbilityContext.ResultContext.EffectRedirects[RedirectIndex].OriginalTargetRef.ObjectID)
					{
						bWasHit = bWasHit || AbilityContext.IsResultContextMultiHit(MultiIndex);
						HitResult = AbilityContext.ResultContext.MultiTargetHitResults[MultiIndex];
						HitResults.AddItem(HitResult);
					}
				}
			}
		}

		for( EffectIndex = 0; EffectIndex < AbilityTemplate.AbilityTargetEffects.Length; ++EffectIndex )
		{
			TestEffect = AbilityTemplate.AbilityTargetEffects[EffectIndex];
			if( X2Effect_Knockback(TestEffect) != None )
			{
				IsKnockback = AbilityContext.FindTargetEffectApplyResult(TestEffect) == 'AA_Success';
				break;
			}
		}
	}
	else if (TickContext != none)
	{
		bWasHit = (TickIndex == INDEX_NONE) || (TickContext.arrTickSuccess[TickIndex] == 'AA_Success');
		HitResult = bWasHit ? eHit_Success : eHit_Miss;

		if (bWasHit)
			HitResults.AddItem(eHit_Success);
	}
	else if (FallingContext != none || AreaDamageContext != None)
	{
		bWasHit = true;
		HitResult = eHit_Success;

		HitResults.AddItem( eHit_Success );
	}
	else if (WorldEffectsContext != none)
	{
		for (WorldResultIndex = 0; WorldResultIndex < WorldEffectsContext.TargetEffectResults.Effects.Length; ++WorldResultIndex)
		{
			if (WorldEffectsContext.TargetEffectResults.Effects[WorldResultIndex] == OriginatingEffect)
			{
				if (WorldEffectsContext.TargetEffectResults.ApplyResults[WorldResultIndex] == 'AA_Success')
				{
					bWasHit = true;
					HitResult = eHit_Success;
					HitResults.AddItem(eHit_Success);
				}
				else
				{
					bWasHit = false;
					HitResult = eHit_Miss;
					HitResults.AddItem(eHit_Miss);
				}
					
				break;
			}
		}
	}
	else
	{
		`RedScreen("Unhandled context for this action:" @ StateChangeContext @ self);
	}

	if (AbilityContext != none || TickContext != none)
	{
		if (bWasHit)
		{
			bPlayDamageAnim = false;
		}

		for (DmgIndex = 0; DmgIndex < UnitState.DamageResults.Length; ++DmgIndex)
		{ 
			if (LastGameStateInInterruptChain != none)
			{
				if(UnitState.DamageResults[DmgIndex].Context != LastGameStateInInterruptChain.GetContext())
					continue;
			}
			else if (UnitState.DamageResults[DmgIndex].Context != StateChangeContext)
			{
				continue;
			}
			LookupEffect = UnitState.DamageResults[DmgIndex].SourceEffect.EffectRef;
			SourceEffect = class'X2Effect'.static.GetX2Effect(LookupEffect);
			if (SourceEffect == OriginatingEffect || (AncestorEffect != None && SourceEffect == AncestorEffect))
			{
				DamageResults.AddItem(UnitState.DamageResults[DmgIndex]);
				m_iDamage = UnitState.DamageResults[DmgIndex].DamageAmount;
				m_iMitigated = UnitState.DamageResults[DmgIndex].MitigationAmount;

				if (bWasHit)
				{
					bPlayDamageAnim = true;
				}
			}
		}

		if (!bWasHit && ((OriginatingEffect.bApplyOnHit && !OriginatingEffect.bApplyOnMiss ) || m_iDamage + m_iMitigated == 0))
		{
			HasSiblingOfType(class'X2Action_ApplyWeaponDamageToUnit', ApplyDamageToUnitActions);
			//  this was not a hit and no damage was dealt. if any other damage action exists, hide this.
			for (ActionIndex = 0; ActionIndex < ApplyDamageToUnitActions.Length; ++ActionIndex)
			{
				OtherAction = X2Action_ApplyWeaponDamageToUnit(ApplyDamageToUnitActions[ActionIndex]);
				if( OtherAction != none && OtherAction != self )
				{
					// Jwats: Only check against actions for our actor
					if ( Metadata.VisualizeActor == OtherAction.Metadata.VisualizeActor && !OtherAction.bHiddenAction)
					{
						bHiddenAction = true;
						break;
					}
				}
			}
		}
		else if (bWasHit && OriginatingEffect.bApplyOnMiss && !OriginatingEffect.bApplyOnHit)
 		{
			//  never visualize the miss effect when it's actually a hit, the hit will visualize instead
			bHiddenAction = true;
		}
	}
	else if (AreaDamageContext != None)
	{
		//  For falling and area damage, there isn't an effect to deal with, so just grab the raw change in HP
		m_iDamage = OldUnitState.GetCurrentStat( eStat_HP ) - UnitState.GetCurrentStat( eStat_HP );

		for (DmgIndex = 0; DmgIndex < UnitState.DamageResults.Length; ++DmgIndex)
		{
			if (UnitState.DamageResults[DmgIndex].Context == AreaDamageContext)
			{
				DmgResult = UnitState.DamageResults[DmgIndex];
				break;
			}
		}

		DmgResult.DamageAmount = m_iDamage;
		DmgResult.Context = AreaDamageContext;

		DamageResults.AddItem( DmgResult );

		bPlayDamageAnim = HasSiblingOfType(class'X2Action_ApplyWeaponDamageToUnit', ApplyDamageToUnitActions) ? (ApplyDamageToUnitActions[0] == self) : false;
	}
	else if (FallingContext != none)
	{
		//  For falling and area damage, there isn't an effect to deal with, so just grab the raw change in HP
		m_iDamage = OldUnitState.GetCurrentStat( eStat_HP ) - UnitState.GetCurrentStat( eStat_HP );
		
		DmgResult.DamageAmount = m_iDamage;
		DmgResult.Context = FallingContext;

		DamageResults.AddItem( DmgResult );
	}
	else
	{
		//  For falling and area damage, there isn't an effect to deal with, so just grab the raw change in HP
		m_iDamage = OldUnitState.GetCurrentStat(eStat_HP) - UnitState.GetCurrentStat(eStat_HP);
	}
	
	bGoingToDeathOrKnockback = UnitState.IsDead() || UnitState.IsIncapacitated() || IsKnockback;

	// If the old state was not Ruptured and the new state has become Ruptured
	bIsUnitRuptured = (OldUnitState.Ruptured == 0) && (UnitState.Ruptured > 0);

	bMoving = `XCOMVISUALIZATIONMGR.IsRunningAction(Unit, class'X2Action_Move', RunningActions);
	if( bMoving )
	{
		RunningAction = X2Action_MoveDirect(RunningActions[0]);
	}

	//  look for an additive anim to play for the target based on its effects
	foreach UnitState.AffectedByEffects(EffectRef)
	{
		EffectState = XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID));
		TargetAdditiveAnim = EffectState.GetX2Effect().TargetAdditiveAnimOnApplyWeaponDamage(StateChangeContext, UnitState, EffectState);
		if (TargetAdditiveAnim != '')
			TargetAdditiveAnims.AddItem(TargetAdditiveAnim);
	}
}

function bool AllowEvent(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
	local XComGameState_Unit EventDataUnit;

	EventDataUnit = XComGameState_Unit(EventData);
	if( EventID == 'Visualizer_ProjectileHit' && (EventDataUnit == None || EventDataUnit.ObjectID != Metadata.StateObject_NewState.ObjectID) )
	{
		return false;
	}

	if (!super.AllowEvent(EventData, EventSource, GameState, EventID, CallbackData))
	{
		return false;
	}

	bShouldContinueAnim = true;

	return true;
}

// This function implements feedback from Jake S, "have the armor lines only play if after 
// the damage is applied, the soldier is at 2/3 health or higher.  Also, they should only 
// say the lines if their armor hasn't been shredded."
function bool ShouldPlayArmorHitVO()
{
	local bool bIsMitigated, bIsShredded;
	local int i;

	// Return false if any damage causes Shedding.
	for (i = 0; i < DamageResults.Length; i++)
	{
		bIsMitigated = bIsMitigated || (DamageResults[i].MitigationAmount > 0);
		bIsShredded = (DamageResults[i].Shred > 0);
		if (bIsShredded)
		{
			return false;
		}
	}

	// Return false if Armor was not used.
	if (!bIsMitigated)
		return false;

	// Return false if the unit has too little health anyway.
	if (UnitState.GetCurrentStat(eStat_HP)/UnitState.GetMaxStat(eStat_HP) < 0.6666f)
		return false;


	return true;
}

//@TODO - rmcfall/jbouscher - effect template?
simulated function bool ShouldPlayAnimation()
{
	local bool bFalling; //See if we are going to be falling / fell. Don't do any hurt animations if so
	local array<X2Action> FallingActions;

	VisualizationMgr.GetNodesOfType(VisualizationMgr.VisualizationTree, class'X2Action_UnitFalling', FallingActions, Metadata.VisualizeActor);
	bFalling = FallingActions.Length > 0;

	return UnitPawn.GetAnimTreeController().GetAllowNewAnimations() &&
			bPlayDamageAnim &&
		   !bMoving &&
		   !bFalling;
}

function bool IsTimedOut()
{
	return ExecutingTime >= TimeoutSeconds;
}

//@TODO - rmcfall/jbouscher - effect template?
simulated function Name ComputeAnimationToPlay(const string AppendEffectString="")
{	
	local vector vHitDir;
	local float fDot;
	local vector UnitRight;
	local float fDotRight;
	local vector WorldUp;
	local Name AnimName;
	local string AnimString;

	WorldUp.X = 0.0f;
	WorldUp.Y = 0.0f;
	WorldUp.Z = 1.0f;
	
	if (AbilityTemplate != none && AbilityTemplate.AbilityTargetStyle.IsA('X2AbilityTarget_Cursor'))
	{
		//Damage from position-based abilities should have their damage direction based on the target location
		`assert( AbilityContext.InputContext.TargetLocations.Length > 0 );
		vHitDir = Unit.GetPawn().Location - AbilityContext.InputContext.TargetLocations[0];
	}
	else if (DamageDealer != none)
	{
		vHitDir = Unit.GetPawn().Location - DamageDealer.Location;
		kPerkContent = XGUnit(DamageDealer).GetPawn().GetPerkContent(string(AbilityTemplate.DataName));
	}
	else
	{
		vHitDir = -Vector(Unit.GetPawn().Rotation);
	}

	vHitDir = Normal(vHitDir);
	m_vMomentum = vHitDir * 500.0f; //@TODO - rmcfall - replace magic number with template field or some other momentum multiplier

	fDot = vHitDir dot vector(Unit.GetPawn().Rotation);
	UnitRight = Vector(Unit.GetPawn().Rotation) cross WorldUp;
	fDotRight = vHitDir dot UnitRight;

	if( kPerkContent != none && kPerkContent.m_PerkData.TargetActivationAnim.PlayAnimation && !kPerkContent.m_PerkData.TargetActivationAnim.AdditiveAnim )
	{
		AnimName = class'XComPerkContent'.static.ChooseAnimationForCover(Unit, kPerkContent.m_PerkData.TargetActivationAnim);
	}

	if (AnimName == '')
	{
		if( Unit.IsTurret() )  //@TODO - rmcfall/jbouscher - this selection may need to eventually be based on other factors, such as the current state of the unit
		{
			if( Unit.GetTeam() == eTeam_Alien )
			{
				AnimString = "NO_"$AppendEffectString$"HurtFront_Advent";
			}
			else
			{
				AnimString = "NO_"$AppendEffectString$"HurtFront_Xcom";
			}
		}
		else
		{
			if( abs(fDot) >= abs(fDotRight) )
			{
				if( fDot > 0 )
				{
					AnimString = "HL_"$AppendEffectString$"HurtBack";
				}
				else
				{
					AnimString = "HL_"$AppendEffectString$"HurtFront";
				}
			}
			else
			{
				if( fDotRight > 0 )
				{
					AnimString = "HL_"$AppendEffectString$"HurtRight";
				}
				else
				{
					AnimString = "HL_"$AppendEffectString$"HurtLeft";
				}
			}
		}

		AnimName = name(AnimString);
	}
	
	if( !Unit.GetPawn().GetAnimTreeController().CanPlayAnimation(AnimName) )
	{
		AnimString = "HL_"$AppendEffectString$"HurtFront";
		AnimName = name(AnimString);

		if( !Unit.GetPawn().GetAnimTreeController().CanPlayAnimation(AnimName) )
		{
			// If AppendEffectString is "", then "HL_HurtFrontA" (the default hit fall back) will be checked
			// which should be there. If it isn't then there is an issue with the animation set.

			// If AppendEffectString is not blank, that means the IdleStateMachine is currently locking down
			// the animations for this unit and if the override is not found, then no animation should be played.
			AnimName = '';
		}
	}

	return AnimName;
}

event OnAnimNotify(AnimNotify ReceiveNotify)
{
	local XComAnimNotify_NotifyTarget NotifyTarget;

	super.OnAnimNotify(ReceiveNotify);

	NotifyTarget = XComAnimNotify_NotifyTarget(ReceiveNotify);
	if(NotifyTarget != none)
	{
		//We are hitting someone while playing our damage anim. This must be a counter attack.
		CompleteActionWithoutExitingExecution();
		CounterattackedAction.CounterAttacked();
	}
}

simulated state Executing
{
	simulated event BeginState(name nmPrevState)
	{
		super.BeginState(nmPrevState);
		
		//Rumbles controller
		Unit.CheckForLowHealthEffects();
	}

	//Returns the string we should use to call out damage - potentially using "Burning", "Poison", etc. instead of the default
	simulated function string GetDamageMessage()
	{
		if (X2Effect_Persistent(DamageEffect) != none)
			return X2Effect_Persistent(DamageEffect).FriendlyName;

		if (X2Effect_Persistent(OriginatingEffect) != None)
			return X2Effect_Persistent(OriginatingEffect).FriendlyName;

		if (X2Effect_Persistent(AncestorEffect) != None)
			return X2Effect_Persistent(AncestorEffect).FriendlyName;

		return "";
	}

	simulated function ShowDamageMessage(EWidgetColor SuccessfulAttackColor, EWidgetColor UnsuccessfulAttackColor)
	{
		local string UIMessage;

		UIMessage = GetDamageMessage();
		if (UIMessage == "")
			UIMessage = class'XGLocalizedData'.default.HealthDamaged;

		if( m_iShredded > 0 )
		{
			ShowShreddedMessage(SuccessfulAttackColor);
		}
		if( m_iMitigated > 0 )
		{
			ShowMitigationMessage(UnsuccessfulAttackColor);
		}
		if(m_iShielded > 0)
		{
			ShowShieldedMessage(UnsuccessfulAttackColor);
		}
		if(m_iDamage > 0)
		{
			ShowHPDamageMessage(UIMessage, , SuccessfulAttackColor);
		}

		if( m_iMitigated > 0 && ShouldPlayArmorHitVO())
		{
			Unit.UnitSpeak('ArmorHit');
		}
		else if(m_iShielded > 0 || m_iDamage > 0)
		{
			Unit.UnitSpeak('TakingDamage');
		}
	}

	simulated function ShowCritMessage(EWidgetColor SuccessfulAttackColor, EWidgetColor UnsuccessfulAttackColor)
	{
		Unit.UnitSpeak('CriticallyWounded');
		
		if( m_iShredded > 0 )
		{
			ShowShreddedMessage(SuccessfulAttackColor);
		}
		if( m_iMitigated > 0 )
		{
			ShowMitigationMessage(UnsuccessfulAttackColor);
		}
		if(m_iShielded > 0)
		{
			ShowShieldedMessage(UnsuccessfulAttackColor);
		}
		if(m_iDamage > 0)
		{
			ShowHPDamageMessage(GetDamageMessage(), class'XGLocalizedData'.default.CriticalHit, SuccessfulAttackColor);
		}
	}

	simulated function ShowGrazeMessage(EWidgetColor SuccessfulAttackColor, EWidgetColor UnsuccessfulAttackColor)
	{
		if( m_iShredded > 0 )
		{
			ShowShreddedMessage(SuccessfulAttackColor);
		}
		if( m_iMitigated > 0 )
		{
			ShowMitigationMessage(UnsuccessfulAttackColor);
		}
		if(m_iShielded > 0)
		{
			ShowShieldedMessage(UnsuccessfulAttackColor);
		}
		if(m_iDamage > 0)
		{
			ShowHPDamageMessage(class'XGLocalizedData'.default.GrazeHit, , SuccessfulAttackColor);
		}

		if( m_iMitigated > 0 && ShouldPlayArmorHitVO())
		{
			Unit.UnitSpeak('ArmorHit');
		}
		else if(m_iShielded > 0 || m_iDamage > 0)
		{
			Unit.UnitSpeak('TakingDamage');
		}
	}

	simulated function ShowHPDamageMessage(string UIMessage, optional string CritMessage, optional EWidgetColor DisplayColor = eColor_Bad)
	{
		class'UIWorldMessageMgr'.static.DamageDisplay(m_vHitLocation, Unit.GetVisualizedStateReference(), UIMessage, UnitPawn.m_eTeamVisibilityFlags, , m_iDamage, 0, CritMessage, DamageTypeName == 'Psi'? eWDT_Psi : -1, DisplayColor);
	}

	simulated function ShowMitigationMessage(EWidgetColor DisplayColor)
	{
		local int CurrentArmor;
		CurrentArmor = UnitState.GetArmorMitigationForUnitFlag();
		//The flyover shows the armor amount that exists after shred has been applied.
		if (CurrentArmor > 0)
		{
			class'UIWorldMessageMgr'.static.DamageDisplay(m_vHitLocation, Unit.GetVisualizedStateReference(), class'XGLocalizedData'.default.ArmorMitigation, UnitPawn.m_eTeamVisibilityFlags, , CurrentArmor, /*modifier*/, /*crit*/, eWDT_Armor, DisplayColor);
		}
	}

	simulated function ShowShieldedMessage(EWidgetColor DisplayColor)
	{
		class'UIWorldMessageMgr'.static.DamageDisplay(m_vHitLocation, Unit.GetVisualizedStateReference(), class'XGLocalizedData'.default.ShieldedMessage, UnitPawn.m_eTeamVisibilityFlags, , m_iShielded,,,, DisplayColor);
	}

	simulated function ShowShreddedMessage(EWidgetColor DisplayColor)
	{
		class'UIWorldMessageMgr'.static.DamageDisplay(m_vHitLocation, Unit.GetVisualizedStateReference(), class'XGLocalizedData'.default.ShreddedMessage, UnitPawn.m_eTeamVisibilityFlags, , m_iShredded, , , eWDT_Shred, DisplayColor);
	}

	simulated function ShowImmuneMessage(EWidgetColor DisplayColor)
	{
		class'UIWorldMessageMgr'.static.DamageDisplay(m_vHitLocation, Unit.GetVisualizedStateReference(), class'XLocalizedData'.default.UnitIsImmuneMsg, UnitPawn.m_eTeamVisibilityFlags, , , , , , DisplayColor);
	}

	simulated function ShowMissMessage(EWidgetColor DisplayColor)
	{
		local String MissedMessage;

		MissedMessage = OriginatingEffect.OverrideMissMessage;
		if( MissedMessage == "" )
		{
			MissedMessage = class'XLocalizedData'.default.MissedMessage;
		}

		if (m_iDamage > 0)
			class'UIWorldMessageMgr'.static.DamageDisplay(m_vHitLocation, Unit.GetVisualizedStateReference(), MissedMessage, UnitPawn.m_eTeamVisibilityFlags, , m_iDamage,,,, DisplayColor);
		else if (!OriginatingEffect.IsA('X2Effect_Persistent')) //Persistent effects that are failing to cause damage are not noteworthy.
			class'UIWorldMessageMgr'.static.DamageDisplay(m_vHitLocation, Unit.GetVisualizedStateReference(), MissedMessage,,,,,,, DisplayColor);
	}

	simulated function ShowCounterattackMessage(EWidgetColor DisplayColor)
	{
		class'UIWorldMessageMgr'.static.DamageDisplay(m_vHitLocation, Unit.GetVisualizedStateReference(), class'XLocalizedData'.default.CounterattackMessage,,,,,,, DisplayColor);
	}

	simulated function ShowLightningReflexesMessage(EWidgetColor DisplayColor)
	{
		local XComGameState_HeadquartersXCom XComHQ;
		local XComGameStateHistory History;
		local string DisplayMessageString;

		History = `XCOMHISTORY;
		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
		if( XComHQ.TacticalGameplayTags.Find('DarkEvent_LightningReflexes') != INDEX_NONE )
		{
			DisplayMessageString = class'XLocalizedData'.default.DarkEvent_LightningReflexesMessage;
		}
		else
		{
			DisplayMessageString = class'XLocalizedData'.default.LightningReflexesMessage;
		}

		class'UIWorldMessageMgr'.static.DamageDisplay(m_vHitLocation, Unit.GetVisualizedStateReference(), DisplayMessageString, , , , , , , DisplayColor);
	}

	simulated function ShowUntouchableMessage(EWidgetColor DisplayColor)
	{
		class'UIWorldMessageMgr'.static.DamageDisplay(m_vHitLocation, Unit.GetVisualizedStateReference(), class'XLocalizedData'.default.UntouchableMessage,,,,,,, DisplayColor);
	}

	simulated function ShowParryMessage(EWidgetColor DisplayColor)
	{
		class'UIWorldMessageMgr'.static.DamageDisplay(m_vHitLocation, Unit.GetVisualizedStateReference(), class'XLocalizedData'.default.ParryMessage,,,,,,, DisplayColor);
	}

	simulated function ShowDeflectMessage(EWidgetColor DisplayColor)
	{
		class'UIWorldMessageMgr'.static.DamageDisplay(m_vHitLocation, Unit.GetVisualizedStateReference(), class'XLocalizedData'.default.DeflectMessage,,,,,,, DisplayColor);
	}

	simulated function ShowReflectMessage(EWidgetColor DisplayColor)
	{
		class'UIWorldMessageMgr'.static.DamageDisplay(m_vHitLocation, Unit.GetVisualizedStateReference(), class'XLocalizedData'.default.ReflectMessage,,,,,,, DisplayColor);
	}

	simulated function ShowFreeKillMessage(name AbilityName, EWidgetColor DisplayColor)
	{
		local X2AbilityTemplate Template;
		local string KillMessage;

		KillMessage = class'XLocalizedData'.default.FreeKillMessage;

		if (AbilityName != '')
		{
			Template = class'XComGameState_Ability'.static.GetMyTemplateManager( ).FindAbilityTemplate( AbilityName );
			if ((Template != none) && (Template.LocFlyOverText != ""))
			{
				KillMessage = Template.LocFlyOverText;
			}
		}

		class'UIWorldMessageMgr'.static.DamageDisplay(m_vHitLocation, Unit.GetVisualizedStateReference(), KillMessage, , , , , , eWDT_Repeater, DisplayColor);
	}

	simulated function ShowSpecialDamageMessage(DamageModifierInfo SpecialMessage, EWidgetColor DisplayColor)
	{
		class'UIWorldMessageMgr'.static.DamageDisplay(m_vHitLocation, Unit.GetVisualizedStateReference(), class'Helpers'.static.GetMessageFromDamageModifierInfo(SpecialMessage),,,,,, (SpecialMessage.Value > 0) ? eWDT_Shred : eWDT_Armor, DisplayColor);
	}

	
	simulated function ShowAttackMessages()
	{			
		local int i, SpecialDamageIndex;
		local ETeam TargetUnitTeam;
		local EWidgetColor SuccessfulAttackColor, UnsuccessfulAttackColor;

		if(!class'X2TacticalVisibilityHelpers'.static.IsUnitVisibleToLocalPlayer(UnitState.ObjectId, CurrentHistoryIndex))
			return;

		TargetUnitTeam = UnitState.GetTeam();
		if( TargetUnitTeam == eTeam_XCom || TargetUnitTeam == eTeam_Resistance )
		{
			SuccessfulAttackColor = eColor_Bad;
			UnsuccessfulAttackColor = eColor_Good;
		}
		else
		{
			SuccessfulAttackColor = eColor_Good;
			UnsuccessfulAttackColor = eColor_Bad;
		}

		if (HitResults.Length == 0 && DamageResults.Length == 0 && bWasHit)
		{
			// Must be damage from World Effects (Fire, Poison, Acid)
			ShowDamageMessage(SuccessfulAttackColor, UnsuccessfulAttackColor);
		}
		else
		{
			//It seems that misses contain a hit result but no damage results. So fill in some zero / null damage result entries if there is a mismatch.
			if(HitResults.Length > DamageResults.Length)
			{				
				for( i = 0; i < HitResults.Length; ++i )
				{
					if( class'XComGameStateContext_Ability'.static.IsHitResultMiss(HitResults[i]))
					{
						DamageResults.Insert(i, 1);
					}
				}
			}

			if( bCombineFlyovers )
			{
				m_iDamage = 0;
				m_iMitigated = 0;
				m_iShielded = 0;
				m_iShredded = 0;
				for( i = 0; i < HitResults.Length && i < DamageResults.Length; i++ ) // some abilities damage the same target multiple times
				{
					if( HitResults[i] == eHit_Success )
					{
						m_iDamage += DamageResults[i].DamageAmount;
						m_iMitigated += DamageResults[i].MitigationAmount;
						m_iShielded += DamageResults[i].ShieldHP;
						m_iShredded += DamageResults[i].Shred;
					}
				}

				ShowDamageMessage(SuccessfulAttackColor, UnsuccessfulAttackColor);
			}
			else
			{
				for( i = 0; i < HitResults.Length && i < DamageResults.Length; i++ ) // some abilities damage the same target multiple times
				{
					HitResult = HitResults[i];

					m_iDamage = DamageResults[i].DamageAmount;
					m_iMitigated = DamageResults[i].MitigationAmount;
					m_iShielded = DamageResults[i].ShieldHP;
					m_iShredded = DamageResults[i].Shred;

					if( DamageResults[i].bFreeKill )
					{
						ShowFreeKillMessage( DamageResults[i].FreeKillAbilityName, SuccessfulAttackColor);
						return;
					}

					for( SpecialDamageIndex = 0; SpecialDamageIndex < DamageResults[i].SpecialDamageFactors.Length; ++SpecialDamageIndex )
					{
						ShowSpecialDamageMessage(DamageResults[i].SpecialDamageFactors[SpecialDamageIndex], (DamageResults[i].SpecialDamageFactors[SpecialDamageIndex].Value > 0) ? SuccessfulAttackColor : UnsuccessfulAttackColor);
					}

					if (DamageResults[i].bImmuneToAllDamage)
					{
						ShowImmuneMessage(UnsuccessfulAttackColor);
						continue;
					}

					switch( HitResult )
					{
					case eHit_CounterAttack:
						ShowCounterattackMessage(UnsuccessfulAttackColor);
						break;
					case eHit_LightningReflexes:
						ShowLightningReflexesMessage(UnsuccessfulAttackColor);
						break;
					case eHit_Untouchable:
						ShowUntouchableMessage(UnsuccessfulAttackColor);
						break;
					case eHit_Crit:
						ShowCritMessage(SuccessfulAttackColor, UnsuccessfulAttackColor);
						break;
					case eHit_Graze:
						ShowGrazeMessage(SuccessfulAttackColor, UnsuccessfulAttackColor);
						break;
					case eHit_Success:
						ShowDamageMessage(SuccessfulAttackColor, UnsuccessfulAttackColor);
						break;
					case eHit_Parry:
						ShowParryMessage(UnsuccessfulAttackColor);
						break;
					case eHit_Deflect:
						ShowDeflectMessage(UnsuccessfulAttackColor);
						break;
					case eHit_Reflect:
						ShowReflectMessage(UnsuccessfulAttackColor);
						break;
					default:
						ShowMissMessage(UnsuccessfulAttackColor);
						break;
					}
				}
			}
		}
	}

	function bool SingleProjectileVolley()
	{
		local XGUnit DealerUnit;

		DealerUnit = XGUnit(DamageDealer);

		if (DealerUnit == none) // if melee is treated as a single volley, treat collateral damage as a single as well.
			return true;

		// Jwats: Melee doesn't have a volley so treat no volley as a single volley
		return DealerUnit.GetPawn().GetAnimTreeController().GetNumProjectileVolleys() <= 1;
	}

	function bool AttackersAnimUsesWeaponVolleyNotify()
	{
		local array<AnimNotify_FireWeaponVolley> OutNotifies;
		local array<float> OutNotifyTimes;
		local XGUnit DealerUnit;

		DealerUnit = XGUnit(DamageDealer);

		if (DealerUnit == none)
			return false;

		DealerUnit.GetPawn().GetAnimTreeController().GetFireWeaponVolleyNotifies(OutNotifies, OutNotifyTimes);
		return (OutNotifies.length > 0);
	}

	function DoTargetAdditiveAnims()
	{
		local name TargetAdditiveAnim;
		local CustomAnimParams CustomAnim;

		CustomAnim.Additive = true;
		foreach TargetAdditiveAnims(TargetAdditiveAnim)
		{
			CustomAnim.AnimName = TargetAdditiveAnim;
			UnitPawn.GetAnimTreeController().PlayAdditiveDynamicAnim(CustomAnim);
		}
	}

	function UnDoTargetAdditiveAnims()
	{
		local name TargetAdditiveAnim;
		local CustomAnimParams CustomAnim;

		CustomAnim.Additive = true;
		CustomAnim.TargetWeight = 0.0f;
		foreach TargetAdditiveAnims(TargetAdditiveAnim)
		{
			CustomAnim.AnimName = TargetAdditiveAnim;
			UnitPawn.GetAnimTreeController().PlayAdditiveDynamicAnim(CustomAnim);
		}
	}

Begin:
	if (!bHiddenAction)
	{
		GroupState = UnitState.GetGroupMembership();
		if( GroupState != None )
		{
			for( ScanGroup = 0; ScanGroup < GroupState.m_arrMembers.Length; ++ScanGroup )
			{
				ScanUnit = XGUnit(`XCOMHISTORY.GetVisualizer(GroupState.m_arrMembers[ScanGroup].ObjectID));
				if( ScanUnit != None )
				{
					ScanUnit.VisualizedAlertLevel = eAL_Red;
					ScanUnit.IdleStateMachine.CheckForStanceUpdateOnIdle();
				}
			}
		}

		if( bShowFlyovers )
		{
			ShowAttackMessages();
		}

		if( bWasHit || m_iDamage > 0 || m_iMitigated > 0)       //  misses can deal damage
		{
			`PRES.m_kUnitFlagManager.RespondToNewGameState(Unit, StateChangeContext.GetLastStateInInterruptChain(), true);

			// The unit was hit but may be locked in a persistent CustomIdleOverrideAnim state
			// Check to see if we need to temporarily suspend that to play a reaction
			OverrideOldUnitState = XComGameState_Unit(Metadata.StateObject_OldState);
			bDoOverrideAnim = class'X2StatusEffects'.static.GetHighestEffectOnUnit(OverrideOldUnitState, OverridePersistentEffectTemplate, true);

			OverrideAnimEffectString = "";
			if( bDoOverrideAnim )
			{
				// Allow new animations to play
				UnitPawn.GetAnimTreeController().SetAllowNewAnimations(true);
				OverrideAnimEffectString = string(OverridePersistentEffectTemplate.EffectName);
			}

			if (ShouldPlayAnimation())
			{
				// Particle effects should only play when the animation plays.  mdomowicz 2015_07_08
				// Update: if the attacker's animation uses AnimNotify_FireWeaponVolley, the hit effect will play 
				// via X2UnifiedProjectile, so in that case we should skip the hit effect here.  mdomowicz 2015_07_29
				if (!AttackersAnimUsesWeaponVolleyNotify())
				{
					if( SourceUnitState != None && SourceUnitState.IsUnitAffectedByEffectName(class'X2Effect_BloodTrail'.default.EffectName) && HitResult == eHit_Success )
					{
						EffectHitEffectsOverride = eHit_Crit;
					}
					else
					{
						EffectHitEffectsOverride = HitResult;
					}
					UnitPawn.PlayHitEffects(m_iDamage, DamageDealer, m_vHitLocation, DamageTypeName, m_vMomentum, bIsUnitRuptured, HitResult);
				}

				Unit.ResetWeaponsToDefaultSockets();
				AnimParams.AnimName = ComputeAnimationToPlay(OverrideAnimEffectString);

				if( AnimParams.AnimName != '' )
				{
					AnimParams.PlayRate = GetMoveAnimationSpeed();
					PlayingSequence = UnitPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(AnimParams);
				}

				kPerkContent = XGUnit(DamageDealer) != none ? XGUnit(DamageDealer).GetPawn().GetPerkContent(string(AbilityTemplate.Name)) : none;
				if( kPerkContent != none && kPerkContent.m_PerkData.TargetActivationAnim.PlayAnimation && kPerkContent.m_PerkData.TargetActivationAnim.AdditiveAnim )
				{
					AnimParams.AnimName = class'XComPerkContent'.static.ChooseAnimationForCover(Unit, kPerkContent.m_PerkData.TargetActivationAnim);
					UnitPawn.GetAnimTreeController().PlayAdditiveDynamicAnim(AnimParams);
				}
				DoTargetAdditiveAnims();
			}
			else if( bMoving && RunningAction != None )
			{
				RunningAction.TriggerRunFlinch();
			}
			else
			{
				`log("HurtAnim not playing", , 'XCom_Visualization');
			}

			if( !bGoingToDeathOrKnockback && !bSkipWaitForAnim && (PlayingSequence != none))
			{
				if( Metadata.VisualizeActor.CustomTimeDilation < 1.0 )
				{
					Sleep(PlayingSequence.AnimSeq.SequenceLength * PlayingSequence.Rate * Metadata.VisualizeActor.CustomTimeDilation);
				}
				else
				{
					FinishAnim(PlayingSequence);
				}
				bShouldContinueAnim = false;
			}

			if( bDoOverrideAnim )
			{
				// Turn off new animation playing
				UnitPawn.GetAnimTreeController().SetAllowNewAnimations(false);
			}
		}
		else
		{
			if (ShouldPlayAnimation())
			{
				if(bCounterAttackAnim)
				{
					AnimParams.AnimName = 'HL_Counterattack';					
				}
				else
				{
					Unit.ResetWeaponsToDefaultSockets();

					if( Unit.IsTurret() )  //@TODO - rmcfall/jbouscher - this selection may need to eventually be based on other factors, such as the current state of the unit
					{
						if( Unit.GetTeam() == eTeam_Alien )
						{
							AnimParams.AnimName = 'NO_Flinch_Advent';
						}
						else
						{
							AnimParams.AnimName = 'NO_Flinch_Xcom';
						}
					}
					else if( HitResult == eHit_Deflect || HitResult == eHit_Parry )
					{
						AnimParams.AnimName = 'HL_Deflect';
						if( AbilityTemplate != None && AbilityTemplate.IsMelee() )
						{
							AnimParams.AnimName = 'HL_DeflectMelee';
						}
						// Jwats: No matter what we were doing, we should now just idle (don't peek stop)
						Unit.IdleStateMachine.OverwriteReturnState('Idle');
					}
					else if( HitResult == eHit_Reflect )
					{
						AnimParams.AnimName = 'HL_ReflectStart';
					}
					else
					{
						switch( Unit.m_eCoverState )
						{
						case eCS_LowLeft:
						case eCS_HighLeft:
							AnimParams.AnimName = 'HL_Flinch';
							break;
						case eCS_LowRight:
						case eCS_HighRight:
							AnimParams.AnimName = 'HR_Flinch';
							break;
						case eCS_None:
							// Jwats: No cover randomizes between the 2 animations
							if( Rand(2) == 0 )
							{
								AnimParams.AnimName = 'HL_Flinch';
							}
							else
							{
								AnimParams.AnimName = 'HR_Flinch';
							}
							break;
						}
					}
				}				

				PlayingSequence = UnitPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(AnimParams);
				DoTargetAdditiveAnims();
			}
			else if( bMoving && RunningAction != None )
			{
				RunningAction.TriggerRunFlinch();
			}
			else
			{
				`log("DodgeAnim not playing");
			}

			if( !bGoingToDeathOrKnockback && (PlayingSequence != none))
			{
				if( Metadata.VisualizeActor.CustomTimeDilation < 1.0 )
				{
					Sleep(PlayingSequence.AnimSeq.SequenceLength * PlayingSequence.Rate * Metadata.VisualizeActor.CustomTimeDilation);
				}
				else
				{
					FinishAnim(PlayingSequence);
				}
				bShouldContinueAnim = false;
			}

			if (!bWasCounterAttack)
			{
				Unit.UnitSpeak('TakingFire');
			}
		}

		if( !bMoving )
		{
			if( PlayingSequence != None && !bGoingToDeathOrKnockback )
			{
				Sleep(0.0f);
				while( bShouldContinueAnim )
				{
					PlayingSequence.ReplayAnim();
					FinishAnim(PlayingSequence);
					bShouldContinueAnim = false;
					Sleep(0.0f); // Wait to see if another projectile comes
				}
			}
			else if( PlayingSequence != None && bGoingToDeathOrKnockback )
			{
				//Only play the hit react if there is more than one projectile volley
				if( !SingleProjectileVolley() )
				{
					Sleep(HitReactDelayTimeToDeath * GetDelayModifier()); // Let the hit react play for a little bit before we CompleteAction to go to death
				}
			}
		}
	}

	kPerkContent = XGUnit(DamageDealer) != none ? XGUnit(DamageDealer).GetPawn().GetPerkContent(string(AbilityTemplate.Name)) : none;
	if( kPerkContent != none && kPerkContent.m_PerkData.TargetActivationAnim.PlayAnimation && kPerkContent.m_PerkData.TargetActivationAnim.AdditiveAnim )
	{
		AnimParams.AnimName = class'XComPerkContent'.static.ChooseAnimationForCover(Unit, kPerkContent.m_PerkData.TargetActivationAnim);
		UnitPawn.GetAnimTreeController().RemoveAdditiveDynamicAnim(AnimParams);
	}
	UnDoTargetAdditiveAnims();

	CompleteAction();
}

DefaultProperties
{
	InputEventIDs.Add( "Visualizer_AbilityHit" )
	InputEventIDs.Add( "Visualizer_ProjectileHit" )
	OutputEventIDs.Add( "Visualizer_EffectApplied" )
	TimeoutSeconds = 8.0f
	bDoOverrideAnim = false
	bPlayDamageAnim = true
	bCauseTimeDilationWhenInterrupting = true
	bShowFlyovers = true
}
