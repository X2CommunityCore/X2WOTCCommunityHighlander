class CHDLCRunOrder extends Object perobjectconfig config(Game);

enum EDLCRunPriority
{
	RUN_STANDARD,
	RUN_FIRST,
	RUN_LAST
};

var config array<string> RunBefore;
var config array<string> RunAfter;
var config EDLCRunPriority RunPriorityGroup;
