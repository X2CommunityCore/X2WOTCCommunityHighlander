// INTERNAL CHL CLASS!
// Not covered by BC and should NOT be used/referenced by mods.
class CHEmitterPoolDelayedReturner extends Actor config(Dummy);

// Marked as config so that we can assign to it directly without grabbing the CDO
var private config string SingletonPath;

struct CHEPDR_Countdown
{
	var ParticleSystemComponent PSC;
	var float TimeLeft;
};

var private array<CHEPDR_Countdown> CurrentPending;

////////////////////
/// External API ///
////////////////////

static function CHEmitterPoolDelayedReturner GetSingleton ()
{
	local CHEmitterPoolDelayedReturner Instance;

	if (default.SingletonPath != "")
	{
		Instance = CHEmitterPoolDelayedReturner(FindObject(default.SingletonPath, class'CHEmitterPoolDelayedReturner'));
	}

	if (Instance == none)
	{
		// Log any instantiation, to make sure it happens once per layer(/map) load
		`log("Instantiating" @ default.Class.Name,, 'CHL');
		`log(GetScriptTrace(),, 'CHL');

		Instance = class'WorldInfo'.static.GetWorldInfo().Spawn(class'CHEmitterPoolDelayedReturner');
		default.SingletonPath = PathName(Instance);
	}

	return Instance;
}

function AddCountdown (ParticleSystemComponent PSC, float TimeUntilReturn)
{
	local CHEPDR_Countdown Countdown;

	Countdown.PSC = PSC;
	Countdown.TimeLeft = TimeUntilReturn;

	CurrentPending.AddItem(Countdown);
}

//////////////////////
/// Internal logic ///
//////////////////////

event Tick (float DeltaTime)
{
	local int i;

	for (i = CurrentPending.Length - 1; i >= 0; i--)
	{
		CurrentPending[i].TimeLeft -= DeltaTime;

		if (CurrentPending[i].TimeLeft < 0)
		{
			WorldInfo.MyEmitterPool.OnParticleSystemFinished(CurrentPending[i].PSC);
			CurrentPending.Remove(i, 1);
		}
	}
}
