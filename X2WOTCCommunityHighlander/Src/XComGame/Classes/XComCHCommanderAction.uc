// Such weird name due to dependson fun
class XComCHCommanderAction extends Object dependson(XComLWTuple);

var name Id;

var string sIcon;
var string DisplayText;
var string Tooltip;
var bool bHighlight;

var AvailableAction AbilityInfo; // Automatically used if OnActivated is none
var array<XComLWTuple> AdditionalData;

delegate OnActivated (XComCHCommanderAction Action);

///////////////
/// Helpers ///
///////////////

function XComLWTuple GetAdditionalDataById (name TupleId)
{
	local XComLWTuple Tuple;

	foreach AdditionalData(Tuple)
	{
		if (Tuple.Id == TupleId)
		{
			return Tuple;
		}
	}

	return none;
}

static function name GetActionNameForAbility (X2AbilityTemplate AbilityTemplate)
{
	return name("Ability_" $ AbilityTemplate.DataName);
}

function bool IsPlaceEvac ()
{
	local X2AbilityTemplate AbilityTemplate;

	AbilityTemplate = GetAbilityTemplate();
	if (AbilityTemplate == none) return false;

	return AbilityTemplate.DataName == 'PlaceEvacZone';
}

function bool IsAbility ()
{
	return OnActivated == none;
}

function XComGameState_Ability GetAbilityState ()
{
	return XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(AbilityInfo.AbilityObjectRef.ObjectID));
}

function X2AbilityTemplate GetAbilityTemplate ()
{
	local XComGameState_Ability AbilityState;

	AbilityState = GetAbilityState();
	if (AbilityState == none) return none;

	return AbilityState.GetMyTemplate();
}

////////////////
/// Creation ///
////////////////

static function XComCHCommanderAction CreateFromAvailableAction (AvailableAction InAbilityInfo)
{
	local XComGameState_BattleData BattleData;
	local XComGameState_Ability AbilityState;
	local X2AbilityTemplate AbilityTemplate;
	local XComCHCommanderAction Action;

	AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(InAbilityInfo.AbilityObjectRef.ObjectID));
	if (AbilityState == none) 
	{
		`RedScreen("CHCommanderAction::CreateFromAvailableAction cannot find ability state");
		return none;
	}

	AbilityTemplate = AbilityState.GetMyTemplate();
	if (AbilityTemplate == none) 
	{
		`RedScreen("CHCommanderAction::CreateFromAvailableAction cannot find ability template");
		return none;
	}

	BattleData = XComGameState_BattleData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
	Action = new class'XComCHCommanderAction';

	Action.Id = GetActionNameForAbility(AbilityTemplate);
	Action.sIcon = AbilityTemplate.IconImage;
	Action.DisplayText = Caps(AbilityState.GetMyFriendlyName());
	Action.bHighlight = BattleData.IsAbilityObjectiveHighlighted(AbilityTemplate);
	Action.AbilityInfo = InAbilityInfo;

	return Action;
}

// Intended to be called from UITacticalHUD_AbilityContainer. Moved here due to dependson issues
static function array<XComCHCommanderAction> ProcessCommanderAbilities (array<AvailableAction> Abilities)
{
	local array<XComCHCommanderAction> CHActions;
	local XComCHCommanderAction CHAction;
	local AvailableAction Ability;
	local XComLWTValue TupleValue;
	local XComLWTuple Tuple;

	foreach Abilities(Ability)
	{
		CHActions.AddItem(CreateFromAvailableAction(Ability));
	}

	// Skip the entire logic if we are in tutorial
	// It can't be modifed by mods anyway, so preemptively avoid breaking it
	if (!`REPLAY.bInTutorial)
	{
		Tuple = new class'XComLWTuple';
		Tuple.Id = 'ModifyCommanderActions';

		foreach CHActions(CHAction)
		{
			TupleValue.kind = XComLWTVObject;
			TupleValue.o = CHAction;

			Tuple.Data.AddItem(TupleValue);
		}

		`XEVENTMGR.TriggerEvent('ModifyCommanderActions', Tuple);
		CHActions.Length = 0;

		foreach Tuple.Data(TupleValue)
		{
			if (TupleValue.kind != XComLWTVObject) continue;

			CHAction = XComCHCommanderAction(TupleValue.o);
			
			if (CHAction == none)
			{
				`Redscreen("ModifyCommanderActions listener supplied non-XComCHCommanderAction or none object - skipping");
				continue;
			}

			if (CHAction.IsAbility() && !ValidateAbilityAction(CHAction, Abilities))
			{
				`Redscreen("ModifyCommanderActions listener modified AbilityInfo contents or created a new one. Ability Object ID -" @ CHAction.AbilityInfo.AbilityObjectRef.ObjectID);
				`Redscreen("This is not allowed as it will ready to very inconsistent behaviour - you can only reorder or remove abilities");
				`Redscreen("Please use the normal ability system to change any other values");
				`Redscreen("");
				continue;
			}

			CHActions.AddItem(CHAction);
		}
	}

	return CHActions;
}

static private function bool ValidateAbilityAction (XComCHCommanderAction CHAction, out array<AvailableAction> Abilities)
{
	local AvailableAction AbilityInfo;
	local bool bFound;
	local int i, j;

	foreach Abilities(AbilityInfo, i)
	{
		if (CHAction.AbilityInfo.AbilityObjectRef.ObjectID == AbilityInfo.AbilityObjectRef.ObjectID)
		{
			bFound = true;
			break;
		}
	}

	if (!bFound) return false;

	if (CHAction.AbilityInfo.AvailableTargetCurrIndex != AbilityInfo.AvailableTargetCurrIndex) return false;
	if (CHAction.AbilityInfo.eAbilityIconBehaviorHUD != AbilityInfo.eAbilityIconBehaviorHUD) return false;
	if (CHAction.AbilityInfo.AvailableTargets.Length != AbilityInfo.AvailableTargets.Length) return false;
	if (CHAction.AbilityInfo.bInputTriggered != AbilityInfo.bInputTriggered) return false;
	if (CHAction.AbilityInfo.AvailableCode != AbilityInfo.AvailableCode) return false;
	if (CHAction.AbilityInfo.bFreeAim != AbilityInfo.bFreeAim) return false;

	for (i = 0; i < AbilityInfo.AvailableTargets.Length; i++)
	{
		if (AbilityInfo.AvailableTargets[i].AdditionalTargets.Length != CHAction.AbilityInfo.AvailableTargets[i].AdditionalTargets.Length) return false;
		if (AbilityInfo.AvailableTargets[i].PrimaryTarget != CHAction.AbilityInfo.AvailableTargets[i].PrimaryTarget) return false;

		for (j = 0; j < AbilityInfo.AvailableTargets[i].AdditionalTargets.Length; j++)
		{
			if (AbilityInfo.AvailableTargets[i].AdditionalTargets[j] != CHAction.AbilityInfo.AvailableTargets[i].AdditionalTargets[j]) return false;
		}
	}

	// All good

	Abilities.Remove(i, 1);
	return true;
}