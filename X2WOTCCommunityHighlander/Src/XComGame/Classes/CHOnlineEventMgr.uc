// Issue #511
// Create a DLCInfo loadorder system
class CHOnlineEventMgr extends XComOnlineEventMgr dependson(CHDLCRunOrder);

var bool bWarmCache;
var string strWarnings;

event Init()
{
	super.Init();
	TestTopologicalOrdering();
}

function array<X2DownloadableContentInfo> GetDLCInfos(bool bNewDLCOnly)
{
	local array<X2DownloadableContentInfo> DLCInfoClasses;
	local X2DownloadableContentInfo DLCInfoClass;
	local CHDLCInfoTopologicalOrderNode Node;
	local array<CHDLCInfoTopologicalOrderNode> NodesFirst;
	local array<CHDLCInfoTopologicalOrderNode> NodesStandard;
	local array<CHDLCInfoTopologicalOrderNode> NodesLast;
	local array<CHDLCInfoTopologicalOrderNode> Stack;

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
		Node = new class'CHDLCInfoTopologicalOrderNode';
		Node.DLCInfoClass = DLCInfoClass;
		Node.DLCIdentifier = DLCInfoClass.DLCIdentifier;
		Node.RunBefore = DLCInfoClass.GetRunBeforeDLCIdentifiers();
		Node.RunAfter =  DLCInfoClass.GetRunAfterDLCIdentifiers();
		Node.bVisited = false;

		switch (DLCInfoClass.GetRunPriorityGroup())
		{
			case RUN_FIRST:
				NodesFirst.AddItem(Node);
				break;
			case RUN_LAST:
				NodesLast.AddItem(Node);
				break;
			case RUN_STANDARD: default:
				NodesStandard.AddItem(Node);
				break;
		}
	}

	`LOG(default.class @ GetFuncName() @ "--- Before sort" @ DLCInfoClasses.Length,, 'X2WOTCCommunityHighlander');

	strWarnings = "";
	DLCInfoClasses.Length = 0;
	m_cachedDLCInfos.Length = 0;

	ToplogicalSort(NodesFirst, Stack);
	AddStackAndReset(DLCInfoClasses, Stack);
	strWarnings = Repl(strWarnings, "%s", "RUN_FIRST");

	ToplogicalSort(NodesStandard, Stack);
	AddStackAndReset(DLCInfoClasses, Stack);
	strWarnings = Repl(strWarnings, "%s", "RUN_STANDARD");

	ToplogicalSort(NodesLast, Stack);
	AddStackAndReset(DLCInfoClasses, Stack);
	strWarnings = Repl(strWarnings, "%s", "RUN_LAST");

	`LOG(default.class @ GetFuncName() @ "--- After sort" @ DLCInfoClasses.Length,, 'X2WOTCCommunityHighlander');

	if (strWarnings != "")
	{
		`LOG(default.class @ GetFuncName() @ strWarnings,, 'X2WOTCCommunityHighlander');
		strWarnings = "";
	}

	bWarmCache = true;

	return DLCInfoClasses;
}


private function AddStackAndReset(
	out array<X2DownloadableContentInfo> DLCInfoClasses,
	out array<CHDLCInfoTopologicalOrderNode> Stack
)
{
	local CHDLCInfoTopologicalOrderNode Node;

	foreach Stack(Node)
	{
		DLCInfoClasses.AddItem(Node.DLCInfoClass);
		m_cachedDLCInfos.AddItem(Node.DLCInfoClass);
	}

	Stack.Length = 0;
}

private function ToplogicalSort(array<CHDLCInfoTopologicalOrderNode> Nodes, out array<CHDLCInfoTopologicalOrderNode> Stack)
{
	local CHDLCInfoTopologicalOrderNode Node, RunBeforeNode;
	local string RunBefore;
	
	// rewrite RunBefore to RunAfter
	foreach Nodes(Node)
	{
		foreach Node.RunBefore(RunBefore)
		{
			RunBeforeNode = FindNode(Nodes, RunBefore);

			if (RunBeforeNode == none)
			{
				strWarnings $= default.class @ Node.DLCIdentifier @ "could not find RunBefore" @ RunBefore @ "in priority group %s\n";
			}

			if (RunBeforeNode != None)
			{
				RunBeforeNode.RunAfter.AddItem(Node.DLCIdentifier);
			}
		}
	}

	// Sort NodesStandard based on RunAfter
	foreach Nodes(Node)
	{
		if (!Node.bVisited)
		{
			ToplogicalSortUtil(Nodes, Stack, Node);
		}
	}
}

private function ToplogicalSortUtil(
	array<CHDLCInfoTopologicalOrderNode> Nodes,
	out array<CHDLCInfoTopologicalOrderNode> Stack,
	CHDLCInfoTopologicalOrderNode Node
)
{
	local CHDLCInfoTopologicalOrderNode SubNode;
	local string RunAfter;

	Node.bVisited = true;

	foreach Node.RunAfter(RunAfter)
	{
		SubNode = FindNode(Nodes, RunAfter);

		if (SubNode == none)
		{
			strWarnings $= default.class @ Node.DLCIdentifier @ "could not find RunAfter" @ RunAfter @ "in priority group %s\n";
		}

		if (SubNode != None && !SubNode.bVisited)
		{
			ToplogicalSortUtil(Nodes, Stack, SubNode);
		}
	}

	Stack.AddItem(Node);
}

private function CHDLCInfoTopologicalOrderNode FindNode(array<CHDLCInfoTopologicalOrderNode> HayStack, string DLCIdentifier)
{
	local CHDLCInfoTopologicalOrderNode Node;

	foreach HayStack(Node)
	{
		if (Node.DLCIdentifier == DLCIdentifier)
		{
			return Node;
		}
	}
	return None;
}

// Unit tests
private function TestTopologicalOrdering()
{
	local array<CHDLCInfoTopologicalOrderNode> NodesFst, NodesLst, NodesStd;
	local array<CHDLCInfoTopologicalOrderNode> Buffer, MyStack;
	local CHDLCInfoTopologicalOrderNode Node;
	local array<string> ExpectedResult;
	local int Index;

	NodesFst.AddItem(GetNode("Z"));
	NodesFst.AddItem(GetNode("Y", "1", "Z"));

	NodesStd.AddItem(GetNode("A", "Z", "C"));
	NodesStd.AddItem(GetNode("B",, "A"));
	NodesStd.AddItem(GetNode("C"));
	NodesStd.AddItem(GetNode("E", "A"));

	NodesLst.AddItem(GetNode("2", "B"));
	NodesLst.AddItem(GetNode("1", "2"));

	ExpectedResult.AddItem("Z");
	ExpectedResult.AddItem("Y");
	ExpectedResult.AddItem("C");
	ExpectedResult.AddItem("E");
	ExpectedResult.AddItem("A");
	ExpectedResult.AddItem("B");
	ExpectedResult.AddItem("1");
	ExpectedResult.AddItem("2");

	ToplogicalSort(NodesFst, MyStack);
	AddMyStackToBufferAndReset(Buffer, MyStack);
	strWarnings = Repl(strWarnings, "%s", "RUN_FIRST");

	ToplogicalSort(NodesStd, MyStack);
	AddMyStackToBufferAndReset(Buffer, MyStack);
	strWarnings = Repl(strWarnings, "%s", "RUN_STANDARD");

	ToplogicalSort(NodesLst, MyStack);
	AddMyStackToBufferAndReset(Buffer, MyStack);
	strWarnings = Repl(strWarnings, "%s", "RUN_LAST");

	`LOG(default.class @ GetFuncName() @ strWarnings,, 'X2WOTCCommunityHighlander');

	foreach Buffer(Node)
	{
		`LOG(default.class @ GetFuncName() @ Node.DLCIdentifier @ Node.DLCIdentifier == ExpectedResult[Index],, 'X2WOTCCommunityHighlander');
		Index++;
	}
}

private function AddMyStackToBufferAndReset(
	out array<CHDLCInfoTopologicalOrderNode> Buffer,
	out array<CHDLCInfoTopologicalOrderNode> Stack
)
{
	local CHDLCInfoTopologicalOrderNode Node;

	foreach Stack(Node)
	{
		Buffer.AddItem(Node);
	}

	Stack.Length = 0;
}

static private function CHDLCInfoTopologicalOrderNode GetNode(
	string DLCIdentifer,
	optional string RunBefore,
	optional string RunAfter
)
{	
	local CHDLCInfoTopologicalOrderNode Node;

	Node = new class'CHDLCInfoTopologicalOrderNode';
	Node.DLCIdentifier = DLCIdentifer;
	if (RunBefore != "")
	{
		Node.RunBefore.AddItem(RunBefore);
	}
	if (RunAfter != "")
	{
		Node.RunAfter.AddItem(RunAfter);
	}
	return Node;
}