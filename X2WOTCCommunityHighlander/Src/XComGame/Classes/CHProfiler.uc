/// HL-Docs: feature:CHProfiler; issue:1044; tags:
/// While you can profile the game's and mods' UnrealScript code with the
/// [Gameplay Profiler](https://www.reddit.com/r/xcom2mods/wiki/index/profiling),
/// the profiles lack semantic information. The CHProfiler facilitates recording
/// and dumping **additional** performance information, usually requiring user
/// configuration to do so (console commands, config).
///
/// ## Ability Profiling
///
/// Sometimes, the gameplay profiler may yield performance issues in ability target
/// collection and condition checking. It's often hard to figure out which ability
/// in particular is at fault, since all native conditions are usually invisible
/// in the gameplay profiler and many abilities share conditions.
///
/// The ability profiler records the time it takes for an ability to collect
/// targets and check conditions. The currently used timer has a **millisecond**
/// resolution due to a missing higher-resolution timer, so it may only be
/// useful to identify egregious issues.
///
/// The console command `CHLBeginAbilityProfiling` begins event collection,
/// while `CHLEndAbilityProfiling` ends it and prints the collected data
/// to the log and console.
/// The resulting string conforms to the following grammar:
///
/// ```abnf
/// <string> ::= <part> | (<part> ";" <string>) | E
/// <part> ::= <name> ":" <numlist>
/// <numlist> ::= <number> | (<number> "," <numlist>)
/// <number> ::= [0-9]+
/// <name> ::= ([A-Z] | [a-z] | [0-9] | "_")+
/// ```
///
/// i.e. a semicolon-separated list of AbilityName, colon, comma-separated numbers sequences.
/// Every time the game calls `UpdateAbilityAvailability`, it measures the time it took the call.
/// Every number in the output corresponds to one call.
///
/// You can then analyze the results with an external tool, for example by [visualizing them
/// using matplotlib](https://gist.github.com/robojumper/1ee2de9bd38377b9c57e6ff684075780):
///
/// ![matplotlib ability profile](https://i.imgur.com/VHWJAqs.png)
///
/// **The exact output format and the clock resolution are subject to change.**
class CHProfiler extends Object config(CHProfiling);

struct AbilityEvents
{
	var name AbilityName;
	var array<int> Events;
};

var private array<AbilityEvents> AbilityTimings;

var privatewrite bool bAbilityProfileEnabled;

var config privatewrite array<name> ExtendedProfileAbilityNames;
var privatewrite bool bExtendedProfilingUnconditional;

private static function CHProfiler GetCDO()
{
	// This is hot code, so use an optimized function here
	return CHProfiler(FindObject("XComGame.Default__CHProfiler", class'CHProfiler'));
}

static function AddAbilityTiming(name AbilityName, int Millis)
{
	local CHProfiler Prof;

	Prof = static.GetCDO();
	AddAbilityEvent(Prof.AbilityTimings, AbilityName, Millis);
}

static private function AddAbilityEvent(out array<AbilityEvents> arr, name AbilityName, int Num)
{
	local int idx;

	idx = arr.Find('AbilityName', AbilityName);
	if (idx == INDEX_NONE)
	{
		idx = arr.Length;
		arr.Add(1);
		arr[idx].AbilityName = AbilityName;
	}
	arr[idx].Events.AddItem(Num);
}

static function bool ShouldExtendedProfileActivity(name AbilityName)
{
	return default.bExtendedProfilingUnconditional || default.ExtendedProfileAbilityNames.Find(AbilityName) != INDEX_NONE;
}

static function EnableExtendedAbilityProfiling(name AbilityName)
{
	local CHProfiler Prof;

	Prof = static.GetCDO();
	if (string(AbilityName) ~= "all")
	{
		Prof.bExtendedProfilingUnconditional = true;
	}
	else
	{
		Prof.ExtendedProfileAbilityNames.AddItem(AbilityName);
	}
}

static function ClearAbilityProfile()
{
	local CHProfiler Prof;
	Prof = static.GetCDO();
	Prof.AbilityTimings.Length = 0;
}

static function SetAbilityProfiling(bool bEnabled)
{
	local CHProfiler Prof;
	Prof = static.GetCDO();
	Prof.bAbilityProfileEnabled = bEnabled;
}

static function DumpAbilityProfile()
{
	local CHProfiler Prof;

	Prof = static.GetCDO();

	class'X2TacticalGameRuleset'.static.ReleaseScriptLog("CHProfiler: Ability timings");
	class'X2TacticalGameRuleset'.static.ReleaseScriptLog(FormatEvents(Prof.AbilityTimings));
}

static private function string FormatEvents(const out array<AbilityEvents> arr)
{
	local string DataString;
	local int idx, eidx;
	
	DataString = "";
	for (idx = 0; idx < arr.Length; idx++)
	{
		DataString $= arr[idx].AbilityName;
		DataString $= ":";

		for (eidx = 0; eidx < arr[idx].Events.Length; eidx++)
		{
			DataString $= arr[idx].Events[eidx];

			if (eidx != arr[idx].Events.Length - 1)
			{
				DataString $= ",";
			}
		}

		if (idx != arr.Length - 1)
		{
			DataString $= ";";
		}
	}

	return DataString;
}