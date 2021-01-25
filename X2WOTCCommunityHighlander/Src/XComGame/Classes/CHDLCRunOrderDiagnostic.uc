class CHDLCRunOrderDiagnostic extends Object;

enum CHRunOrderWarningKind
{
	eCHROWK_OrderCorrectDifferentGroup, // e.g. A RunBefore B and A is RUN_FIRST and B is RUN_STANDARD
	eCHROWK_OrderIncorrectDifferentGroup, // e.g. A RunBefore B and A is RUN_LAST and B is RUN_STANDARD
	eCHROKW_Cycle,
};

struct CHRunOrderDesiredEdge
{
	var CHDLCRunOrder FirstNode;
	var CHDLCRunOrder SecondNode;
	var EDLCEdgeSource EdgeSource;
};

var CHRunOrderWarningKind Kind;
var array<CHRunOrderDesiredEdge> Edges;


static function CHDLCRunOrderDiagnostic GroupWarning(CHRunOrderWarningKind InKind, CHDLCRunOrder First, CHDLCRunOrder Second, EDLCEdgeSource EdgeSource)
{
	local CHDLCRunOrderDiagnostic Diag;
	local CHRunOrderDesiredEdge Edge;

	Diag = new default.Class;

	Diag.Kind = InKind;

	Edge.FirstNode = First;
	Edge.SecondNode = Second;
	Edge.EdgeSource = EdgeSource;

	Diag.Edges.AddItem(Edge);

	return Diag;
}

static function CHDLCRunOrderDiagnostic CycleError(const out array<CHRunOrderDesiredEdge> InEdges)
{
	local CHDLCRunOrderDiagnostic Diag;
	local string Last;

	Diag = new default.Class;

	Diag.Kind = eCHROKW_Cycle;
	Diag.Edges = InEdges;

	Last = Diag.Edges[Diag.Edges.Length - 1].FirstNode.DLCInfoClass.DLCIdentifier;

	// This loop *should* always exit due to the second condition, but we really don't
	// want some super weird config I couldn't ever imagine to deadlock the game just for
	// some error reporting.
	while (Diag.Edges.Length > 0 && Diag.Edges[0].SecondNode.DLCInfoClass.DLCIdentifier != Last)
	{
		Diag.Edges.Remove(0, 1);
	}

	return Diag;
}

function array<string> Blame()
{
	local array<string> UniqueDLCIdents;
	local CHRunOrderDesiredEdge Edge;

	foreach Edges(Edge)
	{
		switch (Edge.EdgeSource)
		{
			case SOURCE_RunBefore:
				`AddUniqueItemToArray(UniqueDLCIdents, Edge.FirstNode.DLCInfoClass.DLCIdentifier);
				break;
			case SOURCE_RunAfter:
				`AddUniqueItemToArray(UniqueDLCIdents, Edge.SecondNode.DLCInfoClass.DLCIdentifier);
				break;
			case SOURCE_Both:
				`AddUniqueItemToArray(UniqueDLCIdents, Edge.FirstNode.DLCInfoClass.DLCIdentifier);
				`AddUniqueItemToArray(UniqueDLCIdents, Edge.SecondNode.DLCInfoClass.DLCIdentifier);
				break;
		}
	}

	return UniqueDLCIdents;
}

function array<string> FormatEdgeFacts()
{
	local array<string> Res;
	local CHRunOrderDesiredEdge Edge;

	foreach Edges(Edge)
	{
		Res.AddItem(FormatFact(Edge));
	}

	return Res;
}

function string FormatSingleFact()
{
	`assert(Kind == eCHROWK_OrderCorrectDifferentGroup || Kind == eCHROWK_OrderIncorrectDifferentGroup);
	return FormatFact(Edges[0]);
}

function string FormatGroups()
{
	local CHRunOrderDesiredEdge Edge;
	local string FmtString;
	`assert(Kind == eCHROWK_OrderCorrectDifferentGroup || Kind == eCHROWK_OrderIncorrectDifferentGroup);

	switch (Kind)
	{
		case eCHROWK_OrderIncorrectDifferentGroup:
			FmtString = "%FID is in group %FGROUP and %SID is in group %SGROUP, so %FID will never run before %SID";
			break;
		case eCHROWK_OrderCorrectDifferentGroup:
			FmtString = "%FID is in group %FGROUP and %SID is in group %SGROUP, so %FID will always run before %SID";
			break;
	}

	Edge = Edges[0];
	FmtString = Repl(FmtString, "%FID", Edge.FirstNode.DLCInfoClass.DLCIdentifier);
	FmtString = Repl(FmtString, "%SID", Edge.SecondNode.DLCInfoClass.DLCIdentifier);
	FmtString = Repl(FmtString, "%FGROUP", Edge.FirstNode.RunPriorityGroup);
	FmtString = Repl(FmtString, "%SGROUP", Edge.SecondNode.RunPriorityGroup);

	return FmtString;
}

private function string FormatFact(CHRunOrderDesiredEdge Edge)
{
	local string FmtString;
	switch (Edge.EdgeSource)
	{
		case SOURCE_RunBefore:
			FmtString = "%FID wants to run before %SID";
			break;
		case SOURCE_RunAfter:
			FmtString = "%SID wants to run after %FID";
			break;
		case SOURCE_Both:
			FmtString = "%FID wants to run before %SID and %SID wants to run after %FID";
			break;
	}

	FmtString = Repl(FmtString, "%FID", Edge.FirstNode.DLCInfoClass.DLCIdentifier);
	FmtString = Repl(FmtString, "%SID", Edge.SecondNode.DLCInfoClass.DLCIdentifier);

	return FmtString;
}