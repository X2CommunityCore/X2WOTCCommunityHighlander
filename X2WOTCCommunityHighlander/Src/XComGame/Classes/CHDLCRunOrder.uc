class CHDLCRunOrder extends Object perobjectconfig config(Game);

enum EDLCRunPriority
{
	RUN_STANDARD, // Must be 0 for default value
	RUN_FIRST,
	RUN_LAST
};

enum EDLCEdgeSource
{
	SOURCE_RunBefore,
	SOURCE_RunAfter,
	SOURCE_Both,
};

var config array<string> RunBefore;
var config array<string> RunAfter;
var config EDLCRunPriority RunPriorityGroup;

// Runtime data
struct RunAfterEdge
{
	var CHDLCRunOrder Node;
	var EDLCEdgeSource EdgeSource;
};

var X2DownloadableContentInfo DLCInfoClass;
var array<RunAfterEdge> RunAfterEdges;
var bool bVisited;
var bool bVisitedWeak;

// Source must be one of {SOURCE_RunBefore, SOURCE_RunAfter}
final function PushRunAfterEdge(CHDLCRunOrder Node, EDLCEdgeSource Source)
{
	local int idx;
	local RunAfterEdge Edge;

	idx = RunAfterEdges.Find('Node', Node);
	if (idx != INDEX_NONE)
	{
		if (RunAfterEdges[idx].EdgeSource != Source)
		{
			RunAfterEdges[idx].EdgeSource = SOURCE_Both;
		}
	}
	else
	{
		Edge.Node = Node;
		Edge.EdgeSource = Source;
		RunAfterEdges.AddItem(Edge);
	}
}