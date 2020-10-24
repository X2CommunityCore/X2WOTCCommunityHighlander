//---------------------------------------------------------------------------------------
//  FILE:    XComLWTuple.uc
//  AUTHOR:  tracktwo / Pavonis Interactive
//  PURPOSE: A general-purpose data structure for sharing information between mods.
//
/// HL-Docs: feature:XComLWTuple; issue:754; tags:events
///
/// XComLWTuple is based on the original LWTuple that many other mods package themselves,
/// but it cannot be used interchangeably with that class. That means you *have* to use
/// XComLWTuple for community highlander hooks that rely on it.
///
/// LWTuple can be used to pass information between two mods without those mods needing to 
/// share any additional class types. Typically this information is passed using the XCOM2
/// event system: an event trigger passes an LWTuple as the EventData, and the listeners
/// can retrieve this LWTuple. Data can be passed in both directions through this system,
/// and the only type they both need to know about is LWTuple.
///
/// LWTuples contain an id (a name) and an array of LWTValue values. The name is
/// arbitrary and can be used to allow the sender and receiver to validate they are working
/// with the tuple they are expecting. The data array holds the actual data to pass.
///
/// LWTValue values are a union-like structure, similar to the ASValue struct used by the
/// Scaleform system. A value can hold a bool, int, float, string, name, or object. Values
/// are used by setting the field corresponding to the type you wish to store (e.g. i for
/// int) and setting the kind field to the corresponding enum value (LWTVInt in this case).
/// Readers should read only the field corresponding to the kind set in the value.
///
/// To use a tuple with the event system, the code firing the event should "new" a LWTuple,
/// set its ID field to an appropriate name, optionally fill in any information needed by
/// the event listeners, and pass it as the EventData for the event.
///
/// Listeners should cast the EventData back to a LWTuple, validate that the result is not
/// none, that its ID is the one they are expecting, and that any contents are as expected.
/// They can then store any new data needed into the tuple by adding to the data array before
/// returning from the listener. These listeners should typically use ELDImmediate as their
/// deferral mode so that the results are immediately processed and passed back to the caller,
/// although mods may advertise longer-lived tuples that can be processed with other
/// deferral strategies.
///
/// Note that since multiple mods can all be listening on the same event there may be multiple
/// mods receiving the same tuple. If more than one mod needs to return data in a tuple that
/// was not intended to receive data from more than one mod a conflict occurs and these mods
/// may be incompatible.
class XComLWTuple extends Object;


/// HL-Docs: ref:XComLWTuple
/// ## List of data types
/// 
/// The kind of data stored in a XComLWTValue. Find the corresponding
/// struct property names in `XComLWTuple.uc` (see *Source code references*)
/// HL-Include:
enum XComLWTValueKind
{
    XComLWTVBool,
    XComLWTVInt,
    XComLWTVFloat,
    XComLWTVString,
    XComLWTVName,
    XComLWTVObject,
    XComLWTVVector,
    XComLWTVRotator,
    XComLWTVTile,
    XComLWTVArrayObjects,
    XComLWTVArrayInts,
    XComLWTVArrayFloats,
    XComLWTVArrayStrings,
    XComLWTVArrayNames,
    XComLWTVArrayVectors,
    XComLWTVArrayRotators,
    XComLWTVArrayTiles
};
///

// A single value stored in a tuple.
struct XComLWTValue
{
    var bool b;
    var int i;
    var float f;
    var String s;
    var name n;
    var Object o;
    var Vector v;
    var Rotator r;
    var TTile t;
    var array<Object> ao;
    var array<int> ai;
    var array<float> af;
    var array<string> as;
    var array<name> an;
    var array<Vector> av;
    var array<Rotator> ar;
    var array<TTile> at;

    var XComLWTValueKind kind;
};

// An arbitrary identifier for this tuple.
var name Id;

// The data stored within this tuple.
var array<XComLWTValue> Data;
