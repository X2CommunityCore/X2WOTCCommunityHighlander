// Issue #511
// Create a DLCInfo loadorder system
class CHOnlineEventMgr extends XComOnlineEventMgr;

var array<CHDLCInfoTopologicalOrderNode> Nodes;
var array<CHDLCInfoTopologicalOrderNode> Stack;

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

	DLCInfoClasses = super.GetDLCInfos(bNewDLCOnly);

	// Maybe bypass ordering here if stack is filled and return cache
	// if (Stack.Length > 0)
	// {
	// 	return m_cachedDLCInfos;
	// }

	Nodes.Length = 0;
	Stack.Length = 0;

	foreach DLCInfoClasses(DLCInfoClass)
	{
		Node = new class'CHDLCInfoTopologicalOrderNode';
		Node.DLCInfoClass = DLCInfoClass;
		Node.DLCIdentifier = DLCInfoClass.DLCIdentifier;
		Node.RunBefore = DLCInfoClass.GetRunBeforeDLCIdentifiers();
		Node.RunAfter =  DLCInfoClass.GetRunAfterDLCIdentifiers();
		Node.bVisited = false;
		Nodes.AddItem(Node);
	}

	`LOG(default.class @ GetFuncName() @ "--- Before sort" @ DLCInfoClasses.Length @ "Nodes" @ Nodes.Length,, 'X2WOTCCommunityHighlander');

	ToplogicalSort();

	DLCInfoClasses.Length = 0;
	m_cachedDLCInfos.Length = 0;

	foreach Stack(Node)
	{
		DLCInfoClasses.AddItem(Node.DLCInfoClass);
		m_cachedDLCInfos.AddItem(Node.DLCInfoClass);
	}

	`LOG(default.class @ GetFuncName() @ "--- After sort" @ DLCInfoClasses.Length @ "Stack" @ Stack.Length,, 'X2WOTCCommunityHighlander');

	return DLCInfoClasses;
}

private function ToplogicalSort()
{
	local CHDLCInfoTopologicalOrderNode Node, RunBeforeNode;
	local string RunBefore;
	
	// rewrite RunAfter to RunBefore
	foreach Nodes(Node)
	{
		foreach Node.RunBefore(RunBefore)
		{
			RunBeforeNode = FindNode(Nodes, RunBefore);
			if (RunBeforeNode != None)
			{
				RunBeforeNode.RunAfter.AddItem(Node.DLCIdentifier);
			}
		}
	}

	// Sort nodes based on RunAfter
	foreach Nodes(Node)
	{
		if (!Node.bVisited)
		{
			ToplogicalSortUtil(Node);
		}
	}
}

private function ToplogicalSortUtil(CHDLCInfoTopologicalOrderNode Node)
{
	local CHDLCInfoTopologicalOrderNode SubNode;
	local string RunAfter;

	Node.bVisited = true;

	foreach Node.RunAfter(RunAfter)
	{
		SubNode = FindNode(Nodes, RunAfter);
		if (SubNode != None && !SubNode.bVisited)
		{
			ToplogicalSortUtil(SubNode);
		}
	}

	Stack.AddItem(Node);
}

private function CHDLCInfoTopologicalOrderNode FindNode(array<CHDLCInfoTopologicalOrderNode> Haystack, string DLCIdentifier)
{
	local CHDLCInfoTopologicalOrderNode Node;

	foreach Haystack(Node)
	{
		if (Node.DLCIdentifier == DLCIdentifier)
		{
			return Node;
		}
	}
	return None;
}


private function TestTopologicalOrdering()
{
	local CHDLCInfoTopologicalOrderNode Node;
	local array<string> ExpectedResult;
	local int Index;

	Nodes.Length = 0;
	Stack.Length = 0;

	Node = new class'CHDLCInfoTopologicalOrderNode';
	Node.DLCIdentifier = "A";
	Node.RunAfter.AddItem("C");
	//Node.RunBefore.AddItem("E");
	Nodes.AddItem(Node);

	Node = new class'CHDLCInfoTopologicalOrderNode';
	Node.DLCIdentifier = "B";
	Node.RunAfter.AddItem("A");
	Nodes.AddItem(Node);

	Node = new class'CHDLCInfoTopologicalOrderNode';
	Node.DLCIdentifier = "C";
	Nodes.AddItem(Node);

	Node = new class'CHDLCInfoTopologicalOrderNode';
	Node.DLCIdentifier = "E";
	Node.RunBefore.AddItem("A");
	Nodes.AddItem(Node);

	ExpectedResult.AddItem("C");
	ExpectedResult.AddItem("E");
	ExpectedResult.AddItem("A");
	ExpectedResult.AddItem("B");

	ToplogicalSort();

	foreach Stack(Node)
	{
		`LOG(default.class @ GetFuncName() @ Node.DLCIdentifier @ Node.DLCIdentifier == ExpectedResult[Index],, 'X2WOTCCommunityHighlander');
		Index++;
	}
}