class X2Effect_Sustain extends X2Effect_Persistent config(GameData_SoldierSkills);

struct SustainTriggerUnitCheck
{
	var name UnitType;
	var int PercentChance;
};

var config array<SustainTriggerUnitCheck> SUSTAINTRIGGERUNITCHECK_ARRAY;

var privatewrite name SustainUsed;
var privatewrite name SustainEvent, SustainTriggeredEvent;

function bool PreDeathCheck(XComGameState NewGameState, XComGameState_Unit UnitState, XComGameState_Effect EffectState)
{
	local X2EventManager EventMan;
	local UnitValue SustainValue;
	local int Index, PercentChance, RandRoll;

	if( !UnitState.IsAbleToAct(true) )
	{
		// Stunned units may not go into Sustain
		return false;
	}

	if (UnitState.GetUnitValue(default.SustainUsed, SustainValue))
	{
		if (SustainValue.fValue > 0)
			return false;
	}

	Index = default.SUSTAINTRIGGERUNITCHECK_ARRAY.Find('UnitType', UnitState.GetMyTemplateName());

	// If the Unit Type is not in the array, then it always triggers sustain
	if (Index != INDEX_NONE)
	{
		PercentChance = default.SUSTAINTRIGGERUNITCHECK_ARRAY[Index].PercentChance;

		RandRoll = `SYNC_RAND(100);
		if (RandRoll >= PercentChance)
		{
			// RandRoll is greater or equal to the percent chance, so sustain failed
			return false;
		}
	}

	UnitState.SetUnitFloatValue(default.SustainUsed, 1, eCleanup_BeginTactical);
	UnitState.SetCurrentStat(eStat_HP, 1);
	EventMan = `XEVENTMGR;
	EventMan.TriggerEvent(default.SustainEvent, UnitState, UnitState, NewGameState);
	return true;
}

function bool PreBleedoutCheck(XComGameState NewGameState, XComGameState_Unit UnitState, XComGameState_Effect EffectState)
{
	return PreDeathCheck(NewGameState, UnitState, EffectState);
}

function RegisterForEvents(XComGameState_Effect EffectGameState)
{
	local XComGameState_Unit UnitState;
	local X2EventManager EventMan;
	local Object EffectObj;

	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(EffectGameState.ApplyEffectParameters.TargetStateObjectRef.ObjectID));
	EventMan = `XEVENTMGR;
	EffectObj = EffectGameState;
	EventMan.RegisterForEvent(EffectObj, default.SustainTriggeredEvent, class'XComGameState_Effect'.static.SustainActivated, ELD_OnStateSubmitted, , UnitState);
}

DefaultProperties
{
	SustainUsed = "SustainUsed"
	SustainEvent = "SustainTriggered"
	SustainTriggeredEvent = "SustainSuccess"
}