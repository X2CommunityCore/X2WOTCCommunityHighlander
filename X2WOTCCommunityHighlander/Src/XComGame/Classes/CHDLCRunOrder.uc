/// HL-Docs: feature:DLCRunOrder; issue:511; tags:compatibility
/// The base game and Highlander have many "DLC hooks": Overridable
/// functions in `X2DownloadableContentInfo` that the game calls for all mods
/// in some order so that mods can do something. The most ubiquitous hook
/// is `OnPostTemplatesCreated`, which allows mods to modify templates.
///
/// Unfortunately, the order in which the DLC hooks of mods are executed
/// ("run order") depends on load order, which is [not guaranteed][blog].
/// However, run order can matter a lot. Consider a mod that creates copies
/// of guns with different visuals: This mod really wants to run after mods that
/// make changes to specific guns (e.g. stat changes) so that the changes
/// translate to the copies.
///
/// The CHL Run Order system provides two ways for mods to specify their
/// position within the run order. This information is relayed to the
/// Highlander using configuration entries (XComGame.ini):
///
/// ```
/// [zzzWeaponSkinReplacer.X2DownloadableContentInfo_WeaponSkinReplacer]
/// DLCIdentifier="zzzWeaponSkinReplacer"
///
/// [zzzWeaponSkinReplacer CHDLCRunOrder]
/// +RunAfter=PrimarySecondaries
/// +RunAfter=XCOM2RPGOverhaul
/// +RunBefore=WOTCUnderbarrelAttachments
/// RunPriorityGroup=RUN_LAST
/// ```
///
/// Since this system is all about DLC Hooks, the important identifier here is
/// the `DLCIdentifier` corresponding to a `X2DownloadableContentInfo` class,
/// of which a mod may have zero, one or more. The DLCIdentifier is *case-sensitive*.
/// Run Order is about DLCInfos, not individual mods, and a mod may have an
/// X2DLCInfo that runs before a certain other X2DLCInfo and another that runs
/// after that other one.
///
/// ## Coarse (RunPriorityGroup)
///
/// `RunPriorityGroup` is a coarse way for DLCInfos to control when they run.
/// RunPriorityGroup can have three different values: `RUN_STANDARD`,
/// `RUN_FIRST` and `RUN_LAST`. `RUN_STANDARD` is the default. All DLCInfos
/// with `RUN_FIRST` always run before all `RUN_STANDARD` ones, and all
/// DLCInfos with `RUN_LAST` always run after all `RUN_STANDARD` ones.
///
/// A DLCInfo with `RunPriorityGroup=RUN_LAST` already runs after the vast
/// majority of other DLCInfos.
///
/// ## Fine (RunBefore/RunAfter)
///
/// Within these groups, DLCInfos can specify which other DLCInfos they run
/// before and after. `[A] +RunBefore="B"` is equivalent to specifying
/// `[B] +RunAfter="A"`. If `A` and `B` were in a different
/// `RunPriorityGroup`, their relative `RunBefore`/`RunAfter` lines would
/// be ignored.
///
/// ## Errors
///
/// The Highlander catches some potential configuration errors and writes them
/// to the log. Warnings and errors are printed to the log, errors are shown
/// to the user in combination with a list of DLCIdentifiers whose authors they
/// should report the error to.
///
/// * It is a *warning* for a DLCInfo B to `RunAfter` a DLCInfo A, or A to
///   `RunBefore` B, if A is in an earlier `RunPriorityGroup` than B, since
///   these config lines are redundant and always fulfilled.
/// * It is an *error* for a DLCInfo B to `RunAfter` a DLCInfo A, or A to
///   `RunBefore` B, if A is in a later `RunPriorityGroup` than B, since
///   these config lines are contradictions and never fulfilled.
/// * It is an *error* for any number of DLCInfos to cause a cycle, since
///   cycles have no solution that fulfills all requirements.
///
/// The console command `CHLDumpRunOrderInternals` can be used to print all
/// the information the CHL has about `X2DownloadableContentInfo` classes
/// to the log, for debugging purposes.
///
/// One configuration error that can't be caught is a missing `DLCIdentifier`.
/// If your `X2DownloadableContentInfo` subclass specifies a custom config
/// file via `config(CustomConfig)`, then the `DLCIdentifier` needs to go in
/// `XComCustomConfig.ini`, while the `CHDLCRunOrder` still goes in
/// `XComGame.ini`.
///
/// ## Splitting DLCInfo
///
/// Sometimes it can be useful to split your DLC Infos into two different
/// classes, one containing all changes that can run whenever (`RUN_STANDARD`)
/// and one that needs to make its changes last. You can simply create more
/// subclasses and specify run order for any of them:
///
/// `X2DownloadableContentInfo_NormalChanges.uc`
/// ```unrealscript
/// class X2DownloadableContentInfo_NormalChanges extends X2DownloadableContentInfo;
///
/// static event OnPostTemplatesCreated()
/// {
/// 	// Make regular changes here
/// }
/// ```
///
/// `X2DownloadableContentInfo_LastChanges.uc`
/// ```unrealscript
/// class X2DownloadableContentInfo_LastChanges extends X2DownloadableContentInfo;
///
/// static event OnPostTemplatesCreated()
/// {
/// 	// Make last changes here
/// }
/// ```
///
/// `XComGame.ini`
/// ```ini
/// [MyMod.X2DownloadableContentInfo_NormalChanges]
/// DLCIdentifier="MyModNormal"
/// [MyMod.X2DownloadableContentInfo_LastChanges]
/// DLCIdentifier="MyModLast"
///
/// [MyModLast CHDLCRunOrder]
/// RunPriorityGroup=RUN_LAST
/// ```
///
/// This combats the trend of mods to move all their changes to `RUN_LAST`
/// because they contain only one change that actually needs to run last.
/// This trend can be problematic because it requires explicit `RunAfter`
/// annotations in other mods if they want to run after your normal changes.
/// Splitting DLCInfos can help mods that use `RUN_LAST` do the right thing
/// by default.
///
/// [blog]: https://robojumper.github.io/too-real/load-order/
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
