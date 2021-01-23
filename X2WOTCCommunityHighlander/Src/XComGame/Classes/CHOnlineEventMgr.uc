// Issue #511
// Create a DLCInfo loadorder system
class CHOnlineEventMgr extends XComOnlineEventMgr dependson(CHDLCRunOrder);

var bool bWarmCache;

enum CHRunOrderWarningKind
{
	eCHROWK_OrderCorrectDifferentGroup, // e.g. A RunsBefore B and A is RUN_FIRST and B is RUN_STANDARD
	eCHROWK_OrderIncorrectDifferentGroup, // e.g. A RunsBefore B and A is RUN_LAST and B is RUN_STANDARD
	eCHROKW_Cycle,
};

struct CHRunOrderDesiredEdge
{
	var CHDLCRunOrder FirstNode;
	var CHDLCRunOrder SecondNode;
	var EDLCEdgeSource EdgeSource;
};

struct CHRunOrderWarning
{
	var CHRunOrderWarningKind Kind;
	var array<CHRunOrderDesiredEdge> Edges;
};

struct CHRunOrderIdentLookup
{
	var string DLCIdentifier;
	var CHDLCRunOrder Node;
};

// Accelerator for access by DLCIdentifier
var array<CHRunOrderIdentLookup> AllNodes;

var array<CHRunOrderWarning> Warnings;

event Init()
{
	super.Init();
}

function array<X2DownloadableContentInfo> GetDLCInfos(bool bNewDLCOnly)
{
	local array<X2DownloadableContentInfo> DLCInfoClasses;
	local X2DownloadableContentInfo DLCInfoClass;
	local CHDLCRunOrder ConfigObject;
	local array<CHRunOrderIdentLookup> NodesFirst;
	local array<CHRunOrderIdentLookup> NodesStandard;
	local array<CHRunOrderIdentLookup> NodesLast;
	local CHRunOrderIdentLookup TmpLookup;

	DLCInfoClasses = super.GetDLCInfos(bNewDLCOnly);

	if (bNewDLCOnly)
	{
		return DLCInfoClasses;
	}
	
	// Bypass ordering here if we have a warm cache
	if (bWarmCache && m_cachedDLCInfos.Length > 0)
	{
		return m_cachedDLCInfos;
	}

	foreach DLCInfoClasses(DLCInfoClass)
	{
		if (DLCInfoClass.DLCIdentifier != "")
		{
			ConfigObject = new(none, DLCInfoClass.DLCIdentifier) class'CHDLCRunOrder';
		}
		else
		{
			ConfigObject = new class'CHDLCRunOrder';
		}

		ConfigObject.DLCInfoClass = DLCInfoClass;

		TmpLookup.DLCIdentifier = DLCInfoClass.DLCIdentifier;
		TmpLookup.Node = ConfigObject;
		AllNodes.AddItem(TmpLookup);

		switch (ConfigObject.RunPriorityGroup)
		{
			case RUN_FIRST:
				NodesFirst.AddItem(TmpLookup);
				break;
			case RUN_LAST:
				NodesLast.AddItem(TmpLookup);
				break;
			case RUN_STANDARD:
			default:
				NodesStandard.AddItem(TmpLookup);
				break;
		}
	}

	`LOG(default.class @ GetFuncName() @ "--- Before sort" @ DLCInfoClasses.Length,, 'X2WOTCCommunityHighlander');

	CanonicalizeEdges();

	DLCInfoClasses.Length = 0;
	m_cachedDLCInfos.Length = 0;

	ToplogicalSort(NodesFirst, DLCInfoClasses);
	ToplogicalSort(NodesStandard, DLCInfoClasses);
	ToplogicalSort(NodesLast, DLCInfoClasses);

	`LOG(default.class @ GetFuncName() @ "--- After sort" @ DLCInfoClasses.Length,, 'X2WOTCCommunityHighlander');

	m_cachedDLCInfos = DLCInfoClasses;
	bWarmCache = true;

	return DLCInfoClasses;
}

