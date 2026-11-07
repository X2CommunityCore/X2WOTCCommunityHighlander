class X2Condition_SolaceCleanseNeeded extends X2Condition;

event name CallAbilityMeetsCondition(XComGameState_Ability kAbility, XComGameState_BaseObject kTarget)
{
    local XComGameStateHistory History;
    local XComGameState_Unit TargetUnit, SourceUnit;
    local X2AbilityTemplate Template;
    local X2Effect Effect;
    local X2Effect_RemoveEffects RemoveEffect;
    local StateObjectReference EffectRef;
    local XComGameState_Effect EffectState;
    local X2Effect_Persistent PersistentEffect;

    TargetUnit = XComGameState_Unit(kTarget);
    if (TargetUnit == none) return 'AA_NotAUnit';

    Template = kAbility.GetMyTemplate();

    History = `XCOMHISTORY;
    SourceUnit = XComGameState_Unit(History.GetGameStateForObjectID(kAbility.OwnerStateObject.ObjectID));

    foreach Template.AbilityTargetEffects(Effect)
    {
        // dont trigger this effect on the wrong side, robots, etc.
        if (!Effect.TargetIsValidForAbility(TargetUnit, SourceUnit, kAbility)) continue;

        RemoveEffect = X2Effect_RemoveEffects(Effect);
        if (RemoveEffect == none) return 'AA_Success';

        // will cleanse remove anything on the target
        foreach TargetUnit.AffectedByEffects(EffectRef)
        {
            EffectState = XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID));
            if (EffectState == none) continue;
            if (EffectState.bRemoved) continue;

            PersistentEffect = EffectState.GetX2Effect();
            if (PersistentEffect == none) continue;
            if (RemoveEffect.ShouldRemoveEffect(EffectState, PersistentEffect)) return 'AA_Success';
        }
    }

    return 'AA_UnitIsNotImpaired';
}