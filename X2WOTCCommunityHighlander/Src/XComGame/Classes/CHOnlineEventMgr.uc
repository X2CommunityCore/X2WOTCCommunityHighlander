// Issue #511
/// HL-Docs: ref:DLCRunOrder
class CHOnlineEventMgr extends XComOnlineEventMgr dependson(CHDLCRunOrder, CHDLCRunOrderDiagnostic);

var bool bWarmCache;

struct CHRunOrderIdentLookup
{
	var string DLCIdentifier;
	var CHDLCRunOrder Node;
};

// Accelerator for access by DLCIdentifier
var array<CHRunOrderIdentLookup> AllNodes;

var array<CHDLCRunOrderDiagnostic> Diagnostics;

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
	PrintWarnings();

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
						Diagnostics.AddItem(class'CHDLCRunOrderDiagnostic'.static.GroupWarning(eCHROWK_OrderCorrectDifferentGroup, Curr, Other, SOURCE_RunBefore));
						break;
					case 1:
						Diagnostics.AddItem(class'CHDLCRunOrderDiagnostic'.static.GroupWarning(eCHROWK_OrderIncorrectDifferentGroup, Curr, Other, SOURCE_RunBefore));
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
						Diagnostics.AddItem(class'CHDLCRunOrderDiagnostic'.static.GroupWarning(eCHROWK_OrderIncorrectDifferentGroup, Other, Curr, SOURCE_RunAfter));
						break;
					case 1:
						Diagnostics.AddItem(class'CHDLCRunOrderDiagnostic'.static.GroupWarning(eCHROWK_OrderCorrectDifferentGroup, Other, Curr, SOURCE_RunAfter));
						break;
					case 0:
						Curr.PushRunAfterEdge(Other, SOURCE_RunAfter);
						break;
				}
			}
		}
	}
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
		Diagnostics.AddItem(class'CHDLCRunOrderDiagnostic'.static.CycleError(PotentialCycleEdges));
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

	if (DLCIdentifier == "") return None;

	idx = Nodes.Find('DLCIdentifier', DLCIdentifier);

	return idx != INDEX_NONE ? Nodes[idx].Node : None;
}

final function DumpInternals()
{
	local X2DownloadableContentInfo DLCInfo;

	if (!bWarmCache)
	{
		CHReleaseLog("DumpInternals: No info yet", 'X2WOTCCommunityHighlander');
		return;
	}

	CHReleaseLog("#########################################", 'X2WOTCCommunityHighlander');
	CHReleaseLog("Run Order DumpInternals: Dumping info about DLC Info classes, in run order:", 'X2WOTCCommunityHighlander');

	foreach m_cachedDLCInfos(DLCInfo)
	{
		CHReleaseLog(FormatDLCInfo(DLCInfo), 'X2WOTCCommunityHighlander');
	}

	CHReleaseLog("#########################################", 'X2WOTCCommunityHighlander');
	CHReleaseLog("Run Order DumpInternals: The following warnings and errors were found during DAG construction", 'X2WOTCCommunityHighlander');
	PrintWarnings();
	CHReleaseLog("#########################################", 'X2WOTCCommunityHighlander');
}

private function string FormatDLCInfo(X2DownloadableContentInfo DLCInfo)
{
	local string Fmt, Arr, DLCIdent;
	local CHDLCRunOrder Node;
	local int i;

	Fmt $= PathName(DLCInfo.Class) $ ": DLCIdentifier=";
	DLCIdent = DLCInfo.DLCIdentifier;
	Fmt $= DLCIdent != "" ? DLCIdent : "MISSING";

	if (DLCIdent != "")
	{
		i = AllNodes.Find('DLCIdentifier', DLCIdent);
		if (i != INDEX_NONE)
		{
			Node = AllNodes[i].Node;

			Fmt $= ", RunPriorityGroup=" $ Node.RunPriorityGroup;

			if (Node.RunBefore.Length > 0)
			{
				Arr = "";
				Fmt $= ", RunBefore=[";
				JoinArray(Node.RunBefore, Arr);
				Fmt $= Arr $ "]";
			}

			if (Node.RunAfter.Length > 0)
			{
				Arr = "";
				Fmt $= ", RunAfter=[";
				JoinArray(Node.RunAfter, Arr);
				Fmt $= Arr $ "]";
			}
		}
	}

	return Fmt;
}

private function PrintWarnings()
{
	local CHDLCRunOrderDiagnostic Diag;
	local array<string> Blame;
	local string BlameFmt;

	foreach Diagnostics(Diag)
	{
		switch (Diag.Kind)
		{
			case eCHROKW_Cycle:
				PrintCycleWarning(Diag);
				break;
			case eCHROWK_OrderCorrectDifferentGroup:
				CHReleaseLog("WARNING: Redundant RunBefore/RunAfter lines:" @ Diag.FormatSingleFact(true) @ "but this is always the case because" @ Diag.FormatGroups(true), 'X2WOTCCommunityHighlander');
				break;
			case eCHROWK_OrderIncorrectDifferentGroup:
				CHReleaseLog("ERROR: INCORRECT and IGNORED RunBefore/RunAfter lines:" @ Diag.FormatSingleFact(true) @ "but this is NEVER the case because" @ Diag.FormatGroups(true), 'X2WOTCCommunityHighlander');
				break;
		}

		BlameFmt = "";
		Blame = Diag.Blame();
		JoinArray(Blame, BlameFmt, ", ");
		CHReleaseLog("  The following DLCIdentifiers provided config that lead to this problem:" @ BlameFmt, 'X2WOTCCommunityHighlander');
	}
}

private function PrintCycleWarning(CHDLCRunOrderDiagnostic Diag)
{
	local array<string> Facts;
	local string Fact;

	CHReleaseLog("ERROR: RunBefore/RunAfter lines cause cycle and cannot be fulfilled:", 'X2WOTCCommunityHighlander');
	
	Facts = Diag.FormatEdgeFacts(true);

	foreach Facts(Fact)
	{
		CHReleaseLog("    " $ Fact, 'X2WOTCCommunityHighlander');
	}
	CHReleaseLog("  ...completing the cycle. Until this is corrected, run order will be undefined.", 'X2WOTCCommunityHighlander');
}