// Rewrite all edges in terms of RunAfter while reporting warnings for DLCIdentifiers that
// attempt to do RunOrder things with DLCIdentifiers in other RunPriorityGroups
private function CanonicalizeEdges()
{
	local CHRunOrderIdentLookup Lookup;
	local CHDLCRunOrder Curr, Other;
	local string Target;
	local int CmpResult;

	foreach AllNodes(Lookup)
	{
		Curr = Lookup.Node;
		foreach Curr.RunBefore(Target)
		{
			Other = FindNode(AllNodes, Target);
			if (Other != none)
			{
				CmpResult = CompareRunPriority(Curr.RunPriorityGroup, Other.RunPriorityGroup);
				switch (CmpResult)
				{
					case -1:
						PushGroupWarning(eCHROWK_OrderCorrectDifferentGroup, Curr, Other, SOURCE_RunBefore);
						break;
					case 1:
						PushGroupWarning(eCHROWK_OrderIncorrectDifferentGroup, Curr, Other, SOURCE_RunBefore);
						break;
					case 0:
						Other.PushRunAfterEdge(Curr, SOURCE_RunBefore);
						break;
				}
			}
		}

		foreach Curr.RunAfter(Target)
		{
			Other = FindNode(AllNodes, Target);
			if (Other != none)
			{
				CmpResult = CompareRunPriority(Curr.RunPriorityGroup, Other.RunPriorityGroup);
				switch (CmpResult)
				{
					case -1:
						PushGroupWarning(eCHROWK_OrderIncorrectDifferentGroup, Other, Curr, SOURCE_RunAfter);
						break;
					case 1:
						PushGroupWarning(eCHROWK_OrderCorrectDifferentGroup, Other, Curr, SOURCE_RunAfter);
						break;
					case 0:
						Curr.PushRunAfterEdge(Other, SOURCE_RunAfter);
						break;
				}
			}
		}
	}
}

private function PushGroupWarning(CHRunOrderWarningKind Kind, CHDLCRunOrder First, CHDLCRunOrder Second, EDLCEdgeSource EdgeSource)
{
	local CHRunOrderWarning Warning;
	local CHRunOrderDesiredEdge Edge;

	Warning.Kind = Kind;

	Edge.FirstNode = First;
	Edge.SecondNode = Second;
	Edge.EdgeSource = EdgeSource;
	Warning.Edges.AddItem(Edge);

	Warnings.AddItem(Warning);
}

private function ReportCycleError(const out array<CHRunOrderDesiredEdge> Edges)
{
	local CHRunOrderWarning Warning;
	local string Last;

	Warning.Kind = eCHROKW_Cycle;
	Warning.Edges = Edges;

	Last = Warning.Edges[Warning.Edges.Length - 1].SecondNode.DLCIdentifier;

	// This loop *should* always exit due to the second condition, but we really don't
	// want some super weird config I couldn't ever imagine to deadlock the game just for
	// some error reporting.
	while (Warning.Edges.Length > 0 && Warning.Edges[0].FirstNode.DLCIdentifier != Last)
	{
		Warning.Edges.Remove(0, 1);
	}

	Warnings.AddItem(Warning);
}

// Returns 0 if same run group, -1 if A runs before B, +1 if B runs before A
private function int CompareRunPriority(EDLCRunPriority A, EDLCRunPriority B)
{
	if (A == B) return 0;
	if (A == RUN_FIRST) return -1;
	if (A == RUN_LAST) return 1;
	if (B == RUN_FIRST) return 1;
	if (B == RUN_LAST) return -1;
}

private function ToplogicalSort(const out array<CHRunOrderIdentLookup> Nodes, out array<X2DownloadableContentInfo> DLCInfos)
{
	local CHRunOrderIdentLookup Entry;
	local array<CHRunOrderDesiredEdge> PotentialCycleEdges;

	foreach Nodes(Entry)
	{
		if (!Entry.Node.bVisited)
		{
			DFSTopSort(Nodes, DLCInfos, PotentialCycleEdges, Entry.Node);
		}
	}
}

// A depth-first-search based topological sorting algorithm with cycle checking -- and a twist.
// The algorithm is based on https://en.wikipedia.org/wiki/Topological_sorting#Depth-first_search
// with a small modification:
// Instead of starting with an unvisited node and running the recursive DFS over its successors and adding
// the node to the head of the list after the recursive call, we run the DFS over the predecessors and add
// nodes to the tail of the list. This is facilitated by `CanonicalizeEdges`, which rewrites all edges
// to RunAfter edges.
private function DFSTopSort(
	const out array<CHRunOrderIdentLookup> Nodes,
	out array<X2DownloadableContentInfo> DLCInfos,
	out array<CHRunOrderDesiredEdge> PotentialCycleEdges,
	CHDLCRunOrder Node
)
{
	local RunAfterEdge RunAfter;
	local CHRunOrderDesiredEdge NewEdge;

	if (Node.bVisitedWeak)
	{
		ReportCycleError(PotentialCycleEdges);
		// This will lead to incorrect order since a topological ordering
		// is not possible. Losing DLCInfo classes would be much worse though,
		// so simply return and end up with *some* order.
		Node.bVisitedWeak = false;
		return;
	}

	Node.bVisitedWeak = true;

	foreach Node.RunAfterEdges(RunAfter)
	{
		if (!RunAfter.Node.bVisited)
		{
			NewEdge.FirstNode = RunAfter.Node;
			NewEdge.SecondNode = Node;
			NewEdge.EdgeSource = RunAfter.EdgeSource;
			PotentialCycleEdges.AddItem(NewEdge);
			
			DFSTopSort(Nodes, DLCInfos, PotentialCycleEdges, RunAfter.Node);

			PotentialCycleEdges.Remove(PotentialCycleEdges.Length - 1, 1);
		}
	}

	Node.bVisitedWeak = false;
	Node.bVisited = true;

	DLCInfos.AddItem(Node.DLCInfoClass);
}

