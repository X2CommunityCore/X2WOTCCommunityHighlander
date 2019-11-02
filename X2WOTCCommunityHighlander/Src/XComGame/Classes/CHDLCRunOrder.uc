class CHDLCRunOrder extends Object perobjectconfig config(Game);

enum EDLCRunPriority
{
	RUN_STANDARD, // Must be 0 for default value
	RUN_FIRST,
	RUN_LAST
};

var config array<string> RunBefore;
var config array<string> RunAfter;
var config EDLCRunPriority RunPriorityGroup;
