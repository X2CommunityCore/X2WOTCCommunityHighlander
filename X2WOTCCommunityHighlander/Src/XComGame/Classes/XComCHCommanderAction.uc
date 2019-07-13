// Such weird name due to dependson fun
class XComCHCommanderAction extends Object dependson(XComLWTuple);

var name Id;

var string sIcon;
var string DisplayText;
var string Tooltip;
var bool bHighlight;

var AvailableAction ActionInfo; // Automatically used if OnActivated is none
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

////////////////
/// Creation ///
////////////////

static function XComCHCommanderAction CreateFromAvailableAction (AvailableAction InActionInfo)
{
	local XComGameState_BattleData BattleData;
	local XComGameState_Ability AbilityState;
	local X2AbilityTemplate AbilityTemplate;
	local XComCHCommanderAction Action;

	AbilityState = XComGameState_Ability(`XCOMHISTORY.GetGameStateForObjectID(InActionInfo.AbilityObjectRef.ObjectID));
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
	Action.ActionInfo = InActionInfo;

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

		CHActions.AddItem(CHAction);
	}

	return CHActions;
}