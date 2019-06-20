// Issue #511
// Create a DLCInfo loadorder system
class CHDLCInfoTopologicalOrderNode extends Object;

var X2DownloadableContentInfo DLCInfoClass;
var string DLCIdentifier;
var array<string> RunBefore;
var array<string> RunAfter;
var bool bVisited;