private function CHDLCRunOrder FindNode(const out array<CHRunOrderIdentLookup> Nodes, string DLCIdentifier)
{
	local int idx;

	idx = Nodes.Find('DLCIdentifier', DLCIdentifier);

	return idx != INDEX_NONE ? Nodes[idx].Node : None;
}


final function DumpInternals()
{
	local CHRunOrderIdentLookup Lookup;
	local RunAfterEdge Edge;

	foreach AllNodes(Lookup)
	{
		if (Lookup.Node.RunAfterEdges.Length > 0)
		{
			`log("Node with" @ Lookup.DLCIdentifier @ "runs after:", , 'X2WOTCCommunityHighlander');
			foreach Lookup.Node.RunAfterEdges(Edge)
			{
				`log("  " $ Edge.Node.DLCInfoClass.DLCIdentifier @ "with source" @ Edge.EdgeSource, , 'X2WOTCCommunityHighlander');
			}
		}
		else
		{
			`log("Node with" @ Lookup.DLCIdentifier, , 'X2WOTCCommunityHighlander');
		}
	}

	PrintWarnings();
}

final function PrintWarnings()
{
	local CHRunOrderWarning Warn;

	foreach Warnings(Warn)
	{
		switch (Warn.Kind)
		{
			case eCHROKW_Cycle:
				PrintCycleWarning(Warn.Edges);
				break;
			case eCHROWK_OrderCorrectDifferentGroup:
				`log("WARNING: Redundant RunBefore/RunAfter lines:" @ FormatFact(Warn.Edges[0]) @ "but this is always the case because" @ FormatGroups(Warn.Edges[0]), , 'X2WOTCCommunityHighlander');
				break;
			case eCHROWK_OrderIncorrectDifferentGroup:
				`log("ERROR: INCORRECT and IGNORED RunBefore/RunAfter lines:" @ FormatFact(Warn.Edges[0]) @ "but this is NEVER the case because" @ FormatGroups(Warn.Edges[0]), , 'X2WOTCCommunityHighlander');
				break;
		}
	}
}

private function PrintCycleWarning(const out array<CHRunOrderDesiredEdge> Edges)
{
	local CHRunOrderDesiredEdge Edge;
	`log("ERROR: RunBefore/RunAfter lines cause cycle and cannot be fulfilled:", , 'X2WOTCCommunityHighlander');

	foreach Edges(Edge)
	{
		`log("    " $ FormatFact(Edge), , 'X2WOTCCommunityHighlander');
	}
	`log("  ...completing the cycle. Until this is corrected, run order will be undefined.", , 'X2WOTCCommunityHighlander');
}

private function string FormatFact(CHRunOrderDesiredEdge Edge)
{
	switch (Edge.EdgeSource)
	{
		case SOURCE_RunBefore:
			return Edge.FirstNode.DLCInfoClass.DLCIdentifier @ "wants to run before" @ Edge.SecondNode.DLCInfoClass.DLCIdentifier;
		case SOURCE_RunAfter:
			return Edge.SecondNode.DLCInfoClass.DLCIdentifier @ "wants to run after" @ Edge.FirstNode.DLCInfoClass.DLCIdentifier;
		case SOURCE_Both:
			return Edge.FirstNode.DLCInfoClass.DLCIdentifier @ "wants to run before" @ Edge.SecondNode.DLCInfoClass.DLCIdentifier
				@ "and" @ Edge.SecondNode.DLCInfoClass.DLCIdentifier @ "wants to run after" @ Edge.FirstNode.DLCInfoClass.DLCIdentifier;
	}
}

private function string FormatGroups(CHRunOrderDesiredEdge Edge)
{
	return Edge.FirstNode.DLCInfoClass.DLCIdentifier @ "is in group" @ Edge.FirstNode.RunPriorityGroup @ "and"
		@ Edge.SecondNode.DLCInfoClass.DLCIdentifier @ "is in group" @ Edge.SecondNode.RunPriorityGroup;
